# WzComparerR2

## Repositório

- `tools/WzComparerR2`
- Submodule Git: `https://github.com/Kagamia/WzComparerR2`

## O que é

Ferramenta para inspeção e comparação de arquivos WZ entre versões/builds de cliente.

## Onde ajuda no nosso projeto

- Descobrir se um mapa, mob, NPC, string ou asset existe no client usado.
- Comparar cliente base v08 com outra build para mapear diferenças.
- Investigar por que determinado conteúdo não aparece no jogo.

## Quando usar

- Antes de editar WZ (fase de diagnóstico).
- Para validar se o ID/arquivo que queremos usar realmente existe.
- Para mapear caminhos e estrutura sem alterar nada.

## Pontos fortes

- Muito forte em diff e investigação.
- Ajuda a reduzir tentativa-e-erro em edição.
- Bom para criar "evidência técnica" antes de mexer.

## Limitações e riscos

- Projeto em manutenção limitada (updates mais lentos).
- Nem toda função avançada é necessária para o nosso cenário.
- Não é a melhor escolha para automação pesada.

## Fluxo seguro recomendado

1. Abrir os WZ em modo leitura.
2. Localizar dados-alvo (ID, path, estrutura).
3. Registrar o resultado em documentação curta.
4. Só então editar no Harepacker.

## Perguntas que ele responde bem

- "Esse mob existe nesta versão do client?"
- "Em quais mapas ele aparece no WZ?"
- "O texto/NPC está no client ou faltando?"
- "Qual a diferença entre dois arquivos após uma mudança?"

## Nível de prioridade no BMS v8

- Alta para investigação e validação pré-edição.
