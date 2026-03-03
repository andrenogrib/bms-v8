# Subir servidor e usar monitoramento

Este guia centraliza o fluxo diário para iniciar, validar, monitorar e parar o servidor.

## Pré-requisitos

- Docker Desktop em execução.
- Projeto aberto na raiz: `bms-v8`.
- PowerShell no diretório do projeto.

## 1) Subir o servidor

```powershell
docker compose up -d
```

Se quiser subir e abrir o monitoramento ao mesmo tempo:

```powershell
.\Scripts\monitor\open-monitor.ps1 -StartServer
```

## 2) Ver status dos containers

```powershell
docker compose ps
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Esperado:

- `bmsdb` => `healthy`
- `bms_server` => `Up`

## 3) Monitoramento em tempo real

## 3.1 Modo multi-janela (recomendado)

Abre 4 janelas PowerShell:

- Health
- Login+Center
- Players
- Debug

```powershell
.\Scripts\monitor\open-monitor.ps1
```

Com intervalo customizado:

```powershell
.\Scripts\monitor\open-monitor.ps1 -RefreshSeconds 2
```

## 3.2 Modo janela única

```powershell
.\Scripts\monitor\open-monitor.ps1 -SingleWindow
```

## 3.3 Scripts individuais

```powershell
.\Scripts\monitor\watch-health.ps1
.\Scripts\monitor\watch-login-center.ps1
.\Scripts\monitor\watch-players.ps1
.\Scripts\monitor\watch-debug.ps1
```

## 4) Sinal de pronto (READY)

Você pode logar com segurança quando o `watch-login-center.ps1` mostrar:

- `Login->Center=YES`
- `Center(Login)=YES`
- `Center(Shop)=YES`
- `ServerPingFull=YES`
- `READY=YES`

## 5) Ver logs rapidamente

Último log de Login:

```powershell
$f=(Get-ChildItem .\temp\MSLog\Login_*.log | Sort-Object LastWriteTime -Desc | Select-Object -First 1).FullName
Get-Content $f -Wait
```

Último log de Center:

```powershell
$c=(Get-ChildItem .\temp\MSLog\CenterOrion_*.log | Sort-Object LastWriteTime -Desc | Select-Object -First 1).FullName
Get-Content $c -Wait
```

Logs do container de servidor:

```powershell
docker logs -f bms_server
```

## 6) Parar e reiniciar

Parar tudo:

```powershell
docker compose down
```

Reiniciar apenas o servidor do jogo:

```powershell
docker compose restart bms_server
```

Depois do restart, aguarde novamente `READY=YES` antes de abrir o cliente.

## 7) Regra operacional

- Não testar login enquanto o Center ainda estiver carregando.
- Após alterações SQL relevantes, reiniciar `bms_server` e aguardar `READY=YES`.
- Para script `.s`, `!rs` costuma bastar.
- Para `.img` e `wvsgm.dll`, reiniciar `bms_server`.


