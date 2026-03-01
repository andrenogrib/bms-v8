# Encoding e tags nos scripts de NPC

Este documento registra uma descoberta importante para editar scripts em `Server/DataSvr/Script`.

## 1) Encoding dos arquivos

Sintoma:

- no VS Code, varios scripts aparecem com caracteres quebrados (`�`) quando abertos como UTF-8.

Validacao feita:

- ao reabrir como `Western (Windows 1252)`, os textos ficaram corretos.

Recomendacao:

1. Sempre reabrir arquivos de script com o encoding correto antes de editar.
2. Ao salvar, usar o mesmo encoding (`Save with Encoding`) para nao corromper texto.
3. Evitar conversao em massa para UTF-8 nos scripts legados.

## 2) Sistema de tags dentro das falas

Exemplo:

```text
self.say("Tem certeza que você tem um #b#t4031249##k? Eu faço a melhor proposta da cidade!");
```

Significado:

- `#b` = inicia texto azul
- `#t4031249#` = renderiza o nome do item de ID `4031249`
- `#k` = volta para cor padrao (preto)

## 3) Observacao pratica

- Mesmo quando o editor mostra texto quebrado por encoding, o jogo pode continuar exibindo normal se o runtime estiver lendo o encoding esperado.
- O risco real aparece quando o arquivo e salvo com encoding errado.
