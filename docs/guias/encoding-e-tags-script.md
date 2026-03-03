# Encoding e tags nos scripts de NPC

Este documento registra a regra mais importante para editar scripts em `Server/DataSvr/Script`.

## 1) Situacao real do projeto

Os `.s` legados NAO usam um unico encoding.

No mesmo servidor você pode encontrar:

- `Western (Windows 1252)`
- encodings coreanos (ex.: EUC-KR/CP949)
- arquivos com texto misto (PT + KR) e histórico antigo

Conclusao: encoding e por arquivo, não por pasta.

## 2) Como saber o encoding correto (fluxo seguro)

1. Abra o arquivo e NAO salve imediatamente.
2. No VS Code, use `Reopen with Encoding`.
3. Teste em ordem:
   - `Western (Windows 1252)`
   - `Korean (EUC-KR/CP949)`
   - outros apenas se necessário
4. Valide se o texto ficou coerente:
   - sem caractere de substituicao quebrado
   - sem lixo visual em palavras latinas (ex.: letras trocadas)
   - estrutura de script normal (`script`, `if`, `self.say`, `target`)
5. So depois disso edite e salve com `Save with Encoding` no MESMO encoding.

## 3) Regras de ouro para não quebrar

- Nunca fazer conversao em massa para UTF-8.
- Nunca usar `Save all` em lote sem conferir encoding por arquivo.
- Sempre preservar o encoding original do arquivo.
- Antes de mudar script critico, fazer backup rápido (`.bak`) ou commit.

## 4) Como identificar que você salvou errado

Sinais mais comuns:

- caracteres quebrados no proprio `.s`
- dialogos com texto estranho no cliente
- diff gigante sem alteração lógica (so texto "mudou")

Se isso acontecer:

1. pare de editar
2. reabra com o encoding correto
3. restaure pelo git/backup se necessário

## 5) Sistema de tags dentro das falas

Exemplo:

```text
self.say("Tem certeza que você tem um #b#t4031249##k? Eu faco a melhor proposta da cidade!");
```

Significado:

- `#b` = inicia texto azul
- `#t4031249#` = renderiza o nome do item de ID `4031249`
- `#k` = volta para cor padrão (preto)

## 6) Observacao pratica

- Mesmo quando o editor mostra texto quebrado por encoding, o jogo pode continuar exibindo normal se o runtime estiver lendo o encoding esperado.
- O risco real aparece quando o arquivo e salvo com encoding errado.



