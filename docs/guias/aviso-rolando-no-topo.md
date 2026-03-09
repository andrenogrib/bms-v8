# Aviso rolando no topo da tela (slide)

## Escopo

Este guia mostra como disparar o aviso que "rola" no topo da tela do jogador, como verificar se ja existe suporte, e como alterar depois com seguranca.

## 1) Status atual no projeto

Ja existe suporte no engine de script.

Referencia:

- `Server/DataSvr/Script/standard.s`

Tipos de mensagem definidos:

- `0`: normal
- `1`: alert
- `4`: slide (rolando no topo)
- `7`: NPCSay

## 2) Forma recomendada (sem rebuild)

Use script `.s` com tipo `4`.

Exemplos:

```js
field.notice(4, "Evento iniciado! Boa sorte!");
quest.broadcastMsg(4, "A porta foi aberta.");
setParty.broadcastMsg(4, "Boss apareceu no mapa.");
```

Deploy:

1. Edite o `.s` mantendo encoding original do arquivo.
2. No jogo, rode `!rs` para recarregar scripts.
3. Teste no mapa/quest correspondente.

## 3) Forma via comando GM (futuro)

No momento, o parser custom em `Extension/WvsGame/CommandParser.cpp` nao tem `!notice` dedicado.

Se quiser criar depois:

1. Adicionar comando `!notice`.
2. Enviar pacote de mensagem com tipo `4` (slide).
3. Rebuild do `wvsgm.dll`.
4. Copiar para `Server/BinSvr/wvsgm.dll`.
5. Reiniciar `bms_server` e aguardar `READY=YES`.

## 4) Diferenca importante

- `field.notice(4, ...)`: aviso no contexto do mapa/field.
- `broadcastMsg(...)` sem tipo: existe no script, mas o estilo exato depende da implementacao interna; para garantir "rolando", prefira API com tipo `4`.

## 5) Troubleshooting rapido

- Nao apareceu aviso:
  - Verifique se o trecho do script foi realmente executado.
  - Confirme se o arquivo foi salvo no encoding correto.
  - Rode `!rs` novamente.
- Continua sem efeito:
  - Veja logs em `temp/MSLog`.
  - Reinicie `bms_server` se houver duvida de cache/estado.
