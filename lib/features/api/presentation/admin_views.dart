import 'package:flutter/material.dart' hide Icons;
import '../../../app/theme/fluent_icons_compat.dart';

class AdminView extends StatelessWidget {
  const AdminView({required this.kind, super.key});
  final String kind;
  @override
  Widget build(BuildContext context) {
    final title = switch (kind) {
      'accounting' => 'Contabilidade',
      'sync' => 'Sincronização',
      'aml' => 'Alertas AML',
      'users' => 'Utilizadores',
      'backup' => 'Cópias de segurança',
      _ => 'Administração',
    };
    final icon = switch (kind) {
      'accounting' => Icons.menu_book_outlined,
      'sync' => Icons.sync,
      'aml' => Icons.shield,
      'users' => Icons.people,
      'backup' => Icons.download,
      _ => Icons.apps,
    };
    final rows = switch (kind) {
      'accounting' => const [
        ['20/09/2026', 'Recebimento CR-0303', '5 640 MT', 'Confirmado'],
        ['19/09/2026', 'Despesa operacional', '3 500 MT', 'Aprovado'],
      ],
      'sync' => const [
        ['API remota', '20/09/2026 16:42', '1 248', 'Operacional'],
        ['E-Mola', '20/09/2026 15:52', '3', 'Atenção'],
      ],
      'aml' => const [
        ['AML-2026-088', 'Júlio Custódio', 'Operações fraccionadas', 'Alto'],
        ['AML-2026-081', 'Empresa Maputo Lda', 'Volume atípico', 'Médio'],
      ],
      'users' => const [
        ['Naveia Muaquiquia João', 'Gestor', 'Hoje 16:40', 'Activo'],
        ['Marta João', 'Operadora', 'Hoje 15:20', 'Activo'],
      ],
      _ => const [
        ['20/09/2026 02:00', 'Completa', '248 MB', 'Válida'],
        ['19/09/2026 02:00', 'Completa', '247 MB', 'Válida'],
      ],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const Text(
                    'Gestão administrativa, controlo e rastreabilidade operacional.',
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _form(context, title),
              icon: const Icon(Icons.add),
              label: const Text('Novo registo'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          children: [
            _metric(context, 'Registos activos', '12'),
            _metric(context, 'Pendências', '03'),
            _metric(context, 'Última auditoria', 'Hoje 16:42'),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Pesquisar',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_alt_outlined),
                      label: const Text('Filtros'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('REFERÊNCIA')),
                      DataColumn(label: Text('DESCRIÇÃO')),
                      DataColumn(label: Text('VALOR/ESTADO')),
                      DataColumn(label: Text('SITUAÇÃO')),
                      DataColumn(label: Text('ACÇÕES')),
                    ],
                    rows: [
                      for (final row in rows)
                        DataRow(
                          cells: [
                            for (final value in row) DataCell(Text(value)),
                            DataCell(
                              IconButton(
                                tooltip: 'Ver detalhe',
                                onPressed: () => _details(context, title, row),
                                icon: const Icon(Icons.visibility_outlined),
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

  Widget _metric(BuildContext c, String label, String value) => SizedBox(
    width: 210,
    child: Card(
      child: ListTile(
        title: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(label),
      ),
    ),
  );
  void _details(BuildContext c, String title, List<String> row) =>
      showDialog<void>(
        context: c,
        builder: (dialog) => AlertDialog(
          title: Text('$title · detalhe'),
          content: Text(row.join('\n')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
  void _form(BuildContext c, String title) => showDialog<void>(
    context: c,
    builder: (dialog) => AlertDialog(
      title: Text('Novo registo · $title'),
      content: const SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Descrição')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Referência')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Observações')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
