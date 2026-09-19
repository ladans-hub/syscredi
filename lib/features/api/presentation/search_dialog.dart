import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../domain/repository.dart';

typedef SearchDestination = ({String path, String title, IconData icon});
typedef SearchSelection = ({String path, String query});

class WorkspaceSearchDialog extends StatefulWidget {
  const WorkspaceSearchDialog({
    required this.destinations,
    required this.repository,
    super.key,
  });

  final List<SearchDestination> destinations;
  final Repository repository;

  @override
  State<WorkspaceSearchDialog> createState() => _WorkspaceSearchDialogState();
}

class _WorkspaceSearchDialogState extends State<WorkspaceSearchDialog> {
  final controller = TextEditingController();
  Timer? debounce;
  String scope = 'areas';
  List<Json> results = [];
  bool loading = false;
  String? error;
  int generation = 0;

  String normalize(String value) {
    var text = value.toLowerCase().trim();
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const plain = 'aaaaaeeeeiiiiooooouuuuc';
    for (var i = 0; i < accents.length; i++) {
      text = text.replaceAll(accents[i], plain[i]);
    }
    return text;
  }

  void refresh() {
    debounce?.cancel();
    final current = ++generation;
    setState(() {
      results = [];
      error = null;
      loading = scope != 'areas' && controller.text.trim().isNotEmpty;
    });
    if (!loading) return;
    final path = scope;
    final query = controller.text.trim();
    debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final data = await widget.repository.get(
          '/$path?limit=12&offset=0&q=${Uri.encodeQueryComponent(query)}',
        );
        if (!mounted || generation != current) return;
        setState(
          () => results = (data as List)
              .map((row) => Map<String, dynamic>.from(row as Map))
              .toList(),
        );
      } catch (_) {
        if (!mounted || generation != current) return;
        setState(() => error = 'Não foi possível pesquisar. Tente novamente.');
      } finally {
        if (mounted && generation == current) {
          setState(() => loading = false);
        }
      }
    });
  }

  void open(String path, [String query = '']) {
    Navigator.of(context).pop<SearchSelection>((path: path, query: query));
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final query = controller.text.trim();
    final destinations = widget.destinations
        .where((item) => normalize(item.title).contains(normalize(query)))
        .toList();
    final scopes = widget.destinations.where(
      (item) => ['clients', 'requests', 'contracts'].contains(item.path),
    );
    return Dialog(
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 64,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: .96),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: .6),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 12, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: colors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Pesquisa',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Fechar pesquisa',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, size: 20),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          onChanged: (_) => refresh(),
                          onSubmitted: (_) {
                            if (scope == 'areas' && destinations.isNotEmpty) {
                              open(destinations.first.path);
                            } else if (scope != 'areas' && query.isNotEmpty) {
                              open(scope, query);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: scope == 'areas'
                                ? 'Que área procura?'
                                : 'Pesquise por nome ou referência…',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpar pesquisa',
                                    onPressed: () {
                                      controller.clear();
                                      refresh();
                                    },
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                            filled: true,
                            fillColor: colors.surface,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colors.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final item in [
                                (
                                  path: 'areas',
                                  title: 'Áreas',
                                  icon: Icons.grid_view_rounded,
                                ),
                                ...scopes,
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    avatar: Icon(item.icon, size: 16),
                                    label: Text(item.title),
                                    selected: scope == item.path,
                                    onSelected: (_) {
                                      scope = item.path;
                                      refresh();
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: loading
                            ? const Center(child: CircularProgressIndicator())
                            : error != null
                            ? _message(
                                Icons.cloud_off_outlined,
                                error!,
                                retry: true,
                              )
                            : scope == 'areas'
                            ? destinations.isEmpty
                                  ? _message(
                                      Icons.search_off_rounded,
                                      'Nenhuma área encontrada. Experimente outro termo.',
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: destinations.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == 0) {
                                          return Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              12,
                                              4,
                                              12,
                                              10,
                                            ),
                                            child: Text(
                                              query.isEmpty
                                                  ? 'ACESSO RÁPIDO'
                                                  : 'ÁREAS ENCONTRADAS',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        colors.onSurfaceVariant,
                                                    letterSpacing: 1.2,
                                                  ),
                                            ),
                                          );
                                        }
                                        final item = destinations[index - 1];
                                        return ListTile(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          leading: Icon(
                                            item.icon,
                                            color: colors.primary,
                                          ),
                                          title: Text(item.title),
                                          subtitle: const Text(
                                            'Abrir área de trabalho',
                                          ),
                                          trailing: const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                          ),
                                          onTap: () => open(item.path),
                                        );
                                      },
                                    )
                            : query.isEmpty
                            ? _message(
                                Icons.manage_search_rounded,
                                'Introduza um nome ou referência para começar.',
                              )
                            : results.isEmpty
                            ? _message(
                                Icons.search_off_rounded,
                                'Nenhum resultado encontrado. Experimente outro termo.',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: results.length,
                                itemBuilder: (context, index) {
                                  final row = results[index];
                                  final id = '${row['id'] ?? ''}';
                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    leading: Icon(
                                      scopes
                                          .firstWhere(
                                            (item) => item.path == scope,
                                          )
                                          .icon,
                                      color: colors.primary,
                                    ),
                                    title: Text(
                                      '${row['name'] ?? row['client_name'] ?? row['reference'] ?? id}',
                                    ),
                                    subtitle: Text(
                                      'Referência: $id',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                    ),
                                    onTap: () =>
                                        open(scope, id.isEmpty ? query : id),
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard_return_rounded,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Enter para abrir · Esc para fechar',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(IconData icon, String text, {bool retry = false}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),
          if (retry)
            TextButton(
              onPressed: refresh,
              child: const Text('Tentar novamente'),
            ),
        ],
      ),
    ),
  );
}
