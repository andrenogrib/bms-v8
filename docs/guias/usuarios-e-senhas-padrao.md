# Usuarios e senhas padrao

## Escopo

Este documento lista as credenciais padrao do ambiente BMS v8 deste repositorio e mostra como criar novas contas com opcoes de permissao.

## 1) Login no jogo (contas seed)

Contas criadas no seed de `GlobalAccount.dbo.Account`:

- `user / admin`
- `admin / admin`

Notas:

- `admin` vem com `Admin = 255` (conta com privilegio de GM/admin).
- `user` vem com `Admin = 0` (conta normal).
- A senha `admin` no seed usa hash MD5: `21232f297a57a5a743894a0e4a801fc3`.

Referencia:

- `Database/8-Configure.sql`

## 2) Banco SQL (container bmsdb)

Credencial do SQL Server (SA):

- `sa / Dong0#1sG00d`

Referencia:

- `Server/docker-compose.yml` (env `SA_PASSWORD`)

## 3) Logins de servico SQL (internos)

Criados pelo script de usuarios SQL:

- `us_trading_user / us_trading_user_password`
- `couponadmin / 2chigoalfzl`

Referencia:

- `Database/2-CreateUsers.sql`

## 4) Como criar um usuario novo (conta de jogo)

### 4.1 Script SQL recomendado

Rode no terminal (ajuste os valores no bloco):

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "
DECLARE @AccountName VARCHAR(20) = 'novo_user';
DECLARE @PlainPassword VARCHAR(64) = 'senha123';
DECLARE @Admin TINYINT = 0;      -- 0=player, 1=gm compat, 255=admin forte
DECLARE @Gender SMALLINT = -1;   -- -1 indefinido, 0/1 conforme client
DECLARE @PasswordHash VARCHAR(32) = LOWER(CONVERT(VARCHAR(32), HASHBYTES('MD5', @PlainPassword), 2));

IF EXISTS (SELECT 1 FROM GlobalAccount.dbo.Account WHERE AccountName = @AccountName)
BEGIN
  RAISERROR('Conta ja existe.', 16, 1);
  RETURN;
END

INSERT INTO GlobalAccount.dbo.Account
(
  AccountName, PasswordHash, Pin, ReadEULA, IsBanned, AccountStatusID, PrivateStatusID,
  BirthDate, CurrentIP, Admin, NeedVerification, AccountFlags, ChatBlock, PacketDump,
  Gender, RegisterDate, maplePoint, PurchaseExp, Email, NexonCash
)
VALUES
(
  @AccountName, @PasswordHash, '', 0, 0, 0, 0,
  '1990-01-01 00:00:00.000', '', @Admin, 0, 0, 0, 0,
  @Gender, SYSDATETIME(), 0, 0, CONCAT(@AccountName, '@local'), 0
);

SELECT AccountID, AccountName, Admin, NeedVerification, AccountFlags
FROM GlobalAccount.dbo.Account
WHERE AccountName = @AccountName;
"
```

### 4.2 Opcoes importantes

- `Admin`:
  - `0`: conta normal
  - `1`: GM compativel com checagens que usam bit/grade
  - `255`: admin/GM forte
- `NeedVerification`:
  - `0`: sem popup de verificacao de conta
  - `1`: pode aparecer aviso de verificacao/bloqueio
- `AccountFlags` e `PrivateStatusID`:
  - manter `0` para conta normal
  - usar valores especiais apenas quando souber o efeito (ex.: fluxo de closed beta)

## 5) Como trocar senha de conta existente

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "
DECLARE @AccountName VARCHAR(20) = 'user';
DECLARE @PlainPassword VARCHAR(64) = 'nova_senha';
DECLARE @PasswordHash VARCHAR(32) = LOWER(CONVERT(VARCHAR(32), HASHBYTES('MD5', @PlainPassword), 2));

UPDATE GlobalAccount.dbo.Account
SET PasswordHash = @PasswordHash
WHERE AccountName = @AccountName;

SELECT AccountName, PasswordHash
FROM GlobalAccount.dbo.Account
WHERE AccountName = @AccountName;
"
```

## 6) Promover ou rebaixar permissao (Admin)

```sql
-- Promover para admin forte
UPDATE GlobalAccount.dbo.Account
SET Admin = 255
WHERE AccountName = 'admin';

-- Definir como player normal
UPDATE GlobalAccount.dbo.Account
SET Admin = 0
WHERE AccountName = 'user';
```

## 7) Validacao rapida

```sql
SELECT AccountID, AccountName, Admin, NeedVerification, AccountFlags, IsBanned
FROM GlobalAccount.dbo.Account
ORDER BY AccountID;
```

## 8) Observacoes operacionais

- Mudancas SQL de conta costumam refletir no proximo login.
- Se houver sessao presa ("ja conectado"), deslogue e aguarde o servidor estabilizar; se necessario, reinicie o `bms_server` e aguarde `READY=YES`.

## 9) Observacao de seguranca

Essas credenciais sao para ambiente local de estudo/preservacao.
Para qualquer ambiente externo, troque todas as senhas padrao.
