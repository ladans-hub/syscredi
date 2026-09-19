# Execução incremental

## Estado

- Fase 0: análise e inventário produzidos; baseline 90 Flutter / 31 backend passou.
- Fase 1: primeiro corte implementado. O backlog completo permanece em [ARCHITECTURE_PRODUCT_GAP_ANALYSIS.md](ARCHITECTURE_PRODUCT_GAP_ANALYSIS.md).
- Nenhuma migração foi aplicada à base de produção nesta execução.
- Alterações preexistentes do backend serão preservadas.

## Próximo corte

### Corte FND-01/FND-02 — concluído em ambiente de teste

- Recebimentos validam que a conta e o empréstimo usam a mesma moeda.
- Transferências passaram para o `CommandExecutor`, bloqueiam contas em ordem estável, validam moeda/saldo/estado, e geram duas entradas de caixa, posting e auditoria.
- Foreign keys tenant-aware foram adicionadas de forma aditiva para relações críticas.
- Idempotência e rate limit passaram a usar a chave composta da instituição.
- Índices para prestações vencidas, carteira por moeda e pagamentos foram adicionados.
- O endpoint `/v1/dashboard` passou a devolver empréstimos ativos, desembolsos/recebimentos do mês, `as_of`, `metric_version` e PAR30/PAR90 por moeda, sem somar moedas diferentes.
- A tabela `payment_allocations` guarda principal/juros por pagamento e prestação; a reversão passa a usar essa informação quando disponível e mantém fallback para dados legados.
- Pedidos novos guardam `terms_snapshot` do produto no momento da originação; desembolso e contrato usam essa fotografia mesmo que o produto seja editado depois. `application_status_history` regista criação, decisões e desembolso.
- O desembolso valida moeda, taxa, limites e calendário contra a fotografia capturada; desactivar ou editar o produto depois da aprovação não altera o contrato aprovado.
- O bootstrap local do Flutter deixou de gravar cada empréstimo individualmente durante a abertura. Estado de atraso e estado derivado são calculados em memória, evitando congelamento perceptível em carteiras grandes.
- A migration 017 cria `approval_decisions`, ligando decisões terminais ao pedido, actor, instituição e motivo. A autoridade por montante/maker-checker continua a depender de política configurável.
- A migration 018 preenche snapshots ausentes de pedidos legados a partir do catálogo existente; contratos já desembolsados continuam a usar os seus próprios snapshots.
- `GET /v1/requests/:id/history` expõe o histórico paginado para a timeline de originação no cliente.
- Posting rules centralizadas foram introduzidas para abertura, desembolso, pagamento, transferência e movimentos manuais.
- Verificação: TypeScript build, typecheck, 35 testes backend passaram (22 focados após o dashboard), análise Flutter passou e a suíte Flutter completa terminou com 90 testes. `npm run lint` continua bloqueado por 534 problemas de formatação preexistentes no backend, não introduzidos como correção automática neste corte.

### Limites conhecidos deste corte

- O ledger de alocações começa a ser preenchido em novos pagamentos; alocações históricas não são inventadas.
- Para pagamentos legados sem alocações, a reversão mantém fallback conservador; novos pagamentos usam allocation ledger. A operação agora é um comando idempotente próprio com posting compensatório.
- A migration 014 requer as migrations anteriores e deve ser aplicada pelo script versionado em base de staging antes de produção.
- A migration 016 adiciona `installments.active`; reestruturações aposentam o plano anterior sem apagar histórico. A primeira versão bloqueia ajustes após pagamentos registados até existir migração explícita das alocações.

### Próximo corte

SRV-02: formalizar reestruturação com aprovação, migração de alocações já pagas e snapshots versionados no servidor.
