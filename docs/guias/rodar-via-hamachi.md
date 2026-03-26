# Rodar via Hamachi

## Escopo

Este guia documenta o fluxo que usamos para fazer o servidor funcionar via Hamachi, permitindo que amigos entrem de fora sem mexer no banco existente.

## 1) Objetivo

Usar o servidor atual com:

- banco local existente preservado;
- `bms_server` funcionando normalmente dentro do container;
- clientes remotos conectando pelo IP do Hamachi;
- login, channel e cash shop acessiveis pela rede Hamachi.

## 2) Arquivo usado

Foi criado um compose dedicado:

- `docker-compose.hamachi.yaml`

Arquivo atual:

```yaml
version: "3.9"
x-extra-hosts: &extra_hosts
  - "bms_server:127.0.0.1"
  - "bms_public:25.37.146.205"
```

Ponto mais importante:

- `bms_server` deve continuar em `127.0.0.1`
- `bms_public` deve apontar para o IP do Hamachi do host

Motivo:

- `bms_server` e usado para bind interno do login/game/shop no container
- `bms_public` e o IP anunciado para os clientes remotos

Quando `bms_server` foi apontado para o IP Hamachi, o `WvsLogin` falhou com:

- `Failed in initializing socket acceptor`

## 3) Como subir em modo Hamachi

Na raiz do projeto:

```powershell
docker compose -f docker-compose.hamachi.yaml down
docker compose -f docker-compose.hamachi.yaml up -d
docker compose -f docker-compose.hamachi.yaml ps
```

Importante:

- `docker compose down` nao apaga o banco
- nao usar `docker compose down -v`

## 4) Banco existente nao foi perdido

O banco continua preservado porque o `bmsdb` usa bind mount na pasta:

- `./temp`

Ou seja:

- seus MDF/LDF e arquivos de estado continuam no disco local
- mudar entre `docker-compose.yaml` e `docker-compose.hamachi.yaml` nao reseta o banco

## 5) Como validar o DNS interno no container

Depois de subir:

```powershell
docker exec bms_server getent hosts bms_server
docker exec bms_server getent hosts bms_public
```

Esperado:

- `bms_server` -> `127.0.0.1`
- `bms_public` -> `25.37.146.205`

## 6) Portas que precisam estar acessiveis

No host:

- `8484` -> login
- `8585-8589` -> channels
- `8787` -> cash shop

## 7) Comandos de firewall no PowerShell

Executar em PowerShell como administrador.

### 7.1 Liberar um IP especifico

Exemplo para um amigo:

```powershell
$friendIp = '25.47.248.221'

$rules = @(
  @{ Name = 'BMS Hamachi Login 8484'; Ports = '8484' },
  @{ Name = 'BMS Hamachi Channels 8585-8589'; Ports = '8585-8589' },
  @{ Name = 'BMS Hamachi Shop 8787'; Ports = '8787' }
)

foreach ($rule in $rules) {
  $existing = Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
  if ($existing) {
    Remove-NetFirewallRule -DisplayName $rule.Name
  }

  New-NetFirewallRule `
    -DisplayName $rule.Name `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort $rule.Ports `
    -RemoteAddress $friendIp `
    -Action Allow `
    -Profile Any
}
```

### 7.2 Liberar mais de um IP

Exemplo com dois amigos:

```powershell
$friendIps = @(
  '25.47.248.221',
  '25.53.47.114'
)

$rules = @(
  @{ Name = 'BMS Hamachi Login 8484'; Ports = '8484' },
  @{ Name = 'BMS Hamachi Channels 8585-8589'; Ports = '8585-8589' },
  @{ Name = 'BMS Hamachi Shop 8787'; Ports = '8787' }
)

foreach ($rule in $rules) {
  $existing = Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
  if ($existing) {
    Remove-NetFirewallRule -DisplayName $rule.Name
  }

  New-NetFirewallRule `
    -DisplayName $rule.Name `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort $rule.Ports `
    -RemoteAddress $friendIps `
    -Action Allow `
    -Profile Any
}
```

### 7.3 Conferir as regras

```powershell
Get-NetFirewallRule -DisplayName 'BMS Hamachi*' | Get-NetFirewallAddressFilter | Format-Table -AutoSize
Get-NetFirewallRule -DisplayName 'BMS Hamachi*' | Get-NetFirewallPortFilter | Format-Table -AutoSize
```

## 8) Como testar a conectividade

No computador do amigo:

```powershell
Test-NetConnection 25.37.146.205 -Port 8484
Test-NetConnection 25.37.146.205 -Port 8585
Test-NetConnection 25.37.146.205 -Port 8787
```

Interpretacao:

- `8484` falhou -> nao chega nem no login
- `8585` falhou -> pode logar, mas cair ao escolher canal
- `8787` falhou -> pode jogar, mas cash shop tende a falhar

## 9) Cliente que foi enviado para o amigo

O fluxo que usamos foi mandar a pasta do MapleStory ja pronta, contendo:

- `MapleStory.exe`
- `client.dll`
- `GameLauncher.exe`
- `server.txt`

Isso reduz muito erro de setup no computador remoto.

## 10) `server.txt` do amigo

No cliente remoto:

```txt
MapleStory.exe
MapleStory.exe 25.37.146.205 8484
```

## 11) Como abrir o cliente remoto

No computador do amigo:

- abrir pelo `GameLauncher.exe`
- nao abrir por `MapleStory.exe` direto

Se o launcher e o patch estiverem corretos, o `client.log` deve mostrar:

- `Initializing client.dll`
- `Hook status: CREATED`
- `Client initialized`

## 12) Fluxo de validacao recomendado

1. Subir o servidor com `docker-compose.hamachi.yaml`
2. Confirmar `bms_server` e `bms_public` no container
3. Liberar as portas para os IPs do Hamachi no firewall
4. Pedir para o amigo testar `Test-NetConnection`
5. So depois pedir para ele abrir o jogo
6. Acompanhar `temp/MSLog/Login_*.log`

## 13) Como interpretar os logs

### 13.1 Se nao aparece `Connection accepted`

Problema de:

- rede
- firewall
- Hamachi

### 13.2 Se aparece `Connection accepted` e logo depois `Client socket disconnected`

Problema mais provavel de:

- cliente sem patch correto
- `client.dll` nao injetado
- `GameLauncher.exe` nao usado
- `server.txt` errado

### 13.3 Se loga e cai ao escolher canal

Problema mais provavel de:

- portas `8585-8589` bloqueadas
- IP anunciado errado

### 13.4 Se entra no jogo e o cash shop falha

Problema mais provavel de:

- porta `8787` bloqueada

## 14) Reiniciar so o servidor do jogo

```powershell
docker compose -f docker-compose.hamachi.yaml restart bms_server
```

Depois esperar `READY=YES`.
