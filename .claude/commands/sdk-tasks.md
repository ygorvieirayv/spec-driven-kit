---
description: Gera ou atualiza tasks rastreáveis no ciclo backlog→ready→in-progress→verification-pending→done, com blocked como desvio, cada task ligada a um AC.
argument-hint: "[nome da feature]"
---

# /sdk-tasks — Tasks rastreáveis

Gere ou atualize a lista canônica de tasks de uma feature a partir do plano. Toda feature formal, inclusive
de baixo risco, grava `docs/plans/<feature>/tasks.md` usando o `tasks-template.md`. O plano não mantém uma
segunda tabela de tasks.

Carregue: o plano (`docs/plans/<feature>/plan.md`), a spec (`docs/specs/<feature>/spec.md`), o
`project-context.md`, `.specify/memory/engineering-standards.md` (seção de perfis) e
`.specify/templates/tasks-template.md`.

Leia em `.specify/memory/state-markers.md` somente **Os marcadores**, **Regras transversais** e **Ciclo
normativo das tasks**; essas seções são normativas para estados e transições. Carregue **Contrato de
evidence** apenas se estiver reconciliando recibos já existentes.

## O que fazer

1. **Derive as tasks** do plano. Cada task precisa de: ID, descrição, dependências, **AC que satisfaz**,
   **perfil(is) de prova aplicável(is)**, arquivo(s) afetado(s), forma de **verificação** e **estado**. A
   verificação traz ação/comando exato, diretório/local, fonte/tool e resultado observável. Passo manual
   precisa ser igualmente reproduzível.
2. **Ordene por dependência.** A célula **Depende de** contém somente `—` ou IDs internos separados por
   vírgula (`T1` ou `T1, T2`), sem texto livre, repetição ou referência externa. Para implementar,
   dependências internas em `verification-pending` ou `done` satisfazem a ordem; para uma task ficar
   `done`, todas precisam estar `done`. Rode `sdk-check`: qualquer referência inexistente ou ciclo bloqueia.
3. **Cobertura de AC e perfis:** confira que **todo** AC da spec e **todo** perfil `aplicável` do plano têm
   ao menos uma task. Cada task cita ao menos um perfil aplicável; perfil `N/A` não pode aparecer. Se uma
   task citar vários perfis, a verificação cobre todos; caso contrário, fatie. As duas listas de lacunas
   precisam ficar vazias antes de implementar.
4. **Atualização:** se já existir `tasks.md`, atualize estados e adicione/remova somente tasks que ainda não
   têm `Registro`, preservando o histórico de IDs. Depois do primeiro recibo, ID, descrição/semântica,
   dependências, ACs, perfis e verificação não são apagados nem reutilizados. Mudança semântica ganha novo AC/task
   ou delta feature.
   Uma task não concluída retirada do escopo fica em `backlog`, com o texto original seguido de
   `[DESCONTINUADA: <decisão/referência>]`; `done` permanece histórica. Não reclassifique silenciosamente
   task `done`: sob contrato
   estrito, mande o caso ao `/sdk-review`, que grava bloco `review | not-run` + `Reclassificacao` e então a
   move para `ready`; depois o fluxo segue `/sdk-implement` → `/sdk-review`.
5. **Evidence ainda não nasce aqui.** Em artefato novo, registre o marker para
   `docs/plans/<feature>/evidence.md`; somente `/sdk-implement` cria o arquivo na primeira observação real.
   O marker é obrigatório na fonte das tasks e precisa apontar para a própria feature.

## Estados
`backlog` → `ready` → `in-progress` → `verification-pending` → `done`.

- `blocked` é desvio temporário e volta para `ready` quando a condição objetiva registrada for satisfeita.
- `/sdk-implement` move até `verification-pending` ou `blocked`; nunca para `done`.
- Somente `/sdk-review`, em ordem topológica, promove para `done` após reexecução independente com recibo.
- Falha de uma dependência reclassifica transitivamente dependentes `verification-pending`/`done` para
  `ready`; os recibos e o marker `Reclassificacao` seguem `state-markers.md`.
- `partial` e `reopened` são inválidos.

## Saída
- Grave/atualize `docs/plans/<feature>/tasks.md`. Se as tasks **mudaram** depois de uma análise, volte a
  linha `**Analyze:**` do plano para `pendente`.
- Mostre a tabela e aponte a próxima task `ready`.
- Sugira `/sdk-analyze` (conferir consistência antes de codar) e, em seguida, `/sdk-implement`.
