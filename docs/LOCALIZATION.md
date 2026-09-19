# Localização e moedas

O cliente Flutter selecciona o locale por instituição através de
`institution.locale`. Os valores suportados são `pt_MZ`, `pt_PT` e `en_US`, com
delegates oficiais do Flutter para datas, números e componentes Material.

As operações financeiras aceitam `MZN`, `USD`, `EUR` e `ZAR`. O domínio guarda
valores em unidades menores inteiras; a camada visual apenas formata o valor e
o código da moeda. O backend continua a validar moeda, conta e crédito na
mesma operação.

Para adicionar um idioma, inclua o locale em `SyscrediApp.supportedLocales` e
adicione o catálogo de traduções da feature. Nenhuma fórmula financeira deve
depender da representação regional.
