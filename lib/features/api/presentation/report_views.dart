import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart' hide Icons;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/widgets/operation_feedback.dart';
import '../../settings/domain/settings_schema.dart';
import '../../settings/presentation/institution_branding.dart';
import '../domain/repository.dart';

class ReportView extends StatefulWidget {
  const ReportView({required this.kind, required this.repository, super.key});

  final String kind;
  final Repository repository;

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  final searchController = TextEditingController();
  late DateTime start;
  late DateTime end;
  String bmPeriod = 'Mensal';
  List<Json> rows = [];
  bool loading = true;
  bool exporting = false;
  String query = '';
  String? error;

  _ReportSpec get spec => _specs[widget.kind] ?? _specs['Créditos']!;
  bool get _pdfOnly =>
      widget.kind == 'Cartas' || widget.kind == 'Carta para BM';

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    start = DateTime(today.year, today.month, 1);
    end = today;
    _load();
  }

  @override
  void didUpdateWidget(covariant ReportView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      rows = [];
      query = '';
      searchController.clear();
      _load();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final values = await Future.wait([
        widget.repository.get('/clients?limit=100&offset=0'),
        widget.repository.get('/loans?limit=100&offset=0'),
        widget.repository.get('/requests?limit=100&offset=0'),
        widget.repository.get('/payments?limit=100&offset=0'),
        widget.repository.get('/accounts?limit=100&offset=0'),
        widget.repository.get('/cash-entries?limit=100&offset=0'),
      ]);
      if (!mounted) return;
      setState(() => rows = _buildRows(values));
    } catch (failure) {
      if (mounted) setState(() => error = feedbackMessage(failure));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Json> _buildRows(List<dynamic> values) {
    final clients = _maps(values[0]);
    final loans = _maps(values[1]);
    final requests = _maps(values[2]);
    final payments = _maps(values[3]);
    final accounts = _maps(values[4]);
    final cashEntries = _maps(values[5]);
    final clientNames = {
      for (final client in clients)
        '${client['id']}':
            '${client['name'] ?? client['full_name'] ?? 'Cliente'}',
    };
    if (widget.kind == 'Clientes') {
      return clients
          .map(
            (row) => <String, dynamic>{
              'Cliente': '${row['name'] ?? row['full_name'] ?? '—'}',
              'NUIT': '${row['tax_number'] ?? row['nuit'] ?? '—'}',
              'Telefone': '${row['phone'] ?? '—'}',
              'Estado': row['active'] == false ? 'Inactivo' : 'Activo',
              'Registo': _date(row['created_at']),
            },
          )
          .toList();
    }
    if (widget.kind == 'Financeiros') {
      return [
        ...accounts.map(
          (row) => <String, dynamic>{
            'Tipo': 'Conta',
            'Referência': '${row['code'] ?? row['id'] ?? '—'}',
            'Descrição': '${row['name'] ?? 'Conta financeira'}',
            'Montante': _money(row['balance_cents'] ?? row['balance']),
            'Data': _date(row['updated_at'] ?? row['created_at']),
          },
        ),
        ...cashEntries.map(
          (row) => <String, dynamic>{
            'Tipo': '${row['type'] ?? 'Movimento'}',
            'Referência': '${row['reference'] ?? row['id'] ?? '—'}',
            'Descrição': '${row['description'] ?? row['reason'] ?? '—'}',
            'Montante': _money(row['amount_cents'] ?? row['amount']),
            'Data': _date(row['created_at']),
          },
        ),
      ];
    }
    if (widget.kind == 'Diversos') {
      return [
        {
          'Indicador': 'Clientes registados',
          'Quantidade': '${clients.length}',
          'Montante': '—',
        },
        {
          'Indicador': 'Pedidos de crédito',
          'Quantidade': '${requests.length}',
          'Montante': _money(
            requests.fold<num>(
              0,
              (sum, row) =>
                  sum + (num.tryParse('${row['amount_cents'] ?? 0}') ?? 0),
            ),
          ),
        },
        {
          'Indicador': 'Créditos',
          'Quantidade': '${loans.length}',
          'Montante': _money(
            loans.fold<num>(
              0,
              (sum, row) =>
                  sum + (num.tryParse('${row['principal_cents'] ?? 0}') ?? 0),
            ),
          ),
        },
        {
          'Indicador': 'Pagamentos',
          'Quantidade': '${payments.length}',
          'Montante': _money(
            payments.fold<num>(
              0,
              (sum, row) =>
                  sum + (num.tryParse('${row['amount_cents'] ?? 0}') ?? 0),
            ),
          ),
        },
      ];
    }
    if (widget.kind == 'Cartas') {
      return loans
          .map(
            (row) => <String, dynamic>{
              'Referência': '${row['reference'] ?? row['id'] ?? '—'}',
              'Destinatário': clientNames['${row['client_id']}'] ?? 'Cliente',
              'Assunto': 'Comunicação sobre crédito',
              'Estado': '${row['status'] ?? 'activo'}',
            },
          )
          .toList();
    }
    if (widget.kind == 'Carta para BM') {
      return loans
          .map(
            (row) => <String, dynamic>{
              'Nº Operação': '${row['reference'] ?? row['id'] ?? '—'}',
              'Cliente': clientNames['${row['client_id']}'] ?? 'Cliente',
              'Desembolso': _date(row['disbursed_at'] ?? row['created_at']),
              'Montante': _money(row['principal_cents'] ?? row['amount_cents']),
              'Finalidade': '${row['purpose'] ?? 'Crédito'}',
              'Prestação': _money(row['installment_cents']),
              'Periodicidade': '${row['payment_frequency'] ?? 'Mensal'}',
              'Vencimento': _date(row['maturity_date']),
              'Taxa': _rate(row['annual_rate_bps'] ?? row['rate']),
              'Em dívida': _money(
                row['outstanding_cents'] ?? row['principal_cents'],
              ),
              'Em atraso': _money(row['overdue_cents']),
              'Dias atraso': '${row['days_overdue'] ?? 0}',
              'PPE': row['pep'] == true ? 'Sim' : 'Não',
            },
          )
          .toList();
    }
    if (widget.kind == 'Registos') {
      return [
        ...requests.map(
          (row) => <String, dynamic>{
            'Documento': 'Pedido de crédito',
            'Referência': '${row['reference'] ?? row['id'] ?? '—'}',
            'Data': _date(row['created_at']),
            'Estado': '${row['status'] ?? '—'}',
          },
        ),
        ...payments.map(
          (row) => <String, dynamic>{
            'Documento': 'Pagamento',
            'Referência': '${row['reference'] ?? row['id'] ?? '—'}',
            'Data': _date(row['created_at']),
            'Estado': '${row['status'] ?? 'confirmado'}',
          },
        ),
      ];
    }
    return loans
        .map(
          (row) => <String, dynamic>{
            'Crédito': '${row['reference'] ?? row['id'] ?? '—'}',
            'Cliente': clientNames['${row['client_id']}'] ?? 'Cliente',
            'Capital': _money(row['principal_cents'] ?? row['amount_cents']),
            'Taxa': _rate(row['annual_rate_bps'] ?? row['rate']),
            'Prazo': '${row['term_months'] ?? row['months'] ?? '—'} meses',
            'Estado': '${row['status'] ?? '—'}',
            'Saldo': _money(row['outstanding_cents'] ?? row['principal_cents']),
          },
        )
        .toList();
  }

  List<Json> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map((row) => Json.from(row)).toList()
      : <Json>[];

  List<Json> get shown {
    final normalized = _normalize(query.trim());
    return rows.where((row) {
      if (normalized.isEmpty) return true;
      return _normalize(row.values.join(' ')).contains(normalized);
    }).toList();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');

  String _date(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _money(dynamic value) {
    final amount = num.tryParse('${value ?? 0}') ?? 0;
    final normalized = amount.abs() >= 1000 ? amount / 100 : amount;
    return '${normalized.toStringAsFixed(2).replaceAll('.', ',')} MZN';
  }

  String _rate(dynamic value) {
    final rate = num.tryParse('${value ?? 0}') ?? 0;
    return '${(rate > 100 ? rate / 100 : rate).toStringAsFixed(2)}%';
  }

  Future<void> _pickDate(bool initial) async {
    final current = initial ? start : end;
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(today) ? today : current,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null && mounted) {
      setState(() {
        if (initial) {
          start = picked;
          if (widget.kind == 'Carta para BM' && bmPeriod == 'Trimestral') {
            end = _notAfterToday(_addMonths(picked, 3));
          } else if (picked.year == today.year && picked.month == today.month) {
            end = today;
          }
        } else {
          end = _notAfterToday(picked);
          if (widget.kind == 'Carta para BM' && bmPeriod == 'Trimestral') {
            start = _addMonths(end, -3);
          }
        }
      });
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    final targetMonth = date.month - 1 + months;
    final year = date.year + targetMonth ~/ 12;
    final month = targetMonth % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, date.day.clamp(1, lastDay));
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _notAfterToday(DateTime date) {
    final today = _today();
    return date.isAfter(today) ? today : date;
  }

  void _setBmPeriod(String value) {
    setState(() {
      bmPeriod = value;
      if (value == 'Trimestral') {
        start = _addMonths(end, -3);
      } else {
        start = DateTime(end.year, end.month, 1);
        end = _notAfterToday(end);
      }
    });
  }

  bool _hasDocumentIdentity(SettingsData settings) =>
      institutionAsset(settings, 'signature') != null &&
      institutionAsset(settings, 'stamp') != null;

  Future<bool> _validateDocumentIdentity() async {
    final settings = institutionBranding.value;
    if (_hasDocumentIdentity(settings)) return true;
    await showFeedbackDialog(
      context,
      title: 'Assinatura e carimbo obrigatórios',
      message:
          'Configure a assinatura autorizada e o carimbo oficial em Definições → Identidade e documentos antes de gerar cartas ou relatórios.',
      success: false,
    );
    return false;
  }

  Future<void> _export({required bool pdf, Json? row}) async {
    if (exporting || !await _validateDocumentIdentity()) return;
    setState(() => exporting = true);
    try {
      final extension = pdf ? 'pdf' : 'csv';
      final suffix = row == null ? '' : '_${_fileReference(row)}';
      final location = await getSaveLocation(
        suggestedName:
            '${widget.kind.toLowerCase().replaceAll(' ', '_')}$suffix.$extension',
      );
      if (location == null) return;
      final bytes = pdf ? await _buildPdf(row: row) : _buildCsv(row: row);
      await XFile.fromData(
        bytes,
        mimeType: pdf ? 'application/pdf' : 'text/csv',
      ).saveTo(location.path);
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: 'Documento gerado',
          message: 'O documento profissional foi guardado com sucesso.',
          success: true,
        );
      }
    } catch (failure) {
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: 'Documento não gerado',
          message: feedbackMessage(failure),
          success: false,
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  String _fileReference(Json row) {
    final value = row.values
        .map((value) => '$value'.trim())
        .firstWhere(
          (value) => value.isNotEmpty && value != '—',
          orElse: () => 'registo',
        );
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Uint8List _buildCsv({Json? row}) {
    final data = row == null ? shown : [row];
    final headers = data.isEmpty ? spec.columns : data.first.keys.toList();
    String escape(Object? value) => '"${'$value'.replaceAll('"', '""')}"';
    final text = [
      headers.map(escape).join(','),
      for (final row in data)
        headers.map((header) => escape(row[header] ?? '')).join(','),
    ].join('\r\n');
    return Uint8List.fromList(utf8.encode('\ufeff$text'));
  }

  Future<Uint8List> _buildPdf({Json? row}) async {
    final settings = institutionBranding.value;
    final name = institutionEmailSenderName(settings);
    final branding = await InstitutionDocument.create(settings: settings);
    final reportTitle = widget.kind == 'Carta para BM'
        ? 'Relatório ${bmPeriod.toLowerCase()} para o Banco de Moçambique'
        : spec.title;
    final reportSubtitle = widget.kind == 'Carta para BM'
        ? 'Reporte $bmPeriod segundo o modelo prudencial.'
        : spec.subtitle;
    final doc = pw.Document(title: reportTitle, author: name, creator: name);
    final data = row == null ? shown : [row];
    final headers = data.isEmpty ? spec.columns : data.first.keys.toList();
    final landscape = headers.length > 7;
    if (widget.kind == 'Carta para BM') {
      final bmLogo = (await rootBundle.load(
        'assets/images/banco-de-mocambique.png',
      )).buffer.asUint8List();
      doc.addPage(
        pw.MultiPage(
          pageTheme: branding
              .pageTheme(pageFormat: PdfPageFormat.a4.landscape)
              .copyWith(margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 20)),
          footer: branding.footer,
          build: (_) => [
            pw.Container(
              width: double.infinity,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(pw.MemoryImage(bmLogo), width: 68, height: 68),
                  pw.SizedBox(width: 18),
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        for (final title in const [
                          'BANCO DE MOÇAMBIQUE',
                          'DEPARTAMENTO DE SUPERVISÃO PRUDENCIAL',
                          'REPORTE PERIÓDICO DE INFORMAÇÕES DE MICROFINANÇAS',
                          'INSTITUIÇÕES SUJEITAS À MONITORIZAÇÃO',
                        ])
                          pw.Text(
                            title,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),
            pw.Text(
              'PERÍODO DE REPORTE: ${_date(end)} · ${bmPeriod.toUpperCase()}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _bmSectionTitle('1. IDENTIFICAÇÃO DA INSTITUIÇÃO'),
            pw.SizedBox(height: 8),
            _bmIdentity(branding, settings, name),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: .8),
            pw.SizedBox(height: 8),
            branding.table(
              headers: headers,
              rows: data.isEmpty
                  ? [headers.map((_) => '--').toList()]
                  : [
                      for (final reportRow in data)
                        [
                          for (final header in headers)
                            branding.value(reportRow[header]),
                        ],
                    ],
              compact: true,
            ),
            pw.SizedBox(height: 12),
            branding.sectionTitle('ASSINATURA'),
            branding.signature('Carta para BM'),
            pw.SizedBox(height: 12),
            _bmNotes(),
          ],
        ),
      );
      return doc.save();
    }
    doc.addPage(
      pw.MultiPage(
        pageTheme: branding.pageTheme(
          pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        ),
        header: branding.header,
        footer: branding.footer,
        build: (_) => [
          branding.title(reportTitle, subtitle: reportSubtitle),
          branding.information([
            'Período: ${_date(start)} a ${_date(end)}',
            'Emitido em: ${_date(DateTime.now())}',
            if (widget.kind == 'Carta para BM') 'Periodicidade: $bmPeriod',
          ]),
          if (widget.kind == 'Cartas') ...[
            pw.SizedBox(height: 18),
            pw.Text('Exmo.(a) Senhor(a),'),
            pw.SizedBox(height: 12),
            pw.Text(
              'Pela presente, $name comunica formalmente a informação constante do quadro abaixo. Este documento foi emitido para efeitos administrativos e de acompanhamento das operações de crédito.',
              textAlign: pw.TextAlign.justify,
            ),
          ],
          if (widget.kind == 'Carta para BM') ...[
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Column(
                children: [
                  branding.sectionTitle('BANCO DE MOÇAMBIQUE'),
                  branding.sectionTitle(
                    'DEPARTAMENTO DE SUPERVISÃO PRUDENCIAL',
                  ),
                  branding.sectionTitle(
                    'REPORTE PERIÓDICO DE INFORMAÇÕES DE MICROFINANÇAS',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            branding.sectionTitle('1. IDENTIFICAÇÃO DA INSTITUIÇÃO'),
            pw.Text('Denominação: $name'),
            pw.Text('Endereço: ${branding.value(settings['address'])}'),
            pw.Text('Província: ${branding.value(settings['province'])}'),
            pw.Text('Telefone: ${branding.value(settings['phone'])}'),
            pw.Text('Email: ${branding.value(settings['email'])}'),
          ],
          pw.SizedBox(height: 18),
          if (data.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(24),
              alignment: pw.Alignment.center,
              child: pw.Text('Sem registos para o período seleccionado.'),
            )
          else
            branding.table(
              headers: headers,
              rows: [
                for (final row in data)
                  [for (final header in headers) branding.value(row[header])],
              ],
              compact: landscape,
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            '${settings['documentNotes'] ?? 'Conserve este documento para efeitos de controlo e auditoria.'}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          branding.signature(widget.kind),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _bmSectionTitle(String text) => pw.Container(
    width: double.infinity,
    color: PdfColors.grey300,
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
  );

  pw.Widget _bmIdentity(
    InstitutionDocument branding,
    SettingsData settings,
    String name,
  ) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final item in <(String, String)>[
        ('Denominação:', name),
        ('Endereço:', branding.value(settings['address'])),
        ('Província:', branding.value(settings['province'])),
        ('Telefone:', branding.value(settings['phone'])),
        ('Email:', branding.value(settings['email'])),
        ('Nº de Trabalhadores:', branding.value(settings['employeeCount'])),
        (
          'Data de Início das Actividades:',
          branding.value(settings['activityStartDate']),
        ),
        (
          'Nome do Responsável pela Gestão da Instituição:',
          branding.value(settings['signer']),
        ),
        ('Instituição(ões) Representada(s):', name),
      ])
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '${item.$1}  ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.TextSpan(text: item.$2),
              ],
            ),
          ),
        ),
    ],
  );

  pw.Widget _bmNotes() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Notas Explicativas',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 3),
      for (final note in const [
        '1 - Número da operação de crédito',
        '2 - Nome do cliente',
        '3 - Data do desembolso inicial',
        '4 - Valor do crédito concedido',
        '5 - Finalidade do crédito desembolsado, designadamente para empresas, consumo ou habitação',
        '6 - Montante da prestação periódica para amortizar o crédito',
        '7 - Forma de pagamento acordada, designadamente diária, semanal, mensal ou anual',
        '8 - Data de vencimento do crédito desembolsado',
        '9 - Percentagem da taxa de juro aplicada ao crédito',
        '10 - Montante do crédito desembolsado que falta pagar, excluindo prestações em atraso',
        '11 - Montante das prestações em atraso incluindo capital e juros',
        '12 - Dias em atraso do pagamento das prestações',
        '13 - Crédito concedido a pessoas politicamente expostas',
      ])
        pw.Text(note, style: const pw.TextStyle(fontSize: 7)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final data = shown;
    final headers = data.isEmpty ? spec.columns : data.first.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              spec.icon,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spec.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(spec.subtitle),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: loading || exporting ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                if (widget.kind == 'Carta para BM')
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                      initialValue: bmPeriod,
                      decoration: const InputDecoration(
                        labelText: 'Periodicidade',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Mensal',
                          child: Text('Mensal'),
                        ),
                        DropdownMenuItem(
                          value: 'Trimestral',
                          child: Text('Trimestral'),
                        ),
                      ],
                      onChanged: (value) => _setBmPeriod(value ?? 'Mensal'),
                    ),
                  ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: _date(start)),
                    decoration: InputDecoration(
                      labelText: 'Data inicial',
                      suffixIcon: IconButton(
                        onPressed: () => _pickDate(true),
                        icon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: _date(end)),
                    decoration: InputDecoration(
                      labelText: 'Data final',
                      suffixIcon: IconButton(
                        onPressed: () => _pickDate(false),
                        icon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar nos resultados',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => query = value),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pré-visualização · ${data.length} registos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (!_pdfOnly) ...[
                      OutlinedButton.icon(
                        onPressed: loading || exporting
                            ? null
                            : () => _export(pdf: false),
                        icon: const Icon(Icons.table_view_outlined),
                        label: const Text('CSV'),
                      ),
                      const SizedBox(width: 10),
                    ],
                    FilledButton.icon(
                      onPressed: loading || exporting
                          ? null
                          : () => _export(pdf: true),
                      icon: exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(exporting ? 'A gerar…' : 'PDF'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!loading && data.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: Text('Sem registos para apresentar.')),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        for (final header in headers)
                          DataColumn(label: Text(header.toUpperCase())),
                        const DataColumn(label: Text('ACÇÕES')),
                      ],
                      rows: [
                        for (final row in data)
                          DataRow(
                            cells: [
                              for (final header in headers)
                                DataCell(Text('${row[header] ?? '—'}')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!_pdfOnly)
                                      IconButton(
                                        tooltip: 'Gerar CSV deste registo',
                                        onPressed: exporting
                                            ? null
                                            : () =>
                                                  _export(pdf: false, row: row),
                                        icon: const Icon(
                                          Icons.table_view_outlined,
                                        ),
                                      ),
                                    IconButton(
                                      tooltip: 'Gerar PDF deste registo',
                                      onPressed: exporting
                                          ? null
                                          : () => _export(pdf: true, row: row),
                                      icon: const Icon(
                                        Icons.picture_as_pdf_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportSpec {
  const _ReportSpec(this.title, this.subtitle, this.icon, this.columns);
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> columns;
}

const _specs = <String, _ReportSpec>{
  'Exportações': _ReportSpec(
    'Exportações de relatórios',
    'Gere documentos em PDF ou dados em CSV para análise e arquivo.',
    Icons.table_view_outlined,
    ['Crédito', 'Cliente', 'Capital', 'Estado'],
  ),
  'Registos': _ReportSpec(
    'Registos documentais',
    'Pedidos, pagamentos e documentos emitidos.',
    Icons.receipt_long_outlined,
    ['Documento', 'Referência', 'Data', 'Estado'],
  ),
  'Cartas': _ReportSpec(
    'Cartas e comunicações',
    'Comunicações institucionais personalizadas e assinadas.',
    Icons.alternate_email,
    ['Referência', 'Destinatário', 'Assunto', 'Estado'],
  ),
  'Carta para BM': _ReportSpec(
    'Carta e reporte para o Banco de Moçambique',
    'Reporte mensal ou trimestral segundo o modelo prudencial.',
    Icons.calendar_today_outlined,
    [
      'Nº Operação',
      'Cliente',
      'Desembolso',
      'Montante',
      'Finalidade',
      'Prestação',
      'Periodicidade',
      'Vencimento',
      'Taxa',
      'Em dívida',
      'Em atraso',
      'Dias atraso',
      'PPE',
    ],
  ),
  'Créditos': _ReportSpec(
    'Relatórios de créditos',
    'Carteira, taxas, prazos, estados e saldos.',
    Icons.wallet,
    ['Crédito', 'Cliente', 'Capital', 'Taxa', 'Prazo', 'Estado', 'Saldo'],
  ),
  'Clientes': _ReportSpec(
    'Relatórios de clientes',
    'Cadastro e estado dos clientes da instituição.',
    Icons.people,
    ['Cliente', 'NUIT', 'Telefone', 'Estado', 'Registo'],
  ),
  'Financeiros': _ReportSpec(
    'Relatórios financeiros',
    'Contas, movimentos, receitas e despesas.',
    Icons.analytics,
    ['Tipo', 'Referência', 'Descrição', 'Montante', 'Data'],
  ),
  'Diversos': _ReportSpec(
    'Relatórios diversos',
    'Indicadores consolidados de operação e desempenho.',
    Icons.apps,
    ['Indicador', 'Quantidade', 'Montante'],
  ),
};
