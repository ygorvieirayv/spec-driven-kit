---
description: Implementa uma feature seguindo o plano. Em PRODUCTION, usa TDD (RED→GREEN→REFACTOR) na lógica crítica. Branch dedicada.
argument-hint: "[nome da feature ou ID da task]"
---

# /sdk-implement — Implementação (TDD em PRODUCTION)

Implemente a feature seguindo o plano e as tasks, mantendo a spec como fonte da verdade.

Carregue: a spec (`docs/specs/<feature>/spec.md`), o plano e as tasks (`docs/plans/<feature>/`),
`.specify/memory/constitution.md` e `.specify/memory/engineering-standards.md`. Confirme o **modo** no
`project-context.md`.

## Antes de começar
- **Branch dedicada** para a feature (não trabalhe direto na branch principal). Crie se não existir.
- Pegue a próxima task `ready` (ou a indicada). Marque-a `in-progress`.

## Fluxo por task

### Modo PRODUCTION — TDD na lógica crítica
Para cada AC de lógica crítica:
1. **RED** — escreva o teste que expressa o AC e veja-o **falhar** (confirme que falha pela razão certa).
2. **GREEN** — escreva o **mínimo** de código para o teste passar.
3. **REFACTOR** — melhore o código mantendo o teste verde.
> Implementou antes de ter um teste falhando? **Apague e recomece** pelo RED. A disciplina é o que dá a
> garantia.

### Modo PROTOTYPE
- Implemente o caminho feliz da lógica de maior risco; smoke test do fluxo principal. Menos cerimônia, mas
  ainda **verificável**.

## Regras (valem nos dois modos)
- **Mudanças cirúrgicas:** toque só no necessário; respeite o estilo do código existente.
- **Sem segredos** no código/git/bundle; valide input público; PII fora de logs.
- Rode os comandos do projeto (test/lint/build) e **mostre que passam**.
- Atualize o estado da task para `done` somente quando a verificação **passar**.

## Saída
- Resumo do que foi implementado, por AC, com a verificação que comprova.
- Tasks atualizadas.
- Sugira `/sdk-review` (idealmente em contexto fresco) antes de abrir PR/merge.
