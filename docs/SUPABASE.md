# Migração para Supabase

O aplicativo usa a API e o Supabase como fonte de verdade, sem persistência de negócio no dispositivo. Cada ambiente (`staging` e `production`) deve manter as operações financeiras em funções transaccionais.

## Modelo

Mapear as tabelas camada de dados para PostgreSQL com `numeric(18,2)` para valores MZN e `timestamptz` para datas. Acrescentar `organization_id`, `branch_id`, `created_by` e `updated_at` às entidades de negócio. A tabela `users` deve ser substituída pelo Supabase Auth; perfis e permissões ficam em tabelas próprias.

## Segurança

- Activar RLS em todas as tabelas.
- Nunca colocar a service role key no Flutter ou na Vercel.
- Restringir cada linha pela organização e agência do utilizador.
- Executar desembolso, pagamento e reversão em RPCs idempotentes.
- Registar auditoria append-only com utilizador, dispositivo, origem e valores antes/depois.
- Guardar ficheiros KYC no Supabase Storage com políticas por organização.

## Operações remotas

Cada operação é enviada à API com `idempotency_key`, validação de versão e confirmação transaccional. Falhas ficam visíveis ao utilizador e não são apresentadas como concluídas.

## Deploy Vercel

A Vercel pode alojar o portal web e endpoints de apresentação, usando variáveis de ambiente para a URL e anon key do Supabase. O Flutter desktop/mobile continua a usar o mesmo adaptador remoto, sem acesso a segredos de servidor.
