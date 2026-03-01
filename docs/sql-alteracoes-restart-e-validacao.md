# Alteracoes SQL: sequencia segura e validacao

Data: 2026-03-01

Guia geral para qualquer alteracao manual no banco que afete o jogo.

Regra operacional adotada:

- Sempre que alterar SQL para efeito in-game, reinicie o `bms_server` e valide readiness antes de logar.

No ambiente atual, em varios casos a mudanca fica no banco mas a sessao ativa do jogo nao reflete imediatamente sem restart/relogin.

## Sequencia segura (padrao)

1. Fechar o cliente do jogo.
2. Conferir o valor atual no SQL (baseline).
3. Aplicar update em `BEGIN TRAN`/`COMMIT`.
4. Conferir no SQL se a mudanca foi gravada.
5. Reiniciar `bms_server`.
6. Aguardar `READY=YES`.
7. Abrir o cliente e validar in-game.

## Template de alteracao segura

Use este modelo e adapte a tabela/campos:

```sql
BEGIN TRAN;

-- 1) consulta alvo
-- SELECT ... WHERE ...

-- 2) update
-- UPDATE ... SET ... WHERE ...

-- 3) validacao imediata
-- SELECT ... WHERE ...

COMMIT;
```

Se algo inesperado acontecer durante o teste SQL:

```sql
ROLLBACK;
```

## Checklist de validacao apos restart

1. `docker compose ps` deve mostrar `bmsdb` healthy e `bms_server` up.
2. Monitor de boot deve chegar em `READY=YES`.
3. So depois testar no jogo.

Comandos:

```powershell
docker compose ps
.\Scripts\monitor\open-monitor.ps1 -RefreshSeconds 2
```

## Boas praticas

- Evite fazer update com cliente aberto.
- Evite logar durante boot parcial do servidor.
- Prefira mudancas pequenas e testadas em etapas.
- Sempre salvar o SQL executado no historico (doc/comentario/arquivo).

## Rollback operacional

Se a mudanca causar comportamento ruim:

1. Reaplicar valores anteriores no SQL.
2. Reiniciar `bms_server`.
3. Aguardar `READY=YES`.
4. Validar novamente no jogo.

## Guias especificos relacionados

- Slots de inventario e storage: `docs/alterar-slots-inventario-storage.md`
