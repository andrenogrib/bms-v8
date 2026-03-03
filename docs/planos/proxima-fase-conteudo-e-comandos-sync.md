# Próxima fase: conteúdo + comandos com sync estável

Objetivo: evoluir o servidor com segurança, mantendo a base original o mais intacta possível e adicionando customizações em camada separada.

## Estratégia

1. Preservar base original.
2. Criar customizações em pontos centralizados.
3. Fazer mudanças pequenas, com teste e rollback simples.

## Princípios

- Uma feature por vez.
- Um commit por feature.
- Sem mexer em `.s` legado além do necessário.
- Priorizar overlay (arquivo custom novo) em vez de editar muitos arquivos antigos.

## Camada de customização recomendada

- Script custom central: `Server/DataSvr/Script/z_custom_live.s`
- Comandos custom: `Extension/WvsGame/CommandParser.cpp`
- Documentação por feature em `docs/`.

## Trilha A: Conteúdo sem mexer no client primeiro

## Fase A1 (segura)

- Usar NPC já existente para menu custom.
- Implementar loja por script (`askMenu` + `inventory.exchange`).
- Recarregar com `!rs`.

Checklist:

- NPC abre diálogo sem erro.
- Compra/troca funciona.
- Troca de canal/mapa sem DC.

## Fase A2 (média)

- Spawn temporário de NPC/mob via script (`summonNpc`, `summonMob`).
- Ajustar lógica de evento por script.

Checklist:

- Spawn ocorre no mapa esperado.
- Sem crash ao trocar canal.

## Fase A3 (estrutural)

- Persistência em `.img` (mapa/NPC/shop), quando necessário.
- Reiniciar `bms_server` e validar readiness completo.

Checklist:

- Conteúdo permanece após restart.
- Sem regressão em login/seleção de personagem.

## Trilha B: Comandos GM fortes sem desync

## Fase B1 (baixo risco)

- `!help`, `!commands`, `!warp` e aliases.

## Fase B2 (estado do personagem)

- `!meso`, `!level`, `!ap`, `!sp`, `!job` com limite (`clamp`).

## Fase B3 (mundo)

- `!summon`, `!npc` com limite de quantidade por execução.

## Fase B4 (alto risco)

- `!nx`, `!dropitem`.
- Só depois de validação completa de pipeline.

## Contrato de sync (obrigatório em comandos)

1. Validar entrada.
2. Validar permissão.
3. Aplicar por rotina nativa do servidor.
4. Sincronizar cliente no mesmo fluxo.
5. Testar: imediato, troca de canal, relog e restart.

## Regra de deploy

- `.s` => `!rs` costuma bastar.
- `.img` => restart `bms_server`.
- `wvsgm.dll` => rebuild + copiar + restart `bms_server`.

## Critério de conclusão por etapa

Só avançar para a próxima fase se:

- Não houver crash/DC nos testes básicos.
- O estado persistir corretamente após relog.
- O comportamento continuar estável após restart do servidor.


