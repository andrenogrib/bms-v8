# Mobs por mapa: onde consultar no BMS v8

## Resumo

Para descobrir em quais mapas um mob aparece, voce precisa olhar duas camadas:

1. Spawn fixo de mapa (`Map/*.img`)
2. Spawn dinamico via script (`Script/*.s`)

Um mesmo `mobid` pode aparecer em varios `mapid`.

## 1) Spawn fixo (dados de mapa)

Arquivos:

- `Server/DataSvr/Map/Map0/*.img`
- `Server/DataSvr/Map/Map1/*.img`
- `Server/DataSvr/Map/Map2/*.img`
- `Server/DataSvr/Map/Map6/*.img`
- `Server/DataSvr/Map/Map8/*.img`
- `Server/DataSvr/Map/Map9/*.img`

Cada arquivo `#########.img` representa um `mapid`.

Dentro do mapa, os mobs ficam no bloco `life`:

- `type = "m"` => entrada de mob
- `id = <mobid>` => template do monstro
- campos de posicao/spawn (ex.: `x`, `y`, `fh`, `mobTime`)

Observacao:

- Esses `.img` sao binarios da Nexon.
- No VSCode o conteudo pode parecer quebrado.
- Para leitura correta, usar WzComparerR2/HaRepacker.

## 2) Spawn dinamico (script)

Alguns mobs nao estao como spawn fixo no mapa e entram por script de evento/PQ/boss.

Procure por chamadas como:

- `field.summonMob(...)`
- `field.setMobGen(...)`
- `field.getMobCount(...)`
- `field.removeMob(...)`

Comando util para buscar um `mobid` especifico:

```powershell
rg -n --hidden -S "field\.summonMob\([^)]*MOBID\)|getMobCount\(\s*MOBID\s*\)|setMobGen\([^,]+,\s*MOBID\s*\)|removeMob\(\s*MOBID\s*\)" Server/DataSvr/Script
```

Troque `MOBID` pelo valor real.

## Regra pratica

Para mapear `mobid -> mapids` de forma completa:

1. Verificar spawn fixo em `Map/*.img`
2. Verificar spawn dinamico em `Script/*.s`
3. Unir os resultados (sem esquecer mapas de evento/PQ/boss)

## Observacao final

Sem ferramenta de leitura de `.img`, voce consegue mapear bem a parte de scripts, mas nao fecha 100% a parte de spawn fixo.
Para auditoria completa, use viewer de WZ/IMG.
