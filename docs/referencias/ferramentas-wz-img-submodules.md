# Ferramentas WZ/IMG (submodules em `tools/`)

## Escopo

Este documento resume as ferramentas externas versionadas como submodule para analise e edicao de arquivos WZ/IMG.

## 1) Submodules adicionados

- `tools/Harepacker-resurrected`
- `tools/WzComparerR2`
- `tools/WzImg-MCP-Server`
- `tools/MapleLib`

## 2) Quando usar cada uma

### Harepacker-resurrected

Uso principal:

- abrir/editar WZ e IMG;
- exportar IMG filesystem (manifest + pastas) para fluxo de analise.

Ponto forte:

- melhor para edicao manual de conteudo (NPC, mapa, strings, estrutura de WZ).

### WzComparerR2

Uso principal:

- comparar versoes de WZ;
- localizar diferencas entre clients;
- busca e inspecao de dados.

Ponto forte:

- melhor para investigacao e diff tecnico.

### WzImg-MCP-Server

Uso principal:

- automacao e consulta programatica do IMG filesystem exportado;
- cross-ref de dados em lote (mobs, drops, mapas, npcs).

Ponto forte:

- melhor para analise assistida por IA e pipelines de dados.

### MapleLib

Uso principal:

- base C# para construir automacoes proprias de leitura/escrita WZ/IMG;
- biblioteca de suporte para utilitarios internos.

Ponto forte:

- melhor para fluxos reproduziveis por codigo.

## 3) Recomendacao de fluxo

1. Extrair/exportar dados com Harepacker.
2. Validar e comparar com WzComparerR2.
3. Fazer analise em lote com WzImg-MCP-Server.
4. Se necessario, automatizar com MapleLib.
5. Aplicar mudanca pequena por vez e testar no cliente.

## 6) Documentacao detalhada

Analise completa de cada tool:

- `docs/tools/README.md`

## 4) Regra de seguranca para edicao de conteudo

- Sempre manter backup do WZ original antes de salvar.
- Nunca editar varios sistemas ao mesmo tempo (mapa + npc + drop + string no mesmo ciclo).
- Testar primeiro em ambiente local, depois consolidar.

## 5) Nota

Submodule fixa commit no repositório principal. Para atualizar ferramenta no futuro:

```powershell
git submodule update --remote --merge
git add .gitmodules tools/*
git commit -m "chore(tools): update submodules"
```
