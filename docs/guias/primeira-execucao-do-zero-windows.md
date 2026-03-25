# Primeira execucao do zero no Windows

## Escopo

Este guia foi feito para quem recebeu o link do repositorio e quer rodar o projeto do zero, sem conhecer o ambiente antes.

O fluxo abaixo e o caminho oficial e validado para Windows:

1. Baixar o que falta.
2. Clonar o repositorio.
3. Posicionar `Server/BinSvr` e `Server/DataSvr`.
4. Subir banco e servidor no Docker.
5. Compilar `client.dll` e `GameLauncher.exe`.
6. Preparar o cliente com `server.txt`.
7. Abrir o jogo e testar login.

## 1) O que precisa baixar antes

Baixe e instale:

1. `Git for Windows`
2. `Docker Desktop`
3. `MapleStory v08` (`mssetup_v08`)
4. Os `server files` do BMS v8
5. Build Tools do Visual Studio 2022 com toolset `v141`

Links que este projeto ja referencia:

- Cliente v08: `https://archive.org/download/maplestory_all/`
- Server files: `https://www.mediafire.com/file/z0vkal61ymwyxlw/5366a09f4e67570decdbef93468edf19.tar.bz2`

## 2) O que precisa existir na maquina

Antes de continuar, confirme:

- Windows 10 ou 11
- PowerShell funcionando
- Docker Desktop aberto
- `git` funcionando no terminal
- `winget` funcionando no terminal

Testes rapidos:

```powershell
git --version
docker --version
docker compose version
winget --version
```

## 3) Clonar o repositorio

Escolha uma pasta de trabalho e rode:

```powershell
git clone https://github.com/andrenogrib/bms-v8.git
cd bms-v8
```

Se quiser baixar tambem os submodules de tools:

```powershell
git submodule update --init --recursive
```

## 4) Preparar os server files

Depois de extrair os server files, copie o conteudo para estas duas pastas do repositorio:

- `Server/BinSvr`
- `Server/DataSvr`

Muito importante:

- Nao apague os arquivos proprios do repositorio.
- Se o arquivo ja existir e for do repo, confira antes de sobrescrever.

Arquivos criticos do repo que precisam continuar existindo:

- `docker-compose.yaml`
- `Server/start-server.sh`
- `Server/BinSvr/Patch/apply-patch.sh`
- `Server/BinSvr/Patch/WvsGame.delta`
- `Server/BinSvr/Patch/WvsLogin.delta`
- `Server/BinSvr/Patch/WvsShop.delta`

## 5) Instalar Build Tools

Rode este comando no PowerShell:

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --source winget --accept-package-agreements --accept-source-agreements --silent --override "--quiet --wait --norestart --nocache --installPath C:\BuildTools --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --includeRecommended"
```

Isso e necessario para compilar:

- `client.dll`
- `GameLauncher.exe`

## 6) Subir banco e servidor

Na raiz do repositorio:

```powershell
docker compose up -d
docker compose ps
```

Estado esperado:

- `bmsdb` -> `healthy`
- `bms_server` -> `Up`

## 7) Abrir monitoramento

Recomendado:

```powershell
.\Scripts\monitor\open-monitor.ps1 -StartServer
```

Se preferir uma janela so:

```powershell
.\Scripts\monitor\open-monitor.ps1 -SingleWindow
```

O servidor so deve ser testado quando aparecer:

- `Login->Center=YES`
- `Center(Login)=YES`
- `Center(Shop)=YES`
- `ServerPingFull=YES`
- `READY=YES`

## 8) Sobre o "erro" do SQL que seu amigo viu

Estas linhas abaixo, sozinhas, normalmente nao sao erro:

```text
Starting up database 'UserConnection'
Parallel redo is started for database 'UserConnection'
Parallel redo is shutdown for database 'UserConnection'
```

Isso costuma ser apenas o SQL Server abrindo o banco e terminando a etapa de recovery/redo.

O problema real geralmente esta em outro lugar:

- Docker Desktop nao iniciado
- `bmsdb` nao ficou `healthy`
- `bms_server` caiu logo depois
- `Server/BinSvr` ou `Server/DataSvr` incompletos
- cliente aberto sem `client.dll` / `GameLauncher.exe` / `server.txt`

## 9) Compilar `client.dll` e `GameLauncher.exe`

Na raiz do projeto:

```powershell
& "C:\BuildTools\MSBuild\Current\Bin\MSBuild.exe" "Extension\WvsApp.sln" /m /t:WvsCommon;WvsClient;WvsLauncher /p:Configuration=Release;Platform=Win32;WindowsTargetPlatformVersion=10.0.19041.0 /v:minimal
```

Saidas esperadas:

- `Extension\Release\client.dll`
- `Extension\Release\GameLauncher.exe`

Se nao encontrar `MSBuild.exe`:

```powershell
Get-ChildItem "C:\BuildTools" -Recurse -Filter MSBuild.exe | Select-Object -First 5 FullName
```

## 10) Preparar o cliente

Exemplo de pasta do cliente:

`C:\MapleStory`

Copie para a pasta do cliente:

- `Extension\Release\client.dll`
- `Extension\Release\GameLauncher.exe`

Crie o arquivo `server.txt` na mesma pasta com exatamente estas 2 linhas:

```txt
MapleStory.exe
MapleStory.exe 127.0.0.1 8484
```

## 11) Abrir o jogo do jeito certo

Entre na pasta do cliente e abra assim:

```powershell
cd C:\MapleStory
Start-Process -FilePath .\GameLauncher.exe -WorkingDirectory (Get-Location) -Verb RunAs
```

Regras importantes:

- Nao abrir por `MapleStory.exe` direto
- Sempre abrir por `GameLauncher.exe`
- `client.dll` e `server.txt` precisam ficar na mesma pasta do launcher

## 12) Logins padrao

Contas criadas pelo seed:

- `user / admin`
- `admin / admin`

Onde:

- `admin` tem `Admin = 255`
- `user` e conta normal

## 13) Como saber se deu certo

## 13.1 Servidor

```powershell
docker compose ps
```

Esperado:

- `bmsdb` healthy
- `bms_server` up

## 13.2 Login

```powershell
$f=(Get-ChildItem .\temp\MSLog\Login_*.log | Sort-Object LastWriteTime -Desc | Select-Object -First 1).FullName
Select-String -Path $f -Pattern "Center socket connected successfully"
```

## 13.3 Cliente

No `client.log` do MapleStory, espere mensagens como:

- `Initializing client.dll`
- `Hook status: CREATED`
- `Client initialized`

## 14) Comandos mais usados no dia a dia

Subir:

```powershell
docker compose up -d
```

Ver status:

```powershell
docker compose ps
```

Parar:

```powershell
docker compose down
```

Reiniciar apenas o servidor:

```powershell
docker compose restart bms_server
```

## 15) Problemas mais comuns

## 15.1 `dockerDesktopLinuxEngine` / pipe error

Causa comum:

- Docker Desktop fechado

Correcao:

1. Abrir Docker Desktop
2. Esperar ele terminar de iniciar
3. Rodar `docker compose up -d` de novo

## 15.2 Cliente trava no login

Conferir:

1. `client.dll` existe na pasta do cliente
2. `GameLauncher.exe` existe na pasta do cliente
3. `server.txt` existe e esta correto
4. O jogo esta sendo aberto pelo launcher

## 15.3 Cai ao escolher world/channel

Normalmente o Center ainda nao terminou de subir.

Espere `READY=YES` e tente de novo.

## 15.4 Banco sobe, mas servidor nao fica pronto

Conferir:

1. `Server/BinSvr` completo
2. `Server/DataSvr` completo
3. logs de `docker logs -f bms_server`
4. ultimo `Login_*.log`
5. ultimo `CenterOrion_*.log`

## 16) Caminho minimo para suporte

Se outra pessoa ainda nao conseguir rodar, peca estes 4 outputs:

1. `docker compose ps`
2. `docker logs --tail 200 bms_server`
3. ultimas 100 linhas de `temp\MSLog\Login_*.log`
4. ultimas 200 linhas de `temp\MSLog\CenterOrion_*.log`

Com isso, normalmente ja da para descobrir em que etapa travou.

## 17) Leitura complementar

Depois que o ambiente do zero funcionar, usar:

- `docs/guias/subir-servidor-e-monitoramento.md`
- `docs/guias/build-gamelauncher-e-servertxt.md`
- `docs/guias/verificar-status-servicos-center.md`
- `docs/guias/rodar-em-windows-linux-macos.md`
