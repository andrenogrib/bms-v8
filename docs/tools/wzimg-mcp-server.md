# WzImg-MCP-Server

## Repositório

- `tools/WzImg-MCP-Server`
- Submodule Git: `https://github.com/lastbattle/WzImg-MCP-Server`

## O que é

Servidor MCP para consulta programática de IMG filesystem exportado (não trabalha direto no WZ bruto). Permite leitura, análise e automação em lote.

## Pré-requisito importante

Precisa de exportação prévia com `manifest.json` (gerada por Harepacker/HaCreator).

## Onde ajuda no nosso projeto

- Construir cross-ref de dados (mob -> mapas, item -> fontes, npc -> scripts).
- Fazer auditoria em lote sem abrir GUI toda hora.
- Acelerar geração de relatórios/documentação técnica.

## Quando usar

- Quando a pergunta envolve muitos arquivos de uma vez.
- Quando queremos repetibilidade e histórico de consultas.
- Quando for alimentar ferramenta externa (ex.: site/DB de referência).

## Pontos fortes

- Excelente para escala e consistência de análise.
- Integra bem com fluxo assistido por IA.
- Evita trabalho manual repetitivo.

## Limitações e riscos

- Requer pipeline de exportação atualizado.
- Se o export estiver desatualizado, a análise também estará.
- Em escrita automatizada, risco de alterar em massa sem perceber.

## Fluxo seguro recomendado

1. Exportar IMG filesystem atual.
2. Executar consultas de leitura primeiro.
3. Revisar resultados.
4. Só depois considerar escrita/transformação em lote.
5. Aplicar em ambiente de teste e validar no cliente.

## Casos práticos no BMS v8

- Encontrar "todos os mapas que contêm mob X".
- Mapear "todos os itens de evento em uma faixa de IDs".
- Localizar "referências de NPC ID e caminhos relacionados".

## Nível de prioridade no BMS v8

- Média/Alta para análise de dados e automação técnica.
