# Como verificar status de todos os serviços (antes de logar)

Este checklist evita crash/DC na tela de escolha de world/channel quando o server ainda não terminou de subir.

## 1) Confirmar containers

```powershell
docker compose ps
```

Esperado:

- `bmsdb` com status `healthy`
- `bms_server` com status `Up`

## 2) Confirmar Login conectado no Center

```powershell
$f=(Get-ChildItem .\temp\MSLog\Login_*.log | Sort LastWriteTime -Desc | Select -First 1).FullName
Select-String -Path $f -Pattern "Center socket connected successfully"
```

Esperado no resultado:

- `Center socket connected successfully 127.0.0.1:9000`

## 3) Confirmar Center enxergando Login/Game/Shop

```powershell
$c=(Get-ChildItem .\temp\MSLog\CenterOrion_*.log | Sort LastWriteTime -Desc | Select -First 1).FullName
Select-String -Path $c -Pattern "ServerPing:","Game0Orion","Game1Orion","Game2Orion","Game3Orion","Game4Orion","Shop0Orion","Local server connected successfully Login"
```

Esperado no resultado:

- `Local server connected successfully Login`
- `Local server connected successfully Shop0Orion`
- Linha `ServerPing:` contendo `Login`, `Game0Orion..Game4Orion` e `Shop0Orion`

## 4) Regra pratica para abrir o jogo

- So abra o client depois dos 2 checks acima passarem.
- Se clicar cedo (antes do Center terminar), pode fechar ao escolher servidor/channel.

## 5) Fluxo validado no projeto

No caso validado, funcionou apenas esperando ficar tudo online.

Não foi necessário usar:

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "DELETE FROM UserConnection.dbo.Connections;"
docker restart bms_server
```



