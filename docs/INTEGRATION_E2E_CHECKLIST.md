# Checklist de integração E2E — Syscredi

Estado verificado em 23 de setembro de 2026 para `syscredi` + `syscredi-backend`.

## Camadas automatizadas

- [x] Login inválido apresenta diálogo de erro Fluent, sem mensagem vermelha inline.
- [x] Recuperação de palavra-passe apresenta diálogo informativo Fluent.
- [x] Mensagens de `ApiFailure` não expõem prefixos técnicos ao utilizador.
- [x] Cliente HTTP envia `Authorization` apenas em rotas autenticadas.
- [x] Escritas enviam e preservam `Idempotency-Key` em refresh e retry.
- [x] Respostas transitórias repetem a mesma intenção no máximo duas vezes.
- [x] Conflitos `409` não são repetidos automaticamente.
- [x] Respostas `204 No Content` são aceites como sucesso.
- [x] Sessão trocada durante uma operação não adopta resposta do utilizador anterior.
- [x] Pendências são isoladas por API, ambiente e utilizador.
- [x] Suite Flutter completa executada com `flutter test`.
- [x] Backend validado por `npm run typecheck` e `npm run lint`.
- [x] API validada contra PostgreSQL descartável por `npm run test:api`.

## Fluxos E2E cobertos pelo backend

- [x] Autenticação, RBAC, validação e isolamento de schema.
- [x] Cadastros e normalização de erros de domínio.
- [x] Fluxo operador → analista → gestor.
- [x] Pedido, análise, aprovação, autorização e desembolso único.
- [x] Pagamento idempotente e pagamentos concorrentes.
- [x] Rollback de persistência financeira.
- [x] Reversão transaccional e maker-checker.
- [x] Concorrência optimista de clientes e KYC.
- [x] Empresas, co-assinantes e isolamento por instituição.
- [x] Cancelamento e consulta de operações idempotentes.
- [x] Limite de pedidos, tamanho de corpo e cabeçalhos de segurança.
- [x] Configurações institucionais e fecho contabilístico.
- [x] Revogação de acesso, transferências e integridade de foreign keys.

## Execução local

```sh
cd ../syscredi-backend
docker compose -f docker-compose.test.yml up -d postgres-test
until docker compose -f docker-compose.test.yml exec -T postgres-test pg_isready -U postgres -d syscredi_test; do sleep 1; done
npm run typecheck
npm run lint
npm run test:api

cd ../new/syscredi
flutter test
```

## Validação externa ainda necessária

- [ ] Login real no projecto Supabase de staging.
- [ ] CORS do domínio final web e renovação real de token.
- [ ] Envio real de email de recuperação.
- [ ] Upload/download de documentos no storage configurado.
- [ ] Smoke test nos binários Windows, macOS, Android e iOS.
- [ ] Teste do deployment público com `npm run verify:deployment`.

Esses itens dependem de credenciais e serviços externos; não devem ser simulados como concluídos pela suíte local.
