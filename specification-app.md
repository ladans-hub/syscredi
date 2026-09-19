# SysCredi — especificação da aplicação

Documento elaborado em 17/09/2026 a partir do código e das configurações presentes neste repositório. Descreve as capacidades implementadas no aplicativo; não representa uma certificação de produção nem uma validação do servidor em execução.

## 1. Contexto geral

O **SysCredi** é uma plataforma de gestão de microcrédito orientada a instituições e equipas que operam em Moçambique. Centraliza o cadastro de clientes, a análise de pedidos, a concessão de crédito, a carteira de empréstimos, os recebimentos e o acompanhamento financeiro.

O objetivo operacional é permitir acompanhar um financiamento desde a identificação do cliente até à liquidação, mantendo documentos, prestações, movimentos financeiros e registos de auditoria associados ao processo.

A interface utiliza português e conceitos locais, como identificação documental, telefone moçambicano e metical. A configuração institucional permite escolher MT, USD, EUR ou ZAR; a existência dessas opções não implica um serviço de câmbio automático.

Os perfis definidos no código são:

| Perfil | Responsabilidade prevista nas permissões locais |
| --- | --- |
| Operador (`operator`) | Consultar e editar clientes, registar pagamentos e gerir cobranças. |
| Analista (`analyst`) | Capacidades do operador, aprovação de crédito e consulta de auditoria. |
| Gestor (`manager`) | Todas as permissões definidas, incluindo utilizadores, produtos, tesouraria, contabilidade, configurações e backups. |

No funcionamento remoto, a autorização efetiva depende também das regras aplicadas pela API.

## 2. Estado atual e modelo de funcionamento

A entrada normal da aplicação é `lib/main.dart`, que monta `SyscrediApp` e inicia `RemoteRoot`. Este fluxo configura o Supabase, restaura ou inicia a sessão, obtém o perfil e prepara o workspace autenticado.

O modelo atual combina:

1. **Supabase Auth**, para autenticação e sessão.
2. **API HTTP versionada em `/v1`**, para acesso aos dados e operações remotas.
3. **API remota com camada de dados**, para camada remota, persistência auxiliar e serviços locais existentes.
4. **Cache e fila persistente**, para recuperação de leituras e tratamento de operações remotas com resultado incerto.

A API é a fonte de verdade pretendida no fluxo normal. O API remota não seleciona um segundo modo de login. A injeção explícita de uma base em `SyscrediApp` permite exercitar o workspace local, inclusive nos testes.

O repositório conserva serviços e páginas da implementação local, além de uma implementação de workspace remoto em `features/remote/presentation`. A raiz atual apresenta `PremiumRemoteHome` e o `Home` partilhado. Assim, a presença de uma página ou serviço no código não significa que todas as suas ações estejam expostas ou integradas no percurso principal.

**Nota sobre a documentação existente:** o `README.md`, o `ARCHITECTURE.md`, o `MVP_SCOPE.md` e partes de `docs/SUPABASE.md` contêm descrições de fases anteriores. Por exemplo, a descrição de operação exclusivamente remota e o schema 11 não correspondem à composição atual nem ao schema 18 encontrado no código. Esta especificação privilegia a implementação presente.

## 3. Tecnologias

As versões abaixo são as restrições declaradas em `pubspec.yaml`; as versões resolvidas encontram-se em `pubspec.lock`.

| Tecnologia | Versão declarada | Utilização |
| --- | --- | --- |
| Dart | `^3.12.2` | Linguagem da aplicação e regras de negócio. |
| Flutter | SDK Flutter | Interface adaptativa, navegação, formulários e integração com plataformas. |
| Material e Cupertino | Incluídos no Flutter | Componentes visuais e ícones. |
| `fluent_ui` | `^4.16.1` | Tema Fluent, superfícies, indicadores e tokens de animação, em conjunto com Material. |
| `camada de dados` | `^2.34.4` | Acesso tipado a API remota, consultas, transações e migrações. |
| `supabase_flutter` | `^2.17.2` | Integração com autenticação e sessões Supabase. |
| `http` | `^1.6.0` | Transporte HTTP para a API. |
| `flutter_secure_storage` | `^11.1.1` | Armazenamento seguro de sessão, dados de cache e operações pendentes. |
| `cryptography` | `^2.9.0` | Cifragem autenticada e derivação de chaves para arquivos de backup. |
| `crypto` | `^3.0.7` | Hashes e identificação do escopo de configuração. |
| `uuid` | `^4.6.0` | Identificadores utilizados pela infraestrutura remota. |
| `pdf` | `^3.13.0` | Geração de documentos e relatórios PDF no aplicativo. |
| `file_selector` | `^1.0.3` | Seleção de ficheiros e destinos de exportação. |
| `path_provider` | `^2.1.6` | Diretórios de suporte e documentos da plataforma. |
| `shared_preferences` | `^2.5.5` | Compatibilidade com preferências e migração de dados legados. |
| `flutter_test`, `flutter_lints` | SDK / `^6.0.0` | Testes e análise estática. |
| `camada de dados_dev`, `build_runner` | `^2.34.6` / `^2.15.1` | Geração do código de persistência. |

A versão declarada da aplicação é `1.0.0+1`, com publicação no pub.dev desativada.

O backend é descrito na documentação de arquitetura como **NestJS/Supabase**, mas o seu código pertence a outro projeto. Este repositório contém o cliente e os contratos de comunicação, não a implementação do servidor.

## 4. Organização e arquitetura

```text
lib/
  main.dart                    Entrada da aplicação
  app/
    syscredi_app.dart          Aplicação, tema e composição do workspace
    bootstrap/                Construção de dependências e ligação remota
    config/                   Configuração de API e Supabase
    theme/                    Identidade visual e componentes Fluent
  core/
    database/                 Schema camada de dados e abertura de API remota
    persistence/              Preferências, snapshots e migração legada
    backup/                   Exportação, restauração e cifragem
    security/                 Identidade local
    sync/                     Outbox e abstrações de sincronização
    audit/                    Auditoria
    settings/                 Configurações
    licensing/                Licenciamento e trial locais
    csv/, money/, widgets/    Recursos partilhados
  features/
    auth/, remote/            Acesso, sessão e integração com API
    clients/                  Cadastros e perfil do cliente
    credit/                   Produtos, pedidos, contratos e pagamentos
    collections/              Acompanhamento de cobranças
    treasury/, accounting/    Movimentos, conciliação e contabilidade
    compliance/, risk/        KYC, alertas AML e score
    reports/, documents/      Exportações e documentos
    workspace/                Navegação, painel e configurações
    audit/, backup/, sync/    Interfaces operacionais auxiliares
    subscription/             Subscrição e histórico
test/                         Testes de domínio, persistência, API e interface
config/                       Configurações fornecidas por dart-define
docs/                         Documentação técnica e funcional
```

A organização é por funcionalidade, com separação entre domínio, aplicação, dados e apresentação onde essas camadas já foram extraídas. São usados contratos de repositório, casos de uso, composição explícita de dependências e resultados tipados (`AppResult`, `Success`, `Failure`).

O estado usa principalmente `ChangeNotifier`, `ValueNotifier`, `ListenableBuilder`, `AnimatedBuilder` e `setState`. O `Store` coordena os dados do workspace. Várias páginas ainda são ligadas a `syscredi_app.dart` por `part`/`part of`, portanto a separação em ficheiros não representa independência completa entre módulos.

## 5. Módulos implementados

### 5.1. Áreas do workspace principal

| Módulo | Capacidades presentes | Referências principais |
| --- | --- | --- |
| Acesso e sessão | Login, registo, recuperação de palavra-passe, restauração de sessão, carregamento de perfil e logout. | `features/auth/`, `features/remote/application/session_service.dart` |
| Visão geral | Indicadores da carteira e da operação, resumos e atalhos para áreas de trabalho, usando dados carregados pelo `Store`. | `features/workspace/reference_dashboard.dart` |
| Clientes e cadastros | Cadastro e edição de indivíduos, empresas e co-assinantes; importação CSV; perfil financeiro, avalistas, documentos e visitas de campo. | `features/clients/` |
| Produtos de crédito | Gestão de produtos, taxas, limites, prazos e estado ativo, com validações de condições. | `features/workspace/products_page.dart`, `features/credit/domain/credit_product.dart` |
| Simulador | Simulação de capital, taxa anual, prazo e encargos; plano de amortização de capital constante com juros sobre o saldo. | `features/workspace/premium.dart`, `features/credit/domain/entities/repayment_schedule.dart` |
| Pedidos | Criação e acompanhamento do pedido nas etapas documentação, análise, comité, aprovação, recusa e desembolso. | `features/credit/presentation/applications_page.dart` |
| Carteira e contratos | Consulta de empréstimos, saldo, atraso, próximas prestações, detalhe do contrato e acesso a documentos. | `features/credit/presentation/portfolio_page.dart`, `features/workspace/premium.dart` |
| Cobranças | Recebimentos parciais ou totais, acompanhamento de dívida e ações de cobrança. Existem serviços para reversão e ajustes do crédito. | `features/collections/`, `features/credit/application/` |
| Risco e conformidade | Visualização de risco, score e situação documental; serviços e repositórios para revisões KYC e alertas AML. | `features/compliance/`, `features/risk/` |
| Tesouraria | Consulta e registo de movimentos, referências e canais de recebimento/desembolso. | `features/treasury/` |
| Contas e transferências | Gestão de contas e transferências, com identificação de moeda e validações financeiras. | `features/workspace/accounts_page.dart`, `features/treasury/application/account_service.dart` |
| Relatórios | Carteira, clientes, pagamentos, créditos por estado e relatório mensal denominado Banco Central; geração/exportação CSV e PDF. | `features/reports/` |
| Auditoria | Consulta de eventos e infraestrutura para rastrear operações e alterações sensíveis. | `features/audit/`, `core/audit/` |
| Configurações | Identidade institucional, moeda, logótipo, cores, fontes, escala de texto, marca de água, assinatura, carimbo e tema. | `features/workspace/premium.dart`, `core/settings/`, `app/theme/` |
| Ajuda | Conteúdo de orientação sobre o uso do sistema. | `features/workspace/presentation/workspace_shell.dart` |

### 5.2. Capacidades adicionais presentes no código

Estas capacidades possuem implementação própria, mas a sua disponibilidade deve ser verificada no percurso de navegação e na integração usados pela instalação.

| Capacidade | Implementação e alcance |
| --- | --- |
| Contabilidade | Plano de contas, lançamentos com débito/crédito, balancete e fecho de períodos em `features/accounting/`. O workspace remoto também contém operações contabilísticas; isto não equivale a um ERP contabilístico completo. |
| Conciliação bancária | Importação CSV de extratos, procura de movimentos candidatos, associação e desassociação com motivo. Página e serviço em `features/treasury/`; não pressupõe ligação automática a bancos. |
| Utilizadores e permissões | Página de gestão, autenticação local preservada e matriz de permissões por perfil. O fluxo normal de autenticação usa Supabase. |
| Documentos | Gerador local para contrato, recibo e estado de quitação. No percurso remoto há obtenção de PDFs do servidor, incluindo contrato, confissão de dívida, garantia, recibo de desembolso e estado do crédito. |
| Backups | Exportação/restauração API remota, verificação de integridade, cópia preventiva, formatos legados e arquivo cifrado. A cópia do API remota corresponde ao conteúdo local e não substitui um backup do servidor. |
| Sincronização e pendências | Espelhamento de dados, cache, recuperação de sessão, fila de escritas, repetição idempotente e tratamento de pendências. O fornecedor genérico de backup cloud disponível em `core/sync` é `Modo remotoCloudSyncProvider`. |
| Subscrição | Trial local de sete dias, planos trimestral, semestral, anual e vitalício, ativação por código e histórico. Não foi identificado gateway de cobrança associado a esse serviço. |
| Retenção e métricas | Serviços auxiliares em `core/data_retention/` e `core/observability/`; não representam, por si só, uma plataforma externa de monitorização. |

## 6. Fluxo de negócio principal

1. O utilizador autentica-se e carrega o espaço da instituição.
2. Regista ou seleciona um cliente e completa os elementos documentais e financeiros necessários.
3. Seleciona um produto e simula as condições do financiamento.
4. Cria um pedido e acompanha documentação, análise e decisão.
5. Com o pedido aprovado, regista o desembolso e obtém contrato e plano de prestações.
6. Acompanha o empréstimo na carteira e regista recebimentos nas cobranças.
7. Consulta recibos, saldos, atrasos, movimentos, relatórios e auditoria.

O serviço local `LoanLifecycle` implementa transações para desembolso e recebimento. O desembolso verifica aprovação e identidade, gera os registos associados e impede repetição sobre o mesmo pedido. O recebimento valida montante e saldo, atualiza prestações e cria pagamento, recibo e movimento de caixa. Referências repetidas são verificadas para evitar duplicação.

Os serviços de ajuste incluem cálculo de liquidação antecipada e aplicação de encargos de atraso. As operações remotas dependem das garantias equivalentes implementadas pela API.

## 7. Dados e persistência

A base nativa é guardada como `microloan.API remota` no diretório de suporte da aplicação. O schema atual de `AppDatabase` é **18**. A abertura utiliza conexão em background e espera configurada para bloqueios curtos de escrita.

As principais famílias de dados são:

- **Cadastros:** clientes, empresas, co-assinantes, perfis financeiros, avalistas, documentos e visitas.
- **Crédito:** produtos, pedidos, empréstimos, contratos, snapshots contratuais e prestações.
- **Pagamentos:** recebimentos, recibos, detalhes de pagamento e reversões.
- **Financeiro:** contas, movimentos de caixa, linhas de extrato e ações de cobrança.
- **Contabilidade:** contas contabilísticas, lançamentos, linhas e períodos encerrados.
- **Controlo:** revisões KYC, alertas AML, utilizadores, sessões e eventos de auditoria.
- **Infraestrutura:** configurações, histórico de subscrição, outbox e cursores de sincronização.

O código mantém migrações para instalações anteriores. Preferências legadas são migradas para a persistência API remota. O motor de prestações trata distribuição em centavos e ajuste de datas de vencimento; a interface da API também utiliza campos monetários em centavos e taxas em pontos-base.

## 8. Integrações e resiliência

`RemoteRepository` define as operações de leitura, paginação, escrita, obtenção de bytes, repetição e cancelamento. O transporte HTTP e o adaptador Supabase ficam na camada de infraestrutura.

O repositório remoto confiável persiste a intenção de escrita antes do envio, associa-a ao utilizador e reutiliza a chave de idempotência nas repetições. Quando existe uma operação por confirmar, bloqueia novas intenções de escrita para evitar sobreposição. Leituras podem recorrer a respostas guardadas após falhas transitórias; uma resposta válida da API continua a ter prioridade.

A configuração valida HTTPS, permitindo HTTP apenas em endereços locais de desenvolvimento, e rejeita chaves Supabase com papel de servidor. Sessões, armazenamento PKCE e dados da fila utilizam `flutter_secure_storage`.

Os canais **caixa, transferência bancária, M-Pesa, e-Mola e mKesh** identificam a forma de uma operação registada. O código examinado não demonstra envio de dinheiro diretamente para esses operadores.

## 9. Interface e plataformas

A aplicação possui navegação lateral em ecrãs largos, adaptação para ecrãs menores e navegação inferior em dispositivos compactos. Inclui temas claro, escuro e do sistema, identidade institucional configurável, feedback de carregamento e erros com possibilidade de nova tentativa.

A interface combina Material com o tema e componentes Fluent. Estão incluídas as fontes Inter, Geist, IBM Plex Sans, Roboto, DM Sans, Manrope e Plus Jakarta Sans.

Existem diretórios de plataforma para Android, iOS, macOS, Windows e web. Contudo, o percurso principal importa `dart:io` e usa API remota nativo: a existência de `web/` não significa que o aplicativo atual esteja pronto para navegador. Esse destino exige adaptação da persistência e das dependências nativas.

A CI contém build de release para macOS. Android, iOS e Windows precisam de validação nos respetivos ambientes; nenhuma compilação foi executada para produzir este documento.

## 10. Configuração e desenvolvimento

As configurações são lidas em tempo de compilação com `String.fromEnvironment`:

| Variável | Finalidade |
| --- | --- |
| `API_BASE_URL` | Endereço da API, terminado em `/v1`. |
| `SUPABASE_URL` | Endereço do projeto Supabase. |
| `SUPABASE_PUBLISHABLE_KEY` | Chave pública do projeto; não utilizar `service_role`. |

Usar `config/app.example.json` como modelo para um ficheiro de ambiente. O comando de execução com configuração explícita é:

```sh
flutter pub get
flutter run -d macos --dart-define-from-file=config/app.json
```

Comandos de manutenção e verificação:

```sh
dart run build_runner build
flutter analyze
flutter test
flutter build macos --release --dart-define-from-file=config/app.json
```

Não é necessário gerar novamente o código camada de dados para alterações apenas documentais.

## 11. Testes existentes e limites

A pasta `test/` contém testes de ciclo de crédito, amortização, permissões, autenticação, sessões, persistência, migrações, concorrência API remota, pagamentos e reversões, KYC/AML, contabilidade, conciliação, documentos, relatórios, backups, sincronização, contratos HTTP e comportamento visual.

A configuração em `.github/workflows/ci.yml` executa instalação de dependências, geração camada de dados, análise estática e testes em Linux, além de um build macOS num job separado. A presença desses testes e jobs descreve a cobertura prevista, não o resultado de uma execução nesta revisão.

Os limites relevantes para interpretar o projeto são:

- A autenticação e o fluxo normal dependem de serviços remotos; cache e espelho não garantem operação integral sem internet.
- Serviços locais e fluxos remotos coexistem. É necessário confirmar o percurso utilizado antes de assumir que uma ação local altera dados no servidor.
- Backup cifrado está implementado com AES-GCM e derivação de chave PBKDF2; isso não implica cifragem da base API remota em uso.
- Não foi identificada integração operacional com listas AML externas, bureau de crédito, bancos ou gateways de mobile money.
- Os documentos e o relatório mensal têm implementação técnica; a sua existência não comprova aprovação jurídica ou regulamentar.
- O código do backend, as suas políticas de acesso e o seu estado em produção não foram auditados para este documento.

## 12. Fontes internas

- [Dependências e versão](pubspec.yaml)
- [Entrada e composição da aplicação](lib/app/syscredi_app.dart)
- [Inicialização remota](lib/app/bootstrap/remote_composition.dart)
- [Configuração de ambiente](lib/app/config/remote_config.dart)
- [Modelo e estado do workspace](lib/features/workspace/domain/workspace_models.dart)
- [Navegação e páginas](lib/features/workspace/presentation/workspace_shell.dart)
- [Schema API remota](lib/core/database/app_database.dart)
- [Repositório remoto confiável](lib/features/remote/application/reliable_remote_repository.dart)
- [Arquitetura atual documentada](docs/CLEAN_ARCHITECTURE.md)
- [Inventário funcional de desenvolvimento](functionality-todo.md)
- [Integração contínua](.github/workflows/ci.yml)

Os inventários e documentos de planeamento devem ser lidos em conjunto com o código, pois incluem histórico de implementação e afirmações sobre componentes externos a este repositório.
