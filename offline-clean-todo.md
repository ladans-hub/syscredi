# Limpeza de dependências locais e offline

## Objectivo

Manter o SysCredi exclusivamente ligado à API remota, sem SQLite local, mirror, fallback offline ou autenticação local.

## Plano de execução

- [x] Mapear referências a Drift, SQLite, `AppDatabase`, `LocalIdentity`, mirror e fallback local.
- [x] Remover mirror e sincronização de mirror do runtime remoto.
- [x] Fazer o arranque autenticado abrir directamente o workspace remoto.
- [x] Remover logout e carregamento de identidade local do shell remoto.
- [x] Garantir que o módulo remoto não referencia SQLite, Drift ou mirror.
- [x] Extrair navegação, tema, menu de conta e notificações para `features/remote/presentation`.
- [x] Atualizar documentação e mensagens de interface.
- [x] Validar testes remotos, build macOS, build iOS e build Android.
- [x] Remover testes de UI obsoletos que dependiam do banco embutido.
- [x] Criar entrypoint remoto independente (`RemoteOnlyApp`) para retirar o workspace local do runtime.
- [x] Remover páginas e serviços locais não alcançados pelo runtime remoto.
- [x] Manter auditoria, documentos, tesouraria, AML e relatórios fora do runtime até existirem endpoints remotos dedicados.
- [x] Manter preferências e subscrição fora do runtime até existirem endpoints remotos dedicados.
- [x] Remover login e cadastro locais do `LoginPage`; a tela agora exige callbacks remotos.
- [x] Remover `LocalIdentity` e validação de sessão local.
- [x] Adicionar `updatePassword` ao contrato remoto e ao Supabase Auth.
- [x] Ligar alteração de palavra-passe ao menu de perfil remoto.
- [x] Remover `AppDatabase`, migrations, repositórios locais e backups.
- [x] Retirar `syscredi_app.dart` e os 16 ficheiros `part` locais do runtime/compilação do entrypoint.
- [x] Remover testes restantes baseados em SQLite.
- [x] Atualizar teste de arquitectura remota para a composição sem mirror.
- [x] Remover dependências de banco embutido do `pubspec.yaml`.
- [x] Remover nomenclatura `Remote` da aplicação ativa (`App`, `Root`, `Composition`, `Repository`, `Workspace`).
- [ ] Validar distribuição assinada e publicação nas lojas.

## Contagem

Concluídas: 25  
Pendentes: 1

## Critério de conclusão

O código executável, dependências e documentação activa não devem conter `sqlite`, `drift`, `AppDatabase`, `LocalIdentity`, `offline`, `mirror` ou `openPersistentDatabase`.
