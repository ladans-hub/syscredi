import 'dart:typed_data';
import '../../settings/presentation/institution_branding.dart';
import 'package:flutter/material.dart' hide Icons;
import 'package:file_selector/file_selector.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/widgets/operation_feedback.dart';

class ReportView extends StatelessWidget {
  const ReportView({required this.kind, super.key});
  final String kind;

  @override
  Widget build(BuildContext context) {
    final config = _configs[kind] ?? _configs['Créditos']!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              config.icon,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(config.subtitle),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _export(context, pdf: true),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Gerar PDF'),
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
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    initialValue: '2026',
                    decoration: const InputDecoration(labelText: 'Ano'),
                    items: const [
                      DropdownMenuItem(value: '2026', child: Text('2026')),
                      DropdownMenuItem(value: '2025', child: Text('2025')),
                    ],
                    onChanged: (_) {},
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Data inicial',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Data final',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar cliente, contrato ou referência',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _summary(context, config),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pré-visualização',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                _tableHeader(context),
                for (final row in config.rows) _row(context, row),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _export(context, pdf: false),
                      icon: const Icon(Icons.table_view_outlined),
                      label: const Text('Excel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () => _export(context, pdf: true),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary(BuildContext context, _ReportConfig config) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      _metric(
        context,
        'Registos',
        config.rows.length.toString(),
        Icons.receipt_long_outlined,
      ),
      _metric(context, 'Montante', '128 450 MT', Icons.attach_money_rounded),
      _metric(context, 'Actualizado', '20/09/2026', Icons.sync),
    ],
  );
  Widget _metric(BuildContext c, String label, String value, IconData icon) =>
      SizedBox(
        width: 210,
        child: Card(
          child: ListTile(
            leading: Icon(icon, color: Theme.of(c).colorScheme.primary),
            title: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(label),
          ),
        ),
      );
  Widget _row(BuildContext context, List<String> values) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: Row(
      children: [for (final value in values) Expanded(child: Text(value))],
    ),
  );

  Widget _tableHeader(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Row(
      children: [
        Expanded(
          child: Text(
            'Descrição',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text('Valor', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text(
            'Referência',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  void _message(BuildContext context, String text) =>
      showFeedbackDialog(context, message: text);

  Future<void> _export(BuildContext context, {required bool pdf}) async {
    try {
      final extension = pdf ? 'pdf' : 'xls';
      final location = await getSaveLocation(
        suggestedName: '${kind.toLowerCase().replaceAll(' ', '_')}.$extension',
      );
      if (location == null) return;
      final rows = _configs[kind]?.rows ?? const <List<String>>[];
      if (pdf) {
        final document = pw.Document();
        final branding = InstitutionDocument();
        document.addPage(
          pw.MultiPage(
            pageTheme: branding.pageTheme(),
            header: branding.header,
            footer: branding.footer,
            build: (_) => [
              pw.Text(
                '${branding.data['tradeName']}',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                _configs[kind]?.title ?? kind,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(_configs[kind]?.subtitle ?? ''),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: const ['Descrição', 'Valor', 'Referência'],
                data: rows,
              ),
              branding.signature('Relatório'),
            ],
          ),
        );
        await XFile.fromData(
          await document.save(),
          mimeType: 'application/pdf',
        ).saveTo(location.path);
      } else {
        final lines = <String>[
          'Descrição,Valor,Referência',
          ...rows.map(
            (row) => row
                .map((value) => '"${value.replaceAll('"', '""')}"')
                .join(','),
          ),
        ];
        await XFile.fromData(
          Uint8List.fromList(lines.join('\n').codeUnits),
          mimeType: 'application/vnd.ms-excel',
        ).saveTo(location.path);
      }
      if (context.mounted)
        _message(context, 'Ficheiro exportado em ${location.path}');
    } catch (error) {
      if (context.mounted)
        _message(context, 'Não foi possível exportar: $error');
    }
  }
}

class _ReportConfig {
  const _ReportConfig(this.title, this.subtitle, this.icon, this.rows);
  final String title, subtitle;
  final IconData icon;
  final List<List<String>> rows;
}

const _configs = <String, _ReportConfig>{
  'Em PDF': _ReportConfig(
    'Relatórios em PDF',
    'Gere documentos oficiais prontos para partilha.',
    Icons.picture_as_pdf_outlined,
    [
      ['Estado da carteira', '20/09/2026', 'PDF'],
      ['Contratos activos', '48 registos', 'PDF'],
    ],
  ),
  'Em Excel': _ReportConfig(
    'Relatórios em Excel',
    'Exporte dados operacionais para análise.',
    Icons.table_view_outlined,
    [
      ['Carteira de crédito', '48 contratos', 'XLSX'],
      ['Movimentos financeiros', '126 registos', 'XLSX'],
    ],
  ),
  'Registos': _ReportConfig(
    'Registos de relatórios',
    'Consulte o histórico de relatórios gerados e exportados.',
    Icons.receipt_long_outlined,
    [
      ['Estado da carteira', '20/09/2026 16:40', 'PDF'],
      ['Carteira de crédito', '20/09/2026 16:32', 'XLS'],
      ['Relatório financeiro', '19/09/2026 09:15', 'PDF'],
    ],
  ),
  'Cartas': _ReportConfig(
    'Cartas e comunicações',
    'Prepare cartas de envio, aprovação, autorização e comunicação ao cliente.',
    Icons.alternate_email,
    [
      ['Carta de envio ao Banco de Moçambique', 'BM-2026-0098', 'Pronta'],
      ['Carta de aprovação de crédito', 'CR-2026-0303', 'Pronta'],
      [
        'Carta de autorização de desembolso',
        'CR-2026-0303',
        'Pendente assinatura',
      ],
      ['Carta de reestruturação', 'CR-2026-0298', 'Rascunho'],
    ],
  ),
  'Mensal para BM': _ReportConfig(
    'Relatório mensal para o Banco de Moçambique',
    'Reporte o período mensal da instituição.',
    Icons.calendar_today_outlined,
    [
      ['Período de apuração', 'Setembro 2026', '01/09–30/09'],
      ['Bancos — mês 1', '877 760 MT', 'Conta operacional'],
      ['Bancos — mês 2', '897 777 MT', 'Conta operacional'],
      ['Bancos — mês 3', '909 900 MT', 'Conta operacional'],
      ['Caixa — mês 1', '89 777 MT', 'Disponibilidade'],
      ['Caixa — mês 2', '90 990 MT', 'Disponibilidade'],
      ['Empréstimos obtidos', '128 450 MT', '24 operações'],
      ['Donativos obtidos', '0 MT', 'Período'],
      ['Aumento de capital próprio', '50 000 MT', 'Período'],
      ['Capitais próprios', '480 000 MT', 'Saldo final'],
      ['Capitais alheios', '768 600 MT', 'Saldo final'],
    ],
  ),
  'Trimestral para BM': _ReportConfig(
    'Relatório trimestral para o Banco de Moçambique',
    'Consolide a situação financeira do trimestre.',
    Icons.calendar_today_outlined,
    [
      ['Período', '1.º trimestre 2026', '01/01–31/03'],
      ['Capital próprio', '480 000 MT', 'T1 2026'],
      ['Capital alheio', '768 600 MT', 'T1 2026'],
      ['Financiamentos concedidos', '68', '1 248 600 MT'],
      ['Créditos vigentes', '52', '914 200 MT'],
      ['Créditos em risco', '8', '84 600 MT'],
      ['Receitas financeiras', '84 500 MT', 'T1 2026'],
      ['Despesas operacionais', '32 700 MT', 'T1 2026'],
    ],
  ),
  'Créditos': _ReportConfig(
    'Relatórios de créditos',
    'Acompanhe autorizados, aprovados, vigentes e em risco.',
    Icons.wallet,
    [
      ['Autorizados', '18', '96 400 MT'],
      ['Aprovados', '24', '128 450 MT'],
      ['Vigentes', '52', '914 200 MT'],
      ['Por aprovar', '11', '68 400 MT'],
      ['Por autorizar', '7', '42 000 MT'],
      ['Por desembolsar', '5', '28 600 MT'],
      ['Em risco', '6', '24 800 MT'],
      ['Liquidados', '31', '420 800 MT'],
      ['Reestruturados', '4', '31 200 MT'],
    ],
  ),
  'Clientes': _ReportConfig(
    'Relatórios de clientes',
    'Consulte clientes, avalistas e co-devedores.',
    Icons.people,
    [
      ['Particulares', '128', 'Activos'],
      ['Cooperativos', '24', 'Activos'],
      ['Activos', '152', '96,8%'],
      ['Inactivos', '17', '3,2%'],
      ['Avalistas', '86', 'Registados'],
      ['Co-devedores', '34', 'Registados'],
      ['Novos no período', '18', 'Setembro 2026'],
    ],
  ),
  'Financeiros': _ReportConfig(
    'Relatórios financeiros',
    'Analise receitas, despesas, saldos e inadimplência.',
    Icons.analytics,
    [
      ['Receitas', '84 500 MT', 'Este mês'],
      ['Despesas', '32 700 MT', 'Este mês'],
      ['Saldo de caixa', '596 064 MT', 'Actual'],
      ['Saldo bancário', '877 760 MT', 'Actual'],
      ['Inadimplentes', '9', '18 240 MT'],
      ['Juros recebidos', '21 600 MT', 'Este mês'],
      ['Taxas administrativas', '8 450 MT', 'Este mês'],
    ],
  ),
  'Diversos': _ReportConfig(
    'Relatórios diversos',
    'Desempenho, reembolsos, garantias e utilizadores.',
    Icons.apps,
    [
      ['Desempenho', '94,2%', 'Meta mensal'],
      ['Garantias', '42', 'Registadas'],
      ['Utilizadores', '12', 'Activos'],
    ],
  ),
};
