# Evidência — <Nome da Feature>

> **Para o agente:** criado em `docs/plans/<feature>/evidence.md` na primeira observação da implementação.
> As entradas são **append-only**: nunca edite, reordene ou apague uma entrada já registrada. Somente o
> resumo pode ser atualizado para refletir o estado agregado atual. Na criação, substitua todos os
> placeholders da primeira entrada; não deixe o exemplo do molde convivendo com um recibo real.

- **Spec de referência:** `docs/specs/<feature>/spec.md`
- **Plano de referência:** `docs/plans/<feature>/plan.md`

---

## Resumo atualizável

- **Última atualização:** <data/hora>
- **Tasks com implementação observada:** <T... | nenhuma>
- **Tasks aguardando revisão:** <T... | nenhuma>
- **Tasks concluídas pela revisão:** <T... | nenhuma>
- **Tasks bloqueadas:** <T... | nenhuma>
- **Arquivos alterados:** <paths | nenhum>
- **AC com evidência:** <AC... | nenhum>
- **Evidência faltante:** <AC/task/verificação | nenhuma>
- **Falhas conhecidas:** <... | nenhuma>
- **Limitações abertas:** <... | nenhuma>

## Entradas append-only

### E1 - <data/hora ISO-8601> - T1 - <implement|review>

- **Registro:** T1 | AC1, AC2 | implement | pass | worktree@<SHA>
- **Acao/comando:** <acao observada ou comando executado>
- **Diretorio:** <diretorio de execucao ou not-applicable>
- **Fonte:** <teste, script, preview, diff, log ou outra fonte observável>
- **Exit code:** <inteiro | not-applicable | unavailable>
- **Saida/referencia:** <saida curta, caminho de artefato, URL ou referencia reproduzivel>
- **Branch:** <branch | unavailable>
- **Limitacoes:** <limitacoes observadas | nenhuma>

Se a task ficar `blocked`, substitua o comentário abaixo pela linha canônica na mesma entrada. Fora de
`blocked`, remova o comentário ao preencher o molde.

<!-- - **Bloqueio:** T1 | motivo observado | condição objetiva para voltar a ready -->

## Contrato da entrada

- O cabecalho usa exatamente `### E<n> - <ISO-8601> - T<n> - <implement|review>`; comece em `E1` e avance
  de um em um, sem duplicata, inversao ou salto. Task e fase coincidem com o `Registro` do bloco.
- Cada bloco tem exatamente um `Registro` e os sete campos ASCII acima, todos preenchidos. Nao deixe
  placeholders e nao grave `Registro` fora de um bloco canonico.
- A linha `Registro` usa exatamente cinco campos separados por ` | `:
  `task | ACs | fase | resultado | ref`.
- Recibo que promove estado inclui todos os ACs declarados na linha da própria task.
- Fase: `implement` ou `review`.
- Resultado: `pass`, `fail`, `observed`, `not-run` ou `unavailable`.
- Ref: `commit@<7-40 hex>`, `worktree@<7-40 hex>` ou `unavailable`.
- `Exit code`: `pass` usa `0`; `fail`, inteiro diferente de zero; `observed`/`not-run`, `not-applicable`;
  `unavailable`, `unavailable`.
- `pass`/`observed` com ref `unavailable` não promove estado.
- `worktree@<SHA>` identifica uma observação feita com mudanças locais sobre esse SHA; `commit@<SHA>`, uma
  observação do conteúdo commitado. Nesta versão, a ref registra proveniência, sem classificar atualidade.
- A linha `Bloqueio` é obrigatória quando a task entra em `blocked` e permanece no histórico depois do
  desbloqueio. Ela e o handoff ficam no mesmo bloco negativo; entrada separada serve apenas para pausa
  nao bloqueante.
- Se uma dependencia que falhou invalidar uma task ja `done`, inclua no mesmo bloco `review | not-run`:
  `- **Reclassificacao:** T1 | done | ready | <ISO-8601> | <motivo/referencia>`.
  O marker exige implement + review bem-sucedido anteriores que provem o `done`; novo implement depois de
  `done` tambem exige essa transicao registrada antes dele.
- Texto da IA sem ação, fonte e resultado observável não é recibo de execução.
