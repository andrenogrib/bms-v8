# Caso real: Closed Beta, Bandana Brasil e boot do servidor

Este documento registra exatamente o que aconteceu no ambiente local, o que foi alterado e como validar o servidor antes de logar.

## 1) Sintoma inicial

- No NPC "Administrador do Servidor", o personagem recebia:
  - `Voce nao participou do periodo de Closed Beta...`
- Ao alterar flags no banco para tentar liberar Closed Beta, o login passou a mostrar:
  - `Contas nao verificadas serao bloqueadas depois de 7 dias...`
- Apos restart do `bms_server`, tentativas de login antes do boot completo causavam queda/desconexao.

## 2) O que foi alterado no SQL

### 2.1 Tentativa para Closed Beta (conta do FangBlade)

Foi aplicado update na conta para:

- `PrivateStatusID = 1`
- `AccountFlags = 1`
- (em um momento de teste, `NeedVerification = 1`)

### 2.2 Ajuste final para remover popup de verificacao

Para evitar o aviso de conta nao verificada:

- `NeedVerification = 0` nas contas locais.

Comando usado:

```sql
UPDATE GlobalAccount.dbo.Account
SET NeedVerification = 0
WHERE AccountName IN ('user', 'admin');
```

## 3) O que foi alterado no script `etc.s`

Arquivo:

- `Server/DataSvr/Script/etc.s`

Trecho alterado no script `levelUPBRCB`:

Antes:

```text
check = target.IsClosedBetaTester;
if ( check == 1 and val == "" ) {
```

Depois:

```text
// Localhost preservation setup: treat Closed Beta check as enabled for this reward NPC.
check = 1;
if ( check == 1 and val != "end" ) {
```

Motivo:

- Em localhost, a checagem original de `IsClosedBetaTester` nao estava retornando `1` mesmo com flags no banco.
- `val != "end"` evita falso negativo quando o QR record nao vem vazio, mantendo a regra de receber apenas uma vez.

## 4) O que voce fez que funcionou

- Deu restart no servidor.
- Tentou logar cedo e caiu algumas vezes (normal durante boot parcial).
- Usou o monitor (`watch-login-center`) e aguardou:
  - `Login->Center=YES`
  - `Center(Login)=YES`
  - `Center(Shop)=YES`
  - `ServerPingFull=YES`
  - `READY=YES`
- Depois disso, login estabilizou.

## 5) Interpretacao dos logs de boot

Durante inicializacao completa, e normal ver:

- `Failed in connecting to center socket 127.0.0.1:9000` no Login
- `Local server connected successfully ...` aparecendo por etapas no Center

Somente quando o Center termina carga e o Login conecta no Center:

- `Center socket connected successfully 127.0.0.1:9000`
- status passa para `READY=YES`

## 6) Demora para iniciar: e normal?

Sim. Neste setup (Wine + carga de scripts/data), e normal demorar para ficar 100% pronto.

Faixa pratica observada:

- cerca de `1` a `4` minutos para estabilizar tudo, dependendo da maquina e do estado do host.

Conclusao:

- nao logar imediatamente apos restart;
- aguardar `READY=YES` no monitor antes de entrar.

## 7) Procedimento recomendado apos restart

1. Fechar cliente antes de reiniciar server.
2. Iniciar monitor:
   - `.\Scripts\monitor\open-monitor.ps1 -RefreshSeconds 2`
3. Aguardar status `READY=YES`.
4. So entao abrir o client e logar.

## 8) Comando de emergencia (sessao presa)

Se conta ficar "ja conectada" apos queda:

```sql
DELETE FROM UserConnection.dbo.Connections
WHERE AccountID = (SELECT AccountID FROM GameWorld.dbo.Character WHERE CharacterName='FangBlade');
```

Use apenas quando necessario.
