# BMS v8 - Referencia de GM, SuperGM, Dev e comandos

Este documento resume como o projeto trata privilégios e comandos in-game, com base nos arquivos desta base.

## 1) Resumo rápido

- `GlobalAccount.dbo.Account.Admin` controla o nivel de admin da conta.
- No runtime, `m_nGradeCode` (derivado do login) e usado para liberar comandos.
- `Admin = 255` e `Admin = 1` sao tratados como admin/GM no codigo extension.
- `SuperGM` aparece nos scripts via `isSuperGM` e normalmente usa job `510`.
- `GM` comum em scripts usa job `500`.
- Comandos de chat custom implementados no extension: `!fm`, `!gmap`, `!exp`, `!drop`, `!rs`.

## 2) Modelo de permissao de conta (Admin / GradeCode)

### SQL base

Arquivo: `Database/4-GlobalAccount.sql`

- Tabela `Account` define:
  - `Admin` (tinyint)
  - `AccountStatusID`
  - `PrivateStatusID`
  - `AccountFlags`
  - `NeedVerification`
- Procedure `CheckPassword` retorna `@Admin`, `@AccountFlags`, `@NeedVerification`.
- Em ranking, contas `Admin IN (1, 255)` sao filtradas como staff.

Pontos de referência:

- `Database/4-GlobalAccount.sql:139` (`Admin`).
- `Database/4-GlobalAccount.sql:357` (`CheckPassword`).
- `Database/4-GlobalAccount.sql:402` (`@Admin = Admin`).
- `Database/4-GlobalAccount.sql:594` (`Admin IN (1, 255)`).

### Seed inicial (contas padrão)

Arquivo: `Database/8-Configure.sql`

- Cria conta `user` (não admin).
- Cria conta `admin` com `Admin = 255`.
- Hash usado no seed para senha `admin`: `21232f297a57a5a743894a0e4a801fc3` (MD5).

Pontos de referência:

- `Database/8-Configure.sql:45` (insert de `user`).
- `Database/8-Configure.sql:89` (insert de `admin`).
- `Database/8-Configure.sql:98` (`Admin = 255`).

### Runtime extension

Arquivos:

- `Extension/WvsLogin/CClientSocket.cpp`
- `Extension/WvsGame/CUser.cpp`
- `Extension/WvsGame/CommandParser.cpp`

Regras vistas:

- `isAdmin()` retorna true para `m_nGradeCode == 255 || m_nGradeCode == 1`.
- Teleporte GM (`/m`) usa check equivalente (`== 1 || == 255`).
- Parser de comando custom usa `if (user->m_nGradeCode & 1)`.

Pontos de referência:

- `Extension/WvsLogin/CClientSocket.cpp:46`
- `Extension/WvsGame/CUser.cpp:12`
- `Extension/WvsGame/CommandParser.cpp:21`

Observacao: para comandos `!` do extension, a conta precisa grade com bit 1 (ex.: `1` ou `255`).

## 3) SuperGM e GM no script

Arquivos:

- `Server/DataSvr/Script/standard.s`
- `Server/DataSvr/Script/etc.s`
- `Server/DataSvr/Script/event.s`

Achados:

- API de script exposta com `isMaster` e `isSuperGM`.
- Script `levelUP` (NPC) promove para GM:
  - se `isSuperGM == 1` -> job `510`
  - senao -> job `500`
- Scripts de evento usam `isSuperGM == 1` para funções administrativas.

Pontos de referência:

- `Server/DataSvr/Script/standard.s:83`
- `Server/DataSvr/Script/standard.s:85`
- `Server/DataSvr/Script/etc.s:76`
- `Server/DataSvr/Script/etc.s:93`
- `Server/DataSvr/Script/event.s:25`

## 4) Indicios de perfil Dev / interno

Arquivo: `Server/DataSvr/IPCheck.img`

O arquivo tem varias entradas com:

- `internal = 1`
- `master = 1`
- `skipcrc = 1`

E nomes como:

- `WizetDevModified`
- `WizetDev1External`
- `WizetDev2External`
- `LUISAGM1` ate `LUISAGM6`

Pontos de referência:

- `Server/DataSvr/IPCheck.img:7`
- `Server/DataSvr/IPCheck.img:8`
- `Server/DataSvr/IPCheck.img:9`
- `Server/DataSvr/IPCheck.img:57`
- `Server/DataSvr/IPCheck.img:78`
- `Server/DataSvr/IPCheck.img:106`

Complemento no extension:

- Game e Shop forcam comportamento de admin client e bypass de CRC.
- `Extension/WvsClient/Tools.cpp` contém detector de admin client.

Pontos de referência:

- `Extension/WvsGame/Entrypoint.cpp:37`
- `Extension/WvsGame/Entrypoint.cpp:46`
- `Extension/WvsShop/Entrypoint.cpp:33`
- `Extension/WvsShop/Entrypoint.cpp:42`
- `Extension/WvsClient/Tools.cpp:32`

## 5) Comandos in-game encontrados

### 5.1 Comandos custom do extension

Arquivo: `Extension/WvsGame/CommandParser.cpp`

- `!fm` -> teleporta para `910000000`
- `!gmap` -> teleporta para `180000000`
- `!exp <1-5>` -> altera rate de exp
- `!drop <1-5>` -> altera rate de drop
- `!rs` -> recarrega scripts `../DataSvr/Script/*.s`

Pontos de referência:

- `Extension/WvsGame/CommandParser.cpp:8`
- `Extension/WvsGame/CommandParser.cpp:35`
- `Extension/WvsGame/CommandParser.cpp:40`
- `Extension/WvsGame/CommandParser.cpp:45`
- `Extension/WvsGame/CommandParser.cpp:80`
- `Extension/WvsGame/CommandParser.cpp:113` (`onUserCommand` retorna false)

### 5.2 Comandos nativos mencionados (hook/comentarios)

- `/m` (restrito a GM por check de teleporte).
- `/findhm` (comentado no hook do center para evitar crash).

Pontos de referência:

- `Extension/WvsGame/WvsGame.cpp:22`
- `Extension/WvsGame/WvsGame.cpp:28`
- `Extension/WvsGame/CCenter.h:8`

### 5.3 Fluxos de GM por NPC/script

Exemplos:

- `Server/DataSvr/Script/davyJohn.s:384` (`nJob >= 500`)
- `Server/DataSvr/Script/PartyGL.s:236` (`nJob >= 500`)
- `Server/DataSvr/Script/PartyGL.s:544` (`nJob >= 500`)
- `Server/DataSvr/Script/zakum.s:90` (`nJob == 500`)

## 6) Criacao de personagem e relacao com GM

Arquivo: `Database/7-GameWorld.sql`

- Procedure `CreateNewCharacter` cria personagem normal.
- Não ha elevacao automatica de GM nessa procedure.
- GM/SuperGM e algo aplicado depois (conta e/ou script/job).

Ponto de referência:

- `Database/7-GameWorld.sql:1932`

## 7) Consultas SQL de referência

### Ver contas e niveis

```sql
SELECT
  AccountID,
  AccountName,
  Admin,
  AccountStatusID,
  PrivateStatusID,
  AccountFlags,
  NeedVerification
FROM GlobalAccount.dbo.Account
ORDER BY AccountID;
```

### Promover/rebaixar conta (admin grade)

```sql
-- GM/admin forte
UPDATE GlobalAccount.dbo.Account
SET Admin = 255
WHERE AccountName = 'admin';

-- Conta normal
UPDATE GlobalAccount.dbo.Account
SET Admin = 0
WHERE AccountName = 'user';
```

### Ajustar job de personagem GM/SuperGM (script side)

```sql
-- GM job
UPDATE GameWorld.dbo.Character
SET B_Job = 500
WHERE CharacterName = 'seu_char';

-- SuperGM job
UPDATE GameWorld.dbo.Character
SET B_Job = 510
WHERE CharacterName = 'seu_char';
```

Importante: job `500/510` sozinho não substitui `Account.Admin` para os comandos `!` do extension.

## 8) Observacao de possível bug no SQL

Em `SetUserBlockedByCharacterName` existe:

```sql
SELECT @CurrentIP = CurrentIP, @GradeCode = @GradeCode FROM Account WHERE AccountID = @AccountID;
```

Isso parece auto-atribuicao de `@GradeCode`, provavelmente deveria ler um campo da conta (ex.: `Admin`).

Pontos de referência:

- `Database/4-GlobalAccount.sql:649`
- `Database/4-GlobalAccount.sql:672`

## 9) Como atualizar esta referência no futuro

Quando adicionar novos comandos ou alterar regra de GM:

1. Atualize `Extension/WvsGame/CommandParser.cpp`.
2. Rode busca:
   - `rg -n "m_nGradeCode|isAdmin|!|/m|/findhm" Extension`
   - `rg -n "isMaster|isSuperGM|nJob >= 500|nJob == 500|nJob = 510" Server/DataSvr/Script`
3. Atualize este arquivo em `docs/`.



