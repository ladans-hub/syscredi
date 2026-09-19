# Interface SysCredi

A interface segue a referência fornecida nesta conversa: barra lateral azul-escuro, fundo claro, cartões de indicadores, evolução da carteira, distribuição dos pedidos, cartão fotográfico, tabelas de pedidos e vencimentos. Mantém SysCredi, Moçambique e MZN.

## Operações ligadas aos dados

- Indicadores abrem as respectivas áreas; pesquisa global encontra clientes, pedidos e contratos.
- Histórico de 3, 6 ou 12 meses calculado a partir de contratos, saldos e pagamentos API remota; não são geradas séries fictícias para a instalação.
- Pedidos filtráveis por fase e carteira pesquisável por cliente/contrato/estado.
- Produtos configuráveis (taxa, limite, prazo, activar/desactivar), escolhidos nos pedidos e aplicáveis no simulador; limites validados no desembolso.
- Contas e transferências internas com duas entradas transaccionais e validação de saldo.
- Reagendamento de prestações pendentes com motivo auditado, sem alteração dos montantes ou pagamentos anteriores. Não recalcula taxas nem acrescenta encargos.
- Receitas/despesas com canal seleccionado.

## Meios de pagamento

m-Pesa, eMola, mKesh, Millenium BIM e BCI. BIM solicita número de conta e BCI solicita NIB. O registo conserva identificador e referência externa em `payment_details`, no schema API remota 11. Esses dados aparecem no detalhe, recibo copiado e CSV. A validação local confirma presença e formato numérico; não confirma titularidade ou validade bancária. Os meios antigos mantêm-se legíveis nos registos históricos.

As operações são registos locais de movimentos realizados. Não são integrações que enviam dinheiro.

## Imagem e tipografia

Imagem criada com a ferramenta integrada `image_gen` e guardada em `assets/images/entrepreneur.png`. Prompt usado:

> Create a photorealistic editorial photograph for a premium microfinance dashboard promotional card in Mozambique. Landscape 3:2 composition. Rightmost 45%: confident smiling Black Mozambican woman small business owner about 35, wearing a navy apron over neutral taupe shirt, arms casually crossed, in a tasteful small neighborhood shop, warm wooden shelves softly blurred behind her. Left 55%: very soft pale mint blue-grey blank wall, almost uniform, generous clean negative space for later HTML text overlay. Natural soft daylight, warm human tone, understated premium commercial photography. Chest-up portrait, head fully visible with margin. No text, no lettering, no logos, no watermarks. Save image for use as project asset.

Inter é distribuída com a licença SIL Open Font License em `assets/fonts/OFL.txt`.

A captura em `build/previews/dashboard.png` é renderizada pela aplicação com dados de teste exclusivamente em memória. Não altera nem preenche a base operacional.
