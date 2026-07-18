---
description: Implementa pelo risco e pelos perfis; em feature formal registra evidence e termina tasks em verification-pending ou blocked.
argument-hint: "[nome da feature ou ID da task]"
---

# /sdk-implement — Implementação guiada por risco e prova

Implemente a mudança com a menor cerimônia segura para seu risco.

Primeiro confirme pela constituição se é mudança trivial ou feature formal. Para mudança trivial, carregue
somente o pedido confirmado, o diff/contexto mínimo e a barra de engenharia relevante. Para feature formal,
carregue a spec, o plano e `tasks.md` (`docs/plans/<feature>/`), a constituição e
`engineering-standards.md`; confirme risco, limites de fidelidade e perfis. Leia também
`state-markers.md` e `evidence-template.md`.

## Antes de começar
- **Mudança trivial sem lifecycle formal:** use o pedido confirmado como escopo, execute a verificação
  objetiva e siga para review leve sem inventar spec/task/evidence/ledger. Neste caminho, pule todas as
  instruções abaixo que pressupõem task, recibo ou marcador. Se surgir regra, dado, integração ou qualquer
  item de lógica crítica, pare: a mudança foi subestimada e precisa entrar no fluxo formal.
- **Feature formal:** exija spec e plano aprovados, `tasks.md` e `Analyze: consistente`. Não implemente a
  partir de tabela inline nem fabrique task durante o código.
- **Feature formal — baseline Git existente:** rode `git rev-parse --verify HEAD`. Se o repositório estiver unborn, pare
  antes da primeira observação e crie, com aprovação do usuário, um commit baseline dos artefatos já
  aprovados. Sem SHA real não existe `worktree@SHA`, e ref `unavailable` nunca promove.
- **Branch dedicada** para a feature (não trabalhe direto na branch principal). Crie se não existir.
- **Feature formal:** pegue a próxima task `ready` (ou a indicada). Dependências internas em `verification-pending` ou `done`
  satisfazem a ordem. Marque-a `in-progress`.
- **Feature formal:** task `blocked` só volta a `ready` depois de observar a condição objetiva registrada;
  então pode iniciar.
- **Feature formal:** atualize a linha da feature no ledger (`docs/epics.md`, "Ordem de construção") para `em construção`
  somente se ela ainda estiver antes dessa etapa. Em correção pós-review, preserve `em review`; nunca
  rebaixe o ledger.

## Fluxo por task (somente feature formal)

### O que é "lógica crítica" / "maior risco"
A **definição única** está na `constitution.md`, seção "O que é lógica crítica / mudança de alto risco".
Consulte-a integralmente antes de selecionar a estratégia; não copie nem invente uma segunda lista aqui.

Para cada AC de lógica crítica, TDD é obrigatório:
1. **RED** — escreva o teste, veja-o falhar pela razão certa e registre a rodada `implement | fail`.
2. **GREEN** — escreva o mínimo, rode novamente e registre a nova rodada.
3. **REFACTOR** — melhore, reexecute e registre a rodada que manteve o teste verde.
> Implementou antes de ter um teste falhando? **Apague e recomece** pelo RED. A disciplina é o que dá a
> garantia.

Para lógica não crítica e demais superfícies, execute a prova definida no perfil aplicável — não transforme
copy/estilo em TDD por hábito, nem use checagem visual para provar regra de negócio.

### Perfis e fidelidade

- Execute a linha aplicável da matriz de perfis do plano e respeite os perfis citados pela task.
- Comportamento declarado **real** não pode ser promovido por prova apenas mockada. `sandbox` prova a
  integração naquele ambiente; `simulada` prova somente a simulação declarada, nunca o efeito externo real.
- `visual`: gere referência observável (render, screenshot, preview ou inspeção exata) para os estados/ACs.
- `logic`: rode testes determinísticos; lógica crítica segue RED→GREEN→REFACTOR.
- `journey`: atravesse o fluxo e as fronteiras declaradas, incluindo falha relevante.
- `data-security`: prove integridade e negativas de acesso; quando houver migração/schema, transformação
  destrutiva/em massa ou operação reversível, execute forward e rollback/restauração/recuperação em
  ambiente descartável. Rollback apenas escrito não autoriza `verification-pending` nesses casos.
- `operational`: provoque/observe timeout, retry, idempotência, concorrência, job ou health conforme o plano.
- `delivery`: execute build/package/config/deploy/CI que o plano declarou.

## Evidence por rodada (somente feature formal)

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

## Regras universais
- **Mudanças cirúrgicas:** toque só no necessário; respeite o estilo do código existente.
- **Sem segredos** no código/git/bundle; valide input público; PII fora de logs.
- **Disjuntor anti-loop:** depois de **duas tentativas consecutivas da mesma correção sem progresso
  observável**, **pare**; não faça uma terceira automaticamente. Em feature formal, registre `blocked` e a
  condição objetiva para retomar; em mudança trivial, reporte o bloqueio sem fabricar estado.
- **Convergência:** depois de cumprir ACs, perfis e barra inegociável, melhoria nova Médio/Baixo aceita como
  dívida vai ao ledger; não aumente o escopo aprovado durante a implementação.
- **Feature formal — handoff ao parar no meio:** se a pausa cria `blocked`, grave-o nos campos `Saida/referencia` e
  `Limitacoes` do mesmo bloco negativo que contém `Bloqueio`. Use entrada separada somente para uma pausa
  não bloqueante (por decisão do usuário), ainda com bloco canônico completo. Junto da task, no máximo deixe
  uma referência curta; não duplique narrativa fora do evidence.
- **Motor × produto — siga o inventário canônico do `CLAUDE.md`:** se uma task parecer exigir alteração
  de arquivo do motor, **pare e avise**. Mudança no kit é evolução separada, nunca efeito colateral de
  feature; `project-context.md` e `lessons.md` continuam sendo dados legítimos do projeto.
- Antes de codar lógica de risco, dê uma olhada nas **lições** (`lessons.md`) por tag — evite repetir um erro
  já catalogado.
- Rode os comandos do projeto (test/lint/build). Em feature formal, registre cada rodada, inclusive falha,
  `not-run` e `unavailable`; em mudança trivial, reporte a execução na saída. Ausência nunca vira `pass`.
- Ao terminar, **explique em linguagem simples** o que mudou e por quê (o usuário não aceita o que não
  entende). Se um erro relevante surgiu e foi resolvido no caminho, sugira `/sdk-lesson`.
- **Feature formal:** `partial` e `reopened` são inválidos. Se uma task `done` revelar problema, não a altere aqui: mande ao
  `/sdk-review` para registrar `review | not-run` + `Reclassificacao`, voltar a `ready` e então retomar por
  `/sdk-implement`.

## Saída
- **Mudança trivial:** resumo do diff, verificação objetiva realmente executada e bloqueio/limitação; nenhum
  artefato de lifecycle. Sugira review leve.
- **Feature formal:** resumo por perfil/task/AC e rodadas executadas; tasks somente em `in-progress`,
  `verification-pending` ou `blocked`; handoff com evidence, `Registro`, branch/ref e bloqueios.
- Sugira `/sdk-review` antes de abrir PR/merge. Contexto fresco é o padrão; inline é apenas exceção
  justificada, com o mesmo rerun independente.
