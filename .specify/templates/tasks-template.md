# Tasks — <Nome da Feature>

> **Para o agente:** gerado/atualizado pelo `/sdk-tasks` a partir do plano. Lista ordenada por dependência.
> Cada task tem ID, referencia o AC que satisfaz e tem forma de verificação. Estados:
> `backlog → ready → in-progress → done`. Grave junto do plano em `docs/plans/<feature>/tasks.md`.

- **Plano de referência:** `docs/plans/<feature>/plan.md`
- **Spec de referência:** `docs/specs/<feature>/spec.md`

---

## Tabela de tasks

| ID | Descrição | Depende de | AC | Arquivo(s) | Verificação | Estado |
|----|-----------|-----------|----|-----------|-------------|--------|
| T1 | <...> | — | AC1 | `<path>` | <teste/checagem> | backlog |
| T2 | <...> | T1 | AC2 | `<path>` | <...> | backlog |

## Convenções de estado
- **backlog** — ainda não pronta para começar (faltam dependências ou definição).
- **ready** — definida e desbloqueada; pode começar.
- **in-progress** — em execução.
- **done** — implementada **e verificada** (a verificação da linha passou).

## Cobertura de AC
> Garantir que todo AC da spec tem ao menos uma task. Liste AC sem task aqui (deve ficar vazio antes de
> implementar).

- <nenhum AC descoberto>
