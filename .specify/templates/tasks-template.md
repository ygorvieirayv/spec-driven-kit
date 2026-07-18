# Tasks — <Nome da Feature>

> **Para o agente:** gerado/atualizado pelo `/sdk-tasks` a partir do plano. Lista ordenada por dependência.
> Cada task tem ID, referencia o AC que satisfaz e tem forma de verificação. Estados:
> `backlog → ready → in-progress → verification-pending → done`. `blocked` é um desvio temporário e volta
> para `ready` quando sua condição objetiva for satisfeita. Grave junto do plano em
> `docs/plans/<feature>/tasks.md`.

- **Plano de referência:** `docs/plans/<feature>/plan.md`
- **Spec de referência:** `docs/specs/<feature>/spec.md`
- **Evidence:** `docs/plans/<feature>/evidence.md` _(criado na primeira observação de implementação)_

---

## Tabela de tasks

| ID | Descrição | Depende de | AC | Arquivo(s) | Verificação reproduzível | Estado |
|----|-----------|------------|----|------------|--------------------------|--------|
| T1 | <...> | — | AC1 | `<path>` | `<comando>` em `<diretório>` via `<fonte/tool>` → `<resultado observável>` | backlog |
| T2 | <...> | T1 | AC2 | `<path>` | `<ação manual exata>` em `<local>` via `<fonte/tool>` → `<resultado observável>` | backlog |

## Convenções de estado
- **backlog** — ainda não pronta para começar (faltam dependências ou definição).
- **ready** — definida e desbloqueada; pode começar.
- **in-progress** — em execução.
- **verification-pending** — a implementação teve `pass`/`observed` com ref `commit@SHA`/`worktree@SHA`
  em `evidence.md`, mas ainda aguarda reexecução independente por `/sdk-review`.
- **done** — promovida **somente** por `/sdk-review`, depois de um revisor de contexto fresco executar o
  menor subconjunto seguro que cobre a task/AC e registrar recibo `review` com `pass` ou `observed`.
- **blocked** — há impedimento externo ou disjuntor anti-loop, registrado por uma linha canônica
  `- **Bloqueio:** T1 | motivo observado | condição objetiva para voltar a ready` em `evidence.md`.

`blocked → ready` é a única saída do desvio. Se uma task `done` revelar problema, registre bloco
`review | not-run` e `Reclassificacao`, volte-a para `ready` e siga `/sdk-implement` → `/sdk-review`; não
use `reopened`. O estado `partial` não faz parte deste contrato.

## Segurança de dependências

- `verification-pending` exige todas as dependências internas em `verification-pending` ou `done`.
- `done` exige todas as dependências internas em `done`; o `/sdk-review` revisa em ordem topológica.
- Se uma dependência falhar no review, dependentes em `verification-pending`/`done` voltam transitivamente a
  `ready` com recibo `review | not-run`. Dependente antes `done` inclui no mesmo bloco:
  `- **Reclassificacao:** T1 | done | ready | <ISO-8601> | <motivo/referencia>`.
- Detecção mecânica de ciclos não pertence a este PR; continua prevista para a F11/PR IV.

## Cobertura de AC
> Garantir que todo AC da spec tem ao menos uma task. Liste AC sem task aqui (deve ficar vazio antes de
> implementar).

- <nenhum AC descoberto>
