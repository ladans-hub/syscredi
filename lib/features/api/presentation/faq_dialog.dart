import 'package:flutter/material.dart';
import '../../../app/theme/fluent_design.dart';

void showHelpCenter(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _HelpCenter());

class _HelpCenter extends StatefulWidget {
  const _HelpCenter();
  @override
  State<_HelpCenter> createState() => _HelpCenterState();
}

class _HelpCenterState extends State<_HelpCenter> {
  final _search = TextEditingController();
  String _category = 'Todos';
  static const _questions = <(String, String, String)>[
    (
      'Primeiros passos',
      'Por onde devo começar?',
      '1. Nas definições institucionais, confirme os dados da empresa.\n2. Configure os produtos de crédito.\n3. Registe o cliente e confira os documentos.\n4. Simule as condições antes de iniciar o financiamento.',
    ),
    (
      'Clientes e crédito',
      'Como registar e preparar um cliente?',
      'Abra Clientes e escolha a categoria adequada. Preencha os dados de identificação e contacto e reúna os documentos necessários. Confirme a validade documental antes de avançar com o pedido.',
    ),
    (
      'Clientes e crédito',
      'Quais são as etapas de um crédito?',
      'O processo passa pelo financiamento, análise financeira, aprovação, autorização e desembolso. Em cada etapa, confira as condições e as evidências disponíveis. As acções permitidas dependem do seu perfil de acesso.',
    ),
    (
      'Clientes e crédito',
      'O que devo verificar antes do desembolso?',
      'Confirme a aprovação, a autorização, os dados do beneficiário, o montante e as condições acordadas. Após o desembolso, acompanhe o estado do contrato e o plano de prestações.',
    ),
    (
      'Cobranças e risco',
      'Onde acompanho prestações e pagamentos?',
      'Consulte Cobranças para acompanhar vencimentos e recuperação. Confira o contrato, o valor e o canal de pagamento antes de registar um recebimento. Consulte os recibos e os movimentos para confirmar o registo.',
    ),
    (
      'Cobranças e risco',
      'Como interpretar a Central de risco?',
      'A Central de risco apresenta exposição, faixas de atraso e sinais que precisam de acompanhamento. PAR > 30 e PAR > 90 medem a proporção do capital em aberto de contratos acima desses limiares. Verifique sempre a abrangência dos dados indicada no painel e abra a análise para consultar a acção sugerida.',
    ),
    (
      'Cobranças e risco',
      'O que fazer quando um cliente entra em atraso?',
      'Confirme os pagamentos e vencimentos, contacte o cliente e avalie a capacidade de regularização. Acompanhe a cobrança e, quando aplicável, submeta uma reestruturação ao processo de análise e autorização da instituição.',
    ),
    (
      'Administração',
      'Como alterar o nome e a identidade da empresa?',
      'Abra o menu do perfil e seleccione Definições da conta. Nas definições institucionais, actualize o nome comercial e a identidade visual. Guarde as alterações para as aplicar à apresentação da aplicação.',
    ),
    (
      'Administração',
      'Onde encontro relatórios e o histórico de operações?',
      'No menu Relatórios, escolha o tipo de informação pretendido. Em Gestão de logs > Auditoria, consulte as operações registadas, os responsáveis e os detalhes de cada evento.',
    ),
    (
      'Administração',
      'Porque não consigo realizar uma operação?',
      'Confirme o seu perfil de acesso, a etapa do processo e os campos obrigatórios. Se uma operação falhar, verifique a mensagem apresentada e confirme o estado do registo antes de tentar novamente. Para rever permissões, contacte o administrador da instituição.',
    ),
  ];
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _search.text.trim().toLowerCase();
    final shown = _questions
        .where(
          (q) =>
              (_category == 'Todos' || q.$1 == _category) &&
              '${q.$2} ${q.$3}'.toLowerCase().contains(query),
        )
        .toList();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Centro de ajuda',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        const Text('Respostas práticas para o seu dia a dia.'),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar ajuda',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  FluentSurface(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uma operação, passo a passo',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final (i, label) in [
                              'Registar cliente',
                              'Analisar crédito',
                              'Autorizar e desembolsar',
                              'Acompanhar pagamentos',
                            ].indexed)
                              Chip(
                                avatar: CircleAvatar(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                label: Text(label),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Perguntas frequentes',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Pesquisar uma dúvida',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar pesquisa',
                              onPressed: () => setState(_search.clear),
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in [
                        'Todos',
                        'Primeiros passos',
                        'Clientes e crédito',
                        'Cobranças e risco',
                        'Administração',
                      ])
                        ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${shown.length} perguntas',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const Text(
                            'Nenhuma pergunta encontrada. Experimente outro termo ou categoria.',
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _search.clear();
                              _category = 'Todos';
                            }),
                            child: const Text('Mostrar todas as perguntas'),
                          ),
                        ],
                      ),
                    ),
                  for (final q in shown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FluentSurface(
                        child: ExpansionTile(
                          key: ValueKey(q.$2),
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 4,
                          ),
                          title: Text(q.$2, style: theme.textTheme.titleSmall),
                          subtitle: Text(
                            q.$1,
                            style: theme.textTheme.bodySmall,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            18,
                            0,
                            18,
                            18,
                          ),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SelectableText(
                                q.$3,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
