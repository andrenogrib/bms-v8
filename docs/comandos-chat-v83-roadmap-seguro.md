# Comandos de chat: roadmap seguro (base v83 -> BMS v8)

Data: 2026-03-01

Objetivo deste documento:

- mapear sua lista de comandos estilo v83 para a base atual BMS v8
- definir o que e viavel sem mexer em WZ/EXE
- separar por risco para evitar crash/corrupcao de estado

## 1) Estado atual do servidor

Comandos ja implementados no parser custom:

- `!fm`
- `!gmap`
- `!exp <1-5>`
- `!drop <1-5>`
- `!rs`

Arquivos-base:

- `Extension/WvsGame/CommandParser.cpp`
- `Extension/WvsGame/CUser.cpp`
- `Extension/WvsGame/WvsGame.cpp`

## 2) Regra de permissao atual

O parser atual permite comando quando:

- `user->m_nGradeCode & 1` for verdadeiro

Pratica recomendada:

- manter `Account.Admin = 255` para conta staff principal

## 3) O que da para aproveitar AGORA (baixo risco, sem WZ/EXE)

### 3.1 Candidato: `!help` / `!commands`

Viabilidade: alta.

Como implementar:

- listar no chat os comandos suportados pelo parser atual.

Risco: baixo.

### 3.2 Candidato: `!warp <mapId>`

Viabilidade: alta.

Como implementar:

- reutilizar `CUser::PostTransferField(...)`.

Risco: baixo, desde que valide `mapId` inteiro.

### 3.3 Candidato: aliases de comandos existentes

Exemplos:

- `!exprate` -> alias para `!exp`
- `!droprate` -> alias para `!drop`
- `!reloadscripts` -> alias para `!rs`

Viabilidade: alta.
Risco: baixo.

### 3.4 Candidato: `!meso <valor>`

Viabilidade: media/alta.

Caminho tecnico:

- aproveitar rotina de incremento de mesos do servidor (`CQWUser::IncMoney`) ja mapeada no projeto.

Risco:

- medio se aceitar valores sem limite.

Mitigacao:

- limitar range por comando (ex.: max +/- 50.000.000 por execucao).
- logar uso no arquivo do game server.

## 4) O que e viavel, mas com risco medio (requer mais reverse/hook)

### 4.1 `!level`, `!ap`, `!sp`, `!maxstat`

Viabilidade: media.

Motivo:

- exige chamadas internas corretas para atualizar status + persistencia + sync de pacote para client.
- setar campo bruto em memoria sem rotina correta pode causar desync.

Recomendacao:

- preferir caminho SQL controlado para ajustes "grandes".
- depois criar comando in-game apenas se mapear funcoes internas com seguranca.

### 4.2 `!warpto <player>` / `!summon <player>`

Viabilidade: media/baixa no estado atual.

Motivo:

- falta, no patch atual, um wrapper pronto para lookup de `CUser` por nome global.

Recomendacao:

- fase posterior, apos mapear manager de usuarios online no binario.

## 5) O que NAO vale implementar agora (alto risco ou escopo grande)

### 5.1 `!item`, `!drop`, `!proitem`, `!seteqstat`, `!maxskill`, `!resetskill`

Motivo:

- dependem de pipeline interna de criacao de item/SN/locker/packets.
- alto risco de corromper inventario se pular funcoes internas corretas.

Alternativa segura imediata:

- SQL offline com procedimento documentado + relog/restart quando necessario.

### 5.2 `!givenx` / `!givems` via chat global

Motivo:

- para NX via comando in-game e melhor ter wrapper DB interno robusto.
- sem isso, implementacao pode ficar fragil (race, inconsistencia entre sessao e DB).

Alternativa segura imediata:

- usar SQL (ja documentado em `docs/editar-mesos-nx.md`).

### 5.3 Comandos admin de infraestrutura (`!addchannel`, `!addworld`, `!shutdown`, etc)

Motivo:

- tocam topologia/estado global e exigem camada de orquestracao mais completa.

Recomendacao:

- manter via operacao Docker/SQL, nao via chat, nesta fase.

## 6) Plano recomendado (faseado)

## Fase 1 (segura, proxima sessao)

Implementar:

1. `!help` / `!commands`
2. `!warp <mapId>`
3. aliases de comandos ja existentes
4. `!meso <valor>` com limite

Meta:

- aumentar produtividade GM sem mexer em sistemas sensiveis de inventario/NX.

## Fase 2 (controlada)

Estudar e implementar com teste forte:

1. `!level`
2. `!ap`
3. `!sp`

Somente se:

- houver funcao interna segura para persistencia/sync.

## Fase 3 (avancada)

Somente apos mapear internals de item/user manager:

1. `!item` / `!drop`
2. `!warpto <player>` / `!summon <player>`
3. comandos de skills/equip custom

## 7) Regras de seguranca para qualquer novo comando

1. validar parametros (tipo + faixa)
2. limitar impacto por execucao
3. negar comando para usuario sem grade adequada
4. logar quem usou, comando e argumentos
5. fallback com mensagem clara no chat em caso de erro
6. evitar alterar inventario/NX por atalho sem rotina interna validada

## 8) Conclusao

Sem editar WZ/EXE, ainda da para avancar bastante com comandos de operacao GM no chat.

Melhor estrategia:

- primeiro comandos administrativos de baixo risco (help, warp, aliases, meso com limite)
- depois status/level/SP/AP com mapeamento seguro
- deixar item/NX/infra pesada para fase posterior

