# SysCredi — estado de implementação e trabalho pendente

Actualizado em: **14 de Setembro de 2026**.

Este documento inventaria o código actual e organiza a evolução do SysCredi. A aplicação é desenvolvida em Flutter, usa API remota/camada de dados local e está orientada para operações de microcrédito em Moçambique, com montantes em MZN/MT. O fluxo local de cliente → pedido → desembolso → pagamento está implementado. Ainda não equivale a um ERP financeiro completo nem a um serviço partilhado entre dispositivos.

## Como utilizar esta lista

- `[x]` significa que existe implementação identificada; o texto indica se é uma funcionalidade exposta ou apenas uma base técnica.
- `[ ]` significa trabalho pendente, incluindo integração, validação ou decisões de produto ainda necessárias.
- **Parcial** significa que parte do módulo existe, mas faltam componentes para o resultado esperado.
- **P0:** integridade dos dados e controlo de acesso; resolver antes de ampliar a operação.
- **P1:** completar a gestão diária e os módulos centrais de um ERP de microcrédito.
- **P2:** colaboração, integrações e automação; a prioridade pode subir conforme o modelo de operação escolhido.
- **P3:** expansão de produto e capacidades opcionais.

A ordem é uma proposta técnica, não um compromisso de prazo. Não existe estimativa de percentagem concluída: módulos têm dimensões diferentes e parte do escopo depende de decisões da instituição. Marcar uma tarefa como concluída apenas com implementação, ligação ao fluxo aplicável e evidência de validação.

**Reconciliação actual:** 170 itens estão marcados como implementados e 70 permanecem pendentes. O escopo de pagamentos é P2P, com registo local de operações e comprovativos; não inclui integração directa com bancos ou carteiras móveis.


## Implementado nesta continuação

### Entregas adicionais desta continuação
- [x] Tema institucional centralizado: a paleta activa alimenta o `ColorScheme`, campos, botões, menus, estados, avatares e métricas; parametrização ganhou cinco presets de cores aplicáveis imediatamente em todo o MaterialApp.
- [x] Primeira extracção de Clean Architecture do módulo de Clientes: entidades de domínio em `features/clients/domain/client_directory.dart` e leitura de Empresas, Avalistas e Co-assinantes encapsulada em `features/clients/data/client_directory_repository.dart`; a UI deixa de consultar estas tabelas directamente para listagem.
- [x] Clientes recebeu pesquisa, filtro por estado KYC, cadastro com identificação/localização moçambicanas, edição, visualização, confirmação antes de apagar, eliminação protegida por integridade (sem contratos/pedidos) e auditoria da operação.
- [x] Submenus de Clientes agora permanecem no mesmo escopo de navegação: Sidebar, cabeçalho e estrutura principal são preservados ao abrir Indivíduos, Empresas, Avalistas e Co-assinantes.
- [x] Escopo de pagamentos confirmado como P2P: canais como M-Pesa, e-Mola, mKesh, BIM e BCI são apenas referências no registo local; não há envio automático, consulta de saldo ou confirmação por API.
- [x] Adequação terminológica a Moçambique: identificação com BI, DIRE, Passaporte, Cédula pessoal e Carta de condução; NUIT retirado da escolha de documento de identidade. Rótulos de telemóvel, endereço/bairro/localidade, situação habitacional e identificação de avalistas actualizados; empresas apresentam registo comercial/NUEL e NUIT. Novos clientes passam a exigir localização real, eliminando a atribuição automática de Maputo. Validado com análise estática e três testes de interface.
- [x] Empresas e co-assinantes ganharam entidades camada de dados próprias e migration 16→17; submenus separados apresentam os registos persistidos em páginas próprias.
- [x] Menu lateral ampliado com os grupos e submenus da referência: Clientes (indivíduos, empresas, avalistas, co-assinantes), Relatórios, Financeiro (saldos, movimentos, conciliação, estornos), Parametrização, Gestão de logs e Instruções; cada entrada navega para o módulo local correspondente.
- [x] Varredura visual da base de referência: 88 imagens foram catalogadas por dashboard, clientes, pedidos, desembolso, carteira, tesouraria, relatórios, utilizadores e auditoria; o dashboard passou a destacar também capital em atraso ligado à carteira real.
- [x] Cada tipo do acordeão de relatórios passou a gerar também PDF paginado, com cabeçalho SysCredi, título, tabela de dados e numeração de páginas.
- [x] Relatórios ganharam acordeão de tipos inspirado na referência: estado da carteira, pagamentos/recebimentos, cadastro de clientes e carteira por data, todos com exportação CSV ligada aos dados remotos.
- [x] Escopos de acesso formalizados para `operator`, `analyst` e `manager`, com utilizadores de teste criados automaticamente apenas em builds de desenvolvimento (`analist@test.com`, `operator@test.com`, `manager@test.com`; palavra-passe temporária `Test@1234`).
- [x] Cadastro de crédito ampliado com actividade económica, fonte de rendimento, residência, agregado familiar, dependentes, antiguidade do negócio, outras dívidas e capacidade mensal de pagamento; migration camada de dados 15→16 incluída.
- [x] Cadastro e documentos passaram a dar feedback explícito de sucesso, cancelamento e erro nos botões de guardar, anexar e verificar identidade.
- [x] Corrigido o botão **Calcular financiamento**: o simulador agora calcula novamente, valida entradas, trata erros e evita acesso prematuro ao `FocusScope` durante a inicialização.
- [x] Alertas AML passaram a ter tela operacional com atribuição e mudança de estado auditada.
- [x] Fila de sincronização passou a ter tela operacional com reprocessamento e descarte.
- [x] Política de retenção configurável e purga controlada por permissão.
- [x] Agendador de backups cifrados locais com intervalo, última execução e verificação de vencimento.
- [x] Schema 15 com modalidade, carência, mora e moeda no produto.
- [x] Políticas de produto persistidas: modalidade de prestação, dias de carência, taxa de mora e moeda MZN; validação impede políticas incompatíveis.
- [x] Fila de sincronização visível na interface, com contagem de pendências, tentativas, reprocessamento e descarte auditado.
- [x] Migration 14→15 com detecção segura de colunas existentes.

- [x] Schema 14 com avalistas/garantias e registo de visitas de campo.
- [x] Serviços autorizados para avalistas, perfis e visitas de campo.
- [x] Repositório AML com autorização, atribuição, transições protegidas e auditoria.
- [x] Cotação de liquidação antecipada pelo capital pendente e aplicação através do ciclo financeiro.
- [x] Encargo de mora com validações, autorização e auditoria; cálculo financeiro de mora continua dependente da política institucional aprovada.
- [x] Regras de aprovação transaccionais com alçada por utilizador e prevenção de autoaprovação.
- [x] Referências de contas de tesouraria estabilizadas por ID e movimentos com validação de moeda/saldo.
- [x] Testes de workflow autorizado, migração de schema 11→14 e documentos financeiros.


A lista original foi criada antes desta ronda. As seguintes entregas foram implementadas e validadas no código actual:

- [x] Autorização aplicada aos serviços de clientes, pedidos, pagamentos, tesouraria, produtos, definições, auditoria e backups; sessões expiram, logout revoga o token e utilizadores podem ser administrados.
- [x] Senhas novas usam PBKDF2-HMAC-SHA256 com salt individual; senhas legadas são actualizadas no primeiro login válido; tentativas falhadas bloqueiam temporariamente a conta.
- [x] Migração de schema 11 para 13: contas contabilísticas, diário, linhas, períodos fechados, estornos, contactos de cobrança, snapshots de contratos, extractos bancários, documentos e perfis financeiros.
- [x] Contabilidade local com plano de contas inicial, partidas dobradas, idempotência, estorno de lançamentos manuais, períodos fechados, balancete e exportação CSV. Desembolsos, recebimentos e movimentos de caixa geram lançamentos equilibrados.
- [x] Estorno de pagamentos preserva recibo/histórico, exige ordem inversa e recalcula prestações, saldo e caixa.
- [x] Importador CSV robusto com aspas/quebras de linha, validação, pré-visualização, duplicados e operação atómica.
- [x] Perfis financeiros, anexos de documentos com checksum/limite e verificação KYC com validade.
- [x] Conciliação bancária com importação idempotente, candidatos por conta/valor/data, associação única e desfazer auditado.
- [x] Geração de contrato, recibo e quitação em PDF, incluindo condições financeiras imutáveis e rodapé institucional.
- [x] Backup API remota com cópia preventiva, limpeza de sessões após restauração e backup cifrado AES-GCM protegido por PBKDF2.
- [x] Relatórios de pagamentos e carteira por data com estado de estorno; dashboard exclui pagamentos estornados do histórico.
- [x] Interface para gestão de utilizadores, contabilidade, conciliação, importação de clientes, cadastro/documentos, contactos de cobrança e documentos financeiros.
- [x] CI actualizada para análise, testes, build Android/web existentes e build macOS separado; o destino web nativo continua bloqueado pela dependência API remota/dart:io e requer adaptador próprio.

Validação após estas entregas: `flutter analyze` sem problemas e **53 testes passaram** (`flutter test`).

## 1. Resumo por módulo

| Módulo | Estado actual | Principal lacuna |
|---|---|---|
| Clientes | Operacional | Actividade de campo e operação assistida |
| Produtos e simulação | Operacional básico | Mais modalidades e política financeira versionada |
| Pedidos de crédito | Fluxo autorizado implementado | Pareceres, comité, checklist e devolução |
| Desembolso e pagamentos | Transacções locais com estorno e PDFs | Assinatura e integrações externas |
| Carteira e cobrança | Operacional básico | Renegociação financeira e cobrança organizada |
| Tesouraria | Operacional local com conciliação | Operação de caixa e integração bancária de produção |
| Contabilidade | Diário/balancete local | Competência, dimensões e validação institucional |
| Relatórios | Básico | Metas, relatórios históricos e mapas institucionais |
| Autenticação | Operacional local | Recuperação de conta e MFA/remoto |
| Auditoria | Registos, autoria e retenção configurável | Fontes externas e validação institucional |
| Modo remoto | Integração remota implementada | Validação em cada plataforma |
| Sincronização | Base técnica | Serviço remoto, conflitos e integração com operações |
| Backup | Operacional local agendado e cifrado | Armazenamento remoto e exercícios operacionais |
| Licenciamento | Modelo local | Validação comercial e resistência a adulteração |

## 2. Clientes, cadastro e identificação — parcial

### Implementado

- [x] Cadastro e consulta de clientes, pesquisa e persistência API remota.
- [x] Dados básicos de contacto, documento e actividade; interface orientada a contactos moçambicanos.
- [x] Estado de verificação de identidade e revisão no cadastro.
- [x] Bloqueio do desembolso quando o cliente não está identificado como verificado.
- [x] Estruturas e repositório para revisões KYC.
- [x] Parser simples de importação CSV com teste unitário; isto não comprova um importador completo na interface.

### Pendente (reconciliado com o código actual)

- [x] **P0 — Identificadores:** relações novas usam o ID do cliente; referências legadas só permanecem para compatibilidade e migração validada.
- [x] **P0 — Consistência KYC:** validade documental é verificada no fluxo de desembolso e nas operações autorizadas.
- [x] **P1 — Cadastro aprofundado:** perfil financeiro persistente com rendimento, despesas, actividade e capacidade de pagamento.
- [x] **P1 — Documentos:** anexos com checksum, limite, consulta e histórico ligados ao cliente.
- [x] **P1 — Garantias:** avalistas/garantias persistidos e ligados ao cliente/contrato por serviço autorizado.
- [x] **P1 — Importação assistida:** pré-visualização, erros por linha, duplicados e importação atómica disponíveis no fluxo de clientes.
- [x] **P1 — CSV robusto:** parser/encoder suporta aspas, vírgulas internas, quebras de linha, cabeçalhos e escape de fórmulas.
- [ ] **P2 — Actividade de campo:** formulário, próxima visita e histórico por responsável já existem; faltam acompanhamento de execução e indicadores de campo.

**Critério de conclusão:** um operador cadastra e actualiza um cliente sem duplicar a identidade; documentos e verificações ficam ligados ao cliente certo; uma importação inválida apresenta erros claros e não introduz registos inconsistentes.

**Evidências:** `lib/main.dart`, `lib/features/clients/data/`, `lib/features/compliance/`, `test/local_operations_test.dart`, `test/business_features_test.dart`.

## 3. Produtos, taxas e simulação — parcial

### Implementado

- [x] Produtos configuráveis com taxa anual, limite de montante, prazo mínimo/máximo e estado activo.
- [x] Escolha do produto nos pedidos e aplicação no simulador.
- [x] Validação de condições do produto no desembolso.
- [x] Plano mensal com capital constante e juros sobre o capital remanescente.
- [x] Distribuição do capital em centavos, ajuste da última prestação e tratamento do último dia do mês.
- [x] Validações de capital, taxa, prazo e valores não finitos no motor de prestações.

### Pendente

- [x] **P0 — Política financeira:** fórmula do plano, arredondamento, datas e imputação estão documentados no domínio e nos documentos; aprovação institucional continua pendente.
- [ ] **P0 — Representação monetária:** o livro contabilístico usa centavos exactos, mas colunas legadas de crédito ainda usam `double` e precisam de reconciliação.
- [x] **P0 — Condições contratadas:** snapshot imutável das condições é criado no contrato e usado nos PDFs.
- [ ] **P1 — Encargos:** validar a correspondência entre o que o simulador apresenta e o que o contrato/desembolso grava e cobra.
- [ ] **P1 — Modalidades:** decidir quais métodos adicionais são necessários antes de implementar prestações constantes, taxa fixa sobre capital inicial ou outras modalidades.
- [ ] **P1 — Calendário:** parametrizar periodicidade, carência, primeira prestação e regras de dias não úteis, conforme os produtos aprovados.
- [ ] **P1 — Antecipação:** o serviço já liquida pelo capital pendente; falta aprovar desconto de juros futuros e pagamento extraordinário.
- [ ] **P1 — Mora:** validação/auditoria do encargo existe; falta implementar cálculo e memória de cálculo conforme política aprovada.

**Critério de conclusão:** simulação, contrato, plano de prestações e cobrança produzem os mesmos valores para exemplos aprovados; os totais permanecem exactos após pagamentos parciais, antecipações e arredondamentos.

**Evidências:** `lib/features/credit/domain/credit_product.dart`, `lib/features/credit/domain/entities/repayment_schedule.dart`, `lib/features/workspace/products_page.dart`, `lib/features/workspace/premium.dart`, `test/credit_product_test.dart`, `test/repayment_schedule_test.dart`.

## 4. Pedidos, análise e aprovação — parcial

### Implementado

- [x] Estados de rascunho, documentação, análise, comité, aprovação, recusa e cancelamento no domínio.
- [x] Validação de progressão sequencial e bloqueio de novas transições de pedidos terminados.
- [x] Motivo obrigatório para recusa.
- [x] Pesquisa/listagem e filtros por fase na interface.
- [x] Persistência dos pedidos e registo de decisões no fluxo local.

### Pendente

- [x] **P0 — Permissões efectivas:** autorização é validada no serviço que executa cada decisão, não só nos botões.
- [x] **P0 — Segregação:** autoaprovação é impedida; regras adicionais de funções dependem da política institucional.
- [x] **P1 — Alçadas:** limite por utilizador é aplicado transaccionalmente e aprovação acima da alçada é recusada.
- [ ] **P1 — Parecer:** armazenar análise financeira, recomendação, motivo da decisão, autor e data.
- [ ] **P1 — Comité:** implementar votos/quórum e histórico se a instituição exigir comité real; a fase chamada “Comité” não implementa estes mecanismos.
- [ ] **P1 — Checklist:** exigir os documentos e dados necessários antes de cada etapa.
- [ ] **P1 — Devolução:** definir retorno para correcção e reapresentação sem apagar decisões anteriores.

**Critério de conclusão:** um pedido percorre o fluxo apenas com documentação e intervenientes autorizados; decisões ficam justificadas e uma chamada directa ao serviço não contorna as alçadas.

**Evidências:** `lib/features/credit/domain/use_cases/advance_credit_request.dart`, `lib/main.dart`, `test/advance_credit_request_test.dart`, `test/store_API remota_test.dart`.

## 5. Contratos, desembolso e pagamentos — operacional local, incompleto para integrações

### Implementado

- [x] Desembolso exige pedido aprovado e cliente verificado.
- [x] Criação transaccional de crédito, contrato, prestações, saída de tesouraria, estado do pedido e auditoria.
- [x] Bloqueio de uma segunda tentativa de desembolso do mesmo pedido.
- [x] Recebimento parcial ou total com actualização de prestações e saldo.
- [x] Registo transaccional de pagamento, recibo e entrada de caixa.
- [x] Repetição de pagamento com a mesma referência e dados iguais é idempotente; dados divergentes são recusados.
- [x] Consulta/cópia de recibos e exportação de pagamentos em CSV.
- [x] Conservação de canal, identificador de conta e referência externa nos detalhes do pagamento.

### Pendente

- [x] **P0 — Estorno:** pagamentos têm operação compensatória auditada, sem edição destrutiva do histórico.
- [x] **P0 — Fecho financeiro:** saldo, prestações, pagamentos e tesouraria são recalculados e testados após correcções.
- [x] **P1 — Documentos finais:** contrato, recibo e quitação são gerados em PDF com condições e identificação.
- [ ] **P1 — Assinatura:** implementar captura e validação de assinatura conforme o processo definido pela instituição.
- [x] **P1 — Liquidação:** liquidação explícita e comprovativo de quitação estão disponíveis no serviço/documento financeiro.
- [x] **P2P — Operadores externos:** fora do escopo; bancos e carteiras móveis não são chamados pelo SysCredi.
- [x] **P2P — Confirmação:** a instituição regista manualmente a referência, comprovativo, montante, data, canal e responsável pela conferência.

**Limite actual:** seleccionar M-Pesa, eMola, mKesh, BIM ou BCI regista uma operação local. Não envia fundos, não confirma a titularidade de contas e não verifica recebimentos no operador.

**Critério de conclusão P2P:** uma operação tem uma única consequência financeira, mesmo com repetição ou falha; correcções preservam o histórico; o movimento só é concluído após conferência do comprovativo e da referência pelo operador.

**Evidências:** `lib/features/credit/application/loan_lifecycle.dart`, `lib/features/treasury/domain/payment_channels.dart`, `test/loan_lifecycle_test.dart`, `test/contracts_test.dart`, `test/operational_features_test.dart`.

## 6. Carteira, risco e cobrança — parcial

### Implementado

- [x] Consulta de contratos e carteira por cliente, referência e estado.
- [x] Acompanhamento de saldos, vencimentos e atrasos.
- [x] Reagendamento de prestações pendentes com motivo auditado, preservando montantes e pagamentos anteriores.
- [x] Função básica de score e função de indicadores PAR com testes de domínio; não equivalem a um motor de risco validado.

### Pendente

- [ ] **P0 — Indicadores:** validar a definição de exposição, saldo e PAR. A função actual de PAR usa capital originalmente concedido como denominador; decidir a métrica institucional e alinhar fórmula, rótulos e testes.
- [ ] **P0 — Atrasos:** validar actualização pela data corrente, pagamentos parciais e reagendamento; garantir consistência entre painel e relatórios.
- [ ] **P1 — Renegociação completa:** preservar contrato/plano anterior, calcular novas condições e registar aprovação e acordo do cliente.
- [x] **P1 — Cobrança organizada:** contactos, responsável, próxima acção e resultado são persistidos e auditados.
- [ ] **P1 — Perdas:** definir provisão, baixa de créditos e recuperação posterior com ligação contabilística.
- [ ] **P1 — Score explicável:** ligar entradas a dados reais, guardar versão e explicar factores; validar a política antes de usar para decisões automáticas.
- [ ] **P2 — Lembretes:** envio por canal escolhido, preferências de contacto, prevenção de duplicados e registo de entrega.
- [ ] **P2 — Bureau:** integrar fornecedor autorizado, se necessário, com rastreio de consultas.

**Critério de conclusão:** carteira, cobrança e relatórios concordam quanto a saldo e atraso; renegociar preserva o histórico; cada acção de cobrança tem responsável e resultado.

**Evidências:** `lib/main.dart`, `lib/features/reports/domain/portfolio_metrics.dart`, `lib/features/risk/domain/score.dart`, `test/portfolio_metrics_test.dart`, `test/operational_features_test.dart`.

## 7. Contas, tesouraria e conciliação — parcial

### Implementado

- [x] Criação de contas, saldo inicial e cálculo do saldo a partir dos movimentos.
- [x] Transferências internas com duas entradas na mesma transacção.
- [x] Validação de contas activas e saldo disponível nas transferências internas.
- [x] Receitas/despesas e listagem de movimentos locais.
- [x] Função simples de comparação entre saldo esperado e real, com testes; não é conciliação bancária automática.

### Pendente

- [x] **P0 — Relações estáveis:** movimentos ligam-se ao ID da conta e validam a referência.
- [x] **P0 — Regras comuns:** saldo, conta, moeda e referência são validados nos fluxos financeiros principais.
- [ ] **P1 — Caixa:** abertura, contagem, divergência, fecho e identificação do operador.
- [x] **P1 — Extractos:** extractos CSV são importados de forma idempotente e duplicados são detectados.
- [x] **P1 — Conciliação:** candidatos por referência/data/valor podem ser revistos, associados e desfeitos.
- [x] **P1 — Histórico:** origem, operador e desfazimento ficam auditados.
- [x] **P1 — Contabilidade:** movimentos financeiros geram lançamentos ligados à origem.

**Critério de conclusão:** saldo inicial + entradas − saídas corresponde ao saldo final; divergências do extracto são explicadas; importar o mesmo ficheiro duas vezes não duplica movimentos.

**Evidências:** `lib/features/treasury/`, `lib/features/workspace/accounts_page.dart`, `test/reconciliation_test.dart`, `test/operational_features_test.dart`.

## 8. Contabilidade integrada — pendente

Movimentos de tesouraria não constituem um módulo de contabilidade por partidas dobradas.

- [x] **P1 — Modelo:** plano de contas inicial, natureza, períodos e contas de controlo estão persistidos.
- [x] **P1 — Lançamentos:** diário de partidas dobradas equilibradas com origem, data, autor e descrição.
- [x] **P1 — Mapeamento:** contas de desembolso, recebimento, caixa e transferências estão ligadas aos eventos.
- [x] **P1 — Automatização:** eventos financeiros geram lançamentos idempotentes.
- [ ] **P1 — Competência:** definir reconhecimento de juros, apropriações e tratamento de créditos em atraso.
- [x] **P1 — Correcções:** reversão/estorno referencia o lançamento original.
- [x] **P1 — Fecho:** períodos encerrados bloqueiam novos lançamentos.
- [x] **P1 — Demonstrações:** diário e balancete exportáveis; balanço/DR detalhados continuam a exigir expansão.
- [ ] **P2 — Dimensões:** centros de custo, agência, agente e fonte de financiamento, quando aplicável.
- [ ] **P1 — Validação:** aprovar modelos e exemplos com o responsável contabilístico da instituição.

**Dependências:** política financeira, identificadores estáveis, transacções e estornos definidos.

**Critério de conclusão:** cada evento gera lançamentos equilibrados; balancete fecha; relatórios reconciliam com a carteira e tesouraria; um período fechado não é alterado silenciosamente.

## 9. Painel e relatórios — parcial

### Implementado

- [x] Painel com dados remotos reais, indicadores, gráficos e tabelas.
- [x] Histórico visual de 3, 6 ou 12 meses, calculado a partir dos registos disponíveis.
- [x] Resumo de capital concedido e saldo em dívida.
- [x] CSV de pagamentos com referência, contrato, valor, canal, data e detalhes bancários.
- [x] Instalação sem preenchimento automático de dados pessoais de demonstração.

### Pendente

- [x] **P1 — Filtros:** relatórios filtram por período, cliente, produto e estado.
- [x] **P1 — Carteira detalhada:** carteira inclui vencimentos, atrasos, recebimentos, desembolsos e encerramentos.
- [x] **P1 — Histórico reproduzível:** snapshots de contrato e relatórios por data de referência estão disponíveis; validação institucional permanece pendente.
- [ ] **P1 — Metas:** configurar metas de concessão/recebimento e acompanhar realizado por responsável.
- [x] **P1 — Exportação:** CSV e PDFs de documentos/relatórios são gerados com contexto temporal.
- [ ] **P1 — Coerência:** falta aprovar a definição institucional de capital, juros e encargos e reconciliar todos os indicadores.
- [ ] **P2 — Mapas institucionais:** identificar relatórios efectivamente exigidos e implementar versões validadas.
- [ ] **P3 — Impacto social:** estatísticas socioeconómicas, se os dados forem recolhidos e a instituição precisar delas.

**Critério de conclusão:** qualquer total pode ser explicado por registos detalhados; filtros são reproduzidos nas exportações; relatórios históricos mantêm resultados coerentes após novas operações.

**Evidências:** `lib/features/workspace/reference_dashboard.dart`, `lib/features/reports/`, `test/report_service_test.dart`, `test/reference_dashboard_test.dart`.

## 10. Autenticação, utilizadores e permissões — parcial, prioridade P0

### Implementado

- [x] Telas de login e cadastro locais.
- [x] Utilizadores persistidos, estado activo, token de sessão e validade temporal no serviço.
- [x] Login como entrada normal da aplicação; a injecção de uma base no construtor permite entrada directa usada nos testes.
- [x] Matriz de permissões para operador, analista e gestor, com testes unitários.

### Pendente

- [x] **P0 — Aplicação de permissões:** `Authorize` está integrado aos serviços e operações sensíveis.
- [x] **P0 — Senhas:** PBKDF2 com salt individual e migração de hashes legados.
- [x] **P0 — Sessão:** validade e inactivação são verificadas durante o uso.
- [x] **P0 — Logout:** sessão persistida é revogada e o estado local é limpo.
- [x] **P0 — Cadastro:** identificadores de utilizador são únicos e criação/atribuição exigem autorização.
- [x] **P0 — Administração:** utilizadores podem ser activados, desactivados e auditados.
- [x] **P0 — Testes de integração:** existem testes de operações proibidas, expiração e inactivação.
- [ ] **P1 — Recuperação:** bloqueio temporário existe; falta definir e implementar recuperação de conta/senha.
- [ ] **P1 — Dados remotos:** backup e restauração existem; falta definir gestão operacional das chaves e recuperação.
- [ ] **P2 — Autenticação remota/MFA:** escolher mecanismo conforme a futura arquitectura e o modelo de acesso.

**Critério de conclusão:** um utilizador sem permissão não altera dados por nenhum fluxo; sessão revogada/expirada deixa de autorizar; a migração de senhas não bloqueia contas válidas.

**Evidências:** `lib/features/auth/`, `lib/main.dart`, `test/auth_service_test.dart`, `test/permissions_test.dart`.

## 11. Auditoria, retenção e alertas — parcial

### Implementado

- [x] Tabela e serviços de auditoria; consulta na aplicação.
- [x] Registos para operações financeiras e outras alterações sensíveis.
- [x] Estruturas AML, criação/alteração de estado e repositório com teste.
- [x] Serviço técnico para remover auditoria antiga e sessões expiradas.

### Pendente

- [x] **P0 — Autoria:** identidade autenticada é propagada às operações sensíveis.
- [x] **P0 — Contexto:** auditoria guarda entidade, referência, motivo e metadados sem segredos.
- [x] **P0 — Retenção:** política configurável, purga autorizada e auditoria da purga estão implementadas; aprovação institucional falta.
- [x] **P1 — Integridade:** eventos são append-only no fluxo e alterações sensíveis exigem operações compensatórias.
- [x] **P1 — Alertas:** alertas AML têm regras, responsável, evidências e transições auditadas.
- [ ] **P2 — Fontes externas:** integrar listas/fornecedores apenas se necessários; não existe rastreio externo automático actualmente.

**Critério de conclusão:** uma operação financeira pode ser reconstruída com autor e motivo; acesso e retenção são controlados; um alerta mantém histórico até à resolução.

## 12. Persistência, backup e recuperação — operacional básico

### Implementado

- [x] API remota nativo através de camada de dados; schema actual 15.
- [x] Persistência de clientes, produtos, pedidos, contratos, prestações, pagamentos, contas, auditoria e configurações.
- [x] Migração de preferências/cadastro legados para armazenamento local actual.
- [x] Exportação completa API remota e restauração com verificação de integridade/schema e cópia preventiva.
- [x] Testes de persistência após fecho/reabertura e restauração.

### Pendente

- [x] **P0 — Migrações:** migrações suportadas têm testes de schema e verificações de referências.
- [x] **P0 — Recuperação:** restauração API remota valida cópia antes de substituir a base e limpa sessões.
- [x] **P1 — Backups protegidos:** backup cifrado AES-GCM com derivação PBKDF2 e retenção local.
- [x] **P1 — Agendamento:** agendador configurável regista última execução e vencimento.
- [ ] **P1 — Recuperação operacional:** documentar passos, responsáveis e objectivos aceitáveis de perda de dados/tempo de recuperação.
- [ ] **P1 — Escala:** medir consultas e exportações com volume representativo; acrescentar índices/paginação conforme os resultados.

**Critério de conclusão:** uma instalação recupera dados a partir de uma cópia validada, com contagens e saldos reconciliados; falhas de restauração preservam a base anterior.

**Evidências:** `lib/core/database/`, `lib/core/persistence/`, `lib/core/backup/`, `docs/SUPABASE.md`, `test/remote_api_test.dart`, `test/loan_lifecycle_test.dart`.

## 13. Sincronização e colaboração — base técnica

### Implementado

- [x] Outbox com chave de idempotência, tentativas e atraso progressivo.
- [x] Interface de fornecedor cloud e implementação explicitamente modo remoto.
- [x] Estruturas de cursores de sincronização e teste básico da fila.

### Pendente

- [ ] **P2 — Arquitectura:** decidir entre operação exclusivamente local, backup remoto ou colaboração real; são entregas diferentes.
- [ ] **P2 — Serviço remoto:** escolher fornecedor e implementar autenticação, API, armazenamento e isolamento dos dados.
- [ ] **P2 — Escopo:** adicionar organização/agência/responsável aos registos que precisam destas dimensões.
- [x] **P2 — Integração da fila:** outbox local persiste pendências com estado, tentativas e auditoria.
- [ ] **P2 — Recepção:** importar alterações remotas com cursor, ordenação e tratamento de exclusões.
- [ ] **P2 — Conflitos:** definir política para alterações concorrentes; pagamentos e decisões exigem garantias próprias.
- [ ] **P2 — Idempotência no servidor:** impedir duplicação mesmo quando o cliente repete uma requisição após perder a resposta.
- [x] **P2 — Experiência modo remoto:** tela de sincronização mostra pendências, última sincronização, retry e descarte.
- [ ] **P2 — Testes:** simular dois dispositivos, queda de rede, repetição, conflito e retomada.

**Critério de conclusão:** dois dispositivos autorizados convergem sem duplicar operações ou perder alterações; falhas de rede preservam dados; instituições distintas não acedem aos dados uma da outra.

**Evidências:** `lib/core/sync/`, `test/sync_service_test.dart`, `docs/SUPABASE.md`.

## 14. Configurações e licenciamento — parcial

### Implementado

- [x] Identidade e preferências da instituição persistidas remotamente.
- [x] Personalização visual, cores, tema e campos de marca/rodapé.
- [x] Trial, planos e activação por código local.
- [x] Histórico de subscrição com teste de armazenamento sem exposição do código original.

### Pendente

- [ ] **P1 — Moeda:** alinhar a moeda apresentada com a moeda efectiva das contas e cálculos; mudar o rótulo não implementa multimoeda ou conversão cambial.
- [x] **P1 — Permissões:** alterações institucionais exigem autorização.
- [x] **P1 — Configurações aplicadas:** configurações de espaço de trabalho alimentam documentos e exportações aplicáveis.
- [ ] **P2 — Licença verificável:** substituir checksum local reproduzível por mecanismo de assinatura/validação apropriado ao modelo comercial.
- [ ] **P2 — Regras comerciais:** definir renovação, expiração, período de tolerância e acesso aos dados após expiração.
- [ ] **P2 — Cobrança da subscrição:** integrar apenas se houver venda automática; plano local não significa pagamento confirmado.

**Critério de conclusão:** configurações têm efeito verificável, alterações sensíveis são autorizadas e a licença não depende apenas de um algoritmo reproduzível distribuído com a aplicação.

## 15. Interface, plataformas e manutenção

### Implementado

- [x] Interface adaptativa para larguras desktop, tablet e móvel.
- [x] Tema claro/escuro, pesquisa global e navegação entre módulos.
- [x] Testes de layout para painel, simulador e diferentes dimensões.
- [x] Histórico documental de build macOS validado; esse build não foi repetido nesta revisão.

### Pendente

- [ ] **P1 — Plataformas:** validar instalação, ficheiros, permissões, API remota e recuperação em cada sistema que será distribuído.
- [ ] **P2 — Web:** implementar adaptador API remota/WASM ou acesso remoto e adaptar uso de `dart:io`; a fábrica actual é nativa.
- [ ] **P1 — Usabilidade:** validar teclado, foco, contraste, textos longos, mensagens de erro e operações em ecrãs pequenos.
- [ ] **P1 — Organização do código:** extrair gradualmente páginas e regras concentradas em `lib/main.dart`, preservando os testes existentes.
- [ ] **P1 — Limites de arquitectura:** concentrar regras e transacções nos serviços; evitar regras de autorização/financeiras apenas nos widgets.
- [ ] **P1 — Documentação:** actualizar `ARCHITECTURE.md`, `MVP_SCOPE.md` e planos antigos; há conteúdo histórico que já não corresponde ao estado API remota actual.
- [ ] **P1 — Entregas:** verificar/configurar CI para análise e testes; definir empacotamento, versão, changelog e actualizações da base.
- [ ] **P2 — Diagnóstico:** logs úteis sem dados sensíveis, captura de falhas e procedimento de suporte.

**Critério de conclusão:** os destinos anunciados são instaláveis e testados; fluxos essenciais funcionam em cada um; a documentação descreve a implementação efectiva.

## 16. Validação existente e próximos testes

Na revisão desta sessão em **13/09/2026**:

- [x] `flutter analyze`: terminou sem problemas reportados.
- [x] `flutter test --reporter compact`: **53 testes passaram**.
- [x] Foram identificados testes de persistência, crédito, pagamentos, KYC, permissões de domínio, backup, sincronização de domínio, relatórios e interface.

Estes resultados não comprovam integrações externas, aplicação completa das permissões, conformidade institucional ou funcionamento em todas as plataformas. Um teste de uma função isolada não demonstra que ela esteja ligada à aplicação.

### Cobertura a acrescentar com as respectivas implementações

- [x] Operação financeira recusada por falta de permissão, sessão expirada e utilizador inactivo.
- [x] Rollback nos pontos de falha cobertos pelo desembolso, pagamento e estorno.
- [x] Repetição de operações com a mesma referência é idempotente ou recusada quando diverge.
- [x] Reconciliação dos totais de contrato, prestações, caixa e contabilidade nos fluxos testados.
- [x] Migrações de schema suportadas e recuperação de backup têm testes automatizados.
- [ ] Antecipações, mora e renegociação, com exemplos financeiros aprovados.
- [ ] Sincronização entre dispositivos e isolamento entre instituições, quando implementados (ainda sem servidor remoto).
- [x] CSV com aspas, vírgulas, linhas inválidas e duplicados.
- [x] Relatórios históricos e indicadores com data de referência controlada.
- [ ] Teste completo no dispositivo: cadastro → aprovação → desembolso → pagamento parcial → liquidação → backup → restauração.

## 17. Sequência proposta de execução

| Etapa | Entrega | Dependências | Condição de saída |
|---|---|---|---|
| 1 — P0 | Permissões, sessões e identidade do operador | Regras de funções aprovadas | Operações não autorizadas bloqueadas e auditadas |
| 2 — P0 | Consistência monetária, referências e estornos | Política de cálculo/contas | Saldos reconciliados e correcções rastreáveis |
| 3 — P1 | Documentos, cobrança e relatórios operacionais | Etapas 1–2 | Ciclo diário completo e exportável |
| 4 — P1 | Contabilidade e conciliação | Eventos financeiros estáveis e plano de contas | Balancete e tesouraria reconciliados |
| 5 — P2 | Colaboração e sincronização | Arquitectura remota escolhida | Dois dispositivos convergem sem duplicação |
| 6 — P2 | Pagamentos externos | Procedimento P2P interno e comprovativos definidos | Registos conferidos, auditáveis e sem duplicação; sem integração automática com bancos ou carteiras |
| 7 — P1/P2 | Distribuição e operação assistida | Plataformas e escopo escolhidos | Instalação, recuperação e suporte ensaiados |

Se a utilização por vários operadores for requisito imediato, antecipar a decisão de arquitectura da etapa 5 antes de desenhar o controlo de acesso e a contabilidade.

## 18. Decisões por fechar

- [ ] Definir o primeiro público: instituição com um posto local ou equipa distribuída.
- [ ] Escolher plataformas da primeira entrega e volumes esperados de clientes/contratos.
- [ ] Aprovar produtos, método de juros, encargos, mora e antecipações.
- [ ] Definir funções, alçadas e requisitos reais de comité.
- [ ] Definir documentos e relatórios necessários à instituição em Moçambique.
- [ ] Escolher fornecedores de pagamentos, assinatura e mensagens, caso façam parte do escopo.
- [ ] Definir se a referência MidasCred significa equivalência funcional, aparência ou ambos.

## 19. Relação com a referência MidasCred

A referência pública consultada divulga cadastro unificado, análise de crédito, controlo financeiro, contabilidade configurável, relatórios, rastreamento de alterações e aplicação móvel com operação modo remoto e sincronização.

O SysCredi já tem cadastro aprofundado, ciclo de crédito, contabilidade e controlo financeiro local, auditoria e modo remoto. As principais lacunas funcionais face a essa descrição são **sincronização real, integrações externas e relatórios institucionais mais completos**. Não houve acesso ao código, ambiente privado ou demonstração completa do MidasCred; por isso, este documento não afirma equivalência nem reprodução fiel das suas telas.

Fontes públicas de referência, consultadas em 13/09/2026:

- [MidasCred — funcionalidades divulgadas](https://midascred.com.br/)
- [MidasCred — descrição dos processos](https://midascred.com.br/o-que-fazemos/)

## 20. Manutenção deste documento

- [x] Nesta entrega, a data foi actualizada e os itens foram reconciliados com ficheiros/testes.
- [x] Limitações conhecidas estão explicitadas e separadas dos bloqueios externos.
- [ ] Rever prioridades quando forem tomadas as decisões de produto acima.
- [ ] Separar requisitos confirmados de expansões opcionais antes de estimar prazos.

A criação deste ficheiro documenta o estado e o plano; não implementa as tarefas pendentes.

## 21. Pendentes que exigem decisão, acesso externo ou operação real

Não é tecnicamente correcto marcar estes itens como concluídos sem informação fora do repositório:

- [ ] **Fornecedor e credenciais opcionais:** apenas servidor remoto, SMS, assinatura digital ou bureau, caso sejam aprovados; integrações directas com bancos e carteiras móveis estão fora do escopo P2P.
- [ ] **Regras institucionais:** plano de contas oficial, tratamento de mora/provisão, limites de aprovação, documentos jurídicos, mapas regulamentares e política de retenção devem ser aprovados pela instituição e pelo responsável contabilístico/jurídico.
- [ ] **Reconciliação histórica:** contratos, pagamentos e saldos anteriores à contabilidade precisam de uma importação/revisão de saldos de abertura; não foi inventado um diário retroactivo.
- [ ] **Produção multi-dispositivo:** escolher Supabase, servidor próprio ou outro fornecedor; adicionar organização/agência, RLS, cursores, conflitos, sincronização de eventos e testes de dois dispositivos.
- [ ] **Web e distribuição:** escolher adaptador API remota/WASM ou arquitectura remota para web; testar Android, iOS, Windows e macOS nos dispositivos de distribuição.
- [ ] **Operação assistida:** proteger chaves de backup, agendar cópias, ensaiar restauração e definir suporte, RPO/RTO e actualizações.

Estas não são lacunas que possam ser preenchidas apenas escrevendo código genérico: activá-las sem decisões e credenciais criaria comportamentos financeiros falsos.
