# Monitoramento em 4 janelas PowerShell

Painel operacional local para acompanhar:

- saude dos containers
- readiness de Login/Center
- contas online
- logs de debug do container

Todos os watchers foram configurados em modo sem flicker:

- sem `Clear-Host`
- atualizacao por append
- `Login+Center` com stream de novas linhas + status de readiness

## Tempo real vs polling

- `watch-debug.ps1`: realtime de verdade (`docker logs -f`).
- `watch-login-center.ps1`: quase realtime, com leitura continua de novas linhas nos logs e avaliacao de readiness a cada ciclo.
- `watch-health.ps1` e `watch-players.ps1`: polling controlado por `-RefreshSeconds` (padrão `2`), sem limpar tela.

Com isso, o terminal não fica piscando e você ainda acompanha tudo ao vivo.

## Scripts

Arquivos em `Scripts/monitor`:

- `open-monitor.ps1` (orquestrador)
- `watch-health.ps1`
- `watch-login-center.ps1`
- `watch-players.ps1`
- `watch-debug.ps1`
- `watch-dashboard.ps1` (modo single window)

## O que cada janela mostra

1. `BMS Health`
- estado dos containers (`docker compose ps`)
- indicador `bmsdb healthy`, `bms_server up`, `overall ready`
- imprime quando estado muda + heartbeat periodico

2. `BMS Login+Center`
- novas linhas de `Login_*.log` e `CenterOrion_*.log`
- linha `[STATUS]` com:
  - `Login->Center`
  - `Center(Login)`
  - `Center(Shop)`
  - `ServerPingFull`
  - `READY`

3. `BMS Players`
- contas online de `UserConnection.dbo.Connections`
- personagens das contas conectadas
- imprime snapshot apenas quando muda

4. `BMS Debug`
- stream continuo de `docker logs -f bms_server`
- reinicia stream automaticamente se encerrar

## Uso rápido

No root do projeto:

```powershell
# So monitorar (4 janelas)
.\Scripts\monitor\open-monitor.ps1

# Subir servidor e abrir monitor
.\Scripts\monitor\open-monitor.ps1 -StartServer

# Modo single window (opcional)
.\Scripts\monitor\open-monitor.ps1 -SingleWindow

# Trocar intervalo de refresh (default: 2s)
.\Scripts\monitor\open-monitor.ps1 -RefreshSeconds 2
```

Parametros disponiveis em `open-monitor.ps1`:

- `-StartServer`: roda `docker compose up -d` antes de abrir os monitores
- `-SingleWindow`: usa dashboard unico em vez de 4 janelas
- `-RefreshSeconds <n>`: intervalo de atualizacao para watchers de polling

## O que significa "pronto para logar"

Checklist:

1. `bmsdb` em `healthy` e `bms_server` em `Up` na janela Health.
2. Janela Login+Center com:
   - linha `[STATUS]` contendo:
     - `Login->Center=YES`
     - `Center(Login)=YES`
     - `Center(Shop)=YES`
     - `ServerPingFull=YES`
     - `READY=YES`
3. Se `READY=YES`, pode logar.

Quando isso aparece, pode abrir o cliente sem pressa.

## Observacao validada

No fluxo testado, bastou esperar o boot completar.

Não foi necessário limpar `UserConnection.dbo.Connections` nem reiniciar o `bms_server` de novo.

## Encerrar monitores

- Feche cada janela PowerShell, ou use `Ctrl+C` em cada uma.
- Isso não para os containers.


