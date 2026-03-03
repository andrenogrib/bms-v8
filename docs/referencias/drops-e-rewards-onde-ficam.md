# Drops e Rewards: onde ficam no BMS v8

## Resumo

Neste projeto, a configuracao de drop/reward de monstros **nao esta no SQL** (`GameWorld`/`GlobalAccount`).
Ela fica em arquivos de dados do servidor (`DataSvr`), principalmente em `.img` binario.

## O que nao esta no SQL

- Nao existe tabela de drop/reward no banco para edicao direta por `UPDATE`/`INSERT`.
- O SQL continua sendo usado para contas, personagens, itens do personagem, inventario, trunk etc., mas nao para tabela de drop global de mobs.

## Onde os drops ficam

Arquivos principais:

- `Server/DataSvr/Reward.img`
  - Tabela principal de reward/drop usada pelo servidor.
- `Server/DataSvr/Reward_ori.img`
  - Snapshot/backup original (util para comparacao e rollback manual).
- `Server/DataSvr/Mob/*.img`
  - Dados por `mobid` (ex.: `0100100.img`), incluindo metadados do mob e ligacoes que afetam comportamento de recompensa.
- `Server/DataSvr/WS_Event.img`
- `Server/DataSvr/Holiday.img`
- `Server/DataSvr/TimeEvent.img`
  - Camadas de evento que podem alterar taxa/efeito de drop/exp em runtime.

## Observacao importante sobre formato `.img`

- Esses `.img` sao binarios no formato de dados da Nexon.
- No VSCode/`Get-Content`, o conteudo aparece corrompido ou ilegivel.
- Para leitura/edicao correta, usar visualizador/editor de WZ/IMG:
  - HaRepacker
  - WzComparerR2

## Como validar rapidamente

1. Confirmar ausencia de tabela de drop no SQL:

```sql
SELECT name FROM GameWorld.sys.tables WHERE name LIKE '%Drop%' OR name LIKE '%Reward%';
SELECT name FROM GlobalAccount.sys.tables WHERE name LIKE '%Drop%' OR name LIKE '%Reward%';
```

2. Conferir arquivos em `DataSvr`:

```powershell
Get-ChildItem .\Server\DataSvr\Reward*.img
Get-ChildItem .\Server\DataSvr\Mob -File | Select-Object -First 10
```

3. Apos editar `.img`, reiniciar `bms_server` e validar logs/estado.

## Regra operacional para esse tema

- Alterou `.s` (scripts): normalmente `!rs` basta.
- Alterou `.img` (Reward/Mob/Event): reiniciar `bms_server`.
- Alterou DLL (`wvsgm.dll`): rebuild + copiar + reiniciar `bms_server`.

## Conclusao pratica

Para mexer em drop de monstro no BMS v8, pense em:

1. `Reward.img` e `Mob/*.img` como fonte de verdade.
2. `WS_Event/Holiday/TimeEvent` como moduladores de evento/rate.
3. SQL fora do fluxo principal de definicao de drop de mob.
