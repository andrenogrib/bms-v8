# dedezin: setup SuperGM completo (aplicado)

Data: 2026-03-01

Este documento registra a promocao do personagem `dedezin` para perfil de operacao/GM completo no ambiente atual.

Objetivo aplicado:

- conta com privilegio maximo de admin no servidor
- personagem em `job` de SuperGM
- level e atributos maximos seguros
- slots de inventario e storage no limite maximo operacional

## 1) Premissas

- Container `bmsdb` online e healthy.
- Personagem `dedezin` existente.
- Alteracao feita sem editar WZ/EXE do client.

## 2) SQL aplicado (transacional)

```sql
SET NOCOUNT ON;
DECLARE @CharacterName varchar(20)='dedezin';
DECLARE @CharacterID int,@AccountID int;

SELECT
  @CharacterID=C.CharacterID,
  @AccountID=C.AccountID
FROM GameWorld.dbo.Character C
WHERE C.CharacterName=@CharacterName;

IF @CharacterID IS NULL
BEGIN
  RAISERROR('Character dedezin not found',16,1);
  RETURN;
END;

BEGIN TRAN;

UPDATE GlobalAccount.dbo.Account
SET
  Admin=255,
  NeedVerification=0,
  AccountFlags=0
WHERE AccountID=@AccountID;

UPDATE GameWorld.dbo.Character
SET
  B_Level=200,
  B_Job=510,
  B_STR=999,
  B_DEX=999,
  B_INT=999,
  B_LUK=999,
  S_HP=30000,
  S_MaxHP=30000,
  S_MP=30000,
  S_MaxMP=30000,
  S_AP=0,
  S_SP=3000,
  S_Money=2000000000
WHERE CharacterID=@CharacterID;

UPDATE GameWorld.dbo.ItemSlot_Size
SET
  Equip_slot=48,
  Use_slot=48,
  Setup_slot=48,
  Etc_slot=48,
  Cash_slot=64
WHERE CharacterID=@CharacterID;

IF @@ROWCOUNT=0
BEGIN
  INSERT INTO GameWorld.dbo.ItemSlot_Size
    (CharacterID,Equip_slot,Use_slot,Setup_slot,Etc_slot,Cash_slot)
  VALUES
    (@CharacterID,48,48,48,48,64);
END;

UPDATE GameWorld.dbo.Trunk
SET Slots=48
WHERE AccountID=@AccountID;

IF @@ROWCOUNT=0
BEGIN
  INSERT INTO GameWorld.dbo.Trunk(AccountID,Slots,Money)
  VALUES(@AccountID,48,0);
END;

COMMIT;
```

## 3) Estado final validado

`dedezin` ficou com:

- `B_Level=200`
- `B_Job=510` (SuperGM job)
- `B_STR/B_DEX/B_INT/B_LUK=999`
- `S_HP/S_MaxHP=30000`
- `S_MP/S_MaxMP=30000`
- `S_SP=3000`
- `S_Money=2000000000`
- inventario: `48/48/48/48/64`
- storage/trunk: `48`

Conta vinculada:

- `AccountName=admin`
- `Admin=255`
- `NeedVerification=0`
- `AccountFlags=0`

## 4) Observacoes de permissao (importante)

Na base atual:

- o parser de comandos custom (`Extension/WvsGame/CommandParser.cpp`) libera comandos para `m_nGradeCode & 1`.
- `Admin=255` atende esse requisito e e o nivel mais forte no modelo atual.
- `job 510` e reconhecido em scripts antigos como SuperGM job.

Ou seja: na pratica, este setup cobre os direitos de GM/SuperGM que existem neste projeto hoje.

## 5) Operacao apos ajuste

Se o personagem estava offline, normalmente basta logar.

Se houver cache/sessao antiga:

1. fechar client
2. reiniciar `bms_server`
3. aguardar readiness completa
4. logar novamente

Referencias:

- `docs/verificar-status-servicos-center.md`
- `docs/sql-alteracoes-restart-e-validacao.md`

