# Harepacker-resurrected

## Repositório

- `tools/Harepacker-resurrected`
- Submodule Git: `https://github.com/lastbattle/Harepacker-resurrected`

## O que é

Suite de ferramentas (HaRepacker + HaCreator) para abrir, editar e salvar arquivos WZ/IMG do cliente MapleStory.

## Onde ajuda no nosso projeto

- Editar conteúdo client-side (NPC, mapas, strings, UI, dados visuais).
- Exportar dados para IMG filesystem com `manifest.json` (base para automação com WzImg-MCP-Server).
- Validar rapidamente se o cliente possui ou não certo recurso visual/textual.

## Quando usar

- Quando o servidor já envia lógica correta, mas o cliente não tem o conteúdo.
- Quando precisamos ajustar texto, estrutura de NPC ou recursos em WZ.
- Quando queremos preparar uma extração para consultas em lote.

## Pontos fortes

- Melhor ferramenta para edição manual de WZ.
- Ecossistema conhecido na comunidade Maple private/research.
- Integração natural com MapleLib e WzImg-MCP-Server.

## Limitações e riscos

- Salvar com estrutura/versão errada pode quebrar o cliente.
- Mudanças grandes de uma vez dificultam identificar causa de crash.
- Não substitui lógica server-side (scripts `.s`, SQL, `wvsgm.dll`).

## Fluxo seguro recomendado

1. Duplicar a pasta do cliente antes de editar.
2. Fazer apenas 1 mudança por ciclo (ex.: 1 NPC ou 1 map).
3. Salvar, abrir cliente e testar.
4. Se funcionar, registrar no `docs/casos` ou `docs/guias`.
5. Só depois avançar para a próxima mudança.

## Uso combinado ideal

- WzComparerR2: descobrir diferenças e confirmar IDs/paths.
- Harepacker: aplicar edição no arquivo.
- WzImg-MCP-Server: gerar consultas e validações de consistência.

## Nível de prioridade no BMS v8

- Alta para edição de conteúdo client-side.
