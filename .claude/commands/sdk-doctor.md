---
description: Diagnóstico global de coerência (drift) entre ledger, artefatos e código — read-only por camadas. Achado só é corrigido com aprovação explícita, um item por vez.
argument-hint: "[opcional: nome da feature para focar]"
---

# /sdk-doctor — Diagnóstico de drift + reconciliação aprovada

Encontre **incoerências** entre o que os artefatos dizem e o que o projeto realmente é — spec × plano ×
tasks × ledger × ADRs × código — e, **só se o usuário aprovar**, reconcilie um item por vez. É o comando
para retomar um projeto perdido, checar saúde antes de um merge de alto risco, ou investigar quando algo
"não bate".

> Diferença para os vizinhos: o **analyze** confere UMA feature antes de codar; o **review** confere o
> código de UMA feature depois de codar; o **doctor** olha o **projeto inteiro**, entre features, e é o
> único com um modo de correção (sempre gateado por aprovação).

Carregue: `.specify/memory/state-markers.md` (o contrato dos marcadores) e a hierarquia de fonte da verdade
do `CLAUDE.md`. O resto se lê **por camadas, sob demanda** — nunca o projeto inteiro de uma vez.

## Camadas do diagnóstico (pare quando tiver o suficiente)

### T0 — determinístico (grátis, sempre)
Rode `scripts/sdk-check.sh` (ou `.ps1` no Windows). Ele valida o contrato dos marcadores por regex — zero
token. Se o script não existir (instalação parcial), diga isso e faça as mesmas checagens por grep.

### T1 — marcadores × disco (grep, barato)
- **Ledger × artefatos:** feature com pasta em `docs/specs/` mas Estado `a fazer` no ledger? Estado
  `concluída` sem `**Review:** aprovado` no plano? Estado `em plano` mas sem `plan.md`?
- **Aprovação fantasma:** spec `aprovada` sem nenhum `- **AC` no formato Dado/Quando/Então? Plano
  `aprovado` com `Analyze: bloqueado`?
- **Pendências críticas:** `[VERIFICAR]` em aberto no `project-context.md` ou em spec de feature `em
  construção`/`concluída`.
- **Restos de atualização do kit:** existem arquivos `*.sdk-new` ou `*.sdk-bak.*` esquecidos? → AVISO:
  reconcilie (compare, incorpore o que quiser e apague o sidecar) — o passo está documentado no
  `INSTALL.md`, "Atualizando o kit".

### T2 — leitura dirigida (só dos arquivos suspeitos de T1)
- **Plano × ADRs:** alguma decisão do plano contradiz um ADR de `docs/decisions/` ou o resumo de decisões
  do `project-context.md`?
- **Brownfield:** spec com Tipo brownfield tem o delta (ADICIONADO/MODIFICADO/REMOVIDO) preenchido? O que
  "não pode quebrar" virou teste de não-regressão nas tasks?
- **README × autoridade:** o README/docs explicativos prometem algo que os artefatos de cima contradizem?

### T3 — código × artefatos (git; só a pedido ou com suspeita concreta)
- Branch de feature com arquivos alterados **fora** dos declarados na coluna Arquivo(s) do plano/tasks.
- Mudanças de código em feature cujo ledger diz `a fazer`/`em spec` (código andando na frente da spec).
- Diff de feature tocando o **motor do kit** (fronteira no `CLAUDE.md`, "Motor × produto") → drift
  **Crítico**: não corrija em silêncio; restaure do repositório oficial do kit (ou trate como evolução
  separada do kit), reexecute o `sdk-check` e só então retome a feature.
> Não tente verificar semanticamente "o código obedece cada AC" aqui — isso é papel do `/sdk-review` por
> feature, com spec e diff no contexto. O doctor pega drift **estrutural**, não relê a implementação toda.

## Saída do diagnóstico
- Achados **agrupados por severidade** (Crítico / Alto / Médio / Baixo, mesmos critérios do `/sdk-review`),
  cada um com `arquivo:linha` e a **regra violada** (contrato, hierarquia, ADR).
- Veredito em linguagem simples: **saudável** / **drift pontual** / **drift sério** (recomende parar de
  construir até reconciliar).
- **Nada foi alterado até aqui.** Diga isso explicitamente.

## Reconciliação (só com aprovação, um item por vez)
Para cada achado que o usuário quiser tratar, ofereça as opções — a hierarquia de fonte da verdade decide a
recomendação:

- **A) Corrigir o de baixo** para obedecer o de cima (código obedece spec; plano obedece ADR; ledger
  obedece a realidade dos artefatos). **Default recomendado.**
- **B) Mudar conscientemente o de cima** — é uma decisão de produto/arquitetura, não um conserto: sugira
  `/sdk-decide` se houver trade-off real, e registre o porquê no artefato alterado.
- **C) Registrar como débito** — criar task/pendência e seguir, com o risco anotado.

Regras da reconciliação:
1. **Uma correção por vez**: aplique, mostre o diff, rode a checagem daquele item (re-rode o `sdk-check` se
   foi marcador), e só então passe ao próximo.
2. Sem aprovação explícita do item, **não toque em nada** — inclusive nos "óbvios".
3. Atualize os marcadores afetados pela correção (**conversa aprova, arquivo registra**).
4. **Disjuntor anti-loop:** a mesma reconciliação falhou 2–3 vezes? Pare e devolva ao usuário com opções.

## Fecho
- Resumo: o que foi diagnosticado, o que foi reconciliado, o que ficou como débito.
- Se um drift revelou um padrão **generalizável**, sugira `/sdk-lesson` (é assim que o erro custa uma vez só).
- Sugira `/sdk-next` para retomar o fluxo do ponto agora consistente.
