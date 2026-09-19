# Restauração integral da interface e identidade SysCredi

O layout do commit de referência é a identidade visual do produto. Todos os
componentes abaixo devem ser portados para os dados e comandos remotos, sem
alterar a aparência, hierarquia, proporções ou comportamento visual.

**Regra principal:** o layout anterior prevalece integralmente. A API remota
substitui apenas a origem dos dados e das operações; não substitui o shell,
componentes, proporções, navegação visual ou identidade do produto.

- [~] Restaurar shell visual original: sidebar, navbar, cabeçalho e responsividade. (cabeçalho da sidebar restaurado; restante em andamento)
- [~] Restaurar logo institucional/SysCredi, favicon, watermark, carimbo e assinatura. (blocos visuais restaurados; upload remoto pendente)
- [x] Restaurar fundo, gradientes, sombras, bordas, raios e estados claro/escuro.
- [x] Restaurar ecrãs de processamento, ligação ao servidor, carregamento, erro e vazio.
- [x] Restaurar dashboard inicial, cards, métricas e espaçamentos.
- [x] Restaurar saudação, avatar, perfil, role, sessão e menu de conta.
- [x] Restaurar topo da Início: pesquisa, notificações, tema, ecrã inteiro e definições.
- [x] Restaurar tipografia, fontes, pesos e escala dos componentes.
- [~] Restaurar Poppins, fonte do sistema, escala configurável e internacionalização. (fontes e escala adicionadas; traduções completas pendentes)
- [x] Restaurar tabelas, filtros, paginação e disposição dos botões.
- [x] Restaurar menus de ações, tooltips, indicadores, badges e estados de seleção.
- [x] Restaurar dialogs, alerts, confirmações e animações.
- [x] Restaurar formulários, validações, rolagem, grupos de botões e feedback de operações.
- [x] Restaurar popup menus de perfil, notificações e tema.
- [~] Restaurar definições, paletas, fontes, logo, marca d’água e carimbo. (paleta rápida e identidade remota adicionadas; upload completo pendente)
- [x] Restaurar preferências de instituição, moeda, idioma, aparência e sessão via API, incluindo carregamento inicial remoto.
- [x] Restaurar clientes, empresas, avalistas, co-assinantes e respetivos detalhes.
- [x] Restaurar simulador, produtos, pedidos, carteira, cobranças e relatórios.
- [x] Reaplicar o fluxo visual das etapas de crédito.
- [x] Restaurar análise, aprovação, autorização, desembolso, estado e reestruturação.
- [x] Restaurar contabilidade, tesouraria, conciliação, AML, auditoria e utilizadores.
- [x] Restaurar documentos, recibos, exportações, impressão e visualização de PDFs.
- [x] Restaurar permissões por role e menus condicionais sem mudar a UI.
- [x] Ligar a apresentação restaurada aos endpoints remotos atuais.
- [x] Garantir que todas as mutações usam feedback premium e confirmação remota.
- [x] Validar macOS, iOS, Android e testes remotos.

Referência visual: commit `33d1473` (`before the biggest refactor`).
