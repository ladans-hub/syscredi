# SysCredi

A camada de dados está temporariamente desativada por defeito. A aplicação abre
apenas a tela de login, sem inicializar a API, o Supabase ou o armazenamento
de sessão. O botão Entrar e o cadastro do primeiro utilizador continuam ligados
ao Supabase; o restante pós-login usa dados mockados. Os dados existentes no
servidor são preservados.

Para reativar a integração existente:

```sh
flutter run -d macos --dart-define=DATA_LAYER_ENABLED=true
```

O fluxo descrito abaixo aplica-se quando a camada de dados está ativa.

Interface conforme a referência visual e novas operações: [docs/INTERFACE.md](docs/INTERFACE.md).

Plataforma Flutter de gestão de crédito para Moçambique, com interface adaptativa, tema claro/escuro e dados centralizados no servidor remoto.

## Fluxo disponível

1. Registar o cliente com telefone moçambicano, documento e actividade.
2. Rever a identidade no cadastro do cliente.
3. Simular capital, taxa anual, prazo, encargos e prestações em MZN.
4. Criar um pedido e avançar por documentação → análise → comité → aprovação. Recusas exigem motivo.
5. Abrir um pedido aprovado e registar o desembolso. São gerados contrato, prestações e movimento de tesouraria.
6. Consultar o contrato na carteira; receber pagamentos parciais ou totais nas cobranças.
7. Consultar/copiar recibos, exportar pagamentos em CSV e acompanhar auditoria.
8. Configurar a instituição e gerir definições, documentos e auditoria no servidor.

O painel e os indicadores operacionais usam dados reais. A instalação começa vazia; não importa os dados pessoais presentes nas fotografias de referência.

```sh
flutter pub get
flutter run -d macos
flutter analyze
flutter test
```

A API remota é a fonte única de verdade. Todas as operações financeiras exigem sessão autenticada, confirmação do servidor e feedback explícito.

Referências funcionais: fotografias em `../base`, [ciclo de crédito Mambu](https://mambu.com/en/lenders) e [direitos do consumidor financeiro — Banco de Moçambique](https://bancomoc.mz/pt/aprenda-mais/portal-do-consumidor-financeiro/direitos-e-deveres-dos-consumidores-financeiros/).
