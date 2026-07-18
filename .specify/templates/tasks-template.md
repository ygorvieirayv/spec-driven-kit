# Tasks — <Nome da Feature>

> **Para o agente:** gerado/atualizado pelo `/sdk-tasks` a partir do plano. Lista ordenada por dependência.
> Este é o artefato **canônico** de tasks para toda feature formal. Cada task tem ID, referencia o AC e os
> perfis de prova que satisfaz e tem forma de verificação. Estados:
> `backlog → ready → in-progress → verification-pending → done`. `blocked` é um desvio temporário e volta
> para `ready` quando sua condição objetiva for satisfeita. Grave junto do plano em
> `docs/plans/<feature>/tasks.md`.

- **Plano de referência:** `docs/plans/<feature>/plan.md`
- **Spec de referência:** `docs/specs/<feature>/spec.md`
- **Evidence:** `docs/plans/<feature>/evidence.md` _(criado na primeira observação de implementação)_

---

## Tabela de tasks

| ID | Descrição | Depende de | AC | Perfis | Arquivo(s) | Verificação reproduzível | Estado |
|----|-----------|------------|----|--------|------------|--------------------------|--------|
| T1 | <...> | — | AC1 | logic, delivery | `<path>` | `<comando>` em `<diretório>` via `<fonte/tool>` → `<resultado observável>` | backlog |
| T2 | <...> | T1 | AC2 | visual | `<path>` | `<ação manual exata>` em `<local>` via `<fonte/tool>` → `<resultado observável>` | backlog |

Depois do primeiro `Registro` de uma task, ID, significado, dependências, ACs, **Perfis** e verificação são
históricos e não podem ser remapeados para fazer a prova antiga cobrir outro contrato. Evolução cria novo
AC/task ou uma delta feature.

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
- **Depende de** aceita somente `—` ou IDs internos separados por vírgula (`T1` ou `T1, T2`). Referência
  inexistente/repetida, texto livre, célula vazia e ciclo falham no `sdk-check` em qualquer estado. Relação
  com outra feature/serviço fica na spec/roadmap, não nessa coluna.

## Cobertura de AC e perfis
> Garanta que todo AC e todo perfil `aplicável` do plano têm ao menos uma task. Cada task cita ao menos um
> perfil aplicável; perfil marcado `N/A` não aparece na tabela. Liste lacunas aqui (deve ficar vazio antes
> de implementar).

- <nenhum AC descoberto>
- <nenhum perfil aplicável descoberto>
