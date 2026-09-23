# Levantamento de telas e funcionalidades — SysCredi

> Documento elaborado em 22 de setembro de 2026 a partir da UI/layout e do código de apresentação existente no projeto Flutter. A fonte principal deste inventário são os arquivos em `lib/features/**/presentation`, complementados pela documentação do repositório.

## 1. Visão geral do produto

O SysCredi é uma aplicação multiplataforma de gestão de microcrédito, orientada ao contexto moçambicano, com valores em MZN. A interface cobre o ciclo operacional desde o cadastro de clientes e a simulação até análise, aprovação, desembolso, cobrança, risco, tesouraria, relatórios, auditoria e parametrização institucional.

A aplicação apresenta três níveis visuais principais:

1. **Autenticação**: entrada, acesso de visitante e criação do primeiro utilizador.
2. **Workspace operacional**: navegação lateral, barra superior, pesquisa global, notificações e conteúdo por módulo.
3. **Administração/configuração**: definições institucionais, utilizadores, logs, backup, subscrição e módulos administrativos.

## 2. Estrutura global da interface

### 2.1 Navegação lateral

A barra lateral usa fundo em gradiente, logótipo e identidade da instituição. É organizada em entradas diretas e grupos expansíveis. A configuração institucional permite controlar largura compacta e exibição de ícones/texto.

Principais grupos visíveis:

- **Início**.
- **Crédito**: simulador, clientes, pedidos e etapas do processo de crédito.
- **Carteira e cobranças**.
- **Gestão financeira**: contas, saldos, transferências, tesouraria e conciliação.
- **Relatórios**: operacionais, financeiros e regulatórios.
- **Parametrização**: produtos de crédito e definições institucionais.
- **Gestão de logs**: auditoria.
- **Administração**: contabilidade, sincronização, AML, utilizadores e cópias de segurança.
- **Planos e subscrições**.
- **Ajuda/FAQ** no rodapé da navegação.

### 2.2 Barra superior

A barra superior reúne:

- Título da área atual.
- Botão para regressar ao início quando fora do dashboard.
- Pesquisa global.
- Acesso rápido a operações pendentes.
- Acesso rápido a pagamentos/notificações.
- Indicador de carregamento/atividade.
- Menu da conta autenticada.

### 2.3 Menu da conta

O menu de conta apresenta nome, iniciais/avatar, e-mail e perfil. Inclui:

- Visualização e edição do perfil de acesso.
- Alteração de nome, e-mail e telefone.
- Consulta da organização e função atribuída.
- Seleção de tema claro, escuro ou conforme o sistema.
- Terminar sessão.

### 2.4 Pesquisa global

A pesquisa global funciona em modal e permite:

- Pesquisar áreas/módulos do sistema.
- Pesquisar registos operacionais.
- Alternar o âmbito da pesquisa.
- Limpar o termo pesquisado.
- Abrir diretamente uma área encontrada.
- Selecionar um registo e navegar para a área correspondente.
- Exibir estado de carregamento, vazio e erro com tentativa novamente.

### 2.5 Comportamento adaptativo

A UI foi construída para desktop, web e dispositivos móveis:

- Sidebar fixa em larguras maiores e navegação adaptada em telas estreitas.
- Cartões e formulários reorganizam-se por `Wrap`, colunas e rolagem.
- Tabelas extensas usam rolagem horizontal.
- Diálogos limitam a largura e permitem rolagem vertical.
- A aparência suporta modo claro/escuro e identidade visual configurável.

### 2.6 Estados transversais

As telas reutilizam padrões para:

- Carregamento.
- Erro com ação “Tentar novamente”.
- Estado vazio.
- Confirmação antes de operações sensíveis.
- Feedback de sucesso e falha.
- Paginação.
- Pesquisa, filtros e ordenação.
- Operações pendentes que podem ser consultadas, reenviadas ou canceladas.
- Controle por perfil, com ações administrativas reservadas a gestores.

## 3. Mapa de telas e rotas

| Área visual | Rotas internas associadas | Finalidade |
|---|---|---|
| Autenticação | entrada inicial | Aceder, visitar ou criar primeiro utilizador |
| Início | `dashboard` | Resumo executivo e atalhos operacionais |
| Simulador | `simulator` | Calcular crédito e plano de prestações |
| Produtos de crédito | `products` | Configurar ofertas, taxas, limites e regras |
| Clientes | `clients`, `businesses`, `client-guarantors`, `co-signers` | Gerir indivíduos, empresas, avalistas e co-assinantes |
| Pedidos de crédito | `requests` | Registar e acompanhar solicitações |
| Financiamento | `financing` | Formalizar proposta e condições de financiamento |
| Análise financeira | `financial-analysis` | Avaliar capacidade e indicadores financeiros |
| Aprovação | `credit-approval` | Registar decisão de aprovação/recusa |
| Autorização | `credit-authorization` | Autorizar crédito aprovado |
| Desembolso | `credit-disbursement` | Registar libertação do crédito |
| Estado do crédito | `credit-status` | Consultar situação e histórico do crédito |
| Reestruturação | `credit-restructuring` | Reagendar ou reestruturar crédito |
| Carteira | `credit-portfolio`, `loans`, `contracts`, `portfolio` | Consultar contratos e saldos |
| Cobranças | `collections`, `payments`, `receipts` | Receber pagamentos e consultar recibos |
| Central de risco | `risk-scores`, `aml-alerts`, `field-visits`, `documents` | Avaliar risco e sinais de alerta |
| Gestão financeira | rotas `finance-*`, `accounts`, `account-transfers` | Saldos, movimentos e transferências |
| Tesouraria | `cash-entries`, `reconciliations`, `journal` | Caixa, conciliação e diário |
| Relatórios | `reports`, rotas `report-*` | Relatórios de crédito, clientes e finanças |
| Auditoria | `audit` | Consultar logs e detalhes de eventos |
| Operações pendentes | `pending` | Confirmar, reenviar ou cancelar operações |
| Períodos contabilísticos | `accounting-periods` | Encerrar e consultar períodos |
| Administração | rotas `admin-*` | Contabilidade, sincronização, AML, utilizadores e backup |
| Planos | `plans` | Consultar e ativar subscrições |
| Definições | `settings`, `organization-settings` | Parametrizar instituição e aparência |
| FAQ | modal de ajuda | Consultar orientação de uso |

## 4. Telas e funcionalidades detalhadas

## 4.1 Autenticação

### Tela de login

Elementos e ações:

- Campo de e-mail/utilizador.
- Campo de palavra-passe com alternância de visibilidade.
- Opção para manter sessão/recordar acesso quando aplicável.
- Botão **Entrar**, com estado “A validar…”.
- Link **Esqueci a palavra-passe**.
- Botão **Explorar como visitante**.
- Botão **Criar primeiro utilizador**.
- Mensagens de erro e validação.
- Painel visual com imagem de fundo, marca e proposta do produto.

### Criação do primeiro utilizador

Abre diálogo com formulário inicial e permite:

- Registar os dados do primeiro administrador.
- Validar campos obrigatórios.
- Cancelar ou criar utilizador.
- Apresentar feedback de sucesso/falha.

### Observação de execução

Por padrão, a documentação do projeto informa que a camada de dados está desativada e a aplicação abre somente a autenticação. O botão Entrar e a criação do primeiro utilizador continuam ligados ao Supabase; o restante do workspace usa dados mockados ou demonstrativos conforme o módulo. A integração completa pode ser ativada com `DATA_LAYER_ENABLED=true`.

## 4.2 Início / Dashboard

O dashboard oferece visão resumida da operação:

- Cartões de indicadores, incluindo clientes ativos, pedidos pendentes, saldo em dívida e montante vencido.
- Cartões clicáveis que encaminham para a área correspondente.
- Evolução da carteira em gráfico histórico.
- Distribuição dos pedidos em gráfico circular.
- Seleção do período histórico, com opções de 3, 6 ou 12 meses.
- Tabela/lista de pedidos recentes.
- Tabela/lista de prestações ou vencimentos próximos.
- Cartão promocional/fotográfico relacionado ao empreendedorismo.
- Atalhos para ações frequentes.
- Estados vazios quando a instalação ainda não possui dados.

## 4.3 Simulador de crédito

A tela permite montar uma simulação e visualizar o custo do financiamento.

Campos/controles observados:

- Produto de crédito.
- Capital/montante solicitado.
- Taxa de juros.
- Periodicidade da taxa.
- Prazo.
- Frequência de pagamento.
- Método de juros, incluindo flat e saldo decrescente.
- Data da operação.
- Encargos/comissões aplicáveis.
- Opções relacionadas a carência conforme produto.

Resultados:

- Resumo do capital, juros, encargos, total e prestação.
- Tabela de amortização com número, vencimento, prestação, capital, juros e saldo.
- Recálculo imediato ao alterar parâmetros.
- Validação de limites e campos numéricos.
- Apresentação responsiva do resumo e da tabela.

## 4.4 Produtos de crédito

Tela de catálogo e parametrização de produtos.

### Lista

- Pesquisa por produto, código ou tipo.
- Filtros por estado: todos, ativos, inativos e rascunhos.
- Ordenação.
- Colunas para produto, tipo, limites, juros, prazo, pagamento, estado e ações.
- Ações **Ver**, **Editar**, **Simular** e **Ativar/desativar**.
- Botão **Novo produto**.

### Criação/edição

O formulário é dividido logicamente em:

- Identificação e descrição.
- Nome e código único.
- Tipo de crédito.
- Descrição comercial.
- Moeda.
- Montante mínimo e máximo.
- Taxa e periodicidade.
- Método de cálculo dos juros.
- Prazo mínimo e máximo.
- Frequência de pagamento.
- Carência.
- Comissões e taxas.
- Garantias e avalistas exigidos.
- Critérios de elegibilidade.
- Documentos obrigatórios.
- Liquidação antecipada.
- Multas e regras de mora.
- Regras de aprovação e incumprimento.
- Estado do produto.

O utilizador pode guardar o produto, cancelar e receber confirmação visual.

## 4.5 Clientes

A área separa quatro categorias: **Indivíduos**, **Empresas**, **Avalistas** e **Co-assinantes**.

### Funcionalidades comuns

- Criar novo registo.
- Pesquisar por nome, documento e outros identificadores.
- Paginar resultados.
- Consultar detalhes.
- Editar registos existentes.
- Inativar/remover conforme permissão e estado.
- Mostrar situação do cliente com badge.
- Mostrar estado KYC como verificado, em revisão ou expirado.
- Relacionar cliente com pedidos, contratos e outros intervenientes.

### Indivíduos

O cadastro suporta dados de:

- Identificação pessoal.
- Contactos.
- Documento de identificação.
- Morada/localização.
- Atividade/profissão.
- Informação económica básica.
- Estado e validade KYC.

A tela possui **importação de indivíduos por CSV**, com confirmação, processamento e feedback do resultado.

### Empresas

O cadastro empresarial diferencia nome legal/comercial e dados institucionais, mantendo ações equivalentes às de clientes individuais.

### Avalistas e co-assinantes

Permitem cadastrar e consultar intervenientes ligados ao crédito, com formulários e tabelas próprios dentro da área de clientes.

## 4.6 Pedidos e ciclo de crédito

O ciclo é apresentado como uma sequência de telas especializadas. Em todas elas há pesquisa, filtros por estado, tabela/lista de casos, indicadores de conclusão, detalhes do processo e ações da etapa.

### Pedidos de crédito

- Criar pedido associado a cliente e produto.
- Informar montante, prazo e finalidade.
- Consultar fase/estado atual.
- Abrir detalhe do pedido.
- Acompanhar documentos e pendências.
- Filtrar pedidos por fase.
- Avançar no fluxo conforme validações.

### Financiamento

- Definir ou rever valor financiado.
- Definir prazo, taxa, prestação e condições.
- Registar garantias e documentação.
- Comparar condições propostas.
- Guardar a etapa e encaminhar para análise.

### Análise financeira

- Registar rendimentos e despesas.
- Avaliar capacidade de pagamento.
- Consultar indicadores e taxa de esforço.
- Registar observações da análise.
- Assinalar documentação/validações pendentes.
- Concluir a análise para decisão posterior.

### Aprovação de crédito

- Consultar resumo do pedido e da análise.
- Aprovar ou recusar.
- Exigir motivo em decisões negativas.
- Associar a decisão ao utilizador autenticado.
- Manter histórico auditável.

### Autorização de crédito

- Rever crédito previamente aprovado.
- Confirmar autorização administrativa.
- Registar decisão, observação e responsável.
- Impedir avanço quando requisitos anteriores não estejam completos.

### Desembolso

- Selecionar pedido autorizado.
- Informar data, canal/meio e referência.
- Confirmar montante e encargos.
- Validar limites do produto.
- Registar desembolso.
- Gerar contrato, plano de prestações e movimento financeiro quando a camada de dados está ativa.
- Exibir confirmação ou erro da operação.

### Estado do crédito

- Consultar estágio atual.
- Visualizar progresso/completude.
- Consultar dados do cliente, montante, prazo e prestação.
- Abrir detalhes e histórico das decisões.
- Ver pendências e alertas associados.

### Reestruturação do crédito

- Selecionar contrato/prestações elegíveis.
- Informar motivo da reestruturação.
- Definir nova data/plano para prestações pendentes.
- Comparar prestação atual e proposta.
- Confirmar a alteração com registo auditável.
- Preservar montantes e pagamentos anteriores conforme a regra documentada.

## 4.7 Carteira de crédito

A tela apresenta contratos/créditos ativos e históricos.

- Pesquisa por cliente ou contrato.
- Filtro por estado.
- Indicadores resumidos da carteira.
- Tabela de contratos com capital, saldo, prestação, vencimento e estado.
- Visualização de detalhes do contrato.
- Consulta do plano de prestações.
- Consulta de saldo em aberto e atraso.
- Identificação visual de contratos regulares, vencidos ou concluídos.
- Acesso ao recebimento/cobrança quando aplicável.

## 4.8 Cobranças, pagamentos e recibos

- Listar prestações e pagamentos.
- Pesquisar cliente ou contrato.
- Filtrar por estado e vencimento.
- Registar pagamento parcial ou total.
- Selecionar canal/meio de pagamento.
- Registar referência externa e identificador do meio.
- Tratar m-Pesa, eMola, mKesh, Millennium BIM e BCI.
- Solicitar número de conta para BIM e NIB para BCI.
- Validar presença/formato numérico localmente.
- Consultar detalhe do pagamento.
- Gerar/consultar recibo.
- Copiar conteúdo do recibo.
- Exportar pagamentos em CSV.
- Solicitar estorno quando permitido, com confirmação e auditoria.

A interface esclarece que esses meios representam registos de movimentos já realizados; não são integrações que transferem dinheiro.

## 4.9 Central de risco

Tela de avaliação de risco com:

- Cartões de indicadores/resumo.
- Pesquisa e filtros.
- Classificação por nível de risco.
- Capital em aberto.
- Dias/nível de atraso.
- Sinais de alerta.
- Ação **Ver análise de risco**.
- Paginação interna e paginação da fonte remota.
- Estado de carregamento e tentativa novamente em caso de falha.

O agrupamento de risco também expõe entradas para alertas AML, visitas de campo e documentos, direcionadas à mesma área operacional ou às rotas correspondentes.

## 4.10 Gestão financeira

As rotas `finance-*` reutilizam uma tela configurável para várias áreas financeiras.

Submódulos identificados pela navegação:

- Saldos.
- Desembolsos.
- Reembolsos.
- Receitas.
- Despesas.
- Prestações vencidas.
- Ativos.
- Contas e transferências internas.

Funcionalidades comuns:

- Cartões de totais.
- Pesquisa e filtros.
- Tabelas de movimentos.
- Registo de nova operação.
- Campos de montante, conta, data, categoria, canal, referência e descrição conforme o submódulo.
- Confirmação e feedback.
- Validação de saldo em transferências internas.
- Transferência com origem e destino distintos.
- Registo transacional das duas entradas da transferência.
- Receitas/despesas com canal selecionado.

## 4.11 Tesouraria e conciliação

A navegação inclui:

- Movimentos de caixa.
- Conciliação bancária.
- Diário/journal.
- Contas e saldos.

Operações observadas:

- Consultar entradas e saídas.
- Registar movimentos.
- Pesquisar e filtrar.
- Conciliar registos financeiros.
- Consultar referências, datas, contas, canais e montantes.
- Ver saldos por conta.
- Navegar entre páginas de dados.

## 4.12 Relatórios

A interface possui uma tela genérica configurada pelo tipo de relatório.

Categorias de navegação:

- Créditos.
- Clientes.
- Financeiros.
- Diversos.
- Registos.
- Cartas.
- Relatório mensal para o Banco de Moçambique.
- Relatório trimestral para o Banco de Moçambique.
- Saídas em PDF e Excel/CSV.

Funcionalidades:

- Selecionar tipo de relatório.
- Definir intervalo/período e filtros.
- Pré-visualizar dados tabulares.
- Gerar CSV.
- Gerar PDF.
- Guardar/baixar o relatório conforme a plataforma.
- Apresentar confirmação de geração ou mensagem de falha.
- Lidar com estado vazio quando não há dados.

## 4.13 Auditoria / Gestão de logs

- Título e contexto de gestão de logs.
- Pesquisa por utilizador, ação, registo ou descrição.
- Filtro por tabela/módulo.
- Seleção de quantidade de registos por página.
- Tabela de eventos.
- Paginação anterior/seguinte.
- Ação para abrir detalhes do evento.
- Modal com utilizador, ação, tabela, data, identificador e conteúdo associado.
- Paginação adicional em blocos de 50 quando os dados vêm da API.

## 4.14 Operações pendentes

Tela para operações cuja confirmação remota não foi concluída:

- Listar operação, referência e montante.
- Consultar ou reenviar a operação.
- Cancelar apenas após verificação de que ainda não foi executada.
- Exigir confirmação antes do cancelamento.
- Apresentar feedback de cancelamento ou falha.
- Estado vazio “Nenhuma operação por confirmar”.

## 4.15 Períodos contabilísticos

- Botão **Encerrar período**.
- Diálogo de confirmação para encerramento contabilístico.
- Registo/lista de períodos encerrados.
- Estado vazio quando não existe encerramento.
- Restrição de operações por período, conforme parametrização institucional.

## 4.16 Módulos administrativos rápidos

As rotas administrativas usam uma tela de cartões/opções por tipo:

- **Contabilidade**.
- **Sincronização**.
- **Alertas AML**.
- **Gerir utilizadores**.
- **Cópias de segurança**.

Essas áreas funcionam como centros administrativos e atalhos para ações relacionadas. Algumas ações são demonstrativas ou redirecionam para as definições institucionais e telas especializadas.

## 4.17 Planos e subscrições

- Exibir plano atual.
- Comparar cartões de planos e recursos incluídos.
- Selecionar plano.
- Informar código de ativação UUID.
- Confirmar ativação em diálogo.
- Copiar ID do dispositivo.
- Exibir feedback de código ausente, recebido e plano ativado.
- Destacar visualmente o plano atual.

## 4.18 Definições institucionais

A área de definições possui navegação própria, pesquisa e rascunho de alterações.

### Operação geral

- Pesquisar configurações.
- Filtrar categorias.
- Editar campos simples, seletores, listas e estruturas.
- Indicar alterações não guardadas.
- Rever alterações antes de aplicar.
- Guardar, guardar e sair, continuar a editar ou descartar.
- Confirmar alterações críticas.
- Validar campos obrigatórios.
- Restringir edição a gestores; outros perfis podem consultar.
- Guardar algumas preferências de navegação automaticamente.

### Categorias identificadas

#### Instituição e identidade

- Nome legal e nome comercial.
- Tipo de instituição.
- NU/NUIT, licença e dados institucionais.
- Fundação, website, e-mail e telefone.
- Endereço, província, cidade, bairro e código postal.
- Biografia/descrição institucional.

#### Aparência e identidade visual

- Tema e paleta primária/secundária.
- Família tipográfica e escala da fonte.
- Densidade, raio dos componentes e tabelas listradas.
- Sidebar compacta.
- Exibição de ícones e texto de navegação.
- Logótipo e imagens institucionais.
- Restaurar padrão Fluent 2.

#### Regionalização

- Idioma.
- Fuso horário.
- Formato de data.
- Separador decimal, casas decimais e arredondamento.
- Moeda de crédito.
- Prefixo telefónico.
- Primeiro dia da semana, feriados e dias úteis.

#### Crédito

- Montante mínimo e máximo.
- Taxa de juros e método.
- Frequência e regras de vencimento.
- Taxas de preparação, desembolso e selo.
- Carência, tolerância e multa por atraso.
- Liquidação antecipada, refinanciamento e reestruturação.
- Garantias, avalistas, documentos obrigatórios e contrato assinado.
- Regras de elegibilidade e idade mínima.
- Estados do crédito e fluxo de aprovação.
- Autoaprovação, duplo controlo, limites e escalonamento.

#### Finanças e contas

- Contas institucionais.
- Categorias de receitas/despesas.
- Centros de custo.
- Meios de pagamento.
- Fecho diário e encerramento de período.
- Aprovação de estorno e motivo obrigatório.
- Bloqueio de períodos encerrados.

#### Numeração e sequências

- Prefixos.
- Quantidade de dígitos.
- Inclusão de ano e agência.
- Próximo número.
- Reinício de sequência.
- Edição por tipo de documento.

#### Utilizadores, perfis e permissões

- Listar utilizadores.
- Criar novo utilizador.
- Editar identidade, agência, função e acesso.
- Escolher fotografia.
- Ativar, desativar, bloquear/desbloquear e redefinir acesso conforme ações disponíveis.
- Consultar detalhe e histórico do utilizador.
- Criar perfil personalizado.
- Gerir perfis e permissões.
- Revogar sessões.

#### Segurança e sessões

- Duração da sessão e bloqueio por inatividade.
- Tentativas de login.
- Expiração e requisitos da palavra-passe.
- Maiúsculas, números e símbolos.
- Forçar palavra-passe inicial.
- Autenticação de dois fatores.
- Reautenticação para ações sensíveis.
- Retenção de sessões/logs.

#### Agências

- Criar, editar e remover agências.
- Código, nome, localização e responsável.
- Associação de utilizadores e numeração quando aplicável.

#### Signatários

- Nome, função/cargo e dados de assinatura.
- Gestão de signatários usados em documentos.

#### Documentos e templates

- Cabeçalho, rodapé, notas e texto legal.
- Local de emissão e campos de documento.
- Marca de água, posição, tamanho e opacidade.
- Imagens/logótipo.
- Pré-visualização de documentos.
- Exportação da pré-visualização.
- Templates para contrato e outros documentos.

#### Mensagens e notificações

- Modelos por evento.
- Edição da mensagem.
- Pré-visualização/teste com variáveis renderizadas.
- SMS, e-mail e notificações internas.
- Remetente, e-mail de resposta e período silencioso.
- Lembretes e escalonamentos.

#### Integrações

- Configurações de canais e serviços externos.
- Estado, último teste e ação para simular teste.
- Desativação de integração.
- Parâmetros de conexão representados no formulário.

#### Backup, exportação e restauração

- Criar backup local.
- Exportar definições.
- Importar/restaurar arquivo JSON.
- Validar e aplicar o conteúdo ao rascunho/configuração.

#### Auditoria de configurações

- Lista de alterações.
- Consulta de detalhe.
- Campos alterados e valores relacionados.
- Módulo, identificador e evento.

## 4.19 FAQ / Guia rápido

O centro de ajuda é exibido em diálogo e inclui:

- Pesquisa por dúvida.
- Filtro por categoria.
- Perguntas expansíveis.
- Respostas práticas sobre uso do sistema.
- Ação para mostrar todas as perguntas.
- Limpeza da pesquisa.
- Fechar o diálogo.

## 5. Padrões de tabela e formulário

### Tabelas

- Cabeçalhos em destaque e ações na última coluna.
- Limite visual de colunas prioritárias em telas genéricas.
- Rolagem horizontal em telas estreitas.
- Badges de estado.
- Botões de ação com tooltip.
- Paginação de 50 registos nas áreas genéricas/remotas.

### Formulários

- Labels visíveis e indicações de obrigatoriedade.
- Máscaras/validação para números, datas e valores monetários.
- Comboboxes para estados e categorias.
- Seletores de data.
- Formulários modais para cadastros rápidos.
- Confirmação para decisões sensíveis.
- Rascunho em configurações antes da gravação definitiva.

## 6. Regras e fluxos de negócio evidenciados pela UI

- O processo de crédito é sequencial: pedido → financiamento/documentação → análise → aprovação → autorização → desembolso → carteira/cobrança.
- Recusas exigem motivo.
- Decisões ficam associadas ao utilizador autenticado e ao histórico de auditoria.
- Desembolso depende de aprovação/autorização e respeita limites do produto.
- Pagamentos podem ser parciais ou totais.
- Estornos e ações críticas exigem confirmação/permissão.
- Reestruturação atua sobre prestações pendentes e exige motivo.
- Transferências internas validam saldo e geram duas entradas transacionais.
- Períodos contabilísticos podem bloquear alterações após encerramento.
- Configurações sensíveis são restritas a gestores.
- A instalação pode iniciar sem dados; a UI prevê estados vazios em todas as áreas relevantes.

## 7. Dependências e nível de implementação observado

### Funcionalidades claramente implementadas na UI

- Navegação completa entre módulos.
- Formulários, filtros, pesquisa, tabelas, paginação e diálogos.
- Simulador e tabela de amortização.
- Catálogo e editor de produtos.
- Telas do ciclo de crédito.
- Carteira, cobranças, risco, relatórios e auditoria.
- Configuração institucional extensa.
- Temas, branding, FAQ e planos.
- Feedback e tratamento visual de erro/vazio/carregamento.

### Funcionalidades dependentes da camada remota

- Autenticação real.
- Persistência centralizada dos cadastros.
- Pedidos, contratos, desembolsos e pagamentos reais.
- Métricas reais do dashboard.
- Auditoria persistida.
- Geração definitiva de documentos e movimentos financeiros.
- Sincronização e confirmação de operações pendentes.

### Funcionalidades demonstrativas ou locais em parte da UI

- Diversos módulos usam dados mockados/demonstração quando a camada de dados está desativada.
- Algumas telas administrativas são centros de opções/representações visuais, e não fluxos completos isolados.
- Integrações financeiras exibidas são registos operacionais, não conectores que movimentam dinheiro.
- Validações bancárias verificam formato/presença, não titularidade ou validade externa da conta.

## 8. Inventário resumido de telas

Considerando telas principais, variações por categoria/etapa e modais funcionais, a UI contém:

- 1 tela de autenticação com 1 diálogo de criação inicial.
- 1 workspace/base responsivo.
- 1 dashboard.
- 1 simulador.
- 1 catálogo de produtos com visualização e editor.
- 4 variações de clientes.
- 7 telas do processo de crédito: pedidos, financiamento, análise, aprovação, autorização, desembolso, estado/reestruturação — com estado e reestruturação apresentados como áreas próprias.
- 1 carteira.
- 1 cobranças/pagamentos/recibos.
- 1 central de risco.
- Múltiplas variações da tela financeira.
- Múltiplos tipos de relatórios.
- 1 auditoria.
- 1 operações pendentes.
- 1 períodos contabilísticos.
- 5 variações administrativas.
- 1 planos e subscrições.
- 1 área de definições com dezenas de painéis e editores especializados.
- 1 pesquisa global.
- 1 centro de ajuda/FAQ.
- Modais auxiliares para perfil, detalhes, confirmações, importação, recibos, documentos, utilizadores, mensagens, auditoria e operações financeiras.

## 9. Arquivos de referência usados no levantamento

- `lib/features/auth/presentation/login_page.dart`
- `lib/features/api/presentation/navigation.dart`
- `lib/features/api/presentation/workspace.dart`
- `lib/features/api/presentation/simulator_panel.dart`
- `lib/features/api/presentation/credit_products.dart`
- `lib/features/api/presentation/credit_stages.dart`
- `lib/features/api/presentation/portfolio_views.dart`
- `lib/features/api/presentation/finance_views.dart`
- `lib/features/api/presentation/report_views.dart`
- `lib/features/api/presentation/risk_center_view.dart`
- `lib/features/api/presentation/audit_logs_view.dart`
- `lib/features/api/presentation/search_dialog.dart`
- `lib/features/api/presentation/faq_dialog.dart`
- `lib/features/api/presentation/plans_view.dart`
- `lib/features/api/presentation/admin_views.dart`
- `lib/features/settings/domain/settings_schema.dart`
- `lib/features/settings/presentation/institution_settings_view.dart`
- `lib/features/settings/presentation/settings_panels.dart`
- `lib/features/settings/presentation/settings_editors.dart`
- `docs/INTERFACE.md`
- `README.md`
