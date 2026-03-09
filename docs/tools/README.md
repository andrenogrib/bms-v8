# Tools (WZ/IMG)

Esta pasta documenta as ferramentas externas adicionadas em `tools/` como submodule, com foco em uso prático no BMS v8.

## Ferramentas

- [Harepacker-resurrected](./harepacker-resurrected.md)
- [WzComparerR2](./wzcomparerr2.md)
- [WzImg-MCP-Server](./wzimg-mcp-server.md)
- [MapleLib](./maplelib.md)

## Fluxo recomendado entre ferramentas

1. Investigar e comparar com WzComparerR2 (modo leitura).
2. Editar em cópia de trabalho com Harepacker.
3. Exportar IMG filesystem e analisar em lote com WzImg-MCP-Server.
4. Se precisar automação própria/repetível, criar utilitário em C# usando MapleLib.
