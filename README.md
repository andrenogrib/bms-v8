# Brazil Maple Story v8 (Docker + Client Patch) - Guia Completo

Este repositório contém a estrutura de banco e runtime para rodar o BMS v8 em Docker.

O servidor sobe no Docker, mas o login do cliente costuma travar se o cliente for aberto "cru" (sem injeção de patch).
O fluxo validado de ponta a ponta foi:

1. Subir servidor e banco no Docker.
2. Compilar `client.dll` e `GameLauncher.exe` na pasta `Extension`.
3. Copiar os arquivos para a pasta do cliente.
4. Criar `server.txt`.
5. Abrir o jogo pelo `GameLauncher.exe` (administrador).

Importante: no setup validado, o cliente utilizado foi o `MapleStory.exe` original.

## Créditos

Projeto baseado em engenharia reversa dos binários originais, com auxílio de ferramentas como IDA e SQL Profiler.
Créditos aos devs que realizaram o trabalho original de reversão e preservação.

## Server files

[Link available since 2014](https://www.mediafire.com/file/z0vkal61ymwyxlw/5366a09f4e67570decdbef93468edf19.tar.bz2)

Instalador do cliente v08 (`mssetup_v08`):

[https://archive.org/download/maplestory_all/](https://archive.org/download/maplestory_all/)

## Before starting

- Windows com Docker Desktop funcionando.
- `winget` funcionando (para instalar Build Tools).
- Cliente do Maple instalado (exemplo usado: `MapleStory.exe` original).

## Estrutura esperada

- `Server/DataSvr` deve conter os dados do servidor original, mantendo os arquivos de configuração deste repositório.
- `Server/BinSvr` deve conter os binários originais do servidor.

## 1) Subir servidor no Docker

No diretório raiz do projeto:

```powershell
docker compose up -d
docker compose ps
```

Comandos rápidos (start/status/stop):

```powershell
# Iniciar servidor
docker compose up -d

# Ver status
docker compose ps

# Parar servidor
docker compose down
```

## 2) Monitoramento (recomendado)

Painel com 4 janelas:

```powershell
.\Scripts\monitor\open-monitor.ps1 -StartServer
```

Modo janela única:

```powershell
.\Scripts\monitor\open-monitor.ps1 -SingleWindow
```

Guia completo:

- `docs/guias/subir-servidor-e-monitoramento.md`
- `docs/guias/monitoramento-operacao.md`

## 3) Instalar Build Tools (C++ + v141)

Comando validado:

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --source winget --accept-package-agreements --accept-source-agreements --silent --override "--quiet --wait --norestart --nocache --installPath C:\BuildTools --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --includeRecommended"
```

## 4) Compilar `client.dll` e `GameLauncher.exe`

No diretório raiz do projeto:

```powershell
& "C:\BuildTools\MSBuild\Current\Bin\MSBuild.exe" "Extension\WvsApp.sln" /m /t:WvsCommon;WvsClient;WvsLauncher /p:Configuration=Release;Platform=Win32;WindowsTargetPlatformVersion=10.0.19041.0 /v:minimal
```

Saídas esperadas:

- `Extension\Release\client.dll`
- `Extension\Release\GameLauncher.exe`

## 5) Copiar arquivos para a pasta do cliente

Exemplo:

`C:\Users\andre\Dropbox\games\ms_server\bms_v8\MapleStory`

Copiar:

- `Extension\Release\client.dll` -> `MapleStory\client.dll`
- `Extension\Release\GameLauncher.exe` -> `MapleStory\GameLauncher.exe`

Criar `MapleStory\server.txt` com 2 linhas:

```txt
MapleStory.exe
MapleStory.exe 127.0.0.1 8484
```

## 6) Abrir o cliente corretamente

Abrir sempre pelo launcher, com privilégios de administrador:

```powershell
cd C:\Users\andre\Dropbox\games\ms_server\bms_v8\MapleStory
Start-Process -FilePath .\GameLauncher.exe -WorkingDirectory (Get-Location) -Verb RunAs
```

Importante:

- Não abrir o jogo direto por `MapleStory.exe` para o login final.
- `GameLauncher.exe` precisa encontrar `client.dll` e `server.txt` na mesma pasta.

## 7) Contas padrão

Criadas pelo seed SQL:

- `user / admin`
- `admin / admin`

Onde:

- `admin` possui GM (`Admin = 255`).
- `user` e conta normal.

Referência:

- `Database/8-Configure.sql`

## 8) Comandos GM atuais

- `!fm` -> teleporta para FM (`910000000`)
- `!gmap` -> teleporta para mapa GM (`180000000`)
- `!exp <1-5>` -> altera rate de EXP
- `!drop <1-5>` -> altera rate de drop
- `!rs` -> recarrega scripts

Referência:

- `Extension/WvsGame/CommandParser.cpp`

## 9) Sinais de que está funcionando

- `temp/MSLog/Login_*.log` contém `Center socket connected successfully 127.0.0.1:9000`.
- `MapleStory/client.log` mostra inicialização do `client.dll`.

Exemplo de `client.log` válido:

- `Initializing client.dll, admin client: false`
- `Hook status: CREATED`
- `Client initialized`

## 10) Cuidado com encoding e scripts

- Scripts em `Server/DataSvr/Script` tem encoding misto (`Windows-1252`, EUC-KR/CP949 etc.).
- Salvar com encoding errado pode quebrar texto e lógica.

Referências:

- `docs/guias/encoding-e-tags-script.md`
- `docs/casos/sp-primeira-job-e-compensacao.md`

## 11) Documentação organizada por tema

Índice geral:

- `docs/README.md`

Categorias:

- `docs/guias` -> passo a passo operacional
- `docs/referencias` -> arquitetura e base técnica
- `docs/casos` -> histórico de incidentes e aprendizados
- `docs/planos` -> roadmap e evolução futura

Próxima fase já documentada:

- `docs/planos/proxima-fase-conteudo-e-comandos-sync.md`

## Troubleshooting rápido

### PowerShell e `start ""`

No PowerShell, use:

```powershell
Start-Process -FilePath .\MapleStory.exe -ArgumentList '127.0.0.1','8484'
```

`start "" ...` e sintaxe de `cmd`, não de PowerShell.

Obs.: para jogar, use `GameLauncher.exe`.

### Login conecta e desconecta em seguida

Se o log mostra apenas:

- `Connection accepted`
- `Client socket disconnected`
- `CheckPassword: 0 called`

ha mismatch de handshake (cliente sem patch).

Confirme:

1. `client.dll`, `GameLauncher.exe` e `server.txt` na pasta do cliente.
2. Execução via `GameLauncher.exe`.
3. Launcher em modo administrador.

### Center demora após restart

Após `docker compose restart bms_server`, aguarde o Center concluir o boot e ficar `READY=YES`.

### SP alterado no banco e não refletiu no jogo

Se `S_SP` está correto no SQL, mas o cliente continua com valor antigo:

1. Feche o cliente.
2. Limpe a sessão em `UserConnection.dbo.Connections`.
3. Reinicie `bms_server`.
4. Aguarde `READY=YES`.
5. Entre novamente.

Referência:

- `docs/casos/sp-primeira-job-e-compensacao.md`

## Observacoes

Este setup e para estudo, pesquisa técnica e preservação de software antigo.
E proibida a comercializacao, monetizacao ou qualquer uso com finalidade financeira deste material.




