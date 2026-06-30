---
description: Gera ou atualiza a lista de tasks rastreáveis de uma feature (estado backlog→ready→in-progress→done), cada task ligada a um AC.
argument-hint: "[nome da feature]"
---

# /sdk-tasks — Tasks rastreáveis

Gere ou atualize a lista de tasks de uma feature a partir do plano. Em **PRODUCTION**, grave em
`docs/plans/<feature>/tasks.md` usando o `tasks-template.md`. Em **PROTOTYPE**, a tabela "Tasks" que já está
dentro do `plan.md` pode bastar (ver matriz de rigor em `constitution.md`) — não duplique em arquivo
separado só por hábito.

Carregue: o plano (`docs/plans/<feature>/plan.md`), a spec (`docs/specs/<feature>/spec.md`), o
`project-context.md` (para confirmar o modo) e, se for gerar arquivo separado,
`.specify/templates/tasks-template.md`.

## O que fazer

0. **Confira o modo.** Se PROTOTYPE e a tabela inline do `plan.md` já cobre o que falta, atualize-a ali
   mesmo e pare por aqui. Se PRODUCTION — ou o usuário quer rastreio mais forte mesmo em PROTOTYPE — siga os
   passos abaixo.
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
- Grave/atualize `docs/plans/<feature>/tasks.md` (ou a tabela inline do `plan.md`, se ficou em PROTOTYPE).
- Mostre a tabela e aponte a próxima task `ready`.
- Sugira `/sdk-analyze` (conferir consistência antes de codar) e, em seguida, `/sdk-implement`.
