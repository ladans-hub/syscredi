part of 'institution_settings_view.dart';

extension _SettingsEditors on InstitutionSettingsViewState {
  Future<void> _editRecord(
    String listKey,
    int? index,
    List<String> columns,
    List<String> labels,
  ) async {
    final rows = data[listKey] as List;
    final original = index == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(rows[index] as Map);
    final values = <String, String>{
      for (final key in columns) key: '${original[key] ?? ''}',
    };
    final form = GlobalKey<FormState>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialog) => PremiumDialog(
        title: Text(
          '${index == null ? 'Adicionar' : 'Editar'} · ${_label(listKey)}',
        ),
        subtitle: 'As alterações ficam no rascunho até guardar as definições.',
        icon: FluentIcons.edit,
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, key) in columns.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _recordInput(
                    listKey,
                    key,
                    labels[i],
                    values,
                    index,
                    rows,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(dialog, values);
            },
            child: const Text('Aplicar ao rascunho'),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (index == null) {
      rows.add(result);
    } else {
      rows[index] = {...original, ...result};
    }
    model.refresh();
  }

  Widget _recordInput(
    String listKey,
    String key,
    String label,
    Map<String, String> values,
    int? index,
    List rows,
  ) {
    final options = switch (key) {
      'role' => (data['roles'] as List).cast<String>(),
      'branch' =>
        (data['branches'] as List).map((b) => '${b['code']}').toList(),
      'active' || 'required' => ['Sim', 'Não'],
      'status' =>
        listKey == 'branches' || listKey == 'accounts'
            ? ['Activa', 'Inactiva']
            : ['Activo', 'Inactivo', 'Bloqueado'],
      'channel' => ['SMS', 'E-mail', 'Interna'],
      'currency' => ['MZN', 'USD', 'ZAR'],
      'type' => ['Caixa', 'Banco', 'Carteira móvel'],
      _ => <String>[],
    };
    if (options.isNotEmpty) {
      if (!options.contains(values[key])) values[key] = options.first;
      return DropdownButtonFormField<String>(
        initialValue: values[key],
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) => values[key] = v!,
      );
    }
    final immutable =
        index != null &&
        (['document', 'stage', 'event'].contains(key) ||
            listKey == 'branches' && key == 'code');
    return TextFormField(
      initialValue: values[key],
      readOnly: immutable,
      minLines: key == 'body' ? 3 : 1,
      maxLines: key == 'body' ? 6 : 1,
      decoration: InputDecoration(
        labelText: label,
        helperText: immutable
            ? 'Identificador de referência preservado'
            : key == 'body'
            ? 'Variáveis: {instituicao}, {cliente}, {referencia}, {valor}'
            : null,
      ),
      onChanged: (v) => values[key] = v.trim(),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return 'Campo obrigatório.';
        if (['next', 'limit'].contains(key)) {
          final number = num.tryParse(v);
          if (number == null ||
              !number.isFinite ||
              number < 0 ||
              key == 'next' && (number < 1 || number % 1 != 0)) {
            return 'Introduza um valor válido.';
          }
          if (key == 'next' &&
              index != null &&
              number < (num.tryParse('${rows[index]['next']}') ?? 1)) {
            return 'A sequência não pode retroceder.';
          }
        }
        if (['code', 'prefix'].contains(key) &&
            !RegExp(r'^[A-Z0-9-]{2,16}$').hasMatch(v)) {
          return 'Use 2–16 letras maiúsculas, números ou hífen.';
        }
        if (['code', 'prefix'].contains(key) &&
            rows.indexed.any((r) => r.$1 != index && r.$2[key] == v)) {
          return 'Este identificador já existe.';
        }
        if (key == 'phone') {
          return validateSetting(
            SettingField('phone', label, '', required: true),
            v,
          );
        }
        if (key == 'body') {
          final invalid = RegExp(r'\{([^}]+)\}')
              .allMatches(v)
              .any(
                (m) => ![
                  'instituicao',
                  'cliente',
                  'referencia',
                  'valor',
                ].contains(m[1]),
              );
          if (invalid) return 'A mensagem contém variáveis desconhecidas.';
        }
        return null;
      },
    );
  }

  Future<void> _editUser(int? index) async {
    final users = data['users'] as List;
    final user = index == null
        ? <String, dynamic>{
            'role': 'Operador',
            'branch': (data['branches'] as List).first['code'],
            'status': 'Activo',
            'lastAccess': 'Nunca',
            'history': 'Convite inicial simulado.',
          }
        : Map<String, dynamic>.from(users[index] as Map);
    final values = <String, String>{
      for (final key in [
        'name',
        'email',
        'phone',
        'address',
        'role',
        'branch',
        'status',
      ])
        key: '${user[key] ?? ''}',
    };
    final form = GlobalKey<FormState>();
    var password = '', confirmation = '';
    Map<String, dynamic>? photo = user['photo'] is Map
        ? Map<String, dynamic>.from(user['photo'] as Map)
        : null;
    bool reveal = false;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => PremiumDialog(
          title: Text(
            index == null ? 'Novo utilizador' : 'Alterar dados do utilizador',
          ),
          icon: FluentIcons.contact,
          subtitle: 'Identidade, agência e acesso · ambiente de demonstração',
          width: 820,
          content: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: photo == null
                            ? null
                            : MemoryImage(
                                base64Decode(photo!['data'] as String),
                              ),
                        child: photo == null
                            ? const Icon(FluentIcons.contact, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              index == null
                                  ? 'Perfil institucional'
                                  : '${user['name']}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text('${user['role']} · ${user['branch']}'),
                            TextButton(
                              onPressed: () async {
                                final asset = await _readImage();
                                if (asset != null && context.mounted) {
                                  update(() => photo = asset);
                                }
                              },
                              child: const Text('Escolher fotografia'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, c) {
                    final width = c.maxWidth >= 540
                        ? (c.maxWidth - 16) / 2
                        : c.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 18,
                      children: [
                        for (final (key, label) in [
                          ('name', 'Nome completo'),
                          ('email', 'E-mail'),
                          ('phone', 'Contacto'),
                          ('address', 'Endereço'),
                          ('role', 'Perfil'),
                          ('branch', 'Agência'),
                          ('status', 'Estado'),
                        ])
                          SizedBox(
                            width: key == 'address' ? c.maxWidth : width,
                            child: ['role', 'branch', 'status'].contains(key)
                                ? _recordInput(
                                    'users',
                                    key,
                                    label,
                                    values,
                                    index,
                                    users,
                                  )
                                : TextFormField(
                                    initialValue: values[key],
                                    decoration: InputDecoration(
                                      labelText: label,
                                    ),
                                    onChanged: (v) => values[key] = v.trim(),
                                    validator: (v) {
                                      final error = validateSetting(
                                        SettingField(
                                          key,
                                          label,
                                          '',
                                          required: key != 'address',
                                        ),
                                        v ?? '',
                                      );
                                      if (error != null) return error;
                                      if (key == 'email' &&
                                          users.indexed.any(
                                            (u) =>
                                                u.$1 != index &&
                                                '${u.$2['email']}'
                                                        .toLowerCase() ==
                                                    v?.trim().toLowerCase(),
                                          )) {
                                        return 'Este e-mail já está associado a um utilizador.';
                                      }
                                      return null;
                                    },
                                  ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Acesso inicial',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Palavra-passe opcional, apenas para validar o formulário de demonstração. Não é guardada nem enviada.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  obscureText: !reveal,
                  decoration: InputDecoration(
                    labelText: 'Nova palavra-passe',
                    suffixIcon: IconButton(
                      tooltip: reveal
                          ? 'Ocultar palavra-passe'
                          : 'Mostrar palavra-passe',
                      onPressed: () => update(() => reveal = !reveal),
                      icon: Icon(
                        reveal ? FluentIcons.hide : FluentIcons.red_eye,
                        size: 18,
                      ),
                    ),
                  ),
                  onChanged: (v) => password = v,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final length =
                        (num.tryParse('${data['passwordLength']}') ?? 12)
                            .toInt();
                    if (v.length < length) {
                      return 'Use pelo menos $length caracteres.';
                    }
                    if (data['passwordUpper'] == true &&
                        (!RegExp('[A-Z]').hasMatch(v) ||
                            !RegExp('[a-z]').hasMatch(v))) {
                      return 'Inclua maiúsculas e minúsculas.';
                    }
                    if (data['passwordNumbers'] == true &&
                        !RegExp('[0-9]').hasMatch(v)) {
                      return 'Inclua um número.';
                    }
                    if (data['passwordSymbols'] == true &&
                        !RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
                      return 'Inclua um carácter especial.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  obscureText: !reveal,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar palavra-passe',
                  ),
                  onChanged: (v) => confirmation = v,
                  validator: (_) => confirmation != password
                      ? 'As palavras-passe não coincidem.'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!form.currentState!.validate()) return;
                if (!_hasManager(users, index, values)) {
                  _toast('É necessário manter pelo menos um Gestor activo.');
                  return;
                }
                Navigator.pop(dialog, {
                  ...user,
                  ...values,
                  'photo': ?photo,
                  'id':
                      user['id'] ??
                      'USR-${DateTime.now().microsecondsSinceEpoch}',
                  'history':
                      '${user['history'] ?? ''}\n${DateTime.now().toIso8601String().substring(0, 16)} · Dados actualizados por ${model.actor}.',
                });
              },
              child: const Text('Aplicar ao rascunho'),
            ),
          ],
        ),
      ),
    );
    password = '';
    confirmation = '';
    if (result == null) return;
    if (index == null) {
      users.add(result);
    } else {
      users[index] = result;
    }
    model.refresh();
  }

  bool _hasManager(List users, int? index, Map replacement) =>
      replacement['role'] == 'Gestor' && replacement['status'] == 'Activo' ||
      users.indexed.any(
        (u) =>
            u.$1 != index &&
            u.$2['role'] == 'Gestor' &&
            u.$2['status'] == 'Activo',
      );

  Future<void> _userAction(int index, String action) async {
    final users = data['users'] as List;
    final user = users[index] as Map;
    if (action == 'Recuperar acesso') {
      if (await _confirm(
        'Simular recuperação de acesso?',
        'Será registada uma simulação para ${user['email']}. Não será enviado um e-mail nem alterada a palavra-passe.',
        action: 'Simular recuperação',
      )) {
        user['history'] =
            '${user['history']}\n${DateTime.now().toIso8601String()} · Recuperação de acesso simulada por ${model.actor}.';
        model.refresh();
        _toast('Recuperação simulada adicionada ao rascunho.');
      }
      return;
    }
    final next = switch (action) {
      'Activar' => 'Activo',
      'Desactivar' => 'Inactivo',
      _ => 'Bloqueado',
    };
    if (!_hasManager(users, index, {...user, 'status': next})) {
      _toast('Não é possível remover o último Gestor activo.');
      return;
    }
    if (await _confirm(
      '$action utilizador?',
      '${user['name']} ficará com estado $next na demonstração.',
      action: action,
    )) {
      user['status'] = next;
      user['history'] =
          '${user['history']}\n${DateTime.now().toIso8601String()} · $action por ${model.actor}.';
      model.refresh();
    }
  }

  Future<void> _userDetails(Map user) => showDialog<void>(
    context: context,
    builder: (context) => PremiumDialog(
      title: Text('${user['name']}'),
      subtitle: '${user['id']} · ${user['role']} · Agência ${user['branch']}',
      icon: FluentIcons.contact,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('${user['status']}'),
          const SizedBox(height: 20),
          DetailFields(
            fields: [
              ('E-mail', '${user['email']}'),
              ('Contacto', '${user['phone']}'),
              ('Endereço', '${user['address']}'),
              ('Último acesso', '${user['lastAccess']}'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Histórico do utilizador',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final event in '${user['history']}'.split('\n'))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    FluentIcons.history,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(event)),
                ],
              ),
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Concluir'),
        ),
      ],
    ),
  );

  Future<void> _addRole() async {
    final controller = TextEditingController();
    final form = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => PremiumDialog(
        title: const Text('Criar perfil personalizado'),
        subtitle:
            'O novo perfil começa sem permissões. Configure a matriz depois de criar.',
        icon: FluentIcons.people,
        width: 560,
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nome do perfil'),
            validator: (v) => v == null || v.trim().length < 3
                ? 'Use pelo menos 3 caracteres.'
                : (data['roles'] as List).any(
                    (r) => '$r'.toLowerCase() == v.trim().toLowerCase(),
                  )
                ? 'Este perfil já existe.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Criar perfil'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    (data['roles'] as List).add(name);
    (data['permissions'] as Map)[name] = {
      for (final module in permissionModules) module: <String>[],
    };
    _role = name;
    model.refresh();
  }

  Future<Map<String, dynamic>?> _readImage() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Imagens PNG e JPEG',
            extensions: ['png', 'jpg', 'jpeg'],
            uniformTypeIdentifiers: ['public.png', 'public.jpeg'],
          ),
        ],
      );
      if (file == null) return null;
      if (await file.length() > 2 * 1024 * 1024) {
        _toast('A imagem deve ter no máximo 2 MB.');
        return null;
      }
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 1200,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      final normalized = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frame.image.dispose();
      codec.dispose();
      if (normalized == null) throw const FormatException('Imagem inválida');
      return {
        'name': file.name,
        'data': base64Encode(normalized.buffer.asUint8List()),
      };
    } catch (_) {
      _toast(
        'Não foi possível ler a imagem. Escolha um ficheiro PNG ou JPG válido.',
      );
      return null;
    }
  }

  Future<void> _pickAsset(String key) async {
    _rebuild(() => _uploading = true);
    final image = await _readImage();
    if (!mounted) return;
    if (image != null) {
      (data['assets'] as Map)[key] = image;
      applyInstitutionSettings(model.draft);
      model.refresh();
    }
    _rebuild(() => _uploading = false);
  }

  Future<void> _exportDocument() async {
    try {
      final file = await getSaveLocation(
        suggestedName: 'previsualizacao_${_document.toLowerCase()}.pdf',
      );
      if (file == null) return;
      final bytes = await InstitutionDocument(
        settings: data,
      ).preview(_document);
      await XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
      ).saveTo(file.path);
      _toast('Pré-visualização PDF exportada.');
    } catch (_) {
      _toast(
        'Não foi possível exportar o PDF. Verifique o destino e tente novamente.',
      );
    }
  }

  Future<void> _exportSettings({bool backup = false}) async {
    try {
      final csv = !backup && data['exportFormat'] == 'CSV';
      final file = await getSaveLocation(
        suggestedName:
            '${backup ? 'backup' : 'definicoes'}_institucionais.${csv ? 'csv' : 'json'}',
      );
      if (file == null) return;
      String escape(String text) => '"${text.replaceAll('"', '""')}"';
      final text = csv
          ? [
              'Campo,Valor',
              ...model.saved.entries
                  .where((e) => e.value is! Map && e.value is! List)
                  .map(
                    (e) => '${escape(_label(e.key))},${escape('${e.value}')}',
                  ),
            ].join('\r\n')
          : model.exportJson();
      await XFile.fromData(
        Uint8List.fromList(utf8.encode(text)),
        mimeType: csv ? 'text/csv' : 'application/json',
      ).saveTo(file.path);
      await model.recordOperation(
        backup ? 'Backup local criado' : 'Definições exportadas',
      );
      _toast(
        backup
            ? 'Backup das definições guardadas criado.'
            : 'Definições guardadas exportadas.',
      );
    } catch (_) {
      _toast(
        'Não foi possível exportar. Verifique o destino e tente novamente.',
      );
    }
  }

  Future<void> _importSettings() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Configurações JSON',
            extensions: ['json'],
            uniformTypeIdentifiers: ['public.json'],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 16000000) {
        throw const FormatException('O ficheiro excede 16 MB.');
      }
      final raw = await file.readAsString();
      InstitutionSettingsController.validateImport(jsonDecode(raw));
      if (!mounted ||
          !await _confirm(
            'Substituir o rascunho?',
            'As definições do ficheiro ${file.name} substituirão o rascunho actual. Reveja e guarde para aplicar. O histórico existente será conservado.',
            action: 'Importar para revisão',
          )) {
        return;
      }
      model.importJson(raw);
      _toast('Ficheiro validado e importado para o rascunho.');
    } catch (error) {
      _toast(
        error is FormatException
            ? error.message
            : 'Não foi possível importar este ficheiro.',
      );
    }
  }

  Future<void> _messageTest(Map row) => showDialog<void>(
    context: context,
    builder: (context) => PremiumDialog(
      title: Text('${row['event']}'),
      subtitle:
          'Pré-visualização · ${row['channel']} · Nenhuma mensagem será enviada',
      icon: FluentIcons.mail,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailFields(
            fields: [
              ('Destinatária de exemplo', 'Amélia Massango'),
              ('Canal', '${row['channel']}'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(_renderMessage('${row['body']}')),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Concluir'),
        ),
      ],
    ),
  );
  Future<void> _auditDetails(Map event) => showDialog<void>(
    context: context,
    builder: (context) => PremiumDialog(
      title: const Text('Detalhes da alteração'),
      subtitle: '${event['module']} · ${event['id']}',
      icon: FluentIcons.history,
      width: 860,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailFields(
            fields: [
              ('Responsável', '${event['actor']}'),
              ('Data / hora', '${event['at']}'),
              ('Operação', '${event['action']}'),
              ('Modo', 'Demonstração local'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Valores anteriores e novos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final change in event['changes'] as List)
            Card(
              child: ExpansionTile(
                title: Text(_label('${change['field']}')),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  DetailFields(
                    fields: [
                      (
                        'Anterior',
                        const JsonEncoder.withIndent(
                          '  ',
                        ).convert(change['before']),
                      ),
                      (
                        'Novo',
                        const JsonEncoder.withIndent(
                          '  ',
                        ).convert(change['after']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Concluir'),
        ),
      ],
    ),
  );
}
