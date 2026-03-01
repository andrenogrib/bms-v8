# Como editar Mesos e NX de um personagem

Este guia usa o container `bmsdb` (SQL Server no Docker) e altera por `CharacterName`.

## 1) Fechar o cliente

- Feche o jogo antes de alterar (evita sobrescrever estado em memoria).

## 2) Conferir valor atual

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "SELECT C.CharacterName,C.S_Money,A.NexonCash,A.maplePoint FROM GameWorld.dbo.Character C JOIN GlobalAccount.dbo.Account A ON A.AccountID=C.AccountID WHERE C.CharacterName='FangBlade';"
```

## 3) Definir novos valores (valor fixo)

Exemplo: `S_Money = 1,000,000,000`, `NexonCash = 500,000`, `maplePoint = 500,000`.

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "UPDATE GameWorld.dbo.Character SET S_Money=1000000000 WHERE CharacterName='FangBlade'; UPDATE A SET NexonCash=500000, maplePoint=500000 FROM GlobalAccount.dbo.Account A JOIN GameWorld.dbo.Character C ON C.AccountID=A.AccountID WHERE C.CharacterName='FangBlade';"
```

## 4) Somar valores (incremento)

Se preferir adicionar ao valor atual, use `+`.

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "UPDATE GameWorld.dbo.Character SET S_Money = S_Money + 10000000 WHERE CharacterName='FangBlade'; UPDATE A SET NexonCash = ISNULL(NexonCash,0) + 10000, maplePoint = ISNULL(maplePoint,0) + 10000 FROM GlobalAccount.dbo.Account A JOIN GameWorld.dbo.Character C ON C.AccountID=A.AccountID WHERE C.CharacterName='FangBlade';"
```

## 5) Validar depois da alteracao

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "SELECT C.CharacterName,C.S_Money,A.NexonCash,A.maplePoint FROM GameWorld.dbo.Character C JOIN GlobalAccount.dbo.Account A ON A.AccountID=C.AccountID WHERE C.CharacterName='FangBlade';"
```

## 6) Se os mesos "voltarem" para o valor antigo

Isso normalmente acontece quando o servidor ainda nao terminou de iniciar e/ou a sessao ainda esta sendo atualizada enquanto voce testa.

Fluxo que foi validado:

1. Fazer o `UPDATE` com o cliente fechado.
2. Esperar o servidor ficar 100% online (Login + Center + Games + Shop conectados).
3. So depois abrir o client e entrar.

Sem usar limpeza forcada de conexao e sem restart extra.

Referencias do checklist de status:

- `docs/verificar-status-servicos-center.md`

## Observacoes

- `S_Money`, `NexonCash` e `maplePoint` sao `int`. Evite passar de `2147483647`.
- Se o personagem nao aparecer no `SELECT`, confirme o nome exato:

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "SELECT TOP 50 CharacterName FROM GameWorld.dbo.Character ORDER BY CharacterID DESC;"
```

Comando opcional para garantir que Mesos e NX ficaram como esperado:

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "SELECT C.CharacterName,C.S_Money,A.NexonCash,A.maplePoint FROM GameWorld.dbo.Character C JOIN GlobalAccount.dbo.Account A ON A.AccountID=C.AccountID WHERE C.CharacterName='FangBlade';"
```
