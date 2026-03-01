# Eventos de aniversario: camadas, comportamento e plano futuro

Data da analise: 2026-03-01

Este documento consolida o que foi aprendido sobre ativacao de eventos (principalmente aniversario) no BMS v8 deste repositorio, com foco em seguranca operacional e baixo risco.

## Objetivo

- Entender o que realmente muda no jogo ao "ativar aniversario".
- Separar o que e controle de script, o que e controle global de rate/evento e o que depende de dados binarios.
- Evitar mexer em client/WZ sem necessidade.
- Deixar um plano futuro claro, reversivel e com checkpoints.

## Resumo executivo

- Ativar somente os scripts de aniversario abre fluxo de NPC/quest/troca com itens de evento.
- Isso nao garante, por si so, que todos os mobs comecem a dropar itens de aniversario.
- Existem camadas adicionais no servidor para eventos/rates globais.
- Alterar client/WZ nao e passo inicial recomendado para resolver drop de mob em ambiente localhost.

## Arquitetura de eventos (visao pratica)

### Camada 1: scripts de NPC/quest

Arquivos principais:

- `Server/DataSvr/Script/event1.s`
- `Server/DataSvr/Script/GLevent.s`

Pontos relevantes confirmados:

- `script "4th_mapleWeapon"` em `event1.s`:
  - troca de Maple Leaf (`4001126`) + armas base por armas de aniversario;
  - possui janela de data antiga (`compareTime`) para liberar/bloquear fluxo.
- `script "q9809e"` em `event1.s`:
  - usa `4001126` para recompensa/buff e marca quest state (`9809`).
- `script "q9800e"` em `event1.s`:
  - entrega `4001126` como parte do fluxo de quest/level e marca state (`9800`).
- `script "2nd_birthday"` em `GLevent.s`:
  - tambem data-driven, com troca de item de aniversario (`4031306`).

Conclusao da camada 1:

- Essa camada controla interacoes e recompensas de NPC/quest.
- Ela nao e prova suficiente de que drop global de mob foi ativado.

### Camada 2: evento/rate global no servidor

Indicadores no codigo:

- `Extension/WvsLogin/CCenter.h` tem campos:
  - `m_nWorldState_WSE`
  - `m_sWorldEventDesc`
  - `m_nEventEXP_WSE`
  - `m_nEventDrop_WSE`

Tabelas SQL relacionadas:

- `GlobalAccount.dbo.IntegratedIncRate`
- `GameWorld.dbo.WorldSpecificEvent`

Estado observado na analise:

- `IntegratedIncRate` sem registros.
- `WorldSpecificEvent` sem registros.
- Logs de game mostrando:
  - `Refresh IIR - Drop_Normal[100] Drop_Premium[100] Exp_Normal[100] Exp_Premium[100]`

Conclusao da camada 2:

- O servidor possui um sistema global de evento/rate separado dos scripts.
- Com estado atual, os rates globais estao padrao.

### Camada 3: dados binarios de evento/drop

Arquivos relevantes:

- `Server/DataSvr/WS_Event.img`
- `Server/DataSvr/Holiday.img`
- `Server/DataSvr/TimeEvent.img`
- arquivos de `Server/DataSvr/Mob/*.img`

Observacao:

- Esses arquivos nao estao em formato texto simples para edicao direta segura no fluxo atual.
- O link entre "evento ativo" e "drop de mob de evento" pode passar por essa camada.

Conclusao da camada 3:

- Existe alta chance de controle de drop/evento depender desses dados binarios e da leitura interna do server.
- Edicao manual sem ferramenta adequada e alto risco.

## O que muda quando ativar aniversario (na pratica)

Com ativacao de aniversario via script (janela de data + reload):

- Deve abrir dialogos e trocas de aniversario.
- Deve habilitar consumo/uso de `4001126` nos NPCs de aniversario.
- Pode ativar fluxos de quest de aniversario (dependendo de states e gatilhos).

O que nao pode ser assumido automaticamente:

- que todos os mobs passarao a dropar Maple Leaf;
- que todos os mobs passarao a dropar equipamentos Maple de aniversario;
- que o drop normal sera substituido por drop de evento.

## Client/WZ: precisa mexer para drop de mob?

Regra pratica para este projeto:

- Nao, para logica de drop em si, o primeiro alvo e server-side.
- Client/WZ normalmente so entra quando:
  - item/asset nao existe no cliente;
  - ha necessidade de UI/recurso visual nao presente;
  - ha incompatibilidade de versao de dados.

Decisao recomendada:

- Nao mexer em client/WZ nesta fase.
- Priorizar validacao por scripts + logs + SQL + comportamento real in-game.

## Plano futuro seguro (passo a passo)

### Fase 0 - baseline e backup

- Garantir `git status` limpo ou com mudancas conhecidas.
- Exportar copia de seguranca das tabelas relacionadas a evento/rate.
- Salvar logs atuais de Login/Center/Game para comparacao.

### Fase 1 - validar camada de script

- Alterar somente janelas de data dos scripts alvo (sem tocar binarios).
- Recarregar scripts (`!rs`) ou reiniciar server.
- Validar em jogo:
  - NPC abre fluxo de aniversario;
  - trocas com `4001126` funcionam;
  - quest states mudam como esperado.

### Fase 2 - observar camada global (sem mudanca invasiva)

- Conferir logs `Refresh IIR`.
- Conferir SQL de `IntegratedIncRate` e `WorldSpecificEvent`.
- Verificar se houve alteracao de comportamento de drop sem mexer em client.

### Fase 3 - teste controlado de eventos globais

- Se necessario, inserir dados de teste em camada global com janela curta e ambiente local.
- Validar somente um canal/cenario por vez.
- Medir efeito em drop real de mobs especificos.

### Fase 4 - camada binaria (somente se estritamente necessario)

- Tratar como ultima opcao.
- Exige ferramenta/conhecimento de formato dos `.img` do DataSvr.
- Fazer snapshot antes/depois e teste isolado.

## Rollback rapido

Rollback minimo recomendado:

- Reverter arquivos de script alterados pelo Git.
- Limpar registros de evento/rate inseridos para teste.
- Reiniciar `bms_server`.
- Confirmar no log retorno para `Refresh IIR ... [100]`.

## Checklist de verificacao antes de concluir "quebrou"

- `docker compose ps` com `bmsdb` healthy e `bms_server` up.
- Login conectado ao Center.
- Center com Login + Shop + Games conectados.
- Server totalmente pronto (`READY=YES` no monitor).
- Somente depois testar comportamento de drop/evento.

## Consultas e comandos uteis

Status containers:

```powershell
docker compose ps
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Checar tabelas de evento:

```powershell
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "SELECT TOP 20 * FROM GlobalAccount.dbo.IntegratedIncRate ORDER BY SN;"
docker exec bmsdb /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Dong0#1sG00d" -Q "SELECT TOP 20 * FROM GameWorld.dbo.WorldSpecificEvent;"
```

Checar IIR no log de game:

```powershell
$g=(Get-ChildItem .\temp\MSLog\Game0Orion_*.log | Sort LastWriteTime -Desc | Select -First 1).FullName
Select-String -Path $g -Pattern "Refresh IIR"
```

Checar scripts de aniversario carregados:

```powershell
Select-String -Path $g -Pattern "Script 'q9800e' loaded","Script 'q9809e' loaded","Script '4th_mapleWeapon' loaded"
```

## Hipoteses abertas para investigacao futura

- Onde exatamente o servidor vincula "evento de aniversario ativo" ao drop de mob de `4001126`.
- Se a camada `WS_Event/Holiday/TimeEvent` so altera taxa global ou tambem injeta drop table de evento.
- Se existe dependencia de world state/event desc para ativacao completa no client list/login.

## Decisao atual

- Continuar sem editar client/WZ.
- Priorizar evolucao por server-side em etapas pequenas, com observabilidade e rollback simples.
