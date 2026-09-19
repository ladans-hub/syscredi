# Arquitetura do aplicativo

O aplicativo usa a API NestJS/Supabase como fonte única de verdade. A API remota é a fonte única de verdade; o cliente não mantém dados de negócio locais.

## Limites

- `lib/app`: composição, configuração e raiz da aplicação. `main.dart` contém apenas o entrypoint; `syscredi_app.dart` monta a aplicação e gere o ciclo de sessão/preferências.
- `lib/app/theme`: fonte única da identidade visual: cores, paleta, gradientes, assets e logótipo configurável.
- `lib/features/remote/domain`: entidades, contratos e regras sem dependência de Flutter, HTTP ou Supabase.
- `lib/features/remote/application`: casos de uso de sessão e confiabilidade (fila, idempotência e retry).
- `lib/features/remote/infrastructure`: adaptadores da API, Supabase Auth e armazenamento seguro.
- `lib/features/remote/presentation`: estado da sessão e widgets do workspace.
- `lib/features/workspace`: domínio da navegação e componentes compartilhados do workspace.
- As telas foram separadas por feature em `clients`, `credit`, `collections`, `treasury`, `compliance` e `reports`; nenhuma dessas responsabilidades permanece no entrypoint.
- `lib/core` e `lib/data`: segurança, apresentação, validações e contratos comuns, sem base de dados de negócio local.

## Segurança e resiliência

- Tokens e dados de fila ficam em `flutter_secure_storage`.
- A API exige HTTPS fora de desenvolvimento, timeout e cabeçalho de idempotência.
- Operações com falha permanecem pendentes no servidor e podem ser consultadas/repetidas com a mesma chave idempotente.
- Permissões são aplicadas novamente no backend; o cliente apenas adapta a interface.
- O cliente nunca substitui uma resposta válida da API por dados remotos.
- A personalização institucional é persistida nas definições remotas e reaplicada pela composição da aplicação; telas usam `BrandPalette`, `BrandVisuals`, `AppColors` e `AppAssets` em vez de duplicar a identidade. O `ColorScheme` deriva estados, superfícies, bordas e contrastes da paleta configurada; valores fixos ficam restritos a fallbacks e presets de escolha.

O desenho detalhado do backend está em [`../syscredi-backend/ARCHITECTURE.md`](../../syscredi-backend/ARCHITECTURE.md).
