# Brazil Maple Story v8 (Docker + Client Patch) - Guia Completo

Este repositorio contem a estrutura de database e runtime para rodar o BMS v8 em Docker.

O servidor sobe no Docker, mas o login do cliente normalmente trava se o cliente for aberto "cru" (sem injecao de patch).
O fluxo que funcionou de ponta a ponta foi:

1. Subir servidor e banco no Docker.
2. Compilar `client.dll` e `GameLauncher.exe` da pasta `Extension`.
3. Colocar os dois na pasta do cliente.
4. Criar `server.txt`.
5. Abrir o jogo pelo `GameLauncher.exe` (administrador).

Importante: neste setup validado, o cliente usado foi o `MapleStory.exe` original.

## Creditos

Projeto baseado em engenharia reversa dos binarios originais com auxilio de ferramentas como IDA e SQL Profiler.
Creditos aos devs que fizeram o trabalho original de reversao/preservacao.

## Server files

[Link available since 2014](https://www.mediafire.com/file/z0vkal61ymwyxlw/5366a09f4e67570decdbef93468edf19.tar.bz2)

## Before starting

- Windows com Docker Desktop funcionando.
- `winget` funcionando (para instalar Build Tools).
- Cliente do Maple instalado (exemplo usado: `MapleStory.exe` original).

## Estrutura esperada

- `Server/DataSvr` deve conter os dados do servidor original, mantendo os arquivos de configuracao deste repo.
- `Server/BinSvr` deve conter os binarios do servidor original.

## 1) Subir servidor no Docker

No root do projeto:

```powershell
docker compose up -d
docker compose ps
```

Comandos rapidos (start/status/stop):

```powershell
# Startar servidor
docker compose up -d

# Ver status
docker compose ps

# Parar servidor
docker compose down
```

Logs ficam em:

- `temp/MSLog/Login_*.log`
- `temp/MSLog/CenterOrion_*.log`
- `temp/MSLog/Game*_*.log`

Comando para acompanhar login:

```powershell
$f=(Get-ChildItem .\temp\MSLog\Login_*.log | Sort-Object LastWriteTime -Desc | Select-Object -First 1).FullName
Get-Content $f -Wait
```

### Painel de monitoramento (4 janelas)

```powershell
.\Scripts\monitor\open-monitor.ps1 -StartServer
```

Opcional (single window):

```powershell
.\Scripts\monitor\open-monitor.ps1 -SingleWindow
```

Referencia completa:

- `docs/monitoramento-operacao.md`

## 2) Instalar Build Tools (C++ + v141)

Comando usado e validado:

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --source winget --accept-package-agreements --accept-source-agreements --silent --override "--quiet --wait --norestart --nocache --installPath C:\BuildTools --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --includeRecommended"
```

## 3) Compilar `client.dll` e `GameLauncher.exe`

No root do projeto:

```powershell
& "C:\BuildTools\MSBuild\Current\Bin\MSBuild.exe" "Extension\WvsApp.sln" /m /t:WvsCommon;WvsClient;WvsLauncher /p:Configuration=Release;Platform=Win32;WindowsTargetPlatformVersion=10.0.19041.0 /v:minimal
```

Saidas esperadas:

- `Extension\Release\client.dll`
- `Extension\Release\GameLauncher.exe`

## 4) Copiar arquivos para a pasta do cliente

Exemplo de pasta usada:

`C:\Users\andre\Dropbox\games\ms_server\bms_v8\MapleStory`

Copiar:

- `Extension\Release\client.dll` -> `MapleStory\client.dll`
- `Extension\Release\GameLauncher.exe` -> `MapleStory\GameLauncher.exe`

Criar `MapleStory\server.txt` com 2 linhas.

### Opcao que funcionou no final (cliente original):

```txt
MapleStory.exe
MapleStory.exe 127.0.0.1 8484
```

## 5) Abrir cliente do jeito certo

Abrir sempre pelo launcher, com privilegios de administrador:

```powershell
cd C:\Users\andre\Dropbox\games\ms_server\bms_v8\MapleStory
Start-Process -FilePath .\GameLauncher.exe -WorkingDirectory (Get-Location) -Verb RunAs
```

Importante:

- Nao abrir o jogo direto pelo `MapleStory.exe` para login final.
- `GameLauncher.exe` precisa achar `client.dll` e `server.txt` na mesma pasta.

## 6) Contas padrao

Criadas pelo seed SQL:

- `user / admin`
- `admin / admin`

Onde:

- `admin` possui GM (`Admin = 255`).
- `user` e conta normal.

Arquivo referencia:

- `Database/8-Configure.sql`

## 7) Comandos GM implementados

Comandos atuais no parser:

- `!fm` -> vai para FM (`910000000`)
- `!gmap` -> vai para mapa GM (`180000000`)
- `!exp <1-5>` -> altera rate de EXP
- `!drop <1-5>` -> altera rate de drop
- `!rs` -> recarrega scripts

Referencia:

- `Extension/WvsGame/CommandParser.cpp`

## 8) Sinais de que esta funcionando

- `temp/MSLog/Login_*.log` mostra `Center socket connected successfully 127.0.0.1:9000`
- `MapleStory/client.log` mostra inicializacao do `client.dll`

Exemplo de `client.log` valido:

- `Initializing client.dll, admin client: false`
- `Hook status: CREATED`
- `Client initialized`

## 9) Cuidado com encoding e tags de script

- Scripts em `Server/DataSvr/Script` podem estar em `Windows-1252` (nao UTF-8).
- Se abrir/salvar com encoding errado, o texto pode quebrar nos arquivos.
- As falas de NPC usam tags como:
  - `#b` (texto azul)
  - `#t<ID>#` (nome dinamico de item)
  - `#k` (volta para cor padrao)

Referencia detalhada:

- `docs/encoding-e-tags-script.md`
- `docs/sp-primeira-job-e-compensacao.md`

## Documentacao tecnica

- Indice geral: `docs/README.md`
- Arquitetura completa: `docs/arquitetura-e-logica-completa.md`

## Troubleshooting rapido

### PowerShell e `start ""`

No PowerShell, use:

```powershell
Start-Process -FilePath .\MapleStory.exe -ArgumentList '127.0.0.1','8484'
```

`start "" ...` e sintaxe de `cmd`, nao do PowerShell.

Obs.: para jogar de fato, use `GameLauncher.exe` como no passo 5.

### Login aceita conexao e desconecta na hora

Se log mostra apenas:

- `Connection accepted`
- `Client socket disconnected`
- `CheckPassword: 0 called`

entao e mismatch de handshake (cliente sem patch).
Confirme que:

1. `client.dll`, `GameLauncher.exe` e `server.txt` estao na pasta do cliente.
2. Esta abrindo pelo `GameLauncher.exe`.
3. Launcher esta rodando como admin.

### Center demora apos restart

Apos `docker compose restart bms_server`, aguarde o `Center` completar boot.

### SP alterado no banco mas nao aparece no jogo

Se `S_SP` esta correto no SQL e o client continua com valor antigo:

1. Feche o cliente.
2. Limpe a sessao em `UserConnection.dbo.Connections`.
3. Reinicie `bms_server`.
4. Aguarde o server ficar READY (Login + Center + Game conectados).
5. Logue novamente.

Referencia detalhada:

- `docs/sp-primeira-job-e-compensacao.md`

## Observacoes

- Este setup e para estudo, pesquisa tecnica e preservacao de software antigo. E proibida a comercializacao, monetizacao ou qualquer uso com finalidade financeira deste material.
