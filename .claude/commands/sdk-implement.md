---
description: Implementa uma feature, registra cada rodada em evidence.md e termina tasks em verification-pending ou blocked. Em PRODUCTION, usa TDD na lógica crítica.
argument-hint: "[nome da feature ou ID da task]"
---

# /sdk-implement — Implementação (TDD em PRODUCTION)

Implemente a feature seguindo o plano e as tasks, mantendo a spec como fonte da verdade.

Carregue: a spec (`docs/specs/<feature>/spec.md`), o plano e as tasks (`docs/plans/<feature>/`),
`.specify/memory/constitution.md` e `.specify/memory/engineering-standards.md`. Confirme o **modo** no
`project-context.md`. Leia também `.specify/memory/state-markers.md` e
`.specify/templates/evidence-template.md`.

## Antes de começar
- **Baseline Git existente:** rode `git rev-parse --verify HEAD`. Se o repositório estiver unborn, pare
  antes da primeira observação e crie, com aprovação do usuário, um commit baseline dos artefatos já
  aprovados. Sem SHA real não existe `worktree@SHA`, e ref `unavailable` nunca promove.
- **Branch dedicada** para a feature (não trabalhe direto na branch principal). Crie se não existir.
- Pegue a próxima task `ready` (ou a indicada). Dependências internas em `verification-pending` ou `done`
  satisfazem a ordem. Marque-a `in-progress`.
- Task `blocked` só volta a `ready` depois de observar a condição objetiva registrada; então pode iniciar.
- Atualize a linha da feature no ledger (`docs/epics.md`, "Ordem de construção") para `em construção`
  somente se ela ainda estiver antes dessa etapa. Em correção pós-review, preserve `em review`; nunca
  rebaixe o ledger.

## Fluxo por task

### O que é "lógica crítica" / "maior risco" (vale nos dois modos)
A **definição única** está na `constitution.md`, seção "O que é lógica crítica / mudança de alto risco" —
dinheiro, acesso/autorização, dados pessoais ou irrecuperáveis (migração/deleção), integração da qual o
fluxo depende, erro já catalogado nas lições. Não invente uma segunda lista aqui.

Isso entra no TDD completo em PRODUCTION e ganha pelo menos um teste de caminho feliz em PROTOTYPE. O resto
(estilo visual, copy, ordenação não-crítica) pode ficar mais leve nos dois modos — não vire TDD por hábito.

### Modo PRODUCTION — TDD na lógica crítica
Para cada AC de lógica crítica:
1. **RED** — escreva o teste, veja-o falhar pela razão certa e registre a rodada `implement | fail`.
2. **GREEN** — escreva o mínimo, rode novamente e registre a nova rodada.
3. **REFACTOR** — melhore, reexecute e registre a rodada que manteve o teste verde.
> Implementou antes de ter um teste falhando? **Apague e recomece** pelo RED. A disciplina é o que dá a
> garantia.

### Modo PROTOTYPE
- Implemente o caminho feliz da lógica de maior risco; smoke test do fluxo principal. Menos cerimônia, mas
  ainda **verificável**.

## Evidence por rodada

Na primeira ação observada, crie `docs/plans/<feature>/evidence.md` pelo template e substitua todos os
placeholders da primeira entrada — não preserve o exemplo como se fosse evidência. Cada execução,
observação, falha ou indisponibilidade vira um **novo bloco append-only** no formato canônico. Atualize
apenas o resumo; nunca reescreva entradas anteriores nem grave `Registro` fora de um bloco.

```md
### E1 - 2026-07-17T21:57:18Z - T1 - implement
- **Registro:** T1 | AC1, AC2 | implement | pass | worktree@abcdef1
- **Acao/comando:** npm test -- --runInBand
- **Diretorio:** C:/repo
- **Fonte:** test runner do projeto
- **Exit code:** 0
- **Saida/referencia:** 12 testes passaram; log em artifacts/test.log
- **Branch:** feat/exemplo
- **Limitacoes:** nenhuma
```

- Cabeçalho: `### E<n> - <ISO-8601> - T<n> - <implement|review>`; use `E1`, `E2`, `E3`... em ordem,
  sem reutilizar nem saltar ID.
- Use exatamente os sete labels ASCII do exemplo, todos preenchidos; task/fase do cabeçalho e `Registro`
  precisam coincidir.
- Resultado: `pass`, `fail`, `observed`, `not-run`, `unavailable`.
- Ref: `commit@<7-40 hex>`, `worktree@<7-40 hex>` ou `unavailable`.
- `Exit code`: `pass` = `0`; `fail` = inteiro diferente de zero; `observed`/`not-run` =
  `not-applicable`; `unavailable` = `unavailable`.
- A ref registra somente proveniência; não compare com HEAD nem use `current`/`historical` nesta versão.
- `pass`/`observed` cobrindo a verificação planejada **e todos os ACs declarados na task**, com ref
  `commit@SHA`/`worktree@SHA` →
  `verification-pending`; ref `unavailable` nunca avança.
- `fail` corrigível → permanece `in-progress`; `not-run` não avança.
- Impedimento externo ou disjuntor anti-loop → `blocked`; o `Registro` negativo, `Bloqueio` e o handoff
  ficam no **mesmo bloco**:

```md
- **Bloqueio:** T1 | <motivo observado> | <condição objetiva para voltar a ready>
```

Nunca marque `done`; essa promoção pertence somente a `/sdk-review` em contexto fresco.

## Regras (valem nos dois modos)
- **Mudanças cirúrgicas:** toque só no necessário; respeite o estilo do código existente.
- **Sem segredos** no código/git/bundle; valide input público; PII fora de logs.
- **Disjuntor anti-loop:** se a mesma coisa falhar **2–3 vezes sem progresso**, **pare**. Não insista no
  escuro queimando token. Resuma o que tentou, o que observou e onde travou, e devolva ao usuário com opções.
- **Handoff ao parar no meio:** se a pausa cria `blocked`, grave-o nos campos `Saida/referencia` e
  `Limitacoes` do mesmo bloco negativo que contém `Bloqueio`. Use entrada separada somente para uma pausa
  não bloqueante (por decisão do usuário), ainda com bloco canônico completo. Junto da task, no máximo deixe
  uma referência curta; não duplique narrativa fora do evidence.
- **Não toque no motor do kit** durante uma feature (comandos/agents `sdk-*`, `.specify/memory/` exceto
  `project-context.md`, templates, `scripts/sdk-*`, `CLAUDE.md`): se uma task parecer exigir isso, **pare e
  avise** — mudança no kit é evolução separada, nunca efeito colateral de feature.
- Antes de codar lógica de risco, dê uma olhada nas **lições** (`lessons.md`) por tag — evite repetir um erro
  já catalogado.
- Rode os comandos do projeto (test/lint/build) e registre cada rodada, inclusive falha, `not-run` e
  `unavailable`. Ausência de execução nunca vira `pass`.
- Ao terminar, **explique em linguagem simples** o que mudou e por quê (o usuário não aceita o que não
  entende). Se um erro relevante surgiu e foi resolvido no caminho, sugira `/sdk-lesson`.
- `partial` e `reopened` são inválidos. Se uma task `done` revelar problema, não a altere aqui: mande ao
  `/sdk-review` para registrar `review | not-run` + `Reclassificacao`, voltar a `ready` e então retomar por
  `/sdk-implement`.

## Saída
- Resumo por task/AC e das rodadas realmente executadas.
- Tasks atualizadas somente para `in-progress`, `verification-pending` ou `blocked`.
- Handoff com caminho do evidence, linhas `Registro`, branch/ref, checks pendentes e bloqueios.
- Sugira `/sdk-review` antes de abrir PR/merge. Contexto fresco é o padrão; inline é apenas exceção
  justificada, com o mesmo rerun independente.
