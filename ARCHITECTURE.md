> Actualização de 11/09/2026: a implementação foi adaptada para SysCredi/Moçambique e API remota. O estado actual, fluxo implementado e limites estão em [README.md](README.md). O texto abaixo preserva o planeamento anterior.

# Arquitectura do SysCredi

O SysCredi segue o mesmo princípio do Systock: UI adaptativa por feature, estado controlado, dependências construídas num composition root e regras de negócio fora dos widgets.

```text
lib/
├── app/
│   └── bootstrap/              # composição e injecção de dependências
├── core/
│   ├── result.dart             # resultado tipado de operações de negócio
│   └── widgets/                # componentes transversais sem regra de domínio
└── features/
    └── credit/
        ├── data/               # adapters: camada de dados/HTTP/ficheiro
        ├── domain/
        │   ├── entities/       # Client, Loan, CreditRequest
        │   ├── repositories/   # contratos independentes da infraestrutura
        │   └── use_cases/      # decisões e validações de negócio
        ├── application/        # controllers/notifiers e coordenação de casos
        └── presentation/       # páginas, formulários e componentes
```

## Padrões aplicados

- **Clean Architecture / Ports and Adapters:** `LoanRepository` é uma porta; `InMemoryLoanRepository` é o adapter actual e pode ser trocado por camada de dados sem alterar as páginas.
- **Composition Root:** `AppDependencies` constrói os serviços e injecta as dependências no estado da aplicação.
- **Use Case:** `RegisterRepayment` valida limites e regras antes de alterar a carteira.
- **Repository:** a UI nunca deve conhecer SQL, HTTP ou a origem dos dados.
- **Result Object:** `AppResult`, `Success` e `Failure` tornam erros de negócio explícitos.
- **Feature-first:** cada capacidade (crédito, cobranças, risco) pode evoluir isoladamente.
- **Presentation/Domain separation:** entidades não importam Flutter; widgets não tomam decisões de crédito.

## Próximas implementações de produção

1. Substituir o adapter em memória por camada de dados, usando migrations versionadas e transacções.
2. Adicionar outbox idempotente e sincronização arquitetura remota, à semelhança do Systock.
3. Persistir auditoria append-only para decisões, alterações KYC e pagamentos.
4. Introduzir RBAC/ABAC por agência, carteira e limite de aprovação.
5. Ligar providers de identidade, pagamentos, SMS, bureau de crédito e listas AML através de ports.
