import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../settings/presentation/institution_branding.dart';
import '../domain/money.dart';
import '../domain/repository.dart';

class ClientContractDocuments {
  ClientContractDocuments({required this.branding, required this.client});

  final InstitutionDocument branding;
  final Json client;

  String get institution => institutionEmailSenderName(branding.data);
  String get clientName => branding.value(client['name']);
  String get document =>
      branding.value(client['document'] ?? client['document_number']);
  String get phone => branding.value(client['phone']);
  String get address =>
      branding.value(client['address'] ?? client['location'] ?? client['city']);
  String get maritalStatus => branding.value(client['marital_status']);
  String get nationality => branding.value(client['nationality']);
  String get birthplace =>
      branding.value(client['birthplace'] ?? client['city']);
  String get institutionAddress => branding.value(branding.data['address']);
  String get institutionNuit => branding.value(branding.data['nuit']);
  String get representative => branding.value(branding.data['signer']);
  String get representativeRole => branding.value(branding.data['signerRole']);
  String get place => branding.value(branding.data['documentPlace']);
  String get today {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  String _value(Json? row, List<String> keys, {String fallback = '--'}) {
    for (final key in keys) {
      final value = branding.value(row?[key]);
      if (value != '--') return value;
    }
    return fallback;
  }

  String _amount(Json? loan) {
    for (final key in ['amount_cents', 'principal_cents', 'amountCents']) {
      final raw = loan?[key];
      if (raw is num) return money(raw);
      final parsed = num.tryParse('$raw');
      if (parsed != null) return money(parsed);
    }
    return '--';
  }

  String _rate(Json? loan) {
    for (final key in ['annual_rate_bps', 'interest_rate_bps', 'rate_bps']) {
      final raw = num.tryParse('${loan?[key] ?? ''}');
      if (raw != null) return '${(raw / 100).toStringAsFixed(2)}%';
    }
    return _value(loan, ['interest_rate', 'rate']);
  }

  String _months(Json? loan) => _value(loan, ['months', 'term_months']);
  String _reference(Json? loan) => _value(loan, ['reference', 'id']);
  String _purpose(Json? loan) =>
      _value(loan, ['purpose', 'reason', 'activity']);

  pw.Widget _article(String number, String heading, List<pw.Widget> body) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(height: 14),
          branding.sectionTitle(number),
          branding.sectionTitle('($heading)'),
          pw.SizedBox(height: 8),
          ...body,
        ],
      );

  pw.Widget _paragraph(String text) => pw.Text(
    text,
    textAlign: pw.TextAlign.justify,
    style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2),
  );

  pw.Widget _parties({required String secondPartyLabel}) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      branding.sectionTitle('ENTRE'),
      pw.SizedBox(height: 10),
      _paragraph(
        'Primeiro Outorgante: $institution, registada na Conservatória das Entidades Legais, com Número Único de Identificação Tributária: $institutionNuit, localizada em $institutionAddress, representada neste acordo por $representative, na qualidade de $representativeRole.',
      ),
      pw.SizedBox(height: 8),
      branding.sectionTitle('E'),
      pw.SizedBox(height: 8),
      _paragraph(
        'Segundo Outorgante: $clientName, doravante denominado $secondPartyLabel, maior, estado civil $maritalStatus, de nacionalidade $nationality, natural de $birthplace, domiciliado em $address, portador do documento de identificação nº $document, contactável pelo nº $phone.',
      ),
    ],
  );

  Future<Uint8List> creditContract({Json? loan}) async {
    final doc = pw.Document(
      title: 'Contrato de concessão de crédito',
      author: institution,
    );
    doc.addPage(
      pw.MultiPage(
        pageTheme: branding.pageTheme(),
        header: branding.header,
        footer: branding.footer,
        build: (_) => [
          branding.title('Contrato de concessão de crédito'),
          _parties(secondPartyLabel: 'MUTUÁRIO(A)'),
          _article('ARTIGO 1º', 'Objeto', [
            _paragraph(
              'O presente contrato tem por objecto a concessão de crédito pelo Primeiro Outorgante ao Segundo Outorgante.',
            ),
          ]),
          _article('ARTIGO 2º', 'Duração', [
            _paragraph(
              'O presente contrato tem a duração de ${_months(loan)} mês(es), contando da data do desembolso até ao cumprimento integral das obrigações assumidas.',
            ),
          ]),
          _article('ARTIGO 3º', 'Atraso do Segundo Outorgante', [
            _paragraph(
              'Considera-se atraso o não pagamento, nos prazos e pela forma devida, de qualquer prestação ou obrigação resultante deste contrato. O atraso constitui-se independentemente de aviso e sujeita o mutuário aos juros moratórios e penalidades previstos nas políticas da instituição e na lei.',
            ),
          ]),
          _article('ARTIGO 4º', 'Obrigações das partes', [
            _paragraph(
              'O Primeiro Outorgante obriga-se a disponibilizar o crédito nas condições aprovadas e a informar o mutuário sobre alterações relevantes. O Segundo Outorgante obriga-se a reembolsar o capital, juros e encargos nas datas acordadas, manter os documentos actualizados e apresentar comprovativos de pagamento quando solicitado.',
            ),
          ]),
          _article('ARTIGO 5º', 'Direitos das partes', [
            _paragraph(
              'O Primeiro Outorgante pode exigir o pagamento e aplicar as penalidades legalmente admissíveis. O Segundo Outorgante pode solicitar informação, recibos, renegociação ou alteração de datas, sujeitas à aprovação da instituição.',
            ),
          ]),
          _article('ARTIGO 6º', 'Valor do crédito, taxa e finalidade', [
            _paragraph(
              'O Primeiro Outorgante concede ao Segundo Outorgante o crédito de ${_amount(loan)}, à taxa de ${_rate(loan)}, destinado a ${_purpose(loan)}. Referência da operação: ${_reference(loan)}.',
            ),
          ]),
          _article('ARTIGO 7º', 'Modalidades de pagamento', [
            _paragraph(
              'O Segundo Outorgante efectuará o reembolso do capital e dos juros conforme o plano de amortização associado à operação de crédito.',
            ),
            pw.SizedBox(height: 8),
            branding.table(
              headers: [
                'Parcela',
                'Vencimento',
                'Prestação',
                'Capital',
                'Juros',
                'Saldo',
              ],
              rows: const [
                ['--', '--', '--', '--', '--', '--'],
              ],
              compact: true,
            ),
          ]),
          _article('ARTIGO 8º', 'Meios de pagamento', [
            _paragraph(
              'Os pagamentos serão efectuados por depósito, transferência bancária, carteira móvel ou outro canal autorizado pela instituição, devendo o mutuário conservar o respectivo comprovativo.',
            ),
          ]),
          _article('ARTIGO 9º', 'Garantia do cumprimento da obrigação', [
            _paragraph(
              'O presente contrato poderá ser acompanhado por contrato de garantia devidamente assinado e registado, quando aplicável.',
            ),
          ]),
          _article('ARTIGO 10º', 'Rescisão do contrato', [
            _paragraph(
              'O contrato poderá ser rescindido nos termos legais e após a regularização das obrigações exigíveis, sem prejuízo do vencimento antecipado em caso de incumprimento.',
            ),
          ]),
          _article('ARTIGO 11º', 'Direito aplicável', [
            _paragraph(
              'O contrato rege-se pela legislação moçambicana aplicável aos contratos comerciais, instituições de crédito e sociedades financeiras, subsidiariamente pelo Código Civil.',
            ),
          ]),
          _article('ARTIGO 12º', 'Do Foro', [
            _paragraph(
              'As partes darão primazia à mediação e arbitragem para resolução de diferendos, sem prejuízo do recurso aos tribunais judiciais competentes.',
            ),
          ]),
          branding.signature('Contrato'),
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> guaranteeContract({Json? loan, Json? guarantee}) async {
    final description = _value(guarantee, ['description', 'name', 'asset']);
    final type = _value(guarantee, ['type', 'asset_type']);
    final guaranteeValue = _value(guarantee, [
      'value',
      'value_cents',
      'amount',
    ]);
    final registration = _value(guarantee, [
      'registration',
      'plate',
      'serial_number',
    ]);
    final doc = pw.Document(title: 'Contrato de garantia', author: institution);
    doc.addPage(
      pw.MultiPage(
        pageTheme: branding.pageTheme(),
        header: branding.header,
        footer: branding.footer,
        build: (_) => [
          branding.title('Contrato de garantia'),
          _parties(secondPartyLabel: 'GARANTIDOR(A)'),
          branding.sectionTitle('CAPÍTULO I'),
          branding.sectionTitle('PARTE GERAL'),
          _article('ARTIGO PRIMEIRO', 'Objeto', [
            _paragraph(
              'Por meio do presente contrato, o garantidor dá a $institution, como garantia do cumprimento da obrigação, os bens abaixo identificados:',
            ),
            pw.SizedBox(height: 8),
            branding.table(
              headers: [
                'NR',
                'Descrição',
                'Tipo',
                'Proprietário',
                'Valor',
                'Matrícula',
              ],
              rows: [
                [
                  '1',
                  description,
                  type,
                  clientName,
                  guaranteeValue,
                  registration,
                ],
              ],
              compact: true,
            ),
          ]),
          _article('ARTIGO SEGUNDO', 'Obrigação garantida', [
            _paragraph(
              'A garantia assegura o cumprimento do pagamento do crédito celebrado pelas partes, no valor de ${_amount(loan)}.',
            ),
          ]),
          _article('ARTIGO TERCEIRO', 'Montante máximo coberto pelo contrato', [
            _paragraph(
              'O montante máximo coberto pela garantia é de $guaranteeValue.',
            ),
          ]),
          _article('ARTIGO QUARTO', 'Duração', [
            _paragraph(
              'O contrato de garantia vigorará até ao cumprimento integral da obrigação garantida e respectivos acessórios.',
            ),
          ]),
          _article('ARTIGO QUINTO', 'Local e data', [
            _paragraph(
              'O presente contrato é celebrado em $place, aos $today.',
            ),
          ]),
          branding.sectionTitle('CAPÍTULO II'),
          branding.sectionTitle('OBRIGAÇÕES DAS PARTES'),
          _article('ARTIGO SEXTO', 'Obrigações do garantidor', [
            _paragraph(
              'O garantidor deve conservar a coisa garantida, permitir a sua inspecção, informar alterações relevantes e cessar actos de disposição após notificação de execução da garantia.',
            ),
          ]),
          _article('ARTIGO SÉTIMO', 'Obrigações do credor', [
            _paragraph(
              'O credor deve conservar e administrar adequadamente o bem sob sua posse, utilizá-lo nos termos acordados e informar o garantidor sobre a obrigação garantida sempre que solicitado.',
            ),
          ]),
          _article('ARTIGO OITAVO', 'Regime jurídico', [
            _paragraph(
              'O contrato rege-se pela Lei n.º 19/2018, de 28 de Dezembro, e demais legislação aplicável às garantias mobiliárias.',
            ),
          ]),
          _article('ARTIGO NONO', 'Execução da garantia', [
            _paragraph(
              'Em caso de incumprimento, a garantia poderá ser executada extrajudicialmente nos termos legais, assegurando-se as notificações e formalidades aplicáveis.',
            ),
          ]),
          _article('ARTIGO DÉCIMO', 'Venda directa da garantia', [
            _paragraph(
              'O credor garantido poderá dispor da coisa garantida segundo a avaliação e os procedimentos previstos na legislação aplicável.',
            ),
          ]),
          _article('ARTIGO DÉCIMO PRIMEIRO', 'Foro', [
            _paragraph(
              'As partes darão primazia à mediação e arbitragem, sem prejuízo do recurso aos tribunais judiciais.',
            ),
          ]),
          _article('ARTIGO DÉCIMO SEGUNDO', 'Registo', [
            _paragraph(
              'Compete ao credor promover o registo da garantia na Central de Registo de Garantias Mobiliárias, quando aplicável.',
            ),
          ]),
          branding.signature('Garantia'),
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> debtConfession({Json? loan}) async {
    final doc = pw.Document(title: 'Confissão da dívida', author: institution);
    doc.addPage(
      pw.MultiPage(
        pageTheme: branding.pageTheme(),
        header: branding.header,
        footer: branding.footer,
        build: (_) => [
          branding.title('Confissão da dívida'),
          _paragraph(
            'Eu, $clientName, maior, estado civil $maritalStatus, de nacionalidade $nationality, natural de $birthplace, domiciliado em $address, portador do documento de identificação nº $document, contactável pelo nº $phone, declaro e confesso ser devedor da obrigação abaixo descrita.',
          ),
          pw.SizedBox(height: 14),
          branding.sectionTitle('1. PLANO DE AMORTIZAÇÃO'),
          pw.SizedBox(height: 8),
          _paragraph(
            'Montante de ${_amount(loan)}, à taxa de juro de ${_rate(loan)}, num prazo de ${_months(loan)} mês(es), referente à operação ${_reference(loan)}.',
          ),
          pw.SizedBox(height: 8),
          branding.table(
            headers: [
              'Parcela',
              'Vencimento',
              'Prestação',
              'Capital',
              'Juros',
              'Saldo remanescente',
            ],
            rows: const [
              ['--', '--', '--', '--', '--', '--'],
            ],
            compact: true,
          ),
          pw.SizedBox(height: 14),
          branding.sectionTitle('2. CONTAS PARA REEMBOLSO'),
          pw.SizedBox(height: 8),
          branding.table(
            headers: ['Banco/Canal', 'Número/NIB', 'Titular'],
            rows: const [
              ['--', '--', '--'],
            ],
          ),
          pw.SizedBox(height: 14),
          branding.sectionTitle('3. CONTA PARA DESEMBOLSO'),
          pw.SizedBox(height: 8),
          branding.table(
            headers: ['Banco/Canal', 'Número', 'NIB', 'Titular'],
            rows: [
              ['--', phone, '--', clientName],
            ],
          ),
          pw.SizedBox(height: 14),
          _paragraph(
            'Nos termos acima descritos, declaro-me responsável pelo pagamento integral da dívida mencionada.',
          ),
          branding.signature('Confissão de dívida'),
        ],
      ),
    );
    return doc.save();
  }
}
