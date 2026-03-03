# BMS v8: arquitetura e lógica completa

Data de referência desta análise: 2026-03-01.

Este documento consolida a visao técnica completa do projeto, incluindo:

- como os componentes sobem e se conectam
- como cliente, servidor e banco conversam
- qual o papel de cada pasta importante
- como os patches de extensao funcionam
- como o SQL foi modelado
- como operar e alterar com seguranca

## 1) Objetivo e escopo

Este setup existe para estudo, pesquisa técnica e preservacao de software antigo.

O projeto recria um ambiente funcional de BMS v8 usando:

- runtime Windows antigo rodando em Linux via Wine (Docker)
- binários originais do servidor em `Server/BinSvr`
- dados de jogo em `Server/DataSvr`
- schema/procedures SQL reconstruidos em `Database`
- patchs C++/C# em `Extension` para compatibilizar handshake/protocolo/fluxo moderno de execucao

## 2) Mapa do repositório

Pastas principais:

- `Server/`
- `Database/`
- `Extension/`
- `Scripts/`
- `docs/`
- `temp/`

### `Server/`

- `Server/BinSvr`: executaveis e DLLs do servidor (`WvsLogin.exe`, `WvsCenter.exe`, `WvsGame.exe`, `WvsShop.exe` etc).
- `Server/BinSvr/Patch`: delta patches aplicados nos EXEs para carregar DLLs de extensao.
- `Server/DataSvr`: dados de jogo, configurações `.img`, scripts `.s`.
- `Server/Win32`: bootstrap antigo via `.bat` (ordem historica de inicialização).
- `Server/start-server.sh`: startup no container `bms_server`.

### `Database/`

Scripts SQL numerados, de bootstrap e schema:

- `1-CreateDatabases.sql`
- `2-CreateUsers.sql`
- `3-UserConnection.sql`
- `4-GlobalAccount.sql`
- `5-Coupon.sql`
- `6-Claim.sql`
- `7-GameWorld.sql`
- `8-Configure.sql`
- `9-Reset.sql`

### `Extension/`

Projetos C++/C# de patch:

- `WvsClient` -> gera `client.dll`
- `WvsLauncher` -> gera `GameLauncher.exe`
- `WvsGame` -> gera `wvsgm.dll`
- `WvsLogin` -> gera `wvslg.dll`
- `WvsShop` -> gera `wvssh.dll`
- `WvsCashDeamon` -> daemon TCP para fluxos de cash shop
- `WvsCommon` -> biblioteca comum de hooks/packets/estruturas

### `Scripts/`

- scripts de banco (`start-database.sh`, `db-healthcheck.sh`, `clean-world.sh`)
- painel de monitoramento (`Scripts/monitor/*.ps1`)

## 3) Arquitetura de runtime (containers)

Definicao central:

- `docker-compose.yaml`

Servicos:

1. `bmsdb` (SQL Server)
2. `bms_sidecar` (cleanup inicial)
3. `bms_server` (Wine + processos do game server)

### `bmsdb`

- sobe SQL Server
- executa `Scripts/start-database.sh`
- cria estrutura SQL no primeiro start (via marcador `started`)
- exposicao de porta `1433`

### `bms_sidecar`

- depende de `bmsdb` healthy
- executa `Scripts/clean-world.sh`
- chama `Database/9-Reset.sql` para limpar `GlobalAccount.dbo.GameWorld.CenterAddress`

### `bms_server`

- build pelo `Dockerfile`
- monta `Server/BinSvr`, `Server/DataSvr` e `temp/MSLog`
- executa `Server/start-server.sh`
- publica:
  - `8484` (login)
  - `8585..8589` (channels)
  - `8787` (shop)

## 4) Sequencia de boot real

Arquivo: `Server/start-server.sh`.

Passos:

1. sobe Xvfb
2. roda `winetricks mdac28`
3. entra em `C:\\Server\\BinSvr`
4. aplica patch em EXEs (`Patch/apply-patch.sh`)
5. inicia `WvsCashDeamon.exe`
6. inicia `WvsLogin.exe`
7. inicia `WvsGame.exe` para `Game0Orion..Game4Orion`
8. inicia `WvsShop.exe`
9. inicia `WvsCenter.exe` em foreground

Comportamento esperado:

- no inicio, Login/Game/Shop podem logar falhas de conexão com Center
- quando Center termina carga (item/map/fieldset), os demais serviços conectam

## 5) Topologia de rede e configuração

Arquivos ativos principais:

- `Server/DataSvr/Login.img`
- `Server/DataSvr/CenterOrion.img`
- `Server/DataSvr/Game0Orion.img` .. `Game4Orion.img`
- `Server/DataSvr/Shop0Orion.img`

Configuracao local validada:

- `Login -> Center`: `localhost:9000`
- `Center` anuncia endpoints de login/game/shop usando hostnames docker (`bms_public` / `bms_server` / `localhost`)
- channels `Game0..Game4` em `8585..8589`
- shop em `8787`

## 6) Por que launcher + client.dll sao obrigatorios

Fluxo validado:

1. abrir jogo pelo `GameLauncher.exe`
2. `GameLauncher` cria processo suspenso do client
3. injeta `client.dll` via `CreateRemoteThread + LoadLibraryA`
4. so depois resume o processo

Sem isso, handshake/protocolo tende a quebrar no login (aceita conexão e desconecta/trava).

Arquivos:

- `Extension/WvsLauncher/Source.cpp`
- `Extension/WvsClient/Entrypoint.cpp`

## 7) O que os patches fazem (resumo por modulo)

## 7.1 `WvsCommon`

Base utilitaria:

- hook de opcode/call/jmp (`Hook.*`)
- serializacao de pacote (`CInPacket`, `COutPacket`)
- ajuste de header/region em buffer (`ZSocketEx`)
- chave AES custom (`AesKey`)

## 7.2 `WvsClient` (`client.dll`)

Pontos principais:

- bypass de checks/client guard
- patch de AES no client
- hook de envio/recebimento em `CClientSocket`
- ajuste de `StringPool` (ex.: string de versão UI)
- suporte a janela e mutex handling

Resultado pratico:

- cliente original passa a falar o protocolo esperado pelo servidor patchado.

## 7.3 `WvsLogin` (`wvslg.dll`)

- patcha AES/header/version checks
- hooka fluxo de seleção de mundo
- valida contexto admin client vs grade da conta

## 7.4 `WvsGame` (`wvsgm.dll`)

- patcha AES/header/version checks
- hooka chat para comandos GM custom:
  - `!fm`
  - `!gmap`
  - `!exp`
  - `!drop`
  - `!rs`
- inclui mitigacoes de crash/exploit em pontos especificos (packet handling, miniroom/scroll/personal shop etc)

## 7.5 `WvsShop` (`wvssh.dll`)

- patcha AES/header/version checks
- integra com cash daemon

## 7.6 `WvsCashDeamon`

Servico TCP que atende requisicoes de cash shop:

- consulta saldo em `GlobalAccount.dbo.Account.NexonCash`
- aprova/rejeita compra
- debita saldo

## 8) DataSvr: dados e scripts

`Server/DataSvr` contém duas grandes classes de conteúdo:

1. dados estruturais de jogo (`Map`, `Mob`, `Item`, `Character`, `Skill` etc)
2. lógica de script (`Script/*.s`)

Tamanho e densidade relevantes (aprox):

- `Mob`: ~163 MB
- `Character`: ~118 MB
- `Map`: ~49 MB
- `Skill`: ~40 MB
- `Script`: 80+ arquivos

Observacoes:

- parte dos `.img` e texto parseavel
- parte dos `.img` e binário proprietario (não editar como texto)
- scripts `.s` podem usar encoding legado (geralmente `Windows-1252`)

Referencia de API de script:

- `Server/DataSvr/Script/standard.s`

Esse arquivo define funções base como:

- `target.incSP`, `target.incMoney`, `inventory.incSlotCount`
- `target.isMaster`, `target.isSuperGM`, `target.IsClosedBetaTester`
- `currentTime`, `compareTime`, `serverType`

## 9) Banco de dados: modelo logico

## 9.1 Bancos e papeis

- `GlobalAccount`: contas, autenticacao, flags, pin, NX/MaplePoint
- `UserConnection`: conexoes online e lock de sessão
- `GameWorld`: personagens, inventario, trunk, quests, guild, cash items
- `Claim`: trilha de denuncias/logs de itens
- `Coupon`: cupons

## 9.2 Snapshot do ambiente em execucao (2026-03-01)

- `GlobalAccount`: 10 tabelas / 14 procedures
- `GameWorld`: 62 tabelas / 61 procedures
- `UserConnection`: 1 tabela / 4 procedures
- `Coupon`: 1 tabela / 0 procedures
- `Claim`: 3 tabelas / 4 procedures

Contas atuais observadas:

- `user` (Admin=0, AccountFlags=1)
- `admin` (Admin=0)

## 9.3 Tabelas chave

### `GlobalAccount.dbo.Account`

Campos relevantes:

- `AccountName`
- `PasswordHash`
- `Pin`
- `Admin`
- `NeedVerification`
- `AccountFlags`
- `NexonCash`
- `maplePoint`

### `UserConnection.dbo.Connections`

Sessao ativa:

- `AccountID`
- `ChannelID`
- `IPStr`

### `GameWorld.dbo.Character`

Estado base do personagem:

- `CharacterID`, `AccountID`, `WorldID`
- `CharacterName`
- job/level/stats (`B_Job`, `B_Level`, `S_SP`, `S_Money` etc)
- `P_Map`

### Inventario e storage

- `GameWorld.dbo.ItemSlot_Size` (slots de inventario por personagem)
- `GameWorld.dbo.Trunk` (storage por conta)

## 9.4 Procedures chave

Autenticacao/sessão:

- `GlobalAccount.dbo.CheckPassword`
- `UserConnection.dbo.TrySetUserConnect`
- `UserConnection.dbo.SetUserDisconnect`
- `UserConnection.dbo.ClearWorldConnect`

Criacao de personagem:

- `GameWorld.dbo.CreateNewCharacter`
  - cria personagem
  - seta inventario inicial
  - inicializa trunk se necessário

Slots/storage:

- `GameWorld.dbo.InventorySize_Get`
- `GameWorld.dbo.InventorySize_Set`
- `GameWorld.dbo.IncreaseItemSlotCount`
- `GameWorld.dbo.IncreaseTrunkCount`

Cash:

- `GameWorld.dbo.BuyCashItem`
- `GameWorld.dbo.UseCashItem`

## 10) Fluxos ponta a ponta

## 10.1 Login

1. client inicia via launcher+DLL
2. conecta em `8484` (Login)
3. Login valida credenciais no `GlobalAccount`
4. Login conversa com Center e recebe estado de mundo/channels
5. cliente seleciona world/channel/char

## 10.2 Selecao de personagem e migracao

1. Login valida/marca sessão
2. Center roteia para canal (`GameXOrion`)
3. `WvsGame` carrega estado completo do char no `GameWorld`

## 10.3 Cash shop

1. cliente entra em shop
2. Shop conversa com CashDaemon (`36091`)
3. CashDaemon consulta/debita `NexonCash`
4. Shop confirma compra

## 11) Observabilidade e readiness

Logs principais:

- `temp/MSLog/Login_*.log`
- `temp/MSLog/CenterOrion_*.log`
- `temp/MSLog/Game*_*.log`
- `temp/MSLog/Shop0Orion_*.log`

Sinais de pronto:

- Login: `Center socket connected successfully`
- Center: `Local server connected successfully Login`
- Center: `Local server connected successfully Game0..Game4`
- Center: `Local server connected successfully Shop0Orion`
- `ServerPing` contendo todos os serviços

Ferramenta pronta no projeto:

- `Scripts/monitor/open-monitor.ps1`

## 12) Operacao segura (pratica recomendada)

Para alterações SQL que impactam estado in-game:

1. fechar client
2. aplicar SQL
3. validar no banco
4. reiniciar `bms_server` se necessário para descarregar estado em memoria
5. aguardar readiness completa
6. reabrir client

Quando logar cedo (antes do READY), e comum queda/DC na seleção de servidor/canal.

## 13) Riscos e limitacoes tecnicas

1. Hooks por endereco fixo: se trocar EXE base, offsets podem invalidar.
2. Arquivos `.img` binários: edicao textual indevida pode corromper.
3. Encoding legado em scripts: salvar com encoding errado pode quebrar texto/parse.
4. Credenciais/hash legado: não expor publicamente.
5. Stack Wine antiga: warnings de compatibilidade existem, mas nem sempre sao falha funcional.

## 14) Checklist rápido de diagnostico

Se travar no login:

1. confirmar `client.dll`, `GameLauncher.exe`, `server.txt` na pasta do client
2. abrir pelo `GameLauncher.exe` como admin
3. validar logs `Login` e `Center`

Se cair na seleção de canal:

1. confirmar se todos Game servers conectaram no Center
2. aguardar `ServerPing` completo

Se dado SQL "não refletir" no jogo:

1. fechar client
2. confirmar update em SQL
3. reiniciar `bms_server`
4. aguardar readiness
5. logar de novo

## 15) Relacao com os demais docs

Use este arquivo como "visao macro". Para operacao diaria, use os guias especificos em:

- `docs/README.md`
- `docs/guias/verificar-status-servicos-center.md`
- `docs/guias/monitoramento-operacao.md`
- `docs/guias/sql-alteracoes-restart-e-validacao.md`
- `docs/guias/alterar-slots-inventario-storage.md`
- `docs/referencias/gm-supergm-dev-comandos.md`




