> Actualização de 11/09/2026: a implementação foi adaptada para SysCredi/Moçambique e API remota. O estado actual, fluxo implementado e limites estão em [README.md](README.md). O texto abaixo preserva o planeamento anterior.

# SysCredi — escopo simplificado

O SysCredi é um sistema de gestão de crédito para pequenas e médias operações. O produto deve ser simples de configurar e usar diariamente por uma equipa pequena.

## Fluxo principal

1. Criar cliente.
2. Registar pedido de crédito.
3. Analisar e aprovar ou recusar.
4. Emitir contrato e plano de prestações.
5. Registar pagamentos.
6. Acompanhar saldo e atrasos.
7. Consultar cobranças e relatórios.

## Módulos activos

- Dashboard simples;
- Clientes;
- Pedidos de crédito;
- Carteira de empréstimos;
- Prestações e pagamentos;
- Cobranças;
- Relatórios básicos;
- Utilizadores e permissões simples;
- Subscrição e trial.

## Funcionalidades mantidas simples

- KYC limitado a documento, telefone e estado de verificação;
- risco baseado num score simples e regras configuráveis;
- tesouraria limitada ao registo de pagamentos e exportação;
- auditoria apenas para decisões, pagamentos e alterações sensíveis;
- sincronização opcional apenas para backup, sem colaboração em tempo real;
- funcionamento modo remoto como comportamento padrão.

## Fora do MVP

- AML avançado e listas externas;
- bureau de crédito;
- contabilidade integrada;
- mobile money e gateways de pagamento;
- reconciliação bancária complexa;
- múltiplas agências e estruturas empresariais complexas;
- ABAC avançado, MFA obrigatório e workflows de comité;
- dashboards financeiros de grandes instituições.

## Critério de conclusão do MVP

Um operador deve conseguir gerir o ciclo completo de um crédito sem internet: cliente, pedido, aprovação, contrato, prestação, pagamento, atraso e relatório. Os dados devem sobreviver ao reinício da aplicação e os pagamentos devem ser auditáveis.
