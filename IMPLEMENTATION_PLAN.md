> Actualização de 11/09/2026: a implementação foi adaptada para SysCredi/Moçambique e API remota. O estado actual, fluxo implementado e limites estão em [README.md](README.md). O texto abaixo preserva o planeamento anterior.

# Plano completo de implementação do SysCredi

Este plano transforma a aplicação actual num sistema simples de gestão de crédito, pronto para operação modo remoto. Não são usados dados mock no arranque: os registos aparecem apenas quando o operador os cria, restaura um backup ou sincroniza uma conta autorizada. A implementação mantém a separação `domain / data / application / presentation`.

## Estado actual

Já existem shell responsiva, dashboard, clientes, pedidos, carteira, cobranças, risco, tesouraria, relatórios, configurações, dados de demonstração e o caso de uso de pagamentos. A subscrição inclui trial de sete dias, planos Trimestral, Semestral, Anual e Vitalício, preços em MT, activação modo remoto e expiração.

Limitações actuais: os dados de negócio ainda estão em memória, as acções de configuração são demonstrativas, não existe autenticação, backend ou sincronização entre dispositivos.

## Arquitectura e regras base

- `domain`: entidades imutáveis, value objects, contratos e casos de uso;
- `data`: camada de dados/API remota, DTOs, mappers, HTTP e sincronização;
- `application`: controllers, estado de carregamento e coordenação;
- `presentation`: páginas, formulários, tabelas e navegação;
- todas as datas são UTC e dinheiro usa representação decimal/inteira segura;
- operações financeiras são transaccionais, idempotentes e auditáveis;
- nenhuma regra financeira fica dentro de um widget.

## Fase 0 — Fundação e qualidade

Configurar ambientes development/staging/production, CI com `flutter analyze`, `flutter test` e builds, lint obrigatório, logging sem dados pessoais, seeds explícitos e gestão de segredos. Definir convenções de estados, erros, referências e datas.

Aceitação: uma instalação limpa arranca sem dados inválidos; todas as falhas têm mensagem clara; não há credenciais no repositório; CI executa em cada alteração.

## Fase 1 — Integração remota

Implementar migrations camada de dados para `institutions`, `branches`, `users`, `roles`, `permissions`, `clients`, `client_documents`, `kyc_reviews`, `credit_products`, `credit_requests`, `approval_steps`, `loans`, `installments`, `repayments`, `receipts`, `cash_accounts`, `cash_movements`, `risk_assessments`, `aml_alerts`, `audit_events`, `sync_outbox`, `sync_cursors`, `app_settings` e `subscriptions`.

Substituir o repositório em memória, criar índices, transacções, seed de desenvolvimento e backup/restauração local. Aceitação: fechar e reabrir preserva tudo; uma falha a meio não deixa saldo parcial; migrations antigas são aplicadas sem perda.

## Fase 2 — Clientes e KYC

Criar, editar, arquivar e pesquisar clientes por nome, telefone, documento, referência e localização. Adicionar contactos, morada, actividade, beneficiários, documentos, validade, revisão KYC, notas, histórico e detecção de duplicados.

Regras: documento obrigatório antes do pedido; cliente arquivado não recebe crédito; documentos expirados geram alerta; alterações sensíveis geram auditoria. Aceitação: operador cria cliente, anexa documentos, submete KYC, aprova/rejeita e consulta histórico.

## Fase 3 — Produtos e pedidos

Configurar produtos, taxas, prazos, periodicidade, comissões e garantias. Implementar rascunho, checklist, cálculo de prestação, atribuição a analista/agência e estados `rascunho`, `documentação`, `análise`, `comité`, `aprovado`, `recusado`, `cancelado`.

Aplicar limites por função, KYC válido, motivo obrigatório de recusa e evento imutável em cada transição. Aceitação: pedido percorre o fluxo completo com decisão reproduzível e cálculo detalhado.

## Fase 4 — Contratos, carteira e cobranças

Emitir contrato, gerar amortização, desembolsar, controlar principal/juros/comissões/atrasos, aceitar pagamentos totais e parciais, emitir recibo, agendar cobrança e reverter com autorização. Calcular PAR, recuperação e imparidade.

Referências são únicas; pagamentos repetidos não duplicam dinheiro; reversão preserva o original; qualquer mudança de saldo fica auditada. Aceitação: dashboard, carteira, cobranças e relatórios mantêm saldos consistentes.

## Fase 5 — Tesouraria e reconciliação

Adicionar contas de caixa/banco/mobile money, entradas, saídas, transferências, ajustes, abertura/fecho, importação de extracto, reconciliação, divergências, aprovação e saldos por agência. Exportar CSV/PDF.

## Fase 6 — Risco, AML e conformidade

Implementar score configurável, matriz de risco, concentração, sobre-endividamento, listas AML, alertas, investigação, anexos e auditoria append-only com utilizador, origem, data e antes/depois. Aceitação: cada decisão mostra regras, dados, pontuação, alertas e responsável.

## Fase 7 — Relatórios

Disponibilizar carteira por produto/agência/agente, vencimentos, atrasos, PAR 1/7/30/90, desembolsos, cobranças, rendimentos, comissões, imparidade, caixa, KYC, AML e auditoria. Todos aceitam período, agência, produto, exportação e timestamp.

## Fase 8 — Utilizadores e segurança

Implementar autenticação, MFA, recuperação, sessões, RBAC/ABAC por agência/carteira, menor privilégio, encriptação de dados sensíveis, armazenamento seguro de tokens, rate limiting, lockout e auditoria de tentativas.

Aceitação: cada utilizador só vê e altera o permitido pela função; operações indevidas são rejeitadas e registadas.

## Fase 9 — Subscrições

Manter trial e planos actuais; adicionar histórico de activações, renovação, avisos antes da expiração, modo leitura após expiração e emissão de licenças no backend. Em produção, códigos devem ser assinados no servidor, com protecção contra replay e alteração do relógio.

## Fase 10 — Integrações e sincronização

Criar ports para pagamentos, SMS, email, bureau, AML, contabilidade e documentos. Implementar outbox, retries com backoff, idempotency keys, cursores, conflitos e estado de sincronização visível.

## Fase 11 — Operação e produção

Adicionar backups cifrados e restauração testada, migrações reversíveis, métricas, alertas, retenção/eliminação de dados, runbooks, suporte, builds Android/iOS/web/desktop e staging obrigatório.

## Ordem exacta de execução

1. Fundação, CI e contratos de domínio.
2. camada de dados, migrations e backup local.
3. Clientes e KYC.
4. Produtos e pedidos.
5. Contratos, carteira e pagamentos.
6. Tesouraria e reconciliação.
7. Risco, AML e auditoria.
8. Relatórios e exportações.
9. Autenticação e permissões.
10. Subscrições online e integrações.
11. Sincronização arquitetura remota.
12. Hardening, observabilidade e publicação.

## Definition of Done

Uma feature só termina quando tem UI responsiva, caso de uso testado, persistência, loading/vazio/sucesso/erro, permissões, auditoria quando aplicável, idempotência, testes unitários e widget/integrados, `flutter analyze`, `flutter test`, build no CI e documentação actualizada.

## Marcos

- **M1:** demonstração com subscrição, seed e pagamento local.
- **M2:** persistência remota e clientes/KYC.
- **M3:** ciclo de crédito até contrato e amortização.
- **M4:** cobranças, tesouraria e relatórios reconciliados.
- **M5:** risco, AML, auditoria e permissões.
- **M6:** backend, sincronização, integrações e segurança de produção.

O próximo trabalho técnico é o M2: implementar o schema camada de dados e migrar clientes, empréstimos, pedidos e pagamentos, preservando os casos de uso já existentes.
