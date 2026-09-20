part of 'institution_settings_view.dart';

extension _SettingsPanels on InstitutionSettingsViewState {
  List<Widget> _specialPanels() => switch (category) {
    'institution' => [
      _records(
        'branches',
        'Filiais e agências',
        ['Código', 'Agência', 'Endereço', 'Contacto', 'Responsável', 'Estado'],
        ['code', 'name', 'address', 'phone', 'manager', 'status'],
      ),
    ],
    'identity' => [
      _uploads(),
      _documentPreview(),
      _records(
        'signers',
        'Responsáveis por documento',
        ['Documento', 'Nome', 'Cargo'],
        ['document', 'name', 'position'],
        allowAdd: false,
      ),
    ],
    'users' => [_usersPanel(), _permissionsPanel()],
    'security' => [_sessionsPanel(), _auditPanel()],
    'appearance' => [],
    'credit' => [
      _notice(
        'Herança dos produtos: os parâmetros globais funcionam como base. A sobrescrita por produto fica limitada aos campos e limites autorizados; neste ambiente não altera contratos nem cálculos existentes.',
      ),
    ],
    'workflow' => [_workflowPanel()],
    'numbering' => [
      _sequencesPanel(),
      _records(
        'templates',
        'Templates de documentos',
        ['Documento', 'Título', 'Texto complementar', 'Activo'],
        ['document', 'title', 'body', 'active'],
        allowAdd: false,
      ),
      _notice(
        'Campos obrigatórios preservados: identificação das partes, capital, moeda, juros, prazo e plano de prestações. O texto complementar não substitui estes campos.',
      ),
      _documentPreview(),
    ],
    'finance' => [
      _records(
        'accounts',
        'Contas de caixa e banco',
        ['Código', 'Conta', 'Tipo', 'Moeda', 'Estado'],
        ['code', 'name', 'type', 'currency', 'status'],
      ),
    ],
    'notifications' => [_messagesPanel()],
    'data' => [_dataPanel(), _integrationsPanel(), _auditPanel()],
    'regional' => [_regionalPreview()],
    _ => [],
  };

  Widget _panel(
    String title,
    Widget child, {
    Widget? action,
    String? description,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              ?action,
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );

  Widget _table(
    List<String> headings,
    List<List<Widget>> rows,
  ) => LayoutBuilder(
    builder: (context, constraints) => Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.primary.withValues(alpha: .06),
            ),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            dataRowMinHeight: 56,
            dataRowMaxHeight: 76,
            horizontalMargin: 12,
            columnSpacing: 22,
            columns: headings.map((h) => DataColumn(label: Text(h))).toList(),
            rows: rows.indexed
                .map(
                  (e) => DataRow(
                    color: data['stripedTables'] == true && e.$1.isOdd
                        ? WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.surfaceContainerLow,
                          )
                        : null,
                    cells: e.$2.map(DataCell.new).toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ),
  );

  Widget _cell(String value, {double width = 180}) => SizedBox(
    width: width,
    child: Tooltip(
      message: value,
      child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
    ),
  );

  Widget _records(
    String key,
    String title,
    List<String> headings,
    List<String> columns, {
    bool allowAdd = true,
  }) {
    final rows = (data[key] as List).cast<Map>();
    return _panel(
      title,
      rows.isEmpty
          ? const Text(
              'Ainda não existem registos. Adicione o primeiro para começar.',
            )
          : _table(
              [...headings, 'Acções'],
              [
                for (final (index, row) in rows.indexed)
                  [
                    for (final column in columns)
                      column == 'status' || column == 'active'
                          ? _badge('${row[column]}')
                          : _cell(
                              '${row[column]}',
                              width: column == 'body' || column == 'address'
                                  ? 260
                                  : 155,
                            ),
                    IconButton(
                      tooltip: 'Editar ${row[columns.first]}',
                      onPressed: () =>
                          _editRecord(key, index, columns, headings),
                      icon: const Icon(FluentIcons.edit, size: 16),
                    ),
                  ],
              ],
            ),
      action: allowAdd
          ? OutlinedButton.icon(
              onPressed: () => _editRecord(key, null, columns, headings),
              icon: const Icon(FluentIcons.add, size: 14),
              label: const Text('Adicionar'),
            )
          : null,
    );
  }

  Widget _usersPanel() {
    final users = (data['users'] as List).cast<Map>();
    final filtered = users
        .where(
          (u) =>
              (_userStatus == 'Todos' || u['status'] == _userStatus) &&
              '${u['name']} ${u['email']} ${u['role']} ${u['branch']}'
                  .toLowerCase()
                  .contains(_userSearch.text.toLowerCase()),
        )
        .toList();
    final pages = (filtered.length / 5).ceil();
    final page = _userPage.clamp(0, pages == 0 ? 0 : pages - 1);
    return _panel(
      'Utilizadores da instituição',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge('${users.length} utilizadores'),
              _badge(
                '${users.where((u) => u['status'] == 'Activo').length} activos',
              ),
              _badge('${(data['roles'] as List).length} perfis'),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: c.maxWidth < 340 ? c.maxWidth : 340,
                  child: TextField(
                    controller: _userSearch,
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar utilizadores',
                      prefixIcon: Icon(FluentIcons.search, size: 16),
                    ),
                    onChanged: (_) => _rebuild(() => _userPage = 0),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    initialValue: _userStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: ['Todos', 'Activo', 'Inactivo', 'Bloqueado']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => _rebuild(() {
                      _userStatus = v!;
                      _userPage = 0;
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _notice('Nenhum utilizador corresponde aos filtros.')
          else
            _table(
              [
                'Utilizador',
                'Perfil / agência',
                'Estado',
                'Último acesso',
                'Acções',
              ],
              [
                for (final user in filtered.skip(page * 5).take(5))
                  [
                    SizedBox(
                      width: 245,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            child: Text('${user['name']}'.substring(0, 1)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user['name']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${user['email']}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _cell('${user['role']} · ${user['branch']}', width: 155),
                    _badge('${user['status']}'),
                    _cell('${user['lastAccess']}', width: 140),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Consultar ${user['name']}',
                          onPressed: () => _userDetails(user),
                          icon: const Icon(FluentIcons.contact, size: 16),
                        ),
                        IconButton(
                          tooltip: 'Editar ${user['name']}',
                          onPressed: () => _editUser(users.indexOf(user)),
                          icon: const Icon(FluentIcons.edit, size: 16),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Acções do utilizador',
                          onSelected: (action) =>
                              _userAction(users.indexOf(user), action),
                          itemBuilder: (_) => [
                            for (final action in [
                              'Activar',
                              'Desactivar',
                              'Bloquear',
                              'Recuperar acesso',
                            ])
                              PopupMenuItem(value: action, child: Text(action)),
                          ],
                        ),
                      ],
                    ),
                  ],
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('${filtered.length} utilizadores encontrados'),
              ),
              IconButton(
                tooltip: 'Utilizadores anteriores',
                onPressed: page > 0 ? () => _rebuild(() => _userPage--) : null,
                icon: const Icon(FluentIcons.chevron_left, size: 14),
              ),
              Text('${pages == 0 ? 0 : page + 1} / $pages'),
              IconButton(
                tooltip: 'Próximos utilizadores',
                onPressed: page + 1 < pages
                    ? () => _rebuild(() => _userPage++)
                    : null,
                icon: const Icon(FluentIcons.chevron_right, size: 14),
              ),
            ],
          ),
        ],
      ),
      action: FilledButton.icon(
        onPressed: () => _editUser(null),
        icon: const Icon(FluentIcons.add, size: 16),
        label: const Text('Novo utilizador'),
      ),
      description:
          'Contas de demonstração. Criar ou recuperar uma conta aqui não envia convites nem altera o acesso real.',
    );
  }

  Widget _permissionsPanel() {
    final roles = (data['roles'] as List).cast<String>();
    if (!roles.contains(_role)) _role = roles.first;
    final matrix = (data['permissions'] as Map)[_role] as Map;
    return _panel(
      'Perfis e matriz de permissões',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in roles)
                ChoiceChip(
                  label: Text(role),
                  selected: _role == role,
                  onSelected: (_) => _rebuild(() => _role = role),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _notice(
            _role == 'Gestor'
                ? 'O perfil Gestor mantém o acesso administrativo. Crie um perfil personalizado para configurar acessos restritos.'
                : 'As permissões são um modelo de demonstração. A autorização efectiva deve ser aplicada pelo serviço central.',
          ),
          _table(
            ['Módulo', ...permissionActions],
            [
              for (final module in permissionModules)
                [
                  _cell(module, width: 120),
                  for (final action in permissionActions)
                    Tooltip(
                      message: '$_role · $module · $action',
                      child: Checkbox(
                        value: (matrix[module] as List).contains(action),
                        onChanged: _role == 'Gestor'
                            ? null
                            : (checked) {
                                final permissions = List<String>.from(
                                  matrix[module] as List,
                                );
                                if (checked == true) {
                                  if (!permissions.contains(action)) {
                                    permissions.add(action);
                                  }
                                  if (action != 'Visualizar' &&
                                      !permissions.contains('Visualizar')) {
                                    permissions.add('Visualizar');
                                  }
                                } else {
                                  permissions.remove(action);
                                  if (action == 'Visualizar') {
                                    permissions.clear();
                                  }
                                }
                                matrix[module] = permissions;
                                model.refresh();
                              },
                      ),
                    ),
                ],
            ],
          ),
        ],
      ),
      action: OutlinedButton.icon(
        onPressed: _addRole,
        icon: const Icon(FluentIcons.add, size: 14),
        label: const Text('Criar perfil'),
      ),
    );
  }

  Widget _sessionsPanel() => _panel(
    'Sessões e dispositivos',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _notice(
          'Sessões demonstrativas. Revogar aqui não termina sessões reais.',
        ),
        _table(
          [
            'Utilizador',
            'Dispositivo',
            'Local / último acesso',
            'Estado',
            'Acção',
          ],
          [
            for (final row in data['sessions'] as List)
              [
                _cell('${row['user']}'),
                _cell('${row['device']}'),
                _cell('${row['location']} · ${row['lastAccess']}'),
                _badge('${row['status']}'),
                TextButton(
                  onPressed: row['status'] == 'Activa'
                      ? () async {
                          if (await _confirm(
                            'Revogar sessão?',
                            'A sessão de ${row['user']} será marcada como revogada na demonstração.',
                          )) {
                            row['status'] = 'Revogada';
                            model.refresh();
                          }
                        }
                      : null,
                  child: const Text('Revogar'),
                ),
              ],
          ],
        ),
      ],
    ),
  );

  Widget _auditPanel() => _panel(
    'Histórico de alterações',
    model.audit.isEmpty
        ? _notice(
            'Nenhuma alteração guardada nesta demonstração. O primeiro registo será criado ao guardar.',
          )
        : _table(
            ['Data / hora', 'Utilizador', 'Acção', 'Alterações'],
            [
              for (final event in model.audit.reversed.take(100))
                [
                  _cell(
                    '${event['at']}'.replaceFirst('T', ' ').split('.').first,
                  ),
                  _cell('${event['actor']}'),
                  _cell('${event['action']}', width: 230),
                  TextButton(
                    onPressed: () => _auditDetails(event),
                    child: Text(
                      '${(event['changes'] as List).length} alterações',
                    ),
                  ),
                ],
            ],
          ),
    description:
        'Histórico só de consulta, sem edição ou eliminação nesta interface. Armazenamento local demonstrativo; a imutabilidade exige um serviço de auditoria central.',
  );

  Widget _workflowPanel() => _panel(
    'Etapas do ciclo de crédito',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            for (final (i, row) in (data['workflow'] as List).indexed)
              _badge('${i + 1}. ${row['stage']}'),
          ],
        ),
        const SizedBox(height: 18),
        _table(
          ['Etapa', 'Responsável', 'Limite (MZN)', 'Obrigatória', 'Acção'],
          [
            for (final (index, row) in (data['workflow'] as List).indexed)
              [
                _cell('${index + 1}. ${row['stage']}', width: 220),
                _cell('${row['role']}'),
                _cell('${row['limit']}', width: 120),
                _badge('${row['required']}'),
                IconButton(
                  tooltip: 'Configurar ${row['stage']}',
                  onPressed: () => _editRecord(
                    'workflow',
                    index,
                    ['stage', 'role', 'limit', 'required'],
                    [
                      'Etapa',
                      'Perfil responsável',
                      'Limite monetário (MZN)',
                      'Obrigatória',
                    ],
                  ),
                  icon: const Icon(FluentIcons.edit, size: 16),
                ),
              ],
          ],
        ),
      ],
    ),
    description:
        'A aprovação pode terminar em rejeição; apenas pedidos aprovados avançam para contrato e desembolso.',
  );

  Widget _sequencesPanel() => _panel(
    'Sequências automáticas',
    _table(
      ['Documento', 'Prefixo', 'Próximo número', 'Pré-visualização', 'Acção'],
      [
        for (final (index, row) in (data['sequences'] as List).indexed)
          [
            _cell('${row['document']}', width: 130),
            _cell('${row['prefix']}', width: 80),
            _cell('${row['next']}', width: 110),
            _cell(_sequence(row), width: 260),
            IconButton(
              tooltip: 'Editar sequência ${row['document']}',
              onPressed: () => _editRecord(
                'sequences',
                index,
                ['document', 'prefix', 'next'],
                ['Documento', 'Prefixo', 'Próximo número'],
              ),
              icon: const Icon(FluentIcons.edit, size: 16),
            ),
          ],
      ],
    ),
  );
  String _sequence(Map row) => [
    row['prefix'],
    if (data['includeYear'] == true) DateTime.now().year,
    if (data['includeBranch'] == true) (data['branches'] as List).first['code'],
    '${row['next']}'.padLeft(
      (num.tryParse('${data['sequenceDigits']}') ?? 6).toInt().clamp(4, 10),
      '0',
    ),
  ].join('-');

  Widget _messagesPanel() => _panel(
    'Eventos e mensagens',
    Column(
      children: [
        for (final (index, row) in (data['messages'] as List).indexed)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              leading: const Icon(FluentIcons.mail, size: 20),
              title: Text('${row['event']}'),
              subtitle: Text(
                '${row['channel']} · ${row['active'] == 'Sim' ? 'Activo' : 'Inactivo'}',
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_renderMessage('${row['body']}')),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _editRecord(
                        'messages',
                        index,
                        ['event', 'channel', 'body', 'active'],
                        ['Evento', 'Canal', 'Mensagem', 'Activo'],
                      ),
                      icon: const Icon(FluentIcons.edit, size: 14),
                      label: const Text('Editar mensagem'),
                    ),
                    TextButton(
                      onPressed: () => _messageTest(row),
                      child: const Text('Testar pré-visualização'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
    description:
        'Variáveis: {cliente}, {referencia}, {valor}, {instituicao}. Os testes apresentam a mensagem sem efectuar envios.',
  );
  String _renderMessage(String text) => text
      .replaceAll('{cliente}', 'Amélia Massango')
      .replaceAll('{referencia}', 'CRE-2026-000304')
      .replaceAll('{valor}', '4 650,00')
      .replaceAll('{instituicao}', '${data['tradeName']}');

  Widget _dataPanel() => _panel(
    'Portabilidade e cópias de segurança',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _notice(
          'As operações abaixo abrangem apenas as definições guardadas desta demonstração. Não incluem clientes, créditos, credenciais nem a base de dados de produção.',
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => _exportSettings(backup: true),
              icon: const Icon(FluentIcons.save, size: 16),
              label: const Text('Criar backup local'),
            ),
            OutlinedButton.icon(
              onPressed: () => _exportSettings(),
              icon: const Icon(FluentIcons.download, size: 16),
              label: const Text('Exportar definições'),
            ),
            OutlinedButton.icon(
              onPressed: _importSettings,
              icon: const Icon(FluentIcons.upload, size: 16),
              label: const Text('Importar / restaurar JSON'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _integrationsPanel() => _panel(
    'Integrações disponíveis',
    Column(
      children: [
        for (final row in data['integrations'] as List)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _surface(
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    FluentIcons.plug_connected,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(
                    width: 210,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${row['name']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Última verificação: ${row['lastCheck']}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _badge('${row['status']}'),
                  TextButton(
                    onPressed: () {
                      row['status'] = 'Simulado';
                      row['lastCheck'] = DateTime.now()
                          .toIso8601String()
                          .substring(0, 16)
                          .replaceFirst('T', ' ');
                      model.refresh();
                      _toast(
                        'Teste de demonstração concluído. Nenhuma ligação externa foi realizada.',
                      );
                    },
                    child: const Text('Simular teste'),
                  ),
                  if (row['status'] == 'Simulado')
                    TextButton(
                      onPressed: () async {
                        if (await _confirm(
                          'Desactivar integração?',
                          'A integração ${row['name']} será desactivada na demonstração.',
                        )) {
                          row['status'] = 'Não ligado';
                          model.refresh();
                        }
                      },
                      child: const Text('Desactivar'),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
    description:
        'Não são recolhidos nem apresentados tokens, palavras-passe ou chaves privadas.',
  );

  Widget _regionalPreview() => _panel(
    'Exemplo dos formatos seleccionados',
    Wrap(
      spacing: 28,
      runSpacing: 16,
      children: [
        _formatExample(
          'Data',
          data['dateFormat'] == 'dd/MM/yyyy' ? '20/09/2026' : '2026-09-20',
        ),
        _formatExample(
          'Valor monetário',
          '${data['decimalSeparator'] == 'Vírgula' ? '25 000,50' : '25,000.50'} ${data['currency']}',
        ),
        _formatExample('Telefone', '${data['phonePrefix']} 84 123 4567'),
        _formatExample('Fuso horário', '${data['timezone']}'),
      ],
    ),
  );
  Widget _formatExample(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 6),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );

  Widget _appearancePreview() {
    final primary = _color('${data['primaryColor']}');
    final dark =
        data['theme'] == 'Escuro' ||
        data['theme'] == 'Sistema' &&
            Theme.of(context).brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    final radius = (num.tryParse('${data['radius']}') ?? 8).toDouble().clamp(
      4.0,
      12.0,
    );
    final scale = (num.tryParse('${data['fontScale']}') ?? 100) / 100;
    final onPrimary = primary.computeLuminance() > .179
        ? Colors.black
        : Colors.white;
    return _panel(
      'Pré-visualização da interface',
      Theme(
        data: Theme.of(context).copyWith(
          colorScheme: scheme,
          textTheme: Theme.of(context).textTheme.apply(
            fontFamily: data['fontFamily'] == 'System'
                ? null
                : '${data['fontFamily']}',
            fontSizeFactor: scale,
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(
            data['density'] == 'Compacta'
                ? 12
                : data['density'] == 'Espaçosa'
                ? 24
                : 18,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: data['headers'] == 'Institucional'
                      ? _color('${data['secondaryColor']}')
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.bank,
                      color: data['headers'] == 'Institucional'
                          ? (_color(
                                      '${data['secondaryColor']}',
                                    ).computeLuminance() >
                                    .179
                                ? Colors.black
                                : Colors.white)
                          : scheme.onSurface,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${data['tradeName']}',
                        style: TextStyle(
                          color: data['headers'] == 'Institucional'
                              ? (_color(
                                          '${data['secondaryColor']}',
                                        ).computeLuminance() >
                                        .179
                                    ? Colors.black
                                    : Colors.white)
                              : scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Carteira de crédito',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '248 clientes · 18 pedidos em análise',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Text(
                      'Novo pedido',
                      style: TextStyle(
                        color: onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _color(
                        '${data['accentColor']}',
                      ).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Text(
                      'Em análise',
                      style: TextStyle(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Contraste do botão ajustado automaticamente para texto claro ou escuro.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      action: TextButton.icon(
        onPressed: () async {
          if (await _confirm(
            'Restaurar padrão Fluent 2?',
            'A personalização voltará ao padrão no rascunho. Guarde para aplicar.',
            action: 'Restaurar padrão',
          )) {
            model.restoreAppearance();
          }
        },
        icon: const Icon(FluentIcons.reset, size: 16),
        label: const Text('Restaurar padrão Fluent 2'),
      ),
    );
  }

  Widget _uploads() => _panel(
    'Elementos da identidade',
    LayoutBuilder(
      builder: (context, c) => Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final (key, title) in [
            ('logo', 'Logotipo principal'),
            ('alternate', 'Logotipo alternativo'),
            ('favicon', 'Ícone / favicon'),
            ('stamp', 'Carimbo oficial'),
            ('signature', 'Assinatura autorizada'),
          ])
            SizedBox(
              width: c.maxWidth >= 640
                  ? (c.maxWidth - 28) / 3
                  : c.maxWidth >= 400
                  ? (c.maxWidth - 14) / 2
                  : c.maxWidth,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 76,
                      child: institutionAsset(data, key) == null
                          ? Icon(
                              key == 'signature'
                                  ? FluentIcons.edit
                                  : FluentIcons.photo2,
                              size: 32,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            )
                          : Image.memory(
                              institutionAsset(data, key)!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, error, stack) =>
                                  const Text('Imagem inválida'),
                            ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(data['assets'] as Map)[key]?['name'] ?? 'PNG ou JPG · até 2 MB'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _uploading ? null : () => _pickAsset(key),
                          icon: const Icon(FluentIcons.upload, size: 14),
                          label: const Text('Escolher imagem'),
                        ),
                        if ((data['assets'] as Map).containsKey(key))
                          IconButton(
                            tooltip: 'Remover $title',
                            onPressed: () {
                              (data['assets'] as Map).remove(key);
                              applyInstitutionSettings(model.draft);
                              model.refresh();
                            },
                            icon: const Icon(FluentIcons.delete, size: 14),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
    description:
        'O logotipo guardado é aplicado ao sistema. Os documentos usam os elementos institucionais da versão guardada.',
  );

  Widget _documentPreview() {
    final logo = institutionAsset(data, 'logo');
    final stamp = institutionAsset(data, 'stamp');
    final signature = institutionAsset(data, 'signature');
    final signer = (data['signers'] as List).firstWhere(
      (s) => s['document'] == _document,
    );
    final template = (data['templates'] as List).firstWhere(
      (s) => s['document'] == _document,
    );
    return _panel(
      'Pré-visualização A4 em tempo real',
      Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in documentTypes)
                ChoiceChip(
                  label: Text(type),
                  selected: _document == type,
                  onSelected: (_) => _rebuild(() => _document = type),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 570),
              child: AspectRatio(
                aspectRatio: 210 / 297,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xffd7dce2)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x15000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRect(
                    child: Stack(
                      children: [
                        if (data['watermarkDocuments'] == true)
                          Align(
                            alignment: switch (data['watermarkPosition']) {
                              'Inferior direito' => Alignment.bottomRight,
                              'Superior esquerdo' => Alignment.topLeft,
                              _ => Alignment.center,
                            },
                            child: Opacity(
                              opacity:
                                  ((num.tryParse(
                                                '${data['watermarkOpacity']}',
                                              ) ??
                                              6) /
                                          100)
                                      .clamp(.01, .15),
                              child: logo != null
                                  ? Image.memory(
                                      logo,
                                      width:
                                          (num.tryParse(
                                                    '${data['watermarkSize']}',
                                                  ) ??
                                                  320)
                                              .toDouble()
                                              .clamp(100, 560),
                                      fit: BoxFit.contain,
                                    )
                                  : Text(
                                      '${data['tradeName']}',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        color: Colors.black,
                                      ),
                                    ),
                            ),
                          ),
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 570,
                              height: 806,
                              child: Padding(
                                padding: const EdgeInsets.all(36),
                                child: DefaultTextStyle(
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff263445),
                                    height: 1.5,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (logo != null) ...[
                                            Image.memory(
                                              logo,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.contain,
                                            ),
                                            const SizedBox(width: 14),
                                          ],
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${data['legalName']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'NUIT ${data['nuit']} · ${data['license']}',
                                                ),
                                                Text(
                                                  '${data['documentHeader']}',
                                                  maxLines: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 30),
                                      Text(
                                        '${template['title']}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'PRÉ-VISUALIZAÇÃO · SEM VALIDADE CONTRATUAL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xff64748b),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        _renderMessage('${template['body']}'),
                                        maxLines: 5,
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'CLIENTE   Amélia João Massango\nNUIT   123456789\nREFERÊNCIA   CRE-2026-MPT-000304\nCAPITAL   25 000,00 MZN\nJUROS / PRAZO   3% ao mês / 6 meses\nPRESTAÇÕES   Conforme plano contratual',
                                      ),
                                      const SizedBox(height: 20),
                                      Text('${data['legalText']}', maxLines: 5),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${data['documentNotes']}',
                                        maxLines: 3,
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${data['documentPlace']}${data['showDate'] == true ? ', ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}' : ''}',
                                      ),
                                      Row(
                                        children: [
                                          if (signature != null)
                                            Image.memory(
                                              signature,
                                              width: 110,
                                              height: 55,
                                              fit: BoxFit.contain,
                                            )
                                          else
                                            const SizedBox(
                                              height: 48,
                                              width: 110,
                                            ),
                                          const Spacer(),
                                          if (stamp != null)
                                            Image.memory(
                                              stamp,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.contain,
                                            ),
                                        ],
                                      ),
                                      Text(
                                        '${signer['name']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text('${signer['position']}'),
                                      const Divider(height: 26),
                                      Text(
                                        '${data['documentFooter']}',
                                        maxLines: 2,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      const Text(
                                        'Página 1 de 1',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      action: OutlinedButton.icon(
        onPressed: _exportDocument,
        icon: const Icon(FluentIcons.pdf, size: 16),
        label: const Text('Exportar pré-visualização'),
      ),
    );
  }
}
