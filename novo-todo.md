# SysCredi — estado e execução

Este ficheiro é a fonte de acompanhamento da evolução do produto. Cada item deve permanecer verificável por código, migration, teste ou documentação.

## Implementado

- [x] Inventário arquitectural, mapa de domínio, API, base de dados e navegação.
- [x] `specification-app.md` e análise de gaps.
- [x] Flutter com cards arredondados e cores institucionais restauradas.
- [x] Design tokens e componentes visuais existentes preservados.
- [x] Cache/outbox/sincronização local e estados de erro no arranque.
- [x] Backend NestJS modular com `CommandExecutor`, `UnitOfWork` e autorização.
- [x] Minor units para dinheiro e motor determinístico de calendário existente.
- [x] Validação de moeda em pagamentos, desembolsos e transferências.
- [x] Transferências e movimentos de caixa como comandos idempotentes.
- [x] Posting rules centralizadas e reversíveis.
- [x] Tenant isolation, FKs compostas e organização imutável.
- [x] `payment_allocations` com principal e juros por prestação.
- [x] Reversão de pagamento como comando idempotente, auditável e compensatório.
- [x] Snapshot dos termos do produto na originação.
- [x] Histórico de estados de pedidos e endpoint de timeline.
- [x] Planos de prestações versionados sem apagar histórico.
- [x] Dashboard com métricas por moeda, `as_of`, versão e PAR.
- [x] Testes de domínio, aplicação, Flutter e análise estática base.

## P0 — correcção e segurança

- [x] Approval workflow persistente completo com maker-checker e autoridade por montante (tabelas `approval_policies`/`approval_requests`, API de políticas, decisões persistentes, maker-checker, regra por montante e enforcement de múltiplos aprovadores implementados).
- [x] Migrar alocações históricas de pagamentos ou bloquear explicitamente casos ambíguos com relatório (`migration 036`, fila `payment_allocation_exceptions` e reversão protegida).
- [x] Backfill de snapshots para pedidos legados sem fotografia (`migration 018`).
- [x] Testes de integração PostgreSQL para reversão/liquidação, tenant e concorrência (suíte `test:api` cobre reversão transaccional idempotente, concorrência de desembolso/pagamentos, isolamento por instituição e constraints multi-tenant; 19/19 testes aprovados).
- [x] Rever todas as queries para garantir `organization_id` e filtros de planos activos (queries de apresentação auditadas, RLS/contexto tenant documentado em `docs/QUERY-TENANCY.md`, agregações cross-tenant corrigidas e leitura histórica de produtos preservada por snapshot).
- [x] Corrigir configuração da base local de testes e executar a suíte API completa (`.env.test.example`, `docker-compose.test.yml`, `test:api` e `docs/TESTING.md`; 18/18 testes aprovados).

## P1 — operação central

- [x] Versões de produtos, tarifas, multas, carência e regras de elegibilidade (versionamento via `migration 037`, endpoint `/v1/products/:id/versions`, `validateProductRules` e `evaluateEligibility` determinísticos implementados).
- [x] Customer 360 com finanças, documentos, referências, relacionamentos e timeline (endpoint `/v1/clients/:id/360` agrega créditos, pagamentos, documentos, referências, avalistas, risco e timeline; acção Customer 360 adicionada ao workspace remoto).
- [x] Loan 360 com schedule, pagamentos, documentos, garantias, cobranças e contabilidade (endpoint `/v1/loans/:id/360` agrega as secções e timeline; acção Loan 360 adicionada ao workspace remoto com estados de erro).
- [x] Componentes de dívida separados: principal, juros, taxas, multas e waivers (tabela `loan_charges`, posting contabilístico específico e comando idempotente de alocação por prestação em `POST /v1/loans/:id/charges/:chargeId/allocate`).
- [x] Collections completo com DPD, PAR30/60/90, filas, promessas e tarefas (fila, métricas DPD/PAR, acções de contacto, promessas, tarefas e UI de cobranças disponíveis nos endpoints e workspace).
- [x] Liquidação antecipada, excesso, write-off e reversão com aprovação (settlement com desconto, write-off, reversão compensatória, créditos por excesso de pagamento e maker-checker que impede o criador de reverter a própria resolução; coberto por integração PostgreSQL).
- [x] Tabelas server-side com filtros, ordenação, paginação e exportação (API aceita `q`, `limit`, `offset`, `sort` e `direction`; workspace Flutter expõe pesquisa/ordenação/paginação e relatórios CSV/PDF).
- [x] Dashboard operacional com Action Center e drill-down (KPIs remotos/versionados, centro de acções com cobranças, pedidos e vencimentos, e navegação contextual para cada fila).
- [x] Flutter modularizado por feature e carregamento remoto paginado (features separadas em `lib/features/*`, `RemoteRepository.page`, sincronização incremental e tabelas com offset server-side).
- [x] Erros seguros, correlation IDs, freshness e cancelamento de pedidos (filtro HTTP normaliza erros, `x-request-id`, refresh de workspace e cancelamento idempotente de operações pendentes).
- [x] Documentos baseados no snapshot jurídico do crédito, com versionamento de metadados por cliente/tipo (`migration 022`) e renderers que usam o snapshot do contrato.

## P2 — sofisticação

- [x] Score explicável/versionado, affordability e risk override (score, affordability, modelos versionados, `POST/GET /v1/risk-models`, factores padrão e `custom.*` validados/aplicados deterministicamente, override e aprovação condicionada implementados).
- [x] KYC/AML cases, PEP, sanções e providers substituíveis (migration `039`, casos e screenings PEP/sanções, comandos idempotentes, interfaces de providers e filas remotas KYC/AML no Flutter implementados).
- [x] Collateral, avaliações, LTV, inspeções, liberação e execução (migrations `044`/`045`, cadastro tenant-safe, avaliações, LTV, inspeções, estados de liberação/execução, auditoria e fila Flutter implementados).
- [x] Reconciliação com importação, normalização, matching e diferenças: normalização, deduplicação, persistência, importação, consulta, matching automático, revisão manual, estados de diferença, confidence score, auditoria e UI local implementados.
- [x] Relatórios e analytics com KPIs documentados e drill-down (definições em `docs/evolution/ARCHITECTURE_PRODUCT_GAP_ANALYSIS.md`, relatórios CSV/PDF e endpoint protegido `/v1/reports/portfolio/:loanId`).
- [x] Filiais, equipas e permissões contextuais (branches tenant-safe, associação de utilizadores/equipas, filtros de carteira por `branchId`/`teamId` e enforcement por função/filial/equipa implementados; limites de aprovação continuam no workflow de montante).
- [x] Tasks, notificações internas e transactional outbox (tarefas, notificações, estados, inbox, outbox transaccional, retries idempotentes, monitorização via API e consumidor interno periódico com `SKIP LOCKED` implementados; providers externos permanecem desacoplados por design).
- [x] Observabilidade com logs estruturados, métricas e jobs monitorizados (middleware com `X-Request-Id`, duração/status, logs JSON opt-in, endpoint protegido `/v1/metrics` e fila outbox monitorizável).

## P3 — expansão

- [ ] Grupos, crédito solidário, revolving, linhas, agrícola e sazonal.
- [ ] Providers reais de bancos, mobile money, bureau, AML, SMS e WhatsApp.
- [x] Captura mobile de documentos, fotografias e visitas (selector multiplataforma para PDF/JPG/PNG com limite de 10 MB, persistência remota/modo remoto, auditoria e registo de visitas com notas, resultado e próxima visita).
- [x] Internacionalização completa e moedas adicionais (localização institucional `pt_MZ`/`pt_PT`/`en_US`, delegates Flutter, suporte MZN/USD/EUR/ZAR e documentação em `docs/LOCALIZATION.md`).
- [x] Feature flags, command palette e atalhos de desktop (feature flags persistentes/API e pesquisa global já existentes; comando Ctrl/Cmd+K abre a paleta de pesquisa no dashboard).

## Critério de conclusão

Um item só passa a concluído quando possui implementação, migração compatível quando necessária, autorização, validação, auditoria, estados de UI, testes e documentação.
