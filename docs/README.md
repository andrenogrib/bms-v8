# Documentação

Esta pasta está organizada por tema para reduzir risco de manutenção e facilitar consulta.

## 1) Guias (como fazer)

Materiais didáticos, passo a passo operacional e procedimentos de rotina.

- [Subir servidor e usar monitoramento](./guias/subir-servidor-e-monitoramento.md)
- [Build do GameLauncher e server.txt](./guias/build-gamelauncher-e-servertxt.md)
- [Monitoramento em 4 janelas PowerShell](./guias/monitoramento-operacao.md)
- [Como verificar status de serviços e Center](./guias/verificar-status-servicos-center.md)
- [Alterações SQL: sequência segura e validação](./guias/sql-alteracoes-restart-e-validacao.md)
- [Como editar Mesos e NX](./guias/editar-mesos-nx.md)
- [Como alterar slots de inventário e storage](./guias/alterar-slots-inventario-storage.md)
- [Encoding e tags nos scripts de NPC](./guias/encoding-e-tags-script.md)
- [Usuarios e senhas padrao](./guias/usuarios-e-senhas-padrao.md)
- [Aviso rolando no topo da tela (slide)](./guias/aviso-rolando-no-topo.md)

## 2) Referências (arquitetura e base técnica)

Materiais de visão global e mapeamento estrutural do projeto.

- [Arquitetura e lógica completa do projeto](./referencias/arquitetura-e-logica-completa.md)
- [GM, SuperGM, Dev e comandos](./referencias/gm-supergm-dev-comandos.md)
- [Drops e Rewards: onde ficam no BMS v8](./referencias/drops-e-rewards-onde-ficam.md)
- [Mobs por mapa e spawn dinamico](./referencias/mobs-por-mapa-e-spawn-dinamico.md)
- [WZ to Web cross-ref (repositorio externo)](./referencias/wz-to-web-crossref-externo.md)

## 3) Casos (histórico e incidentes)

Registros de conversas técnicas, tentativas, correções e aprendizado aplicado.

- [Caso real: Closed Beta, Bandana e boot](./casos/caso-closed-beta-bandana-e-boot.md)
- [Setup aplicado: dedezin SuperGM](./casos/dedezin-supergm-setup.md)
- [Retrospectiva técnica da tentativa de comandos (2026-03-02)](./casos/retrospectiva-comandos-chat-2026-03-02.md)
- [SP na 1ª job e compensação manual](./casos/sp-primeira-job-e-compensacao.md)

## 4) Planos (roadmap e evolução)

Decisões de evolução futura, com fases e risco controlado.

- [Roadmap seguro de comandos de chat (base v83)](./planos/comandos-chat-v83-roadmap-seguro.md)
- [Eventos de aniversário: camadas e plano futuro](./planos/eventos-aniversario-camadas-plano-futuro.md)
- [Próxima fase: conteúdo + comandos com sync estável](./planos/proxima-fase-conteudo-e-comandos-sync.md)

## Regra de deploy (padrão da equipe)

- `.s` => `!rs` costuma bastar.
- `.img` => reiniciar `bms_server` e aguardar `READY=YES`.
- `wvsgm.dll` => rebuild + copiar + reiniciar `bms_server`.



