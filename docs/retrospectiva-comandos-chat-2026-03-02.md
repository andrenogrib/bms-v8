# Retrospectiva tecnica: tentativa de comandos de chat (2026-03-02)

Data: 2026-03-02

Objetivo da sessao:

- implementar a "fase segura" de comandos de chat no `Extension/WvsGame`
- manter risco baixo (sem editar scripts `.s`, sem mexer em WZ/EXE do client)

Status final desta sessao:

- tudo que foi testado nesta rodada foi revertido para o estado do `git HEAD`
- servidor reiniciado apos rollback
- base voltou para estado estavel anterior

---

## 1) Escopo que tentamos implementar

Comandos da fase segura (parser):

- `!help` / `!commands`
- `!buffme`
- `!meso <valor>`
- `!warp <mapid>`
- `!level <valor>`
- `!ap <valor>`
- `!sp <valor>`
- `!job <jobid>`

Arquivos envolvidos:

- `Extension/WvsGame/CommandParser.cpp`
- `Extension/WvsGame/CommandParser.h`
- `Extension/WvsGame/CUser.cpp`
- `Extension/WvsGame/CUser.h`
- `Extension/WvsGame/CQWUser.h`
- deploy de `Extension/Release/wvsgm.dll` para `Server/BinSvr/wvsgm.dll`

---

## 2) O que funcionou inicialmente

- parser de comandos foi integrado no chat (`onAdminCommand` / `onUserCommand`)
- comandos de status e ajuste foram reconhecidos
- build e deploy da DLL funcionaram
- permissao por grade (`m_nGradeCode`) continuou base para GM

---

## 3) Problemas observados em teste

### 3.1 `!meso` mudava so depois de relogar

Comportamento:

- comando aceitava valor
- cliente nao mostrava mudanca imediata
- depois de relog, valor aparecia atualizado

Causa:

- alteracao server-side ocorria via `IncMoney`
- faltava forcar refresh de stat no cliente na mesma hora

Correcao identificada:

- apos `IncMoney(...)`, chamar `SendCharacterStat(1, 0)`

---

### 3.2 `!buffme` dizia "applied", mas sem icones de buff

Comportamento:

- mensagem de sucesso no chat
- efeitos visuais/icone de buff nao apareciam

Tentativa inicial:

- usar `CUser::ApplyTemporaryStat(...)` com skill IDs:
  - `5101000`
  - `5101001`
  - `5101002`
  - `5101003`

Causa provavel:

- esse caminho nao reproduz o mesmo pipeline do `User.giveBuff(integer)` usado em script
- resultado: estado parcial/nao visivel para o cliente

---

### 3.3 `!warp` falhando para alguns mapas

Comportamento:

- `!warp <mapid>` podia falhar mesmo com mapa valido

Causa:

- validacao estava com `GetField(mapId, 0, 0)` (sem force load)
- portal usado podia nao ser o melhor fallback para todos os mapas

Correcao identificada:

- usar `GetField(mapId, 1, 0)` para forcar load na validacao
- usar portal fallback mais generico (`"00"`)

---

## 4) Reverse engineering que foi feito nesta sessao

Foi feita investigacao no `WvsGame.exe` (disassembly) para mapear funcoes de script da camada `User.*`.

Achados relevantes:

- `User.giveBuff(integer)` mapeado para `0x005569D0`
- `User.givePartyBuff(integer)` mapeado para `0x005576B6`
- `User.cancelPartyBuff(integer)` mapeado para `0x0055791B`
- `User.isSuperGM` presente na tabela de script

Descoberta importante:

- o caminho de `giveBuff` usa pipeline interno completo (skill lookup + stat packet + stat changed + efeito)
- isso reforca que `ApplyTemporaryStat` nao e equivalente ao comando de script para o caso desejado

---

## 5) Tentativa de correcao avancada (`GiveBuff` nativo)

Foi montada uma funcao wrapper em `CUser` para tentar chamar o mesmo caminho interno de `User.giveBuff`.

Pontos dessa tentativa:

- skill lookup pelo singleton de `SkillInfo`
- aplicacao por funcao interna de skill/buff
- envio de `SendCharacterStat`
- envio de pacote de stat changed

Resultado:

- compilou e fez deploy
- mas a decisao final foi rollback para retomar com mais calma, em passos menores

---

## 6) Rollback executado

Arquivos revertidos para `HEAD`:

- `Extension/WvsGame/CQWUser.h`
- `Extension/WvsGame/CUser.cpp`
- `Extension/WvsGame/CUser.h`
- `Extension/WvsGame/CommandParser.cpp`
- `Extension/WvsGame/CommandParser.h`
- `Server/BinSvr/wvsgm.dll`

Comando usado:

```powershell
git restore -- Extension/WvsGame/CQWUser.h Extension/WvsGame/CUser.cpp Extension/WvsGame/CUser.h Extension/WvsGame/CommandParser.cpp Extension/WvsGame/CommandParser.h Server/BinSvr/wvsgm.dll
docker compose restart bms_server
git status --short
```

Estado apos rollback:

- `git status` limpo
- servidor reiniciado com binario da versao estavel

---

## 7) Licoes aprendidas

- para comandos que alteram stats/economia, sempre validar sync imediato com cliente
- para buffs, priorizar caminho nativo de script (`giveBuff`) e nao atalhos sem pacote completo
- `warp` precisa validar com mapa carregavel (force load), senao falha falso-negativo
- implementar muitos comandos de uma vez aumenta custo de debug em stack antiga

---

## 8) Plano recomendado para amanha (1 por vez)

Sequencia proposta:

1. `!help` e `!commands` (somente listagem)
2. `!meso` com refresh imediato de stat
3. `!warp` com validacao force-load
4. `!buffme` (so depois de escolher caminho final: wrapper `giveBuff` ou fallback por script)
5. `!level`
6. `!ap`
7. `!sp`
8. `!job`

Regra operacional:

- 1 comando por commit
- build/deploy/teste rapido
- so avancar apos teste manual aprovado

Checklist minimo por comando:

- comando retorna mensagem clara de sucesso/erro
- valor muda no cliente sem relog (quando aplicavel)
- sem crash ao trocar canal/mapa
- sem regressao em login/selecao de personagem

---

## 9) Observacao de estabilidade

Durante restarts apareceram mensagens de Wine/heap no container em alguns momentos.

Interpretacao:

- ambiente ja e sensivel por natureza (stack antiga em Wine)
- por isso, estrategia incremental e obrigatoria para reduzir risco de falso diagnostico

---

## 10) Regras mantidas

- nao editar `.s` nesta frente de comandos (evitar risco de encoding)
- manter comandos de maior risco (`NX`, `dropitem`, itens custom) para fase posterior
- preservar snapshot funcional antes de mudancas grandes

