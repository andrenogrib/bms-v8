# WZ to Web Cross-Ref (repositorio externo)

## Objetivo

Registrar a base externa criada para consulta e cruzamento de dados WZ/IMG do BMS v8:

- Repositorio: `https://github.com/andrenogrib/bms_v8_wztoweb`
- Site publicado: `https://andrenogrib.github.io/bms_v8_wztoweb/`

Essa base foi criada para facilitar analise de conteudo sem depender do jogo aberto:

- drops por mob
- itens que um mob dropa
- em quais mapas um mob aparece
- em quais mapas um NPC aparece
- navegacao por ID/nome com painel de detalhes

## O que o projeto externo entrega

De acordo com o README publico do repositorio:

1. Web app estatico (HTML/CSS/JS), sem backend.
2. Abas de dados exportados (`Mob`, `Npc`, `Skill`, `Item`, etc.).
3. Busca global por ID e nome.
4. Cross-ref de drops via `Reward.img`.
5. Cross-ref de mapa via `Map/*.img`.
6. Indices leves para consulta rapida no frontend.

Arquivos importantes gerados la:

- `WEB/Reward/drop-index.json`
- `WEB/Map/map-links.json`
- `REWARD/Reward.normalized.json`
- `REWARD/Reward.normalized.flat.json`

## Relacao com este repositorio (bms-v8)

No `bms-v8`, os dados continuam binarios em `Server/DataSvr/*.img`.
O projeto `bms_v8_wztoweb` funciona como camada de consulta e auditoria:

1. Exporta os dados WZ/IMG.
2. Normaliza em JSON.
3. Gera indices de relacao.
4. Permite consulta visual para apoiar operacao/edicao no servidor.

Isso reduz tentativa e erro para:

- mapear `mobid -> mapids`
- validar `mobid -> drops`
- verificar impacto antes de alterar scripts/eventos

## Casos de uso recomendados

1. Antes de editar eventos de drop:
   - validar no web DB se o item/mob esperado esta indexado.
2. Antes de mexer em spawn de mapa:
   - confirmar em quais mapas o mob ja aparece.
3. Antes de criar NPC/loja nova:
   - revisar IDs existentes e evitar colisao.
4. Investigacao de conteudo incompleto:
   - identificar lacuna no dado exportado vs dado esperado no jogo.

## Limites atuais

- A qualidade da consulta depende da qualidade do export.
- Se um `.img` nao foi exportado/normalizado, nao vai aparecer no web DB.
- Continuam existindo casos de spawn dinamico por script (`field.summonMob`) que precisam ser auditados em `Server/DataSvr/Script/*.s`.

## Status

Ferramenta externa adotada como referencia de analise de dados para o BMS v8.
