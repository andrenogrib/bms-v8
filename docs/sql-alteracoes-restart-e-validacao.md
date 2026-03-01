# Alteracoes SQL: restart e validacao operacional

Data: 2026-03-01

Este documento registra a regra operacional adotada neste projeto:

- Sempre que alterar dados via SQL para efeito in-game (inventario, storage, status de conta/personagem, quest flags, etc.), reiniciar o servico do jogo antes de testar no cliente.

No nosso ambiente, a mudanca pode aparecer no banco e ainda nao refletir imediatamente no cliente/sessao ativa. O restart do `bms_server` evita estado em cache e inconsistencias de sessao.

## Regra pratica

1. Alterou SQL?
2. Reinicie `bms_server`.
3. Espere o servidor ficar `READY=YES`.
4. So depois abra/logue no cliente para validar.

## Quando aplicar

Aplicar esta regra para mudancas em:

- `GameWorld.dbo.ItemSlot_Size` (slots de inventario)
- `GameWorld.dbo.Trunk` (storage/trunk)
- `GameWorld.dbo.Character` (status/base de personagem)
- `GlobalAccount.dbo.Account` (flags de conta, admin, cash/maplePoint)
- dados de quest/estado em tabelas relacionadas

## Exemplo real validado (slots maximos)

Limites observados neste servidor:

- Inventario EQP/USE/SETUP/ETC: `48`
- CASH: `64`
- Storage (Trunk): `48`

### 1) Conferir antes

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "SET NOCOUNT ON; SELECT C.CharacterName,S.Equip_slot,S.Use_slot,S.Setup_slot,S.Etc_slot,S.Cash_slot,T.Slots AS TrunkSlots FROM GameWorld.dbo.Character C LEFT JOIN GameWorld.dbo.ItemSlot_Size S ON S.CharacterID=C.CharacterID LEFT JOIN GameWorld.dbo.Trunk T ON T.AccountID=C.AccountID WHERE C.CharacterName IN ('FangBlade','dedezin');"
```

### 2) Aplicar update (exemplo para 1 personagem)

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "SET NOCOUNT ON; DECLARE @CharacterName varchar(20)='FangBlade'; DECLARE @CharacterID int,@AccountID int; SELECT @CharacterID=C.CharacterID,@AccountID=C.AccountID FROM GameWorld.dbo.Character C WHERE C.CharacterName=@CharacterName; IF @CharacterID IS NULL BEGIN RAISERROR('Character not found',16,1); RETURN; END; BEGIN TRAN; UPDATE GameWorld.dbo.ItemSlot_Size SET Equip_slot=48,Use_slot=48,Setup_slot=48,Etc_slot=48,Cash_slot=64 WHERE CharacterID=@CharacterID; IF @@ROWCOUNT=0 INSERT INTO GameWorld.dbo.ItemSlot_Size(CharacterID,Equip_slot,Use_slot,Setup_slot,Etc_slot,Cash_slot) VALUES(@CharacterID,48,48,48,48,64); UPDATE GameWorld.dbo.Trunk SET Slots=48 WHERE AccountID=@AccountID; IF @@ROWCOUNT=0 INSERT INTO GameWorld.dbo.Trunk(AccountID,Slots,Money) VALUES(@AccountID,48,0); COMMIT;"
```

### 3) Restart do servidor de jogo

```powershell
docker restart bms_server
```

Opcional (reinicio completo):

```powershell
docker compose down
docker compose up -d
```

## Validacao de readiness antes de logar

Ver containers:

```powershell
docker compose ps
```

Ver status de boot em monitor:

```powershell
.\Scripts\monitor\open-monitor.ps1 -RefreshSeconds 2
```

Somente logar quando:

- `Login->Center=YES`
- `Center(Login)=YES`
- `Center(Shop)=YES`
- `ServerPingFull=YES`
- `READY=YES`

## Validacao final

1. Confirmar valores no SQL (mesma query da etapa "Conferir antes").
2. Entrar no jogo com cliente fechado/reaberto apos restart.
3. Verificar se os slots realmente refletiram no personagem.

## Notas de seguranca

- Evite testar com cliente aberto durante update SQL.
- Evite "spam" de login durante boot parcial (pode causar desconexao/estado de conta presa).
- Se conta ficar presa como online, aguarde o boot completo e tente novamente; so use limpeza manual de conexoes se necessario.
