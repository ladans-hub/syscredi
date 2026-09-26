import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../app/theme/app_theme.dart';
import '../domain/settings_schema.dart';

final institutionBranding = ValueNotifier<SettingsData>(defaultSettings());

String institutionEmailSenderName([SettingsData? settings]) {
  final data = settings ?? institutionBranding.value;
  for (final key in ['tradeName', 'legalName']) {
    final value = '${data[key] ?? ''}'.trim();
    if (value.isNotEmpty) return value;
  }
  return 'Syscredi';
}

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
  InstitutionDocument({SettingsData? settings, Uint8List? fallbackLogo})
    : data = settings ?? institutionBranding.value,
      _fallbackLogo = fallbackLogo;
  final SettingsData data;
  final Uint8List? _fallbackLogo;

  static Future<InstitutionDocument> create({SettingsData? settings}) async {
    final bytes = (await rootBundle.load(
      'assets/images/logo.png',
    )).buffer.asUint8List();
    return InstitutionDocument(settings: settings, fallbackLogo: bytes);
  }

  Uint8List? get logo => institutionAsset(data, 'logo') ?? _fallbackLogo;

  String value(Object? raw) {
    final text = '${raw ?? ''}'.trim();
    return text.isEmpty ||
            text.toLowerCase() == 'null' ||
            text == '—' ||
            text == '�'
        ? '--'
        : text;
  }

  pw.Widget sectionTitle(String value) => pw.Container(
    width: double.infinity,
    alignment: pw.Alignment.center,
    child: pw.Text(
      value,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    ),
  );

  PdfColor get primaryColor {
    final value = '${data['primaryColor'] ?? ''}'.replaceFirst('#', '');
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null
        ? PdfColors.green800
        : PdfColor.fromInt(0xff000000 | parsed);
  }

  pw.Widget title(String value, {String? subtitle}) => pw.Container(
    width: double.infinity,
    alignment: pw.Alignment.center,
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 22),
        pw.Text(
          value.toUpperCase(),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        if (subtitle != null && subtitle.trim().isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
        pw.SizedBox(height: 14),
      ],
    ),
  );

  pw.Widget information(Iterable<String> values) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(4),
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Wrap(
      spacing: 18,
      runSpacing: 5,
      children: [
        for (final value in values)
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    ),
  );

  pw.Widget table({
    required List<String> headers,
    required List<List<String>> rows,
    bool compact = false,
  }) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerDecoration: pw.BoxDecoration(color: primaryColor),
    headerStyle: pw.TextStyle(
      color: PdfColors.white,
      fontWeight: pw.FontWeight.bold,
      fontSize: compact ? 6 : 8,
    ),
    cellStyle: pw.TextStyle(fontSize: compact ? 5.6 : 7.5),
    cellPadding: const pw.EdgeInsets.all(4),
    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
  );
  pw.Widget header(pw.Context context) {
    final documentLogo = logo;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (documentLogo != null)
            pw.Image(pw.MemoryImage(documentLogo), width: 70, height: 70),
          pw.SizedBox(height: 6),
          if (value(data['legalName']) != '—') ...[
            pw.Text(
              value(data['legalName']),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
          ],
          pw.Text(
            'NUIT ${data['nuit']} | ${data['license']}',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '${data['documentHeader']}',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9),
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
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(height: 42),
          pw.Text(
            '${data['documentPlace']}${data['showDate'] == true ? ', ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}' : ''}',
          ),
          pw.SizedBox(
            width: 140,
            height: 74,
            child: pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                if (signature != null)
                  pw.Positioned(
                    bottom: 6,
                    child: pw.Image(
                      pw.MemoryImage(signature),
                      width: 110,
                      height: 50,
                    ),
                  ),
                if (stamp != null)
                  pw.Positioned(
                    top: 0,
                    child: pw.Image(
                      pw.MemoryImage(stamp),
                      width: 65,
                      height: 65,
                    ),
                  ),
              ],
            ),
          ),
          pw.Container(width: 180, height: 1, color: PdfColors.grey700),
          pw.Text('$name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('$role'),
        ],
      ),
    );
  }

  pw.Widget _watermarkBackground() {
    final documentLogo = logo;
    return pw.Center(
      child: data['watermarkDocuments'] == true && documentLogo != null
          ? pw.Opacity(
              opacity: (num.tryParse('${data['watermarkOpacity']}') ?? 6) / 100,
              child: pw.Image(
                pw.MemoryImage(documentLogo),
                width:
                    (num.tryParse('${data['watermarkSize']}') ?? 320)
                        .toDouble() +
                    24,
                fit: pw.BoxFit.contain,
              ),
            )
          : pw.SizedBox(),
    );
  }

  pw.PageTheme pageTheme({PdfPageFormat pageFormat = PdfPageFormat.a4}) {
    return pw.PageTheme(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.all(38),
      buildBackground: (_) =>
          pw.FullPage(ignoreMargins: true, child: _watermarkBackground()),
    );
  }

  Future<Uint8List> preview(String type) async {
    if (_fallbackLogo == null && institutionAsset(data, 'logo') == null) {
      return (await InstitutionDocument.create(settings: data)).preview(type);
    }
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
          title('${template['title']}'),
          sectionTitle('PRÉ-VISUALIZAÇÃO - DOCUMENTO DE DEMONSTRAÇÃO'),
          pw.SizedBox(height: 18),
          pw.Text(
            '${template['body']}'
                .replaceAll('{instituicao}', '${data['tradeName']}')
                .replaceAll('{cliente}', 'Amélia João Massango')
                .replaceAll('{referencia}', 'CRE-2026-MPT-000304'),
          ),
          pw.SizedBox(height: 20),
          table(
            headers: ['Campo obrigatório', 'Valor'],
            rows: [
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
