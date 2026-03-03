# Como alterar slots de inventario e storage

Data: 2026-03-01

Este guia e exclusivo para aumentar/reduzir slots de:

- Inventario do personagem (`Equip`, `Use`, `Setup`, `Etc`, `Cash`)
- Storage/Trunk da conta (`Trunk`)

## Limites maximos observados neste servidor

- `Equip`: 48
- `Use`: 48
- `Setup`: 48
- `Etc`: 48
- `Cash`: 64
- `Trunk (Storage)`: 48

Observacoes:

- Inventario e por personagem (`CharacterID`).
- Trunk/Storage e por conta (`AccountID`) e compartilhado entre chars da mesma conta.

## Sequencia segura (obrigatoria)

1. Fechar cliente.
2. Conferir valores atuais.
3. Aplicar update.
4. Conferir no SQL.
5. Reiniciar `bms_server`.
6. Esperar `READY=YES`.
7. Reabrir cliente e validar no jogo.

## 1) Conferir slots atuais

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "SET NOCOUNT ON; SELECT C.CharacterName,S.Equip_slot,S.Use_slot,S.Setup_slot,S.Etc_slot,S.Cash_slot,T.Slots AS TrunkSlots FROM GameWorld.dbo.Character C LEFT JOIN GameWorld.dbo.ItemSlot_Size S ON S.CharacterID=C.CharacterID LEFT JOIN GameWorld.dbo.Trunk T ON T.AccountID=C.AccountID WHERE C.CharacterName IN ('FangBlade','dedezin');"
```

## 2) Aplicar máximo para 1 personagem

Exemplo (`FangBlade`):

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "SET NOCOUNT ON; DECLARE @CharacterName varchar(20)='FangBlade'; DECLARE @CharacterID int,@AccountID int; SELECT @CharacterID=C.CharacterID,@AccountID=C.AccountID FROM GameWorld.dbo.Character C WHERE C.CharacterName=@CharacterName; IF @CharacterID IS NULL BEGIN RAISERROR('Character not found',16,1); RETURN; END; BEGIN TRAN; UPDATE GameWorld.dbo.ItemSlot_Size SET Equip_slot=48,Use_slot=48,Setup_slot=48,Etc_slot=48,Cash_slot=64 WHERE CharacterID=@CharacterID; IF @@ROWCOUNT=0 INSERT INTO GameWorld.dbo.ItemSlot_Size(CharacterID,Equip_slot,Use_slot,Setup_slot,Etc_slot,Cash_slot) VALUES(@CharacterID,48,48,48,48,64); UPDATE GameWorld.dbo.Trunk SET Slots=48 WHERE AccountID=@AccountID; IF @@ROWCOUNT=0 INSERT INTO GameWorld.dbo.Trunk(AccountID,Slots,Money) VALUES(@AccountID,48,0); COMMIT; SELECT C.CharacterName,S.Equip_slot,S.Use_slot,S.Setup_slot,S.Etc_slot,S.Cash_slot,T.Slots AS TrunkSlots FROM GameWorld.dbo.Character C LEFT JOIN GameWorld.dbo.ItemSlot_Size S ON S.CharacterID=C.CharacterID LEFT JOIN GameWorld.dbo.Trunk T ON T.AccountID=C.AccountID WHERE C.CharacterName=@CharacterName;"
```

## 3) Reiniciar servidor do jogo

```powershell
docker restart bms_server
```

## 4) Esperar readiness

```powershell
.\Scripts\monitor\open-monitor.ps1 -RefreshSeconds 2
```

Entrar apenas quando aparecer:

- `Login->Center=YES`
- `Center(Login)=YES`
- `Center(Shop)=YES`
- `ServerPingFull=YES`
- `READY=YES`

## 5) Ajuste para valor customizado (não máximo)

Troque os numeros no `UPDATE` respeitando os limites:

- `Equip/Use/Setup/Etc`: 1 a 48
- `Cash`: 1 a 64
- `Trunk`: 1 a 48

Exemplo custom (somente SQL):

```sql
UPDATE GameWorld.dbo.ItemSlot_Size
SET Equip_slot=32, Use_slot=32, Setup_slot=32, Etc_slot=32, Cash_slot=64
WHERE CharacterID=@CharacterID;

UPDATE GameWorld.dbo.Trunk
SET Slots=32
WHERE AccountID=@AccountID;
```

Depois: reiniciar `bms_server` e validar.

## Troubleshooting

Se mudou no banco mas não apareceu no jogo:

1. Confirme o nome do personagem correto.
2. Confirme se o char testado e da conta atual.
3. Reinicie `bms_server`.
4. Aguarde `READY=YES`.
5. Entre novamente.

Se storage não mudou:

- Verifique se o char da consulta e da mesma conta.
- Lembre que `Trunk` usa `AccountID`, não `CharacterID`.


