typedef SettingsData = Map<String, dynamic>;

class SettingField {
  const SettingField(
    this.key,
    this.label,
    this.initial, {
    this.options = const [],
    this.help,
    this.min,
    this.max,
    this.required = false,
  });
  final String key, label;
  final dynamic initial;
  final List<String> options;
  final String? help;
  final double? min, max;
  final bool required;
}

class SettingsSection {
  const SettingsSection(this.title, this.description, this.fields);
  final String title, description;
  final List<SettingField> fields;
}

class SettingsCategory {
  const SettingsCategory(
    this.id,
    this.title,
    this.description,
    this.sections, {
    this.critical = false,
  });
  final String id, title, description;
  final List<SettingsSection> sections;
  final bool critical;
}

const provinces = [
  'Maputo Cidade',
  'Maputo Província',
  'Gaza',
  'Inhambane',
  'Sofala',
  'Manica',
  'Tete',
  'Zambézia',
  'Nampula',
  'Cabo Delgado',
  'Niassa',
];
const paymentFrequency = [
  'Diária',
  'Semanal',
  'Quinzenal',
  'Mensal',
  'Trimestral',
];
const documentTypes = [
  'Contrato',
  'Recibo',
  'Comprovativo',
  'Relatório',
  'Mapa financeiro',
];
const permissionActions = [
  'Visualizar',
  'Criar',
  'Editar',
  'Eliminar',
  'Aprovar',
  'Rejeitar',
  'Desembolsar',
  'Estornar',
  'Exportar',
  'Imprimir',
  'Administrar',
];
const permissionModules = [
  'Clientes',
  'Crédito',
  'Contratos',
  'Cobranças',
  'Financeiro',
  'Relatórios',
  'Utilizadores',
  'Definições',
  'Auditoria',
];

const settingsCategories = [
  SettingsCategory(
    'institution',
    'Dados institucionais',
    'Identificação, contactos, contas bancárias e rede de agências.',
    [
      SettingsSection(
        'Identificação da instituição',
        'Informações usadas nos documentos e na comunicação institucional.',
        [
          SettingField(
            'tradeName',
            'Nome comercial',
            'Minha instituição',
            required: true,
          ),
          SettingField(
            'institutionBio',
            'Bio institucional',
            'Serviços financeiros responsáveis.',
          ),
          SettingField(
            'legalName',
            'Denominação legal',
            'Minha Instituição, Lda.',
            required: true,
          ),
          SettingField(
            'nuit',
            'NUIT',
            '000000000',
            required: true,
            help: 'Introduza os 9 dígitos do NUIT.',
          ),
          SettingField(
            'license',
            'Número / licença da instituição',
            'PENDENTE',
            required: true,
          ),
          SettingField(
            'institutionType',
            'Tipo de instituição',
            'Operador de microcrédito',
            options: [
              'Operador de microcrédito',
              'Microbanco',
              'Cooperativa de crédito',
              'Outra',
            ],
          ),
          SettingField(
            'founded',
            'Ano de constituição',
            2026,
            min: 1900,
            max: 2100,
          ),
        ],
      ),
      SettingsSection(
        'Contactos e localização',
        'Contactos públicos da sede e endereço para correspondência.',
        [
          SettingField(
            'email',
            'E-mail institucional',
            'contacto@instituicao.example',
            required: true,
          ),
          SettingField(
            'phone',
            'Telefone institucional',
            '+258 00 000 0000',
            required: true,
          ),
          SettingField('website', 'Website', ''),
          SettingField(
            'province',
            'Província',
            'Maputo Cidade',
            options: provinces,
          ),
          SettingField('city', 'Distrito / cidade', 'Maputo', required: true),
          SettingField('neighborhood', 'Bairro', ''),
          SettingField(
            'address',
            'Rua / avenida e número',
            'Endereço por configurar',
            required: true,
          ),
          SettingField('postal', 'Código postal', ''),
        ],
      ),
      SettingsSection(
        'Dados bancários',
        'Conta institucional de referência nos documentos.',
        [
          SettingField('bank', 'Banco', ''),
          SettingField('accountHolder', 'Titular', ''),
          SettingField('bankAccount', 'Número de conta', ''),
          SettingField('nib', 'NIB', ''),
          SettingField('swift', 'SWIFT / BIC', ''),
        ],
      ),
    ],
  ),
  SettingsCategory(
    'identity',
    'Identidade e documentos',
    'Uma identidade consistente em todo o sistema e nos documentos oficiais.',
    [
      SettingsSection(
        'Assinatura institucional',
        'Defina o signatário padrão e as informações da emissão.',
        [
          SettingField(
            'signer',
            'Nome do signatário',
            'Gestor da instituição',
            required: true,
          ),
          SettingField('signerRole', 'Cargo', 'Gestor', required: true),
          SettingField('documentPlace', 'Local de emissão', 'Maputo'),
          SettingField('showDate', 'Incluir data de emissão', true),
          SettingField('documentHeader', 'Cabeçalho', ''),
          SettingField('documentFooter', 'Rodapé', ''),
        ],
      ),
      SettingsSection(
        'Marca de água',
        'Aplicação discreta nas páginas e documentos, sem interferir com a leitura.',
        [
          SettingField('watermarkPages', 'Marca de água no sistema', true),
          SettingField(
            'watermarkDocuments',
            'Marca de água nos documentos',
            true,
          ),
          SettingField('watermarkOpacity', 'Opacidade (%)', 6, min: 1, max: 15),
          SettingField(
            'watermarkSize',
            'Tamanho (px)',
            320,
            min: 100,
            max: 560,
          ),
        ],
      ),
    ],
  ),
  SettingsCategory(
    'users',
    'Utilizadores e permissões',
    'Pessoas, perfis e acesso por módulo e operação.',
    [],
    critical: true,
  ),
  SettingsCategory(
    'security',
    'Segurança e acesso',
    'Políticas de acesso e rastreabilidade das alterações institucionais.',
    [
      SettingsSection(
        'Palavras-passe',
        'Políticas aplicadas ao acesso e à autenticação da organização.',
        [
          SettingField(
            'passwordLength',
            'Comprimento mínimo',
            12,
            min: 8,
            max: 64,
          ),
          SettingField(
            'passwordExpiry',
            'Validade da palavra-passe (dias)',
            90,
            min: 1,
            max: 365,
          ),
          SettingField('passwordUpper', 'Exigir maiúsculas e minúsculas', true),
          SettingField('passwordNumbers', 'Exigir números', true),
          SettingField('passwordSymbols', 'Exigir caracteres especiais', true),
          SettingField(
            'forceInitialPassword',
            'Alterar palavra-passe no primeiro acesso',
            true,
          ),
        ],
      ),
      SettingsSection(
        'Sessões e operações sensíveis',
        'Regras para sessões e operações que exigem protecção adicional.',
        [
          SettingField(
            'sessionMinutes',
            'Expiração por inactividade (minutos)',
            30,
            min: 5,
            max: 480,
          ),
          SettingField(
            'loginAttempts',
            'Tentativas antes de bloquear',
            5,
            min: 3,
            max: 10,
          ),
          SettingField(
            'lockMinutes',
            'Duração do bloqueio (minutos)',
            30,
            min: 5,
            max: 1440,
          ),
          SettingField(
            'twoFactor',
            'Exigir segundo factor quando disponível',
            true,
          ),
          SettingField(
            'sensitiveReauth',
            'Reautenticar em operações sensíveis',
            true,
          ),
          SettingField(
            'dualControl',
            'Dupla autorização em estornos e desembolsos',
            true,
          ),
        ],
      ),
    ],
    critical: true,
  ),
  SettingsCategory(
    'appearance',
    'Personalização',
    'Tema, cores e apresentação com pré-visualização antes de aplicar.',
    [
      SettingsSection(
        'Aparência',
        'As alterações só são aplicadas ao sistema depois de guardar.',
        [
          SettingField(
            'theme',
            'Tema',
            'Sistema',
            options: ['Claro', 'Escuro', 'Sistema'],
          ),
          SettingField('primaryColor', 'Cor primária', '#21A56B'),
          SettingField('secondaryColor', 'Cor secundária', '#152739'),
          SettingField('accentColor', 'Cor de destaque', '#0078D4'),
          SettingField(
            'fontFamily',
            'Tipografia',
            'Inter',
            options: [
              'System',
              'Inter',
              'Poppins',
              'Geist',
              'Manrope',
              'IBM Plex Sans',
            ],
          ),
          SettingField(
            'fontScale',
            'Escala do texto (%)',
            100,
            min: 90,
            max: 120,
          ),
          SettingField(
            'density',
            'Densidade',
            'Confortável',
            options: ['Compacta', 'Confortável', 'Espaçosa'],
          ),
          SettingField('radius', 'Arredondamento (px)', 8, min: 4, max: 12),
          SettingField(
            'sidebar',
            'Menu lateral',
            'Expandido',
            options: ['Expandido', 'Compacto'],
          ),
          SettingField(
            'navigation',
            'Navegação',
            'Ícones e texto',
            options: ['Ícones e texto', 'Texto'],
          ),
          SettingField(
            'headers',
            'Cabeçalhos',
            'Institucional',
            options: ['Institucional', 'Neutro'],
          ),
          SettingField('stripedTables', 'Linhas alternadas nas tabelas', true),
          SettingField(
            'dashboard',
            'Dashboard inicial',
            'Visão geral',
            options: ['Visão geral', 'Crédito', 'Financeiro'],
          ),
          SettingField(
            'rememberCategory',
            'Guardar automaticamente a última categoria',
            true,
          ),
        ],
      ),
    ],
  ),
  SettingsCategory(
    'credit',
    'Configurações de crédito',
    'Parâmetros globais e limites para a configuração dos produtos.',
    [
      SettingsSection(
        'Valores e cálculo',
        'Valores globais sujeitos às políticas aprovadas pela instituição.',
        [
          SettingField(
            'creditCurrency',
            'Moeda do crédito',
            'MZN',
            options: ['MZN', 'USD', 'ZAR'],
          ),
          SettingField('decimals', 'Casas decimais', 2, min: 0, max: 4),
          SettingField('minimumCredit', 'Crédito mínimo (MZN)', 1000, min: 0),
          SettingField('maximumCredit', 'Crédito máximo (MZN)', 500000, min: 1),
          SettingField(
            'frequency',
            'Periodicidade padrão',
            'Mensal',
            options: paymentFrequency,
          ),
          SettingField(
            'interestMethod',
            'Método de juros',
            'Saldo devedor',
            options: ['Saldo devedor', 'Juros simples', 'Prestação constante'],
          ),
          SettingField(
            'interestRate',
            'Taxa de juros por período (%)',
            3,
            min: 0,
            max: 100,
          ),
          SettingField(
            'dailyInterest',
            'Juros de mora ao dia (%)',
            0.1,
            min: 0,
            max: 100,
          ),
          SettingField(
            'rounding',
            'Arredondamento',
            'Comercial',
            options: ['Comercial', 'Para cima', 'Para baixo'],
          ),
          SettingField('graceDays', 'Carência (dias)', 0, min: 0, max: 365),
          SettingField(
            'lateTolerance',
            'Tolerância de atraso (dias)',
            3,
            min: 0,
            max: 90,
          ),
          SettingField('latePenalty', 'Multa fixa (MZN)', 150, min: 0),
          SettingField(
            'effortRate',
            'Taxa de esforço máxima (%)',
            35,
            min: 1,
            max: 100,
          ),
        ],
      ),
      SettingsSection(
        'Garantias e elegibilidade',
        'Requisitos comuns a novos pedidos de crédito.',
        [
          SettingField(
            'guarantors',
            'Número mínimo de avalistas',
            1,
            min: 0,
            max: 5,
          ),
          SettingField('collateral', 'Exigir garantia', true),
          SettingField('minimumAge', 'Idade mínima', 18, min: 18, max: 75),
          SettingField(
            'requiredDocuments',
            'Documentos obrigatórios',
            'BI / DIRE; NUIT; comprovativo de residência; comprovativo de rendimento',
          ),
          SettingField(
            'eligibility',
            'Critérios gerais',
            'Capacidade de pagamento verificada; identificação válida; ausência de dívida vencida não regularizada.',
          ),
          SettingField(
            'productOverride',
            'Permitir sobrescrita pelo produto',
            true,
            help:
                'Os produtos podem substituir taxa, prazo e periodicidade, dentro dos limites globais.',
          ),
          SettingField(
            'overrideFields',
            'Campos sobrescrevíveis',
            'Taxa de juros; prazo; periodicidade; carência',
          ),
        ],
      ),
      SettingsSection(
        'Desembolso e ciclo de crédito',
        'Regras para emissão, liquidação e renegociação.',
        [
          SettingField('automaticCollection', 'Cobrança automática', false),
          SettingField(
            'earlySettlement',
            'Permitir liquidação antecipada',
            true,
          ),
          SettingField('refinance', 'Permitir refinanciamento', true),
          SettingField('restructure', 'Permitir reestruturação', true),
          SettingField(
            'signedContract',
            'Exigir contrato assinado antes do desembolso',
            true,
          ),
          SettingField(
            'stampDutyType',
            'Imposto de selo — tipo',
            'Percentagem',
            options: ['Percentagem', 'Valor fixo'],
          ),
          SettingField('stampDuty', 'Imposto de selo — valor', 0, min: 0),
          SettingField(
            'disbursementFeeType',
            'Taxa de desembolso — tipo',
            'Percentagem',
            options: ['Percentagem', 'Valor fixo'],
          ),
          SettingField(
            'disbursementFee',
            'Taxa de desembolso — valor',
            1,
            min: 0,
          ),
          SettingField(
            'preparationFeeType',
            'Taxa de preparo — tipo',
            'Valor fixo',
            options: ['Percentagem', 'Valor fixo'],
          ),
          SettingField(
            'preparationFee',
            'Taxa de preparo — valor',
            100,
            min: 0,
          ),
          SettingField(
            'feePayer',
            'Responsável pelas taxas',
            'Cliente',
            options: ['Cliente', 'Instituição'],
          ),
          SettingField(
            'creditStates',
            'Estados do crédito',
            'Rascunho; Em análise; Aprovado; Rejeitado; Contratado; Desembolsado; Em cobrança; Liquidado; Reestruturado',
          ),
        ],
      ),
    ],
    critical: true,
  ),
  SettingsCategory(
    'workflow',
    'Fluxos e aprovações',
    'Responsáveis, limites e segregação de funções em cada etapa.',
    [
      SettingsSection(
        'Autorizações superiores',
        'Encaminhamento de operações que excedem a autonomia do perfil.',
        [
          SettingField(
            'selfApproval',
            'Permitir aprovação do próprio pedido',
            false,
          ),
          SettingField(
            'escalationAmount',
            'Autorização superior a partir de (MZN)',
            100000,
            min: 1,
          ),
          SettingField(
            'escalationRole',
            'Perfil de autorização superior',
            'Gestor',
            options: ['Gestor', 'Comité de crédito'],
          ),
          SettingField(
            'approvalLevels',
            'Níveis de aprovação',
            2,
            min: 1,
            max: 5,
          ),
          SettingField(
            'approvalDeadline',
            'Prazo por etapa (horas)',
            48,
            min: 1,
            max: 720,
          ),
        ],
      ),
    ],
    critical: true,
  ),
  SettingsCategory(
    'numbering',
    'Numeração e documentos',
    'Sequências, templates e textos institucionais.',
    [
      SettingsSection(
        'Composição dos identificadores',
        'Regras usadas na composição dos identificadores institucionais.',
        [
          SettingField('includeYear', 'Incluir ano', true),
          SettingField('includeBranch', 'Incluir código da agência', true),
          SettingField(
            'sequenceDigits',
            'Dígitos da sequência',
            6,
            min: 4,
            max: 10,
          ),
          SettingField(
            'resetSequence',
            'Reiniciar sequência',
            'Anualmente',
            options: ['Anualmente', 'Nunca'],
          ),
          SettingField(
            'legalText',
            'Texto legal complementar',
            'As condições particulares e o plano de prestações integram o contrato. O cliente declara ter recebido informação sobre os custos do crédito.',
          ),
          SettingField(
            'documentNotes',
            'Observações institucionais',
            'Conserve este documento. Para esclarecimentos contacte a sua agência.',
          ),
        ],
      ),
    ],
    critical: true,
  ),
  SettingsCategory(
    'finance',
    'Financeiro',
    'Contas, meios de pagamento, controlo e fechos financeiros.',
    [
      SettingsSection(
        'Regras financeiras',
        'Configuração comum a desembolsos, reembolsos e movimentos internos.',
        [
          SettingField(
            'paymentMethods',
            'Formas de pagamento',
            'Numerário; Transferência bancária; M-Pesa; e-Mola; mKesh',
          ),
          SettingField(
            'incomeCategories',
            'Categorias de receitas',
            'Juros; Comissões; Multas; Outras receitas',
          ),
          SettingField(
            'expenseCategories',
            'Categorias de despesas',
            'Pessoal; Renda; Serviços; Transporte; Outras despesas',
          ),
          SettingField(
            'costCenters',
            'Centros de custo',
            'Sede; Agência Matola; Agência Beira',
          ),
          SettingField('reversalReason', 'Exigir motivo para estornos', true),
          SettingField(
            'reversalApproval',
            'Exigir aprovação de estornos',
            true,
          ),
          SettingField(
            'financialLimit',
            'Limite sem aprovação superior (MZN)',
            25000,
            min: 0,
          ),
          SettingField('dailyClosing', 'Exigir fecho diário de caixa', true),
          SettingField(
            'periodClosing',
            'Fecho do período',
            'Mensal',
            options: ['Mensal', 'Trimestral', 'Anual'],
          ),
          SettingField(
            'closedPeriodLock',
            'Bloquear movimentos em períodos fechados',
            true,
          ),
          SettingField(
            'paymentReference',
            'Exigir referência em pagamentos electrónicos',
            true,
          ),
        ],
      ),
    ],
    critical: true,
  ),
  SettingsCategory(
    'notifications',
    'Notificações e comunicação',
    'Mensagens e lembretes por evento e canal.',
    [
      SettingsSection(
        'Canais e lembretes',
        'Canais e horários usados nas comunicações da instituição.',
        [
          SettingField('smsEnabled', 'Activar SMS', true),
          SettingField('emailEnabled', 'Activar e-mail', true),
          SettingField(
            'internalEnabled',
            'Activar notificações internas',
            true,
          ),
          SettingField(
            'reminderDays',
            'Antecedência do lembrete (dias)',
            5,
            min: 1,
            max: 30,
          ),
          SettingField('senderName', 'Nome do remetente', 'Syscredi'),
          SettingField('replyEmail', 'E-mail de resposta', ''),
          SettingField('quietStart', 'Início do horário de silêncio', '20:00'),
          SettingField('quietEnd', 'Fim do horário de silêncio', '08:00'),
        ],
      ),
    ],
  ),
  SettingsCategory(
    'data',
    'Dados e integrações',
    'Backup, portabilidade e acompanhamento dos serviços ligados.',
    [
      SettingsSection(
        'Backup e retenção',
        'Políticas de backup, retenção e portabilidade das configurações.',
        [
          SettingField('backupEnabled', 'Backup automático', true),
          SettingField(
            'backupFrequency',
            'Frequência',
            'Diária',
            options: ['Diária', 'Semanal', 'Mensal'],
          ),
          SettingField('backupTime', 'Hora do backup', '23:00'),
          SettingField(
            'backupRetention',
            'Retenção de backups (dias)',
            90,
            min: 7,
            max: 3650,
          ),
          SettingField(
            'dataRetention',
            'Retenção de dados (anos)',
            10,
            min: 1,
            max: 30,
          ),
          SettingField(
            'logRetention',
            'Retenção de logs (dias)',
            365,
            min: 30,
            max: 3650,
          ),
          SettingField(
            'saveLogs',
            'Registar eventos de auditoria',
            true,
            help: 'O histórico de alterações deste módulo é sempre conservado.',
          ),
          SettingField(
            'exportFormat',
            'Formato de exportação',
            'JSON',
            options: ['JSON', 'CSV'],
          ),
        ],
      ),
    ],
    critical: true,
  ),
  SettingsCategory(
    'regional',
    'Preferências regionais',
    'Formatos e calendário adaptados a Moçambique.',
    [
      SettingsSection(
        'Idioma e formatos',
        'Pré-visualize os formatos antes de guardar.',
        [
          SettingField(
            'language',
            'Idioma',
            'Português (Moçambique)',
            options: [
              'Português (Moçambique)',
              'Português (Portugal)',
              'English',
            ],
          ),
          SettingField(
            'currency',
            'Moeda padrão',
            'MZN',
            options: ['MZN', 'USD', 'ZAR'],
          ),
          SettingField(
            'timezone',
            'Fuso horário',
            'Africa/Maputo',
            options: ['Africa/Maputo', 'Africa/Johannesburg', 'UTC'],
          ),
          SettingField(
            'phonePrefix',
            'Indicativo telefónico',
            '+258',
            options: ['+258', '+27', '+351'],
          ),
          SettingField(
            'dateFormat',
            'Formato de data',
            'dd/MM/yyyy',
            options: ['dd/MM/yyyy', 'yyyy-MM-dd'],
          ),
          SettingField(
            'decimalSeparator',
            'Separador decimal',
            'Vírgula',
            options: ['Vírgula', 'Ponto'],
          ),
          SettingField(
            'weekStart',
            'Início da semana',
            'Segunda-feira',
            options: ['Segunda-feira', 'Domingo'],
          ),
          SettingField(
            'businessDays',
            'Dias úteis',
            'Segunda a sexta',
            options: ['Segunda a sexta', 'Segunda a sábado', 'Todos os dias'],
          ),
          SettingField(
            'holidays',
            'Feriados adicionais (dd/MM)',
            '01/01; 03/02; 07/04; 01/05; 25/06; 07/09; 25/09; 04/10; 25/12',
          ),
          SettingField(
            'dueDateRule',
            'Vencimento em dia não útil',
            'Próximo dia útil',
            options: ['Próximo dia útil', 'Dia útil anterior', 'Manter data'],
          ),
        ],
      ),
    ],
  ),
];

SettingsData defaultSettings() => {
  for (final category in settingsCategories)
    for (final section in category.sections)
      for (final field in section.fields) field.key: field.initial,
  'assets': <String, dynamic>{},
  'branches': [
    {
      'code': 'SED',
      'name': 'Sede',
      'address': 'Endereço por configurar',
      'phone': '+258 00 000 0000',
      'manager': 'Gestor da instituição',
      'status': 'Activa',
    },
  ],
  'users': [
    {
      'id': 'USR-001',
      'name': 'Gestor da instituição',
      'email': 'gestor@instituicao.example',
      'phone': '+258 00 000 0000',
      'role': 'Gestor',
      'branch': 'SED',
      'status': 'Activo',
      'lastAccess': 'Nunca',
      'address': 'Por configurar',
      'history': 'Perfil inicial da instituição.',
    },
  ],
  'roles': ['Gestor', 'Operador', 'Avalista'],
  'permissions': {
    for (final role in ['Gestor', 'Operador', 'Avalista'])
      role: {
        for (final module in permissionModules)
          module: [
            if (role == 'Gestor')
              ...permissionActions
            else if (role == 'Operador' &&
                ![
                  'Definições',
                  'Utilizadores',
                  'Auditoria',
                ].contains(module)) ...[
              'Visualizar',
              'Criar',
              'Editar',
              'Imprimir',
            ] else if (role == 'Avalista' &&
                ['Clientes', 'Crédito', 'Contratos'].contains(module))
              'Visualizar',
          ],
      },
  },
  'workflow': [
    for (final (i, name) in [
      'Solicitação',
      'Análise',
      'Avaliação',
      'Aprovação / rejeição',
      'Contrato',
      'Desembolso',
      'Cobrança',
      'Liquidação',
    ].indexed)
      {
        'stage': name,
        'role': i == 0 || i == 4 || i == 6
            ? 'Operador'
            : i == 2
            ? 'Avalista'
            : 'Gestor',
        'limit': i < 3 ? '50000' : '500000',
        'required': 'Sim',
      },
  ],
  'sequences': [
    for (final (name, prefix) in [
      ('Cliente', 'CLI'),
      ('Pedido', 'PED'),
      ('Crédito', 'CRE'),
      ('Contrato', 'CTR'),
      ('Prestação', 'PRE'),
      ('Recibo', 'REC'),
      ('Desembolso', 'DES'),
      ('Reembolso', 'REE'),
    ])
      {'document': name, 'prefix': prefix, 'next': '1'},
  ],
  'signers': [
    for (final type in documentTypes)
      {'document': type, 'name': 'Gestor da instituição', 'position': 'Gestor'},
  ],
  'templates': [
    for (final type in documentTypes)
      {
        'document': type,
        'title': '$type institucional',
        'body':
            'Documento emitido por {instituicao} para {cliente}. Referência: {referencia}.',
        'active': 'Sim',
      },
  ],
  'accounts': [
    {
      'code': 'CX-SED',
      'name': 'Caixa principal',
      'type': 'Caixa',
      'currency': 'MZN',
      'status': 'Activa',
    },
  ],
  'messages': [
    for (final event in [
      'Crédito aprovado',
      'Crédito rejeitado',
      'Desembolso efectuado',
      'Prestação próxima',
      'Prestação vencida',
      'Crédito em atraso',
      'Pagamento recebido',
    ])
      {
        'event': event,
        'channel': 'SMS',
        'body':
            'Olá {cliente}, $event. Referência {referencia}, valor {valor} MZN. Contacte {instituicao} para mais informações.',
        'active': 'Sim',
      },
  ],
  'sessions': [
    {
      'user': 'Gestor da instituição',
      'device': 'Chrome · Windows 11',
      'location': 'Maputo',
      'lastAccess': '20/09/2026 09:42',
      'status': 'Actual',
    },
    {
      'user': 'Operador de exemplo',
      'device': 'Edge · Windows 11',
      'location': 'Matola',
      'lastAccess': '20/09/2026 08:17',
      'status': 'Activa',
    },
    {
      'user': 'Analista de exemplo',
      'device': 'Safari · iPhone',
      'location': 'Beira',
      'lastAccess': '19/09/2026 16:30',
      'status': 'Activa',
    },
  ],
  'integrations': [
    {
      'name': 'SMS · Gateway local',
      'type': 'SMS',
      'status': 'Simulado',
      'lastCheck': '20/09/2026 09:00',
    },
    {
      'name': 'E-mail institucional',
      'type': 'E-mail',
      'status': 'Simulado',
      'lastCheck': '20/09/2026 09:00',
    },
    {
      'name': 'M-Pesa',
      'type': 'Pagamentos',
      'status': 'Não ligado',
      'lastCheck': '—',
    },
    {
      'name': 'e-Mola',
      'type': 'Pagamentos',
      'status': 'Não ligado',
      'lastCheck': '—',
    },
    {
      'name': 'WhatsApp Business',
      'type': 'Comunicação',
      'status': 'Não ligado',
      'lastCheck': '—',
    },
  ],
};

String? validateSetting(SettingField field, String raw) {
  final value = raw.trim();
  if (field.required && value.isEmpty) return 'Campo obrigatório.';
  if (value.isEmpty) return null;
  if (field.initial is num) {
    final number = num.tryParse(value.replaceAll(',', '.'));
    if (number == null || !number.isFinite) {
      return 'Introduza um número válido.';
    }
    if (field.initial is int && number % 1 != 0) {
      return 'Introduza um número inteiro.';
    }
    if (field.min != null && number < field.min!) {
      return 'Mínimo: ${field.min}.';
    }
    if (field.max != null && number > field.max!) {
      return 'Máximo: ${field.max}.';
    }
  }
  if (field.key == 'nuit' && !RegExp(r'^\d{9}$').hasMatch(value)) {
    return 'O NUIT deve conter 9 dígitos.';
  }
  if (field.initial is String &&
      field.key.toLowerCase().contains('email') &&
      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
    return 'E-mail inválido.';
  }
  if (field.key == 'phone' &&
      !RegExp(
        r'^(\+258)?\d{9}$',
      ).hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
    return 'Use +258 seguido de 9 dígitos.';
  }
  if (field.key == 'website' &&
      !(Uri.tryParse(value)?.host.isNotEmpty == true &&
          ['http', 'https'].contains(Uri.tryParse(value)?.scheme))) {
    return 'Use um endereço https:// válido.';
  }
  if (field.key.endsWith('Color') &&
      !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
    return 'Use uma cor hexadecimal, por exemplo #0078D4.';
  }
  if (['quietStart', 'quietEnd', 'backupTime'].contains(field.key) &&
      !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) {
    return 'Use HH:mm (00:00 a 23:59).';
  }
  return null;
}
