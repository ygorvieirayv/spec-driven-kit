---
description: Gera ou atualiza a lista de tasks rastreáveis de uma feature (estado backlog→ready→in-progress→done), cada task ligada a um AC.
argument-hint: "[nome da feature]"
---

# /sdk-tasks — Tasks rastreáveis

Gere ou atualize a lista de tasks de uma feature a partir do plano. Grave em
`docs/plans/<feature>/tasks.md` usando o `tasks-template.md`.

Carregue: o plano (`docs/plans/<feature>/plan.md`), a spec (`docs/specs/<feature>/spec.md`) e
`.specify/templates/tasks-template.md`.

## O que fazer

1. **Derive as tasks** do plano. Cada task precisa de: ID, descrição, dependências, **AC que satisfaz**,
   arquivo(s) afetado(s), forma de **verificação** e **estado**.
2. **Ordene por dependência** (uma task só fica `ready` quando suas dependências estão `done`).
3. **Cobertura de AC:** confira que **todo** AC da spec tem ao menos uma task. Liste AC sem task — deve ficar
   vazio antes de implementar.
4. **Atualização:** se já existir `tasks.md`, atualize estados e adicione/remova tasks conforme o plano
   mudou, preservando o histórico de IDs.

## Estados
`backlog` (não pronta) → `ready` (desbloqueada) → `in-progress` (em execução) → `done` (implementada **e
verificada**).

## Saída
- Grave/atualize `docs/plans/<feature>/tasks.md`.
- Mostre a tabela e aponte a próxima task `ready`.
- Sugira `/sdk-implement` para executar a próxima task.
