# Build do GameLauncher + `server.txt` (setup completo)

Este guia explica o fluxo completo para pegar o repositorio do zero, posicionar os server files em `Server/BinSvr` e `Server/DataSvr`, compilar `client.dll` e `GameLauncher.exe`, criar `server.txt` e testar login.

## Objetivo

Ao final, voce tera:

- servidor subindo no Docker;
- `client.dll` e `GameLauncher.exe` compilados;
- cliente original iniciando pelo launcher com `server.txt`;
- login funcional no localhost.

## Pre-requisitos

- Windows com Docker Desktop funcionando.
- PowerShell.
- Cliente do jogo instalado (exemplo: `MapleStory.exe` original).
- Repositorio clonado.

## 1) Preparar estrutura do projeto

No projeto, a estrutura esperada e:

- `Server/BinSvr` -> binarios do servidor original.
- `Server/DataSvr` -> dados do servidor original.

## 1.1 Copiar server files

1. Extraia os server files que voce baixou.
2. Copie o conteudo para:
   - `Server/BinSvr`
   - `Server/DataSvr`

## 1.2 Conferir arquivos criticos do repositorio

Garanta que estes arquivos do repositorio continuam existindo:

- `Server/start-server.sh`
- `Server/BinSvr/Patch/apply-patch.sh`
- `Server/BinSvr/Patch/WvsGame.delta`
- `Server/BinSvr/Patch/WvsLogin.delta`
- `Server/BinSvr/Patch/WvsShop.delta`
- `docker-compose.yaml`

Se algum deles sumiu por sobrescrita, restaure via Git antes de continuar.

## 2) Subir banco e servidor

Na raiz do projeto:

```powershell
docker compose up -d
docker compose ps
```

Opcional (recomendado): abrir monitoramento completo:

```powershell
.\Scripts\monitor\open-monitor.ps1 -StartServer
```

Espere o ambiente ficar pronto (`READY=YES` no monitor `Login+Center`).

## 3) Instalar Build Tools (apenas 1 vez na maquina)

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --source winget --accept-package-agreements --accept-source-agreements --silent --override "--quiet --wait --norestart --nocache --installPath C:\BuildTools --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --includeRecommended"
```

## 4) Compilar `client.dll` e `GameLauncher.exe`

Na raiz do projeto:

```powershell
& "C:\BuildTools\MSBuild\Current\Bin\MSBuild.exe" "Extension\WvsApp.sln" /m /t:WvsCommon;WvsClient;WvsLauncher /p:Configuration=Release;Platform=Win32;WindowsTargetPlatformVersion=10.0.19041.0 /v:minimal
```

Saidas esperadas:

- `Extension\Release\client.dll`
- `Extension\Release\GameLauncher.exe`

## 4.1 Se nao encontrar `MSBuild.exe`

Procure o caminho instalado:

```powershell
Get-ChildItem "C:\BuildTools" -Recurse -Filter MSBuild.exe | Select-Object -First 5 FullName
```

E ajuste o comando de build com o caminho correto.

## 5) Copiar arquivos para o cliente

Exemplo de pasta do cliente:

`C:\Users\andre\Dropbox\games\ms_server\bms_v8\MapleStory`

Copiar:

- `Extension\Release\client.dll` -> `MapleStory\client.dll`
- `Extension\Release\GameLauncher.exe` -> `MapleStory\GameLauncher.exe`

## 6) Criar `server.txt`

Na pasta do cliente, crie o arquivo `server.txt` com exatamente estas 2 linhas:

```txt
MapleStory.exe
MapleStory.exe 127.0.0.1 8484
```

## 7) Abrir o jogo do jeito certo

Na pasta do cliente:

```powershell
cd C:\Users\andre\Dropbox\games\ms_server\bms_v8\MapleStory
Start-Process -FilePath .\GameLauncher.exe -WorkingDirectory (Get-Location) -Verb RunAs
```

Regras:

- Nao abrir direto por `MapleStory.exe`.
- Sempre abrir por `GameLauncher.exe`.
- `client.dll` e `server.txt` precisam estar na mesma pasta do launcher.

## 8) Validacao rapida

## 8.1 Validar servidor

```powershell
docker compose ps
```

Esperado:

- `bmsdb` healthy
- `bms_server` up

## 8.2 Validar log de login

```powershell
$f=(Get-ChildItem .\temp\MSLog\Login_*.log | Sort-Object LastWriteTime -Desc | Select-Object -First 1).FullName
Select-String -Path $f -Pattern "Center socket connected successfully"
```

## 8.3 Validar cliente

No `MapleStory\client.log`, espere linhas como:

- `Initializing client.dll`
- `Hook status: CREATED`
- `Client initialized`

## 9) Troubleshooting rapido

## 9.1 Trava no login / conecta e cai

Confira:

1. Esta abrindo pelo `GameLauncher.exe`.
2. `client.dll` existe na pasta do cliente.
3. `server.txt` tem as duas linhas corretas.
4. Servidor esta `READY=YES`.

## 9.2 Erro na selecao de world/channel

Geralmente o Center ainda esta carregando. Aguarde `READY=YES` e tente de novo.

## 9.3 Mudou SQL e nao refletiu no jogo

Feche cliente, reinicie `bms_server`, aguarde `READY=YES`, e so entao relogue.

## 10) Fluxo resumido (checklist)

1. Copiar server files para `Server/BinSvr` e `Server/DataSvr`.
2. `docker compose up -d`.
3. Aguardar `READY=YES`.
4. Buildar `client.dll` + `GameLauncher.exe`.
5. Copiar os dois para a pasta do cliente.
6. Criar `server.txt`.
7. Abrir por `GameLauncher.exe` como admin.
