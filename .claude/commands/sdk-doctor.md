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

Comece somente pela hierarquia de fonte da verdade do `CLAUDE.md` e pelo T0 abaixo. Carregue de
`.specify/memory/state-markers.md` apenas as seções relacionadas ao achado quando precisar descer para
T1 ou além. O resto se lê **por camadas, sob demanda** — nunca o projeto inteiro de uma vez.

## Camadas do diagnóstico (pare quando tiver o suficiente)

### T0 — determinístico (grátis, sempre)
Rode `scripts/sdk-check.sh` (ou `.ps1` no Windows). Ele valida o contrato dos marcadores por regex — zero
token. Se o script não existir (instalação parcial), diga isso e faça as mesmas checagens por grep.

### T1 — marcadores × disco (grep, barato)
- **Ledger × artefatos:** feature com pasta em `docs/specs/` mas Estado `a fazer` no ledger? Estado
  `concluída` sem `**Review:** aprovado`/`aprovado com ressalvas` no plano? Estado `em plano` mas sem
  `plan.md`?
- **Aprovação fantasma:** spec `aprovada` sem nenhum `- **AC` no formato Dado/Quando/Então? Plano
  `aprovado` com `Analyze: bloqueado`?
- **Risco persistido:** toda spec formal tem `- **Risco:** baixo|medio|alto` preenchido? A descrição
  toca lógica crítica mas o marker a rebaixa? Não recalcule silenciosamente — reporte a divergência.
- **Fonte de tasks:** feature formal com plano aprovado precisa de `tasks.md` antes de Analyze/implement;
  tabela inline no plano não é fonte de tasks.
- **Pendências críticas:** `[VERIFICAR]` em aberto no `project-context.md` ou em spec de feature `em
  construção`/`concluída`.
- **Estado de task:** aceite só `backlog`, `ready`, `in-progress`, `verification-pending`, `done`, `blocked`.
  `partial`/`reopened` são drift. `verification-pending` só depende de
  `verification-pending`/`done`; `done`, somente de `done`. O `sdk-check` rejeita gramática inválida,
  referência ausente/repetida e ciclo no grafo interno de `tasks.md`; dependências entre features ainda
  são conferidas semanticamente pelo `/sdk-roadmap` e `/sdk-analyze`.
- **Estado × evidence (contrato estrito):** a fonte das tasks exige marker `Evidence` para a própria
  feature; ausência/caminho divergente é erro. `verification-pending` exige `Registro implement` válido;
  `done`, `Registro review` `pass`/`observed`; `blocked`, `Bloqueio` no mesmo bloco negativo. Evidence vazio
  antes da primeira observação é drift. Não fabrique evidência retrospectiva.
- **Atualização pendente do kit:** existe `.specify/spec-driven-kit.pending`? → ALTO: o selo de versão
  instalado foi preservado porque um ou mais arquivos do motor divergiram. Leia no marcador o build-alvo e
  os caminhos afetados e compare cada original com seu `*.sdk-new`. Regra específica do produto deve ir para
  `project-context.md`/ADR, não permanecer embutida no motor. Para aplicar o build oficial, o arquivo ativo
  precisa corresponder à versão nova; se o usuário mantiver uma customização no motor, o estado continua
  pendente por definição. Depois da reconciliação, rode o instalador novamente; ele só aplica o novo selo e
  remove o marcador quando não restar conflito no motor.
  Arquivos `*.sdk-new` ou `*.sdk-bak.*` sem marcador ainda geram AVISO e devem ser reconciliados. Nunca
  escolha automaticamente entre dado do projeto e atualização do motor. Um sidecar de `lessons.md`, que
  acumula dados do projeto e exige merge manual, não bloqueia o selo do motor.
- **Contrato de CI do consumidor:** se `scripts/sdk-ci.sh` existir, rode `.\scripts\sdk-ci.ps1 -Validate` no
  Windows ou `bash scripts/sdk-ci.sh --validate` nos demais sistemas. Ausência, divergência com o
  `project-context.md`, duplicidade ou placeholder nos seis gates é drift Alto. Confirme que
  `.github/workflows/sdk-quality.yml` chama `sdk-check.ps1`, `sdk-ci.ps1` e `sdk-secrets.sh`, sem marcador
  `__SDK_`/`SDK-SETUP`, `continue-on-error`, checkout raso no scan ou condição de existência. Não execute
  os gates no doctor.

### T2 — leitura dirigida (só dos arquivos suspeitos de T1)
- **Plano × ADRs:** alguma decisão do plano contradiz um ADR de `docs/decisions/` ou o resumo de decisões
  do `project-context.md`?
- **Brownfield:** spec com Tipo brownfield tem o delta (ADICIONADO/MODIFICADO/REMOVIDO) preenchido? O que
  "não pode quebrar" virou teste de não-regressão nas tasks?
- **Fidelidade:** a spec declara `Limites intencionais: nenhum` ou descreve cada superfície
  real/sandbox/simulada/fora de escopo? O plano/código apresenta como real algo limitado? Simulação que
  pode confundir usuário/operador tem sinalização observável e AC?
- **Perfis:** o plano avaliou os seis perfis canônicos com `aplicável` ou `N/A` justificado? Todo perfil
  aplicável aparece em ao menos uma task, nenhuma task cita perfil `N/A` e a prova é compatível com a
  fidelidade? `data-security` com migração/schema ou transformação destrutiva/em massa tem execução de
  forward e rollback/restauração registrada?
- **README × autoridade:** o README/docs explicativos prometem algo que os artefatos de cima contradizem?
- **Evidence:** os blocos começam em `E1`, avançam de um em um e usam
  `### E<n> - <ISO-8601> - T<n> - <implement|review>`; cada um contém exatamente um
  `Registro` de cinco campos e os labels ASCII `Acao/comando`, `Diretorio`, `Fonte`, `Exit code`,
  `Saida/referencia`, `Branch`, `Limitacoes`, todos preenchidos? Task/fase do cabeçalho coincidem com o
  registro? Não há `Registro` fora de bloco? Task/AC existem? Ref é
  `commit@<7-40 hex>|worktree@<7-40 hex>|unavailable`? Entradas antigas são append-only; só o resumo muda.
- **Exit code:** `pass=0`; `fail=inteiro não zero`; `observed|not-run=not-applicable`;
  `unavailable=unavailable`.
- **Dependências:** review ocorreu em ordem topológica? Se upstream falhou, dependentes
  `verification-pending`/`done` foram
  transitivamente para `ready` com bloco `review | not-run`? Quem estava `done` tem
  `Reclassificacao: Tn | done | ready | ISO-8601 | motivo/referencia` no mesmo bloco?
- **Promoção:** recibo implement nunca justifica `done`; somente rerun review bem-sucedido.
- **Reabertura:** `Reclassificacao` tem prova anterior de `done`? Todo implement posterior a um `done` tem
  um bloco `review | not-run` + `Reclassificacao` entre as duas fases? Sem isso, houve reabertura direta.

A ref SHA registra só proveniência. O doctor não compara evidence comum com HEAD nem classifica
`current`/`historical`; a exceção é o `/sdk-review` ao atestar CI remoto, que exige `head_sha` igual ao
commit revisado porque o provedor só executou aquele snapshot.

### T3 — código × artefatos (git; só a pedido ou com suspeita concreta)
- Branch de feature com arquivos alterados **fora** dos declarados na coluna Arquivo(s) do plano/tasks.
- Mudanças de código em feature cujo ledger diz `a fazer`/`em spec` (código andando na frente da spec).
- **Motor × produto — use o inventário canônico do `CLAUDE.md`:** diff de feature tocando motor é drift
  **Crítico**. Não corrija em silêncio; restaure do repositório oficial do kit (ou trate como evolução
  separada), reexecute o `sdk-check` e só então retome. `project-context.md` e `lessons.md` não são motor.
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
- **C) Registrar como débito** — somente para achado Médio/Baixo: criar sub-feature `a fazer` na tabela
  "Ordem de construção" de `docs/epics.md`, com origem/risco anotados. Crítico/Alto precisa ser corrigido
  ou permanece bloqueado.

Quando uma task comprovada precisar ser reclassificada, o doctor **propõe encaminhar ao `/sdk-review`**:
ele cria o bloco real `review | not-run` com o fato observado e `Reclassificacao`, move para `ready` e então o fluxo é
`/sdk-implement` → `/sdk-review`. O doctor não se passa pelo revisor nem fabrica o recibo.

Regras da reconciliação:
1. **Uma correção por vez**: aplique, mostre o diff, rode a checagem daquele item (re-rode o `sdk-check` se
   foi marcador), e só então passe ao próximo.
2. Sem aprovação explícita do item, **não toque em nada** — inclusive nos "óbvios".
3. Atualize os marcadores afetados pela correção (**conversa aprova, arquivo registra**).
4. **Disjuntor anti-loop:** duas tentativas consecutivas da mesma reconciliação sem progresso? Pare,
   registre a condição objetiva para retomar e não faça uma terceira automaticamente.
5. Não reescreva evidence; recibo novo só nasce de execução real em `/sdk-implement` ou `/sdk-review`.

## Fecho
- Resumo: o que foi diagnosticado, o que foi reconciliado, o que ficou como débito.
- Se um drift revelou um padrão **generalizável**, sugira `/sdk-lesson` (é assim que o erro custa uma vez só).
- Sugira `/sdk-next` para retomar o fluxo do ponto agora consistente.
