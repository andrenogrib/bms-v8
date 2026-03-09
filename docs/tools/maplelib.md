# MapleLib

## Repositório

- `tools/MapleLib`
- Submodule Git: `https://github.com/lastbattle/MapleLib`

## O que é

Biblioteca C# para ler/editar formatos MapleStory (WZ/IMG/MS) e manipular estruturas de protocolo. É base de projetos como Harepacker.

## Onde ajuda no nosso projeto

- Criar utilitários próprios e reproduzíveis para o BMS v8.
- Automatizar operações específicas de WZ/IMG sem GUI.
- Implementar validações em lote antes/depois de edição.

## Quando usar

- Quando o fluxo manual começa a ficar repetitivo.
- Quando precisamos de patch "determinístico" (sempre igual).
- Quando queremos ferramenta interna própria em vez de processo manual.

## Pontos fortes

- Controle total por código.
- Excelente para CI/scripts e transformações repetíveis.
- Suporta múltiplos formatos/versionamentos.

## Limitações e riscos

- Curva técnica maior (C#, estrutura WZ/IMG, versionamento de client).
- Mais fácil introduzir erro estrutural se faltar validação.
- Exige disciplina de testes e backups.

## Como usar de forma segura no BMS v8

1. Começar com operações de leitura e relatório.
2. Depois criar pequenas operações de escrita (escopo mínimo).
3. Validar resultado no WzComparerR2.
4. Testar no cliente.
5. Versionar utilitário e documentar comando de execução.

## Roadmap sugerido para adoção

1. Fase 1: script de leitura (`listar`, `buscar`, `cross-ref`).
2. Fase 2: patch simples e reversível.
3. Fase 3: pipeline completo com validação automática.

## Nível de prioridade no BMS v8

- Média agora, Alta no médio prazo (quando o projeto crescer em automação).
