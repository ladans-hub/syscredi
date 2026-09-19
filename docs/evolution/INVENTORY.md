# Inventário verificável — estado inicial

Gerado em 17/09/2026 antes das alterações estruturais. Frontend: commit `33d1473`; backend: árvore de trabalho existente, incluindo alterações anteriores do utilizador. Não contém credenciais nem dados operacionais.

## API Map atual

| Método | Rota (prefixo /v1) | Controller |
| --- | --- | --- |
| PUT | `/clients/:id` | `src/features/clients/presentation/clients.controller.ts` |
| POST | `/clients/:id/kyc` | `src/features/clients/presentation/clients.controller.ts` |
| GET | `/loans/:id/documents/:kind` | `src/features/clients/presentation/documents.controller.ts` |
| GET | `/aml-alerts` | `src/features/compliance/presentation/parity.controller.ts` |
| POST | `/aml-alerts` | `src/features/compliance/presentation/parity.controller.ts` |
| PATCH | `/aml-alerts/:id` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/field-visits` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/documents` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/reconciliations` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/organization-settings` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/subscription-history` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/client-guarantors` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/businesses` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/co-signers` | `src/features/compliance/presentation/parity.controller.ts` |
| PATCH | `/client-guarantors/:id` | `src/features/compliance/presentation/parity.controller.ts` |
| DELETE | `/client-guarantors/:id` | `src/features/compliance/presentation/parity.controller.ts` |
| POST | `/businesses` | `src/features/compliance/presentation/parity.controller.ts` |
| POST | `/co-signers` | `src/features/compliance/presentation/parity.controller.ts` |
| PATCH | `/businesses/:id` | `src/features/compliance/presentation/parity.controller.ts` |
| PATCH | `/co-signers/:id` | `src/features/compliance/presentation/parity.controller.ts` |
| DELETE | `/co-signers/:id` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/risk-scores` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/account-transfers` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/sync-operations` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/backup-archives` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/retention-policies` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/loan-adjustments` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/payment-reversals` | `src/features/compliance/presentation/parity.controller.ts` |
| GET | `/products` | `src/features/credit/presentation/credit.controller.ts` |
| GET | `/requests` | `src/features/credit/presentation/credit.controller.ts` |
| GET | `/loans` | `src/features/credit/presentation/credit.controller.ts` |
| GET | `/contracts` | `src/features/credit/presentation/credit.controller.ts` |
| GET | `/loans/:id/installments` | `src/features/credit/presentation/credit.controller.ts` |
| POST | `/products` | `src/features/credit/presentation/credit.controller.ts` |
| PATCH | `/products/:id` | `src/features/credit/presentation/credit.controller.ts` |
| POST | `/requests` | `src/features/credit/presentation/credit.controller.ts` |
| PATCH | `/requests/:id/stage` | `src/features/credit/presentation/credit.controller.ts` |
| POST | `/requests/:id/disburse` | `src/features/credit/presentation/credit.controller.ts` |
| GET | `/organizations/mine` | `src/features/organizations/presentation/organizations.controller.ts` |
| POST | `/organizations/select` | `src/features/organizations/presentation/organizations.controller.ts` |
| POST | `/organizations/members/invite` | `src/features/organizations/presentation/organizations.controller.ts` |
| POST | `/organizations/onboard` | `src/features/organizations/presentation/organizations.controller.ts` |
| POST | `/organizations/onboard-self` | `src/features/organizations/presentation/organizations.controller.ts` |
| POST | `/organizations/register` | `src/features/organizations/presentation/organizations.controller.ts` |
| GET | `/reports/portfolio` | `src/features/reports/presentation/reports.controller.ts` |
| GET | `/reports/portfolio.csv` | `src/features/reports/presentation/reports.controller.ts` |
| GET | `/reports/portfolio.pdf` | `src/features/reports/presentation/reports.controller.ts` |
| GET | `/reports/central-bank.csv` | `src/features/reports/presentation/reports.controller.ts` |
| GET | `/reports/central-bank.pdf` | `src/features/reports/presentation/reports.controller.ts` |
| GET | `/reports/audit` | `src/features/reports/presentation/reports.controller.ts` |
| POST | `/field-visits` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/documents` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/client-guarantors` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/risk-scores` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/risk-scores/calculate` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/loan-adjustments` | `src/features/shared/presentation/http/matrix.controller.ts` |
| GET | `/subscription/status` | `src/features/shared/presentation/http/matrix.controller.ts` |
| PATCH | `/sync-operations/:id` | `src/features/shared/presentation/http/matrix.controller.ts` |
| PATCH | `/backup-archives/:id` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/reconciliations` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/account-transfers` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/sync-operations/:id/reconcile` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/backup-archives/:id/restore` | `src/features/shared/presentation/http/matrix.controller.ts` |
| GET | `/organization-settings` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/organization-settings` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/subscription-history` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/sync-operations` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/backup-archives` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/retention-policies` | `src/features/shared/presentation/http/matrix.controller.ts` |
| POST | `/payments/:id/reverse` | `src/features/shared/presentation/http/matrix.controller.ts` |
| GET | `/payments` | `src/features/treasury/presentation/treasury.controller.ts` |
| GET | `/receipts` | `src/features/treasury/presentation/treasury.controller.ts` |
| GET | `/payment-accounts` | `src/features/treasury/presentation/treasury.controller.ts` |
| GET | `/accounts` | `src/features/treasury/presentation/treasury.controller.ts` |
| GET | `/cash-entries` | `src/features/treasury/presentation/treasury.controller.ts` |
| GET | `/journal` | `src/features/treasury/presentation/treasury.controller.ts` |
| GET | `/accounting-periods` | `src/features/treasury/presentation/treasury.controller.ts` |
| POST | `/accounting-periods/:month/close` | `src/features/treasury/presentation/treasury.controller.ts` |
| POST | `/accounts` | `src/features/treasury/presentation/treasury.controller.ts` |
| POST | `/payments` | `src/features/treasury/presentation/treasury.controller.ts` |
| POST | `/cash-entries` | `src/features/treasury/presentation/treasury.controller.ts` |
| GET | `/health` | `src/features/workspace/presentation/system.controller.ts` |
| GET | `/me` | `src/features/workspace/presentation/system.controller.ts` |
| GET | `/dashboard` | `src/features/workspace/presentation/system.controller.ts` |
| GET | `/audit` | `src/features/workspace/presentation/system.controller.ts` |
| GET | `/operations/:key` | `src/features/workspace/presentation/system.controller.ts` |
| POST | `/operations/:key/cancel` | `src/features/workspace/presentation/system.controller.ts` |

## Database Map atual

| Migração | Tabelas criadas |
| --- | --- |
| `001_initial.sql` | profiles, clients, products, credit_requests, accounts, loans, installments, contracts, payments, receipts, cash_entries, journal_entries, audit_events, idempotency |
| `002_runtime_security.sql` | request_limits |
| `003_parity_modules.sql` | aml_alerts, field_visits, documents, reconciliations, organization_settings, subscription_history |
| `004_complete_feature_matrix.sql` | client_guarantors, risk_scores, loan_adjustments, account_transfers, retention_policies, payment_reversals, sync_operations, backup_archives |
| `005_reconciliation_status.sql` | Alterações, políticas, índices ou constraints |
| `006_multi_tenancy.sql` | organizations, organization_members |
| `007_multi_currency.sql` | Alterações, políticas, índices ou constraints |
| `007_remote_directory.sql` | businesses, co_signers |
| `008_client_type.sql` | Alterações, políticas, índices ou constraints |
| `008_product_concurrency.sql` | Alterações, políticas, índices ou constraints |
| `009_organization_directory_access.sql` | Alterações, políticas, índices ou constraints |
| `010_guarantor_concurrency.sql` | Alterações, políticas, índices ou constraints |
| `011_onboarding_idempotency.sql` | onboarding_operations |
| `012_accounting_periods.sql` | accounting_periods |

## Entidades locais (camada de dados)

Clients, Businesses, CoSigners, CreditRequests, Loans, AuditEvents, KycReviews, Installments, Repayments, CashAccounts, Contracts, Receipts, Users, Sessions, AmlAlerts, SyncOutbox, SyncCursors, AppSettings, CreditProducts, SubscriptionHistory, CashEntries, PaymentDetails, LedgerAccounts, JournalEntries, JournalLines, ClosedPeriods, RepaymentReversals, CollectionActions, ContractSnapshots, BankStatementRows, ClientDocuments, ClientProfiles, ClientGuarantors, FieldVisits

## DTOs existentes

PageDto, ClientDto, BusinessDto, CoSignerDto, BusinessUpdateDto, CoSignerUpdateDto, UpdateClientDto, KycDto, ProductDto, ProductUpdateDto, RequestDto, DecisionDto, AccountDto, DisburseDto, PaymentDto, ProfileDto, OrganizationOnboardingDto, OrganizationRegistrationDto, OrganizationSelectDto, OrganizationMemberInviteDto, AmlDto, AmlStatusDto, FieldVisitDto, DocumentMetadataDto, GuarantorDto, GuarantorUpdateDto, RiskScoreDto, RiskCalculationDto, LoanAdjustmentDto, SyncStatusDto, SyncReconcileDto, BackupStatusDto, ReconciliationDto, TransferDto, CashEntryDto, SettingDto, SubscriptionDto, SyncOperationDto, BackupArchiveDto, RetentionDto

## Domain Map atual

| Contexto | Localização backend | Localização Flutter |
| --- | --- | --- |
| auth | `src/features/auth/` | `lib/features/auth/` |
| clients | `src/features/clients/` | `lib/features/clients/` |
| credit | `src/features/credit/` | `lib/features/credit/` |
| treasury | `src/features/treasury/` | `lib/features/treasury/` |
| accounting | `src/features/accounting/` | `lib/features/accounting/` |
| compliance | `src/features/compliance/` | `lib/features/compliance/` |
| reports | `src/features/reports/` | `lib/features/reports/` |
| organizations | `src/features/organizations/` | Distribuído em core/remote/workspace |
| workspace | `src/features/workspace/` | `lib/features/workspace/` |
| shared | `src/features/shared/` | Distribuído em core/remote/workspace |

## Navigation Map atual

Entrada → RemoteRoot → Supabase/session → PremiumRemoteHome → Home → áreas por enum Area. O RemoteWorkspace genérico existe como implementação separada; não é a raiz normal.

| Área | Label |
| --- | --- |
| accounts | Contas e transferências |
| products | Produtos de crédito |
| simulator | Simulador |
| dashboard | Visão geral |
| clients | Clientes |
| applications | Pedidos |
| portfolio | Carteira |
| collections | Cobranças |
| risk | Risco e conformidade |
| treasury | Tesouraria |
| reconciliation | Conciliação bancária |
| reports | Relatórios |
| audit | Auditoria |
| faq | Ajuda e FAQ |
| settings | Configurações |

## Superfícies de acoplamento

| Ficheiro | Linhas |
| --- | --- |
| `lib/features/remote/presentation/remote_workspace.dart` | 2130 |
| `lib/features/workspace/premium.dart` | 1668 |
| `lib/features/workspace/reference_dashboard.dart` | 1239 |
| `lib/features/workspace/domain/workspace_models.dart` | 873 |
| `lib/features/workspace/presentation/workspace_components.dart` | 832 |
| `lib/features/clients/presentation/directory_module.dart` | 813 |
| `lib/features/clients/presentation/clients_page.dart` | 741 |
| `lib/features/auth/presentation/login_page.dart` | 692 |
| `../syscredi-backend/src/features/shared/presentation/http/matrix.controller.ts` | 657 |
| `lib/core/database/app_database.dart` | 628 |
| `lib/features/clients/presentation/client_profile_page.dart` | 602 |
| `lib/features/workspace/presentation/workspace_shell.dart` | 599 |
| `lib/features/credit/application/loan_lifecycle.dart` | 588 |
| `lib/app/bootstrap/remote_root.dart` | 525 |
| `../syscredi-backend/src/features/clients/infrastructure/pdf-document-renderer.ts` | 394 |
| `lib/features/credit/presentation/applications_page.dart` | 382 |
| `lib/features/auth/data/auth_service.dart` | 380 |
| `lib/features/reports/presentation/reports_page.dart` | 379 |
| `lib/features/workspace/products_page.dart` | 370 |
| `lib/features/auth/presentation/register_page.dart` | 363 |
| `lib/features/remote/presentation/remote_form.dart` | 338 |
| `lib/features/auth/presentation/users_page.dart` | 333 |
| `lib/features/workspace/accounts_page.dart` | 324 |
| `lib/features/accounting/accounting_service.dart` | 319 |
| `lib/features/accounting/accounting_page.dart` | 318 |
