---
description: Revisa o diff e reexecuta provas por perfil em contexto fresco. Só esta etapa promove verification-pending para done; Crítico e Alto bloqueiam sempre.
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
- O contrato: em `.specify/memory/state-markers.md`, somente **Os marcadores**, **Regras transversais**,
  **Ciclo normativo das tasks** e **Contrato de evidence**. Carregue
  `.specify/templates/evidence-template.md` apenas se precisar conferir ou reparar a forma estrutural do
  arquivo — não como leitura fixa de toda revisão.
- O contrato de CI em `.specify/memory/project-context.md` quando `delivery` for aplicável.

Se a mudança foi classificada como **trivial** e não possui lifecycle formal, use o pedido confirmado, o
diff e a verificação objetiva como insumos; não invente task/evidence nem altere ledger. Se o diff revelar
risco acima de trivial, bloqueie e peça formalização por `/sdk-spec`.

Para **feature formal**, trate a linha do ledger (`docs/epics.md`, "Ordem de construção") como `em review`.
Se `delivery` exigir CI remoto, observe primeiro o commit publicado com worktree limpo **antes de gravar**
qualquer estado; aplique `em review` junto do primeiro recibo/resultado da revisão. Nos demais casos, grave
`em review` ao começar. Para mudança trivial, faça a revisão leve diretamente pelo diff e pela verificação
objetiva; as regras de severidade e a barra inegociável continuam iguais.

## Gate de verificação independente

Em feature formal, processe as tasks em **ordem topológica**. Para cada task em `verification-pending`:

1. confirme que todas as dependências internas já estão `done`; uma task só pode ficar `done` nessa
   condição;
2. relacione a verificação citada, os recibos `implement` e os ACs;
3. relacione também os perfis da task com a matriz de prova do plano e os limites de fidelidade da spec;
4. peça ao revisor fresco para reexecutar o **menor subconjunto seguro** que cubra task, ACs e perfis;
5. receba recibo completo que liste todos os ACs declarados na task e anexe um novo bloco append-only:

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

6. se a reexecução for satisfatória **e não houver achado que bloqueie a task**, aplique:
   `pass`/`observed` completo **com ref `commit@SHA` ou `worktree@SHA`** → `done`; `fail` → `ready`;
   dependência externa `unavailable` →
   `blocked` com `- **Bloqueio:** T1 | motivo observado | condição objetiva para voltar a ready`;
   `not-run` não promove e mantém `verification-pending` salvo bloqueio observado. Recibo incompleto é
   inválido e não altera estado.

O bloco usa cabeçalho `### E<n> - <ISO-8601> - T<n> - <implement|review>`, exatamente um `Registro` e os
sete labels ASCII do exemplo, sem placeholders. `Exit code`: `pass=0`; `fail=inteiro diferente de zero`;
`observed|not-run=not-applicable`; `unavailable=unavailable`. Cada rerun gera entrada nova. Sem recibo
`review` bem-sucedido, não há `done`.

Depois de anexar cada recibo e aplicar a transição correspondente, atualize **somente** o `Resumo
atualizável` do `evidence.md` existente: última atualização; tasks com implementação observada,
aguardando revisão, concluídas e bloqueadas; ACs cobertos/faltantes; falhas e limitações abertas. Derive o
agregado das tasks e entradas atuais, sem reescrever o histórico. Isso mantém a leitura barata do
`/sdk-next` coerente sem exigir o template como carga fixa.

Quando o perfil `delivery` exigir CI, publique primeiro um commit de implementação com worktree limpo.
Consulte o provedor (por exemplo `gh pr checks`/Check Runs) e aceite somente `completed/success` de
`Quality gates` e `Secret scan` cujo `head_sha` seja exatamente o commit de implementação revisado. Registre URL e SHA em
`Saida/referencia`; isso usa `commit@SHA`, nunca `worktree@SHA`. Ao aplicar o recibo, altere somente
evidence/estado (`evidence.md`, `tasks.md`, `plan.md` e ledger), criando um commit de finalização. Os checks
desse SHA final permanecem gate **externo** de merge: aguarde e reporte o veredito, mas não anexe novo recibo
nem crie outro commit, evitando ciclo infinito de SHA. CI anterior, job ausente/pending, provedor
indisponível ou mudança de produto posterior não promove a task.

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

O `sdk-check` já rejeita ciclos e referências inválidas no grafo interno de `tasks.md`. Isso não substitui
o `/sdk-analyze`, que continua responsável pelas dependências semânticas entre features, serviços e dados.

### Contrato estrito

Plan/tasks precisa conter `- **Evidence:**` apontando para a própria feature. O arquivo nasce na primeira
observação real; quando um estado exige prova, ausência de recibo é erro. Não fabrique evidência
retrospectiva.

## O que checar
1. **Spec ↔ código:** cada AC foi atendido? Há comportamento fora do escopo declarado?
2. **Plano ↔ código:** seguiu a abordagem e as decisões (ADRs)? Desvios justificados?
3. **Barra de engenharia — percorra item a item** (não troque pela leitura corrida; o detalhe de cada item
   está em `.specify/memory/engineering-standards.md`). A barra é única; Crítico/Alto bloqueiam e `N/A`
   sempre exige motivo:
   - [ ] Segredos fora do código/git/bundle/logs (inclui o bundle que vai pro navegador)
   - [ ] Contrato de CI completo: seis gates iguais à matriz `required`/`N/A`, sem bypass; runner/setup
         aprovados; Gitleaks preserva defaults; checks remotos verdes quando `delivery` exigir CI
   - [ ] Toda entrada pública validada **no servidor** (não só na UI)
   - [ ] PII fora de logs, mensagens de erro e telemetria
   - [ ] AuthN (quem é) e AuthZ (pode fazer isto?) checadas no servidor em toda rota protegida
   - [ ] Timeouts em toda chamada de rede; retry só em operação idempotente
   - [ ] Rate limiting em endpoint público/autenticação, se aplicável
   - [ ] Sem N+1 óbvio; paginação em listagem que pode crescer
   - [ ] Trabalho pesado (mídia, e-mail, IA) fora do caminho do request
   - [ ] Cache, se houver, tem plano de invalidação
   - [ ] Verificações cobrindo os AC; lógica crítica com teste automatizado (ver QA abaixo)
   - [ ] Limite `sandbox`/`simulada` não é apresentado como efeito real; a sinalização exigida está observável
   - [ ] Cada perfil aplicável do plano está coberto por task e prova compatível com a fidelidade
   - [ ] `data-security` com migração/schema ou transformação destrutiva/em massa tem forward e rollback/restauração realmente executados

   O que não se aplica, marque **N/A com 1 linha do porquê** — nunca pule em silêncio.
4. **Constituição:** mudança cirúrgica? Simples? Verificável? Sem regra de domínio inventada?
5. **Lições conhecidas:** consulte `.specify/memory/lessons.md` por tag relevante (grep) e verifique se o
   diff cai em algum padrão já catalogado (ex.: `#cache`, `#segredos`, `#integração`). Se um erro novo
   aparecer aqui, sugira registrá-lo com `/sdk-lesson` depois de corrigido.
6. **Motor × produto — confronte com o inventário canônico do `CLAUDE.md`:** arquivo de motor no diff da
   feature é drift **Crítico** e evolução separada, nunca efeito colateral. `project-context.md` e
   `lessons.md` são dados do projeto; editá-los pelos comandos donos não é drift do motor.
   `.github/workflows/sdk-quality.yml` e `.specify/ci/gates/` são configuração do produto: podem mudar por
   feature `delivery`, mas remover `Secret scan`, enfraquecer histórico/hash ou criar bypass é achado Alto.
7. **Evidence ↔ estados:** todo `done` tem recibo `review` completo
   e bem-sucedido? Todo `blocked` tem motivo/condição no mesmo bloco negativo? `verification-pending` depende
   apenas de `verification-pending`/`done` e `done` apenas de `done`? Entradas antigas permaneceram
   intactas? IDs e significados já citados por recibos permaneceram históricos e imutáveis?
8. **Perfis ↔ prova:** monte o mapa `perfil → task/AC → E<n>`. Perfil aplicável sem task/recibo, task
   citando perfil `N/A`, prova incompatível com fidelidade ou rollback apenas narrado bloqueiam a promoção.

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
  sempre.**
- **Alto** — bug provável, desvio relevante da spec/plano, AC sem nenhuma verificação (ou AC crítico sem
  teste automatizado), perfil aplicável sem prova ou fidelidade enganosa. **Bloqueia sempre.**
- **Médio** — qualidade, manutenção, cobertura de verificação insuficiente.
- **Baixo** — estilo, melhorias opcionais.

## Saída
- Lista de achados **agrupada por severidade**, cada um com arquivo:linha e sugestão de correção.
- **Mudança trivial:** informe a verificação rerodada e o veredito, sem criar recibo, task, plan marker ou
  estado de ledger. Se o risco real não for trivial, o único veredito possível é **bloqueado**.
- **Feature formal:** mapa perfil → task/AC → check reexecutado → recibo → estado.
- Veredito: **aprovado** / **aprovado com ressalvas** / **bloqueado**. Crítico/Alto bloqueiam sempre;
  `aprovado com ressalvas` aceita somente achados Médio/Baixo registrados. Em feature formal, task sem
  recibo bem-sucedido impede qualquer aprovação e exige `bloqueado`.
- **Feature formal — registre o veredito no plano** (**conversa aprova, arquivo registra**): atualize a linha `**Review:**`
  do cabeçalho de `docs/plans/<feature>/plan.md` com `<veredito> — <data>`. Só marque o ledger como
  `concluída` se todas as tasks estiverem `done`, todos os ACs/perfis tiverem recibo e o veredito for
  **aprovado** ou **aprovado com ressalvas**. Antes de concluir com ressalvas, grave cada débito Médio/Baixo
  aceito como nova sub-feature `a fazer` na tabela "Ordem de construção" de `docs/epics.md`, com nome curto,
  epic relevante, dependência na feature de origem e referência `review <feature> <data>` no próprio nome.
  Sugestão não aceita não vira dívida. Achado Crítico/Alto mantém `em review` e exige **bloqueado**.
- Não conserte em silêncio durante a revisão — reporte; a correção é um passo à parte.
- **Convergência:** satisfeitos ACs, perfis e a barra, não reabra a rodada por melhoria nova Médio/Baixo;
  se aceita como dívida, registre-a no ledger conforme acima. Duas tentativas consecutivas da mesma correção sem progresso acionam `blocked` e
  impedem uma terceira tentativa automática.
- Se o veredito exigir correção, indique explicitamente `/sdk-implement` como próximo passo e somente depois
  um novo `/sdk-review`.

## Fecho de ciclo (alimentar a biblioteca de lições)
Se algum achado revelou um erro **generalizável** — um padrão que poderia acontecer em qualquer projeto, não
um detalhe pontual deste código —, **proponha registrá-lo com `/sdk-lesson`** assim que for corrigido. É
assim que a biblioteca aprende com o erro **uma vez só**. Não force: se o achado é trivial/específico, siga
em frente. Um bom gatilho: achado **Crítico** ou **Alto** que casa com (ou amplia) uma tag de `lessons.md`.
