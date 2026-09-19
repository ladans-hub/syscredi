# UI restore — shell anterior ao refactor remoto

Regra: restaurar o shell visual do commit anterior ao refactor; somente a origem dos dados e operações usa serviços remotos. Não reintroduzir Store, Drift, SQLite ou cache local.

- [x] Criar clone de referência com a UI completa: `../syscredi-offline-full` (`10cdc08 feat: add premium font system`).
- [x] Recuperar o workspace visual anterior como base da tela autenticada.
- [x] Restaurar sidebar, grupos, etapas de crédito e navegação por áreas.
- [x] Restaurar cabeçalho, marca, menus de perfil/notificações/tema e identidade visual.
- [x] Manter formulários, tabelas, cards e dialogs do shell anterior no workspace remoto.
- [x] Ligar carregamento e mutações às interfaces `ApiClient`/`Repository`.
- [x] Validar compilação macOS e testes remotos.
- [x] Comparar visualmente o shell e ajustar diferenças residuais principais.
- [x] Portar marca d’água, fonte base do sistema e identidade visual sem alterar o shell.
- [x] Portar diferenças residuais de configurações e paleta sem alterar o shell.
- [x] Validar todas as etapas de crédito: navegação, enumeração, ícones e compilação.

## Mapeamento dos commits visuais

Os commits visuais históricos foram incorporados por equivalência no shell remoto:

- `6288817` shell premium → `lib/features/api/presentation/navigation.dart` e `workspace.dart`.
- `9b81f98` navbar remota → cabeçalho e menus do workspace remoto.
- `1a0710e` administração/configurações → rotas remotas de organização e configurações.
- `39bf631` ações da conta → popup de perfil remoto.
- `10cdc08` sistema de fontes → `app_theme.dart`, fonte do sistema e Poppins.
- `ce0962f` cards/marca d’água → cards remotos e `BrandWatermarkOverlay` global.
- `d6fc751` marca d’água no workspace → overlay no shell remoto.
- `9b85d36` marca d’água no login → overlay global do `SysCrediApp`.

Aplicação literal dos três últimos commits não é compatível com o objetivo remoto, pois eles dependem de `Store`, `AppDatabase` e módulos locais removidos. A apresentação foi portada sem essa dependência.
