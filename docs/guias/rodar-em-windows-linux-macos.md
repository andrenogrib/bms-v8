# Rodar o projeto em Windows, Linux e macOS

## Escopo

Este guia explica como executar o projeto em 3 sistemas operacionais:

- Windows (fluxo completo: servidor + build de patch + cliente).
- Linux (servidor completo; cliente via Wine ou maquina Windows separada).
- macOS (servidor completo; com observacao especial para Apple Silicon).

Tambem cobre o que muda entre local host e jogar com amigos em outra maquina.

## 1) Matriz de suporte real

| Componente | Windows | Linux | macOS Intel | macOS Apple Silicon |
|---|---|---|---|---|
| Servidor (`docker compose`) | Sim | Sim | Sim | Sim, com emulacao `linux/amd64` |
| Banco SQL (container `bmsdb`) | Sim | Sim | Sim | Sim, com emulacao `linux/amd64` |
| Monitoramento `Scripts/monitor/*.ps1` | Sim (nativo) | Parcial (PowerShell 7) | Parcial (PowerShell 7) | Parcial (PowerShell 7) |
| Build `client.dll` + `GameLauncher.exe` | Sim (oficial) | Nao suportado nativamente | Nao suportado nativamente | Nao suportado nativamente |
| Cliente MapleStory | Sim (oficial) | Via Wine (experimental) | Via Wine/CrossOver (experimental) | Via CrossOver/Wine + emulacao (experimental) |

Resumo:

- O servidor e cross-platform via Docker.
- O patch de cliente e o fluxo mais estavel continuam Windows-first.

## 2) Pre-requisitos comuns

1. Repo clonado.
2. Server files posicionados:
   - `Server/BinSvr`
   - `Server/DataSvr`
3. Docker funcionando.
4. Portas disponiveis no host:
   - `8484`
   - `8585-8589`
   - `8787`
   - `1433` (SQL, so para administracao local/remota de banco)

## 3) Windows (fluxo completo recomendado)

## 3.1 Subir servidor

Na raiz do projeto:

```powershell
docker compose up -d
docker compose ps
```

Monitoramento (4 janelas):

```powershell
.\Scripts\monitor\open-monitor.ps1 -StartServer
```

Janela unica:

```powershell
.\Scripts\monitor\open-monitor.ps1 -SingleWindow
```

## 3.2 Build do patch do cliente

Instalar Build Tools (uma vez):

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --source winget --accept-package-agreements --accept-source-agreements --silent --override "--quiet --wait --norestart --nocache --installPath C:\BuildTools --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --includeRecommended"
```

Compilar:

```powershell
& "C:\BuildTools\MSBuild\Current\Bin\MSBuild.exe" "Extension\WvsApp.sln" /m /t:WvsCommon;WvsClient;WvsLauncher /p:Configuration=Release;Platform=Win32;WindowsTargetPlatformVersion=10.0.19041.0 /v:minimal
```

Saidas esperadas:

- `Extension\Release\client.dll`
- `Extension\Release\GameLauncher.exe`

## 3.3 Preparar cliente

Copiar para a pasta do client:

- `client.dll`
- `GameLauncher.exe`

Criar `server.txt`:

```txt
MapleStory.exe
MapleStory.exe 127.0.0.1 8484
```

Abrir sempre pelo launcher:

```powershell
Start-Process -FilePath .\GameLauncher.exe -WorkingDirectory (Get-Location) -Verb RunAs
```

## 4) Linux (servidor nativo)

## 4.1 Instalar Docker Engine + Compose plugin

Exemplo Ubuntu/Debian (resumo):

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
```

## 4.2 Subir servidor

Na raiz do projeto:

```bash
docker compose up -d
docker compose ps
```

## 4.3 Monitorar sem PowerShell

Status basico:

```bash
watch -n 2 docker compose ps
```

Se `watch` nao existir no sistema:

```bash
while true; do
  clear
  date
  docker compose ps
  sleep 2
done
```

Logs do servidor:

```bash
docker logs -f bms_server
```

Checagem rapida de pronto (READY manual):

```bash
grep -E "Center socket connected successfully|Local server connected successfully Login|Local server connected successfully Shop0Orion|ServerPing:" temp/MSLog/Login_*.log temp/MSLog/CenterOrion_*.log
```

## 4.4 Cliente no Linux

Opcoes:

1. Rodar cliente em maquina Windows separada (mais estavel).
2. Rodar cliente via Wine (experimental).

Importante:

- Build de `client.dll` e `GameLauncher.exe` nao e suportado nativamente no Linux neste projeto.
- Se estiver no Linux, compile esses binarios em Windows e copie para a pasta do cliente.

## 5) macOS (servidor nativo com Docker Desktop)

## 5.1 macOS Intel

Fluxo igual ao Linux:

```bash
docker compose up -d
docker compose ps
docker logs -f bms_server
```

## 5.2 macOS Apple Silicon (M1/M2/M3)

Este projeto usa imagens `amd64` (confirmado nos images atuais), entao execute emulacao x86_64:

```bash
export DOCKER_DEFAULT_PLATFORM=linux/amd64
docker compose build --no-cache bms_server
docker compose up -d
docker compose ps
```

Opcao mais estavel: criar `docker-compose.override.yaml` com:

```yaml
services:
  bmsdb:
    platform: linux/amd64
  bms_sidecar:
    platform: linux/amd64
  bms_server:
    platform: linux/amd64
```

Depois:

```bash
docker compose up -d --build
```

## 5.3 Cliente no macOS

Opcoes:

1. Cliente em maquina Windows separada (recomendado).
2. CrossOver/Wine no macOS (experimental).

Build do patch continua Windows-first.

## 6) Jogar com amigos (host em qualquer SO)

## 6.1 Rede e portas

Abra/encaminhe no roteador/firewall:

- `8484` (login)
- `8585-8589` (channels)
- `8787` (shop)

## 6.2 Resolucao de host no cliente

Por padrao, os arquivos de configuracao usam nomes como `bms_server` e `bms_public`.
No computador de cada jogador, ajuste `hosts`:

- Windows: `C:\Windows\System32\drivers\etc\hosts`
- Linux/macOS: `/etc/hosts`

Exemplo (troque pelo IP do servidor):

```text
203.0.113.10 bms_server
203.0.113.10 bms_public
```

## 6.3 `server.txt` para cliente remoto

Use IP publico do host:

```txt
MapleStory.exe
MapleStory.exe 203.0.113.10 8484
```

## 7) Sinal de ambiente pronto

Considere pronto quando:

1. `docker compose ps` mostra `bmsdb` healthy e `bms_server` up.
2. Login log contem `Center socket connected successfully 127.0.0.1:9000`.
3. Center log contem:
   - `Local server connected successfully Login`
   - `Local server connected successfully Shop0Orion`
   - `ServerPing` com `Login` e `Game0..Game4` e `Shop0Orion`.

## 8) Troubleshooting por SO

## 8.1 Windows

- Erro `dockerDesktopLinuxEngine`:
  - Docker Desktop nao iniciado.
- Cliente trava no login:
  - verificar `client.dll`, `GameLauncher.exe`, `server.txt`, e abrir via launcher.

## 8.2 Linux/macOS

- `exec format error` ou falha em imagem:
  - forcar `linux/amd64`.
- Falha de login de jogador remoto:
  - revisar portas e `hosts` (`bms_server`/`bms_public`).

## 9) Regra de deploy continua igual

- `.s` -> `!rs` costuma bastar.
- `.img` -> reiniciar `bms_server`.
- `wvsgm.dll` -> rebuild + copiar + reiniciar `bms_server`.
