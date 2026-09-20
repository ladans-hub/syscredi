import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../app/theme/app_theme.dart';
import '../domain/settings_schema.dart';

final institutionBranding = ValueNotifier<SettingsData>(defaultSettings());

Uint8List? institutionAsset(SettingsData data, String key) {
  final asset = (data['assets'] as Map?)?[key];
  if (asset is! Map || asset['data'] is! String) return null;
  try {
    return base64Decode(asset['data'] as String);
  } catch (_) {
    return null;
  }
}

void applyInstitutionSettings(SettingsData data) {
  // Asset and palette updates reuse this function. Only a real change to the
  // persisted theme setting may change the active system theme; uploading a
  // logo or editing another branding field must preserve the current mode.
  final previousTheme = institutionBranding.value['theme'];
  final themeChanged = '${data['theme']}' != '$previousTheme';
  institutionBranding.value = data;
  brandPalette.value = BrandPalette(
    parseBrandColor('${data['primaryColor']}', green),
    parseBrandColor('${data['secondaryColor']}', navy),
  );
  final assets = data['assets'] as Map;
  String? image(String key) => assets[key] is Map
      ? 'data:image/png;base64,${assets[key]['data']}'
      : null;
  brandVisuals.value = BrandVisuals(
    logo: image('logo'),
    alternateLogo: image('alternate'),
    favicon: image('favicon'),
    institutionName: '${data['tradeName']}',
    institutionBio: '${data['institutionBio']}',
    compactSidebar: data['sidebar'] == 'Compacto',
    navigationIcons: data['navigation'] != 'Texto',
    watermark: image('logo'),
    stamp: image('stamp'),
    signature: image('signature'),
    fontFamily: '${data['fontFamily']}',
    fontScale: (num.tryParse('${data['fontScale']}') ?? 100) / 100,
    watermarkEnabled: data['watermarkPages'] == true,
    watermarkOpacity: (num.tryParse('${data['watermarkOpacity']}') ?? 6) / 100,
    watermarkSize: (num.tryParse('${data['watermarkSize']}') ?? 320).toDouble(),
    watermarkPosition: '${data['watermarkPosition']}',
    radius: (num.tryParse('${data['radius']}') ?? 8).toDouble(),
    density: '${data['density']}',
    accent: parseBrandColor('${data['accentColor']}', const Color(0xff0078d4)),
  );
  if (themeChanged) {
    themeMode.value = switch (data['theme']) {
      'Claro' => ThemeMode.light,
      'Escuro' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
  currencyCode.value = '${data['currency']}';
  localeCode.value = data['language'] == 'English'
      ? 'en'
      : data['language'] == 'Português (Portugal)'
      ? 'pt_PT'
      : 'pt_MZ';
}

/// Displays the configured institution name and updates immediately after a
/// settings save. The product name remains the fallback before configuration.
class InstitutionNameText extends StatelessWidget {
  const InstitutionNameText({
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  });
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<SettingsData>(
    valueListenable: institutionBranding,
    builder: (context, data, _) => Text(
      '${data['tradeName'] ?? ''}'.trim().isEmpty
          ? 'SysCredi'
          : '${data['tradeName']}',
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    ),
  );
}

class InstitutionBioText extends StatelessWidget {
  const InstitutionBioText({
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  });
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<SettingsData>(
    valueListenable: institutionBranding,
    builder: (context, data, _) => Text(
      '${data['institutionBio'] ?? ''}'.trim().isEmpty
          ? 'Microcrédito, grandes histórias'
          : '${data['institutionBio']}',
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    ),
  );
}

/// Shared document furniture: report exports and institutional A4 preview use
/// the same settings, assets and signatory lookup.
class InstitutionDocument {
  InstitutionDocument({SettingsData? settings})
    : data = settings ?? institutionBranding.value;
  final SettingsData data;
  pw.Widget header(pw.Context context) {
    final logo = institutionAsset(data, 'logo');
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        children: [
          if (logo != null) ...[
            pw.Image(pw.MemoryImage(logo), width: 55, height: 55),
            pw.SizedBox(width: 14),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${data['legalName']}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'NUIT ${data['nuit']} | ${data['license']}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  '${data['documentHeader']}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget footer(pw.Context context) => pw.Column(
    children: [
      pw.Divider(color: PdfColors.grey400),
      pw.Text(
        '${data['documentFooter']}',
        style: const pw.TextStyle(fontSize: 8),
      ),
      pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8),
      ),
    ],
  );
  pw.Widget signature(String type) {
    final signers = data['signers'] as List;
    final matches = signers.where((s) => s['document'] == type);
    final name = matches.isEmpty ? data['signer'] : matches.first['name'];
    final role = matches.isEmpty
        ? data['signerRole']
        : matches.first['position'];
    final signature = institutionAsset(data, 'signature');
    final stamp = institutionAsset(data, 'stamp');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 24),
        pw.Text(
          '${data['documentPlace']}${data['showDate'] == true ? ', ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}' : ''}',
        ),
        pw.Row(
          children: [
            if (signature != null)
              pw.Image(pw.MemoryImage(signature), width: 110, height: 50),
            if (stamp != null)
              pw.Image(pw.MemoryImage(stamp), width: 65, height: 65),
          ],
        ),
        pw.Text('$name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('$role'),
      ],
    );
  }

  pw.PageTheme pageTheme() {
    final logo = institutionAsset(data, 'logo');
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(38),
      buildBackground: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Align(
          alignment: switch (data['watermarkPosition']) {
            'Inferior direito' => pw.Alignment.bottomRight,
            'Superior esquerdo' => pw.Alignment.topLeft,
            _ => pw.Alignment.center,
          },
          child: data['watermarkDocuments'] == true
              ? pw.Opacity(
                  opacity:
                      (num.tryParse('${data['watermarkOpacity']}') ?? 6) / 100,
                  child: logo == null
                      ? pw.Text(
                          '${data['tradeName']}',
                          style: pw.TextStyle(
                            fontSize: 38,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        )
                      : pw.Image(
                          pw.MemoryImage(logo),
                          width:
                              (num.tryParse('${data['watermarkSize']}') ?? 320)
                                  .toDouble(),
                          height: 260,
                        ),
                )
              : pw.SizedBox(),
        ),
      ),
    );
  }

  Future<Uint8List> preview(String type) async {
    final doc = pw.Document();
    final template = (data['templates'] as List).firstWhere(
      (t) => t['document'] == type,
    );
    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme(),
        header: header,
        footer: footer,
        build: (_) => [
          pw.SizedBox(height: 22),
          pw.Text(
            '${template['title']}',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('PRÉ-VISUALIZAÇÃO - DOCUMENTO DE DEMONSTRAÇÃO'),
          pw.SizedBox(height: 18),
          pw.Text(
            '${template['body']}'
                .replaceAll('{instituicao}', '${data['tradeName']}')
                .replaceAll('{cliente}', 'Amélia João Massango')
                .replaceAll('{referencia}', 'CRE-2026-MPT-000304'),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Campo obrigatório', 'Valor demonstrativo'],
            data: [
              ['Cliente / NUIT', 'Amélia João Massango / 123456789'],
              ['Capital / moeda', '25 000,00 MZN'],
              ['Taxa / prazo', '3% por mês / 6 meses'],
              ['Plano de prestações', 'Conforme condições particulares'],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('${data['legalText']}'),
          pw.SizedBox(height: 12),
          pw.Text('${data['documentNotes']}'),
          signature(type),
        ],
      ),
    );
    return doc.save();
  }
}
