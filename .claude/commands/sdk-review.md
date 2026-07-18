---
description: Revisa o diff e reexecuta verificações em contexto fresco. Só esta etapa promove verification-pending para done; Crítico sempre e Alto em PRODUCTION bloqueiam.
argument-hint: "[nome da feature, opcional]"
---

# /sdk-review — Revisão contra spec + padrões

Revise o trabalho feito contra a **spec**, o **plano** e a **barra de engenharia**. O objetivo é pegar
divergências, regressões e riscos antes de considerar pronto.

## Contexto fresco (padrão)
A promoção usa por padrão o `sdk-reviewer` com contexto limpo, recebendo spec, plano/tasks, evidence, diff e
barra normativa. Se o ambiente não suportar subagente, revisão inline pode promover somente como exceção
justificada: registre o motivo e reexecute a mesma prova independente exigida abaixo, gerando recibo `review`.

## Insumos
- O **diff** a revisar (`git diff` da branch/feature, ou as mudanças não commitadas).
- A spec: `docs/specs/<feature>/spec.md`.
- O plano: `docs/plans/<feature>/plan.md`.
- As tasks e `docs/plans/<feature>/evidence.md`, se existir.
- A barra: `.specify/memory/engineering-standards.md` e a `constitution.md`.
- O contrato: `.specify/memory/state-markers.md` e `.specify/templates/evidence-template.md`.

Ao começar, atualize a linha da feature no ledger (`docs/epics.md`, "Ordem de construção") para `em review`.

## Gate de verificação independente

Processe as tasks em **ordem topológica**. Para cada task em `verification-pending`:

1. confirme que todas as dependências internas já estão `done`; uma task só pode ficar `done` nessa
   condição;
2. relacione a verificação citada, os recibos `implement` e os ACs;
3. peça ao revisor fresco para reexecutar o **menor subconjunto seguro** que cubra task e ACs;
4. receba recibo completo que liste todos os ACs declarados na task e anexe um novo bloco append-only:

```md
### E4 - 2026-07-17T21:57:18Z - T1 - review
- **Registro:** T1 | AC1, AC2 | review | pass | worktree@abcdef1
- **Acao/comando:** npm test -- --runInBand
- **Diretorio:** C:/repo
- **Fonte:** test runner do projeto
- **Exit code:** 0
- **Saida/referencia:** 12 testes passaram; log em artifacts/test.log
- **Branch:** feat/exemplo
- **Limitacoes:** nenhuma
```

5. se a reexecução for satisfatória **e não houver achado que bloqueie a task**, aplique:
   `pass`/`observed` completo **com ref `commit@SHA` ou `worktree@SHA`** → `done`; `fail` → `ready`;
   dependência externa `unavailable` →
   `blocked` com `- **Bloqueio:** T1 | motivo observado | condição objetiva para voltar a ready`;
   `not-run` não promove e mantém `verification-pending` salvo bloqueio observado. Recibo incompleto é
   inválido e não altera estado.

O bloco usa cabeçalho `### E<n> - <ISO-8601> - T<n> - <implement|review>`, exatamente um `Registro` e os
sete labels ASCII do exemplo, sem placeholders. `Exit code`: `pass=0`; `fail=inteiro diferente de zero`;
`observed|not-run=not-applicable`; `unavailable=unavailable`. Cada rerun gera entrada nova. Sem recibo
`review` bem-sucedido, não há `done`.

### Falha, bloqueio e cascata de dependências

- `fail` manda a task para `ready`; a correção obrigatoriamente passa por `/sdk-implement` e só depois por
  novo `/sdk-review`.
- `unavailable` que bloqueia usa `Bloqueio` e handoff no **mesmo bloco negativo**.
- Quando uma task falhar ou ficar bloqueada, encontre transitivamente seus dependentes em
  `verification-pending` ou `done` e reclassifique-os para `ready`, em ordem topológica. Para cada
  dependente, anexe bloco completo `review | not-run` explicando em `Saida/referencia` que a prova não foi
  rerodada porque a dependência deixou de estar `done`.
- Se o dependente estava `done`, inclua no mesmo bloco:

```md
- **Reclassificacao:** T2 | done | ready | 2026-07-17T21:57:18Z | T1 deixou de estar done; ver E4
```

Não faça detecção mecânica de ciclos neste PR; essa guarda permanece prevista para a F11/PR IV.

### Contrato estrito

Plan/tasks precisa conter `- **Evidence:**` apontando para a própria feature. O arquivo nasce na primeira
observação real; quando um estado exige prova, ausência de recibo é erro. Não há modo legado nem evidência
retrospectiva.

## O que checar
1. **Spec ↔ código:** cada AC foi atendido? Há comportamento fora do escopo declarado?
2. **Plano ↔ código:** seguiu a abordagem e as decisões (ADRs)? Desvios justificados?
3. **Barra de engenharia — percorra item a item** (não troque pela leitura corrida; o detalhe de cada item
   está em `.specify/memory/engineering-standards.md`). Roda **igual nos dois modos** — o que muda com o
   modo é só o quanto um achado fora da barra "Sempre" bloqueia ou vira dívida anotada (ver matriz de rigor
   da `constitution.md`):
   - [ ] Segredos fora do código/git/bundle/logs (inclui o bundle que vai pro navegador)
   - [ ] Toda entrada pública validada **no servidor** (não só na UI)
   - [ ] PII fora de logs, mensagens de erro e telemetria
   - [ ] AuthN (quem é) e AuthZ (pode fazer isto?) checadas no servidor em toda rota protegida
   - [ ] Timeouts em toda chamada de rede; retry só em operação idempotente
   - [ ] Rate limiting em endpoint público/autenticação, se aplicável
   - [ ] Sem N+1 óbvio; paginação em listagem que pode crescer
   - [ ] Trabalho pesado (mídia, e-mail, IA) fora do caminho do request
   - [ ] Cache, se houver, tem plano de invalidação
   - [ ] Verificações cobrindo os AC; lógica crítica com teste automatizado (ver QA abaixo)

   O que não se aplica, marque **N/A com 1 linha do porquê** — nunca pule em silêncio.
4. **Constituição:** mudança cirúrgica? Simples? Verificável? Sem regra de domínio inventada?
5. **Lições conhecidas:** consulte `.specify/memory/lessons.md` por tag relevante (grep) e verifique se o
   diff cai em algum padrão já catalogado (ex.: `#cache`, `#segredos`, `#integração`). Se um erro novo
   aparecer aqui, sugira registrá-lo com `/sdk-lesson` depois de corrigido.
6. **Fronteira motor × produto:** o diff toca arquivos do **motor do kit** (`.claude/commands/sdk-*`,
   `.claude/agents/sdk-*`, `.specify/memory/` — exceto `project-context.md` —, `.specify/templates/`,
   `scripts/sdk-*`, `scripts/new-feature.*`, `CLAUDE.md`, `COMO-USAR.md`)? Isso **não** é parte da feature:
   reporte como drift **Crítico** e trate a mudança do kit como evolução separada — nunca como efeito
   colateral corrigido em silêncio.
7. **Evidence ↔ estados:** todo `done` tem recibo `review` completo
   e bem-sucedido? Todo `blocked` tem motivo/condição no mesmo bloco negativo? `verification-pending` depende
   apenas de `verification-pending`/`done` e `done` apenas de `done`? Entradas antigas permaneceram
   intactas? IDs e significados já citados por recibos permaneceram históricos e imutáveis?

## QA — risco e rastreabilidade de testes
Além de achar bugs, faça uma leitura de QA (no espírito de um "test architect", mas simples):

- **Rastreabilidade:** monte um mapa **AC → verificação**. Todo AC tem ao menos uma verificação que o cobre —
  teste automatizado **ou** checagem manual legítima e registrada? Liste os AC **sem** verificação — são
  buracos (tendem a Médio/Alto). **Exceção sem flexibilidade:** AC de **lógica crítica** (definição única na
  `constitution.md`) exige **teste automatizado**; checagem manual não basta, e AC crítico coberto só por
  checagem manual é achado **Alto**.
- **Avaliação de risco:** aponte as 1–3 áreas com **maior chance de quebrar × maior impacto** (ex.: dinheiro,
  dados do usuário, segurança). Diga onde valeria um teste extra ou um par de olhos humano.
- **Teste que não testa:** desconfie de teste que nunca falha (ver lição `#testes`). Confirme que ele pega a
  regressão que deveria pegar.

Mantenha leve: o objetivo é direcionar atenção para o que é arriscado, não burocratizar.

## Severidade
- **Crítico** — segurança, perda de dados, vazamento de segredo/PII, AC essencial quebrado. **Bloqueia
  sempre, nos dois modos.**
- **Alto** — bug provável, desvio relevante da spec/plano, AC sem nenhuma verificação (ou AC crítico sem
  teste automatizado). **Bloqueia em PRODUCTION** (matriz de rigor da constituição); em PROTOTYPE pode
  virar dívida anotada, nunca ignorada.
- **Médio** — qualidade, manutenção, cobertura de verificação insuficiente.
- **Baixo** — estilo, melhorias opcionais.

## Saída
- Lista de achados **agrupada por severidade**, cada um com arquivo:linha e sugestão de correção.
- Mapa task/AC → check reexecutado → recibo → estado.
- Veredito: **aprovado** / **aprovado com ressalvas** / **bloqueado**. Crítico bloqueia sempre; **Alto
  bloqueia em PRODUCTION** — só em PROTOTYPE um Alto pode descer para "aprovado com ressalvas", com a
  dívida anotada. Task sem recibo bem-sucedido impede `aprovado`.
- **Registre o veredito no plano** (**conversa aprova, arquivo registra**): atualize a linha `**Review:**`
  do cabeçalho de `docs/plans/<feature>/plan.md` com `<veredito> — <data>`. Só marque o ledger como
  `concluída` se todas as tasks essenciais estiverem `done`, todos os ACs tiverem recibo e o veredito for
  **aprovado**; senão, mantenha `em review`.
- Não conserte em silêncio durante a revisão — reporte; a correção é um passo à parte.
- Se o veredito exigir correção, indique explicitamente `/sdk-implement` como próximo passo e somente depois
  um novo `/sdk-review`.

## Fecho de ciclo (alimentar a biblioteca de lições)
Se algum achado revelou um erro **generalizável** — um padrão que poderia acontecer em qualquer projeto, não
um detalhe pontual deste código —, **proponha registrá-lo com `/sdk-lesson`** assim que for corrigido. É
assim que a biblioteca aprende com o erro **uma vez só**. Não force: se o achado é trivial/específico, siga
em frente. Um bom gatilho: achado **Crítico** ou **Alto** que casa com (ou amplia) uma tag de `lessons.md`.
