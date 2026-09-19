# Baseline visual do workspace

O commit visual de referência é `406b6a5` (layout premium original). A aplicação reutiliza a composição compartilhada de sidebar e os mesmos tokens de tema em `lib/features/workspace/presentation/workspace_components.dart`.

Breakpoints de revisão:

- Desktop: largura mínima de 1050 px, sidebar expandida de 278 px.
- Tablet: 720–1049 px, navegação compacta e conteúdo fluido.
- Janela estreita: abaixo de 720 px, drawer e navegação inferior.

Elementos que devem permanecer iguais: logo e gradiente, grupos do sidebar, títulos e espaçamentos, cards do dashboard, tipografia escalável, notificações, selector de tema e personalização institucional.

Validação executada: `flutter test test/reference_dashboard_test.dart test/tenant_sync_test.dart` e `flutter analyze`.
