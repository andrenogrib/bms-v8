# SP na 1a Job (caso FangBlade)

## Resumo do caso

- Personagem: `FangBlade`
- Estado observado: virou Gatuno (`B_Job=400`) no level 12, mas ficou com apenas 1 SP.
- Resultado final da investigacao: nao foi perda aleatoria de SP no banco. O comportamento vem da logica atual dos scripts de job.

## Causa raiz

Nos scripts de 1a job, o servidor aplica somente `target.incSP(1, 0)` na troca de classe:

- `Server/DataSvr/Script/job2.s` (Gatuno)
- `Server/DataSvr/Script/job.s` (Guerreiro/Mago)

Ou seja: se o jogador sobe levels como Beginner e so depois faz 1a job, este source nao esta concedendo SP retroativo automatico desses levels anteriores.

## Opcao 2 (aplicada agora, sem alterar script)

Foi aplicada compensacao manual no banco somente para o `FangBlade`:

```sql
UPDATE GameWorld.dbo.Character
SET S_SP = S_SP + 6
WHERE CharacterName='FangBlade';
```

Verificacao apos update:

```sql
SELECT CharacterName,B_Level,B_Job,S_SP
FROM GameWorld.dbo.Character
WHERE CharacterName='FangBlade';
```

Resultado esperado no caso atual: `S_SP = 6`.

## Plano futuro (Opcao 3 - definitiva)

Quando formos mexer nos scripts:

1. Manter o `+1 SP` da 1a job.
2. Adicionar bonus retroativo seguro:
   - Guerreiro/Arqueiro/Gatuno: `extra = max(0, (nLevel - 10) * 3)`
   - Mago: `extra = max(0, (nLevel - 8) * 3)`
3. Aplicar `target.incSP(extra, 0)` somente no momento da 1a job.

## Cuidado com encoding dos scripts

Os arquivos de `Server/DataSvr/Script` podem estar em `Windows-1252`.
Antes de editar `job.s`/`job2.s`:

- abrir no VS Code em `Windows-1252`;
- evitar salvar em UTF-8 sem necessidade;
- evitar formatacao em massa.

Isso reduz risco de corromper textos de NPC e tags de script.
