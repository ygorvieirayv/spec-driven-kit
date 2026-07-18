# Spec Driven Kit

[![CI](https://github.com/ygorvieirayv/spec-driven-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/ygorvieirayv/spec-driven-kit/actions/workflows/ci.yml)

**Um toolkit autônomo de desenvolvimento orientado a IA.** Inspirado pelo
[GitHub Spec Kit](https://github.com/github/spec-kit).

Três diferenciais orientam o produto:

1. **Criação guiada por IA** — o agente conduz a conversa; você responde e aprova. Os artefatos (specs,
   planos, decisões) nascem do diálogo, não de formulários.
2. **Acessível a quem não é técnico** — cada pergunta vem com o "porquê", exemplos e um default seguro.
   Nada de jargão solto.
3. **Decisões conscientes desde o início** — antes de construir, o agente apresenta as escolhas de
   arquitetura/infra como **trade-offs claros** (facilidade × desempenho × custo × escala) e ajuda você a
   escolher — sempre oferecendo construir qualquer caminho.

---

## Para quem é

- Quem tem uma ideia e quer sair dela para um sistema **bem especificado** sem se afogar em decisões técnicas.
- Quem quer entender os **trade-offs** de cada escolha (e o custo) antes de construir.
- Quem usa o **Claude Code** e quer um fluxo de specs guiado por slash commands.
- Quem usa outra ferramenta de IA agente: Codex CLI pelo adaptador `AGENTS.md` e OpenCode por comandos
  nativos gerados sob demanda (ver `INSTALL.md`, "Outras ferramentas").

---

## Como funciona (visão geral)

O kit é construído como **slash commands + markdown** — não é uma CLI pesada. O Claude Code lê os comandos de
`.claude/commands/*.md`. Cada passo do fluxo é um comando `sdk-*`. As bases de conhecimento (constituição,
padrões de engenharia, guia de decisões, lições) são markdown em `.specify/memory/`, **lido sob demanda** por
cada comando — só o resumo de base fica sempre presente, no `CLAUDE.md` (ver "Economia de token" abaixo).

```
ideia vaga
   │
   ▼  /sdk-bootstrap   ── onboarding guiado: stack → descoberta de domínio →
   │                      decisões de arquitetura → regras de negócio → epics + ordem
   ▼  /sdk-roadmap     ── ordem certa de construir (por dependências); o que está pronto p/ começar
   │
   │   ── por feature (na ordem certa) ──────────────────────────────
   ▼  /sdk-spec        ── spec de uma feature (QUÊ e PORQUÊ) [trava: dependências prontas?]
   ▼  /sdk-clarify     ── (se vago) tira a ambiguidade da spec
   ▼  /sdk-plan        ── plano técnico (COMO) + perfis de prova
   ▼  /sdk-tasks       ── tasks rastreáveis na fonte canônica tasks.md
   ▼  /sdk-analyze     ── confere consistência spec ↔ plano ↔ tasks ↔ AC (antes de codar)
   ▼  /sdk-implement   ── implementação + recibos persistidos em evidence.md
   ▼  /sdk-review      ── revisão fresca + reexecução da verificação antes de done
   │   ──────────────────────────────────────────────────────────────
   │
   ▼  (volta ao /sdk-roadmap para a próxima feature pronta)

apoio a qualquer momento:  /sdk-decide (escolha com trade-offs) · /sdk-lesson (registrar lição)
perdido / voltando?        /sdk-next — lê o estado do projeto e diz o próximo passo (não executa nada)
automatizar o mecânico?     /sdk-cycle — encadeia somente tasks → analyze e para antes de implementar
algo não bate?             /sdk-doctor — diagnostica drift (read-only) e reconcilia só o que você aprovar
```

> **Nem toda mudança precisa do ciclo inteiro.** A **régua de cerimônia** da `constitution.md` dita quais
> passos entram conforme o **risco da mudança**: trivial (copy/visual) → implementar + review leve, sem
> lifecycle formal; baixo → spec curta + plano/tasks compactos + analyze + implement + review; médio → ciclo
> padrão; alto (dinheiro, auth, dados pessoais…) → ciclo completo com `/sdk-clarify` e TDD. Toda feature
> formal usa `tasks.md`. O `/sdk-next` aplica essa régua ao recomendar.

### Os comandos

**Porta de entrada:**

| Comando | O que faz |
|---------|-----------|
| `/sdk-next` | ★ Lê o estado do projeto (ledger de `docs/epics.md`, `Status:` dos artefatos, git) e recomenda **o próximo passo + o porquê**. Read-only; não executa nada sozinho. |
| `/sdk-cycle` | Executa somente o trecho mecânico `/sdk-tasks` → `/sdk-analyze`, uma vez cada, e para diante de decisão, erro, implementação ou review. |

**Núcleo do fluxo:**

| Comando | O que faz |
|---------|-----------|
| `/sdk-bootstrap` | Onboarding guiado completo: do produto ao escopo do MVP, com 5 checkpoints de aprovação. |
| `/sdk-roadmap` | ★ Descobre a **ordem certa** de construir as features (por dependências) e o que está "pronto para começar". |
| `/sdk-spec` | Cria a spec de uma feature por conversa (QUÊ/PORQUÊ). Trava se as dependências não estiverem prontas. |
| `/sdk-plan` | Cria o plano técnico (COMO), consultando padrões e lições, e seleciona os perfis de prova aplicáveis. |
| `/sdk-tasks` | Quebra/atualiza a lista rastreável em `tasks.md`, fonte canônica das tasks de toda feature formal. |
| `/sdk-analyze` | Confere a **consistência** spec ↔ plano ↔ tasks ↔ AC (read-only), antes de codar. |
| `/sdk-implement` | Implementa seguindo o plano, aplica TDD na lógica crítica, registra cada verificação em `evidence.md` e deixa a task `verification-pending`. |
| `/sdk-review` | Revisa em contexto fresco e reroda o subconjunto de verificação citado; somente um novo recibo satisfatório confirma `done`. |

O contexto fresco é o **padrão** do review. Revisão inline é apenas fallback justificado para ambiente sem
subagente e precisa executar exatamente o mesmo rerun. Se um review falhar, a correção volta primeiro ao
`/sdk-implement`; só depois se roda `/sdk-review` novamente.

**Apoio (use quando precisar):**

| Comando | O que faz |
|---------|-----------|
| `/sdk-decide` | ★ Assistente de decisão: explica trade-offs de uma escolha e oferece construir qualquer caminho. |
| `/sdk-clarify` | Passo dedicado de tirar ambiguidade de uma spec (entre `/sdk-spec` e `/sdk-plan`). |
| `/sdk-lesson` | Registra uma lição (erro resolvido) de forma generalizada e reutilizável na biblioteca de lições. |
| `/sdk-doctor` | ★ Diagnóstico global de **drift** (ledger × artefatos × código), read-only por camadas; reconcilia só o que você aprovar, um item por vez. |

### Subagentes (opcionais, usados pelos comandos)

| Agente | Para quê |
|--------|----------|
| `sdk-domain-researcher` | Pesquisa de domínio/compliance na descoberta — com fontes e marcas `[VERIFICAR]`. Não dá veredito legal. |
| `sdk-reviewer` | Revisão de **contexto fresco** (sem o viés de quem escreveu o código), usada pelo `/sdk-review`. |
| `sdk-lesson-curator` | Generaliza um incidente em lição reutilizável (sem dados do projeto) e deduplica contra as existentes; usado pelo `/sdk-lesson`. |

---

## Começando

> Pré-requisito: ter o **Claude Code** instalado e o kit instalado na pasta do seu projeto. Veja o
> [`INSTALL.md`](./INSTALL.md) — a opção recomendada é o instalador `install.sh`/`install.ps1`.
>
> 👉 Com pressa? O guia rápido de bolso está em [`COMO-USAR.md`](./COMO-USAR.md).

1. **Abra o Claude Code** na pasta do projeto.
2. Rode **`/sdk-bootstrap`** e descreva o que quer construir — pode ser **uma frase** ou um **esboço com vários
   recursos** (telas, regras, ideias soltas). O agente organiza o despejo em epics, decisões e regras.
3. Responda às perguntas (uma de cada vez). O agente vai:
   - preparar a estrutura e o `.gitignore`;
   - confirmar/recomendar o **stack** a partir das restrições reais (orçamento, escala, operação e prazo);
   - confirmar seis **gates de CI** e gerar um workflow que falha se algum check esperado estiver ausente;
   - fazer a **descoberta de domínio** (país, leis, pagamentos…) com fontes;
   - conduzir as **decisões de arquitetura** com trade-offs;
   - propor os **princípios de negócio** registrados no contexto do projeto;
   - montar o **escopo do MVP** (epics) e a **ordem de construção** (por dependências).
4. A cada checkpoint 🛑, revise e aprove.
5. Rode **`/sdk-roadmap`** para ver qual feature está **pronta para começar** (🟢) — comece por ela.
6. Para essa feature, siga: **`/sdk-spec`** → (se vago, **`/sdk-clarify`**) → **`/sdk-plan`** →
   **`/sdk-tasks`** → **`/sdk-analyze`** → **`/sdk-implement`** → **`/sdk-review`**.
   Depois do plano aprovado, `/sdk-cycle` pode substituir apenas a digitação de `tasks` + `analyze`;
   ele nunca inicia a implementação.
7. Terminou? Volte ao **`/sdk-roadmap`** para a próxima feature desbloqueada.
8. **Perdeu o fio** (pausa de dias, `/clear`, sessão nova)? Rode **`/sdk-next`** — ele lê o estado gravado
   nos arquivos e diz exatamente onde você parou e o que rodar agora.

**Atalho opcional:** `scripts/new-feature.sh "minha-feature"` (ou `.ps1` no Windows) inicia a spec
e uma branch dedicada. Plano e tasks só nascem nos comandos próprios, depois das aprovações.

> 💡 **Quer ver o fluxo inteiro antes de começar?** Há um walkthrough opcional e fictício em
> [`docs/example/`](./docs/example/README.md) mostrando um projeto do "tenho uma ideia" até a primeira
> feature revisada. É só leitura — não muda nada no kit.

---

## Versionamento

A versão do kit fica em [`VERSION`](./VERSION), e mudanças relevantes ficam em
[`CHANGELOG.md`](./CHANGELOG.md). O instalador não copia `VERSION` para a raiz do seu projeto, porque essa
raiz pode ter a versão do seu próprio produto. Em vez disso, ele grava o selo do kit em
`.specify/spec-driven-kit.version`; é seguro commitar esse arquivo para saber qual versão do kit está
instalada no projeto.

---

## Rigor unificado, fidelidade e perfis de prova

O kit tem **uma única barra de integridade**. Segurança, autorização, proteção de dados, honestidade da
evidência e revisão independente não ficam mais fracas porque o pedido é um protótipo, uma demonstração ou
um experimento. O que escala é o trabalho necessário para provar cada **feature**, conforme seu risco e sua
superfície — não um modo global do projeto.

Cada spec registra seus **limites de fidelidade**: o que será real, o que será simulado ou executado em
sandbox e o que ficará fora de escopo. Um checkout demonstrativo, por exemplo, pode usar um gateway simulado;
a spec precisa dizer isso e nunca pode apresentar a simulação como cobrança real.

No plano, os perfis de prova são independentes e combináveis:

| Perfil | O que precisa ser demonstrado |
|--------|-------------------------------|
| `visual` | Renderização, responsividade, estados visuais e acessibilidade observável. |
| `logic` | Regras de negócio e modos de falha por testes automatizados. |
| `journey` | Jornada completa do usuário e integrações atravessadas pelo fluxo. |
| `data-security` | Migração, acesso, autorização, integridade de dados e rollback realmente executado quando aplicável. |
| `operational` | Filas, retries, timeouts, idempotência, observabilidade e comportamento sob falha. |
| `delivery` | Lint, typecheck, build, CI, deploy e capacidade real de entrega. |

Uma alteração visual pode exigir apenas `visual`; uma mudança de autenticação pode combinar `logic`,
`data-security`, `journey` e `delivery`. A régua de risco decide a cerimônia mínima, o plano declara os perfis
aplicáveis e o `/sdk-review` cobra as provas correspondentes. Achados **Crítico** e **Alto** bloqueiam sempre.

### CI do produto sem "verde por ausência"

O bootstrap renderiza `.github/workflows/sdk-quality.yml` somente depois de você aprovar stack, lockfile,
runner, setup, diretórios e comandos. `scripts/sdk-ci.sh` exige exatamente seis gates (`install`, `lint`, `typecheck`,
`test`, `build`, `dependency-audit`): cada um possui um script real ou N/A estrutural justificado. Gate
ausente, divergente do `project-context.md`, placeholder e atalhos como `--if-present`/`|| true` falham antes
de qualquer execução. No Windows, `sdk-ci.ps1` localiza o Git Bash e usa o mesmo contrato.

O job `Secret scan` usa o CLI MIT do Gitleaks fixado por versão e SHA-256, sem licença da Action, e examina
histórico completo + árvore atual com redaction. Os checks remotos estáveis são `Quality gates` e
`Secret scan`. Para impedir bypass pela remoção do workflow, torne ambos obrigatórios em branch
protection/ruleset; sem essa configuração externa, a garantia honesta é "fail-closed quando executado".

---

## Projeto novo ou existente (greenfield × brownfield)

Cada spec declara seu **Tipo**:

- **Greenfield** — algo **novo**. Você especifica do zero, normalmente.
- **Brownfield** — **muda algo que já existe**. Em vez de reespecificar o sistema inteiro, o `/sdk-spec`
  descreve o **comportamento atual** e uma **"delta spec"** (o que é **ADICIONADO / MODIFICADO / REMOVIDO**),
  mais o impacto/migração e o que **não pode quebrar** (vira teste de não-regressão). Essa abordagem incremental
  permite evoluir sistemas em produção sem reescrever tudo.

---

## Ordem de construção (dependências)

Um erro comum é correr para uma parte "lá na frente" antes das que ela depende. Exemplo: não adianta integrar
o **checkout** sem ter os **produtos**, uma **fonte de preço** e o **valor do frete** (que pode vir de uma API
da transportadora). O kit trata isso:

- O `/sdk-bootstrap` e o `/sdk-roadmap` **decompõem cada epic em sub-features** (só os títulos — a "jornada"
  da área) e montam a **ordem de construção** em `docs/epics.md`, mapeando o que depende de quê. Você vê o
  mapa completo do projeto sem precisar detalhar tudo (o detalhe de cada sub-feature vem só na hora, no
  `/sdk-spec`).
- O `/sdk-roadmap` recalcula essa ordem quando quiser e diz **o que está pronto para começar** (🟢), o que é
  **fundacional** (🟡) e o que está **bloqueado** (🔴, dizendo qual dependência falta).
- O `/sdk-spec` tem uma **trava**: antes de detalhar uma sub-feature, ele confere se as dependências existem —
  e, se não, sugere construir antes aquela da qual ela depende.

Regra de bolso: **comece pelo fundacional e siga a ordem 🟢.** Rode `/sdk-roadmap` ao terminar cada feature
para ver o que foi desbloqueado.

## Economia de token (higiene de contexto)

Sessões longas de IA custam token — e o maior desperdício é arrastar contexto inútil. O kit foi desenhado
para gastar pouco:

- **Artefato no disco = memória.** Spec, plano, tasks, decisões e lições ficam em arquivos. Entre fases você
  pode `/clear` e recarregar **só** o arquivo da feature atual — não o histórico inteiro do chat.
- **Carga sob demanda.** As bases de `.specify/memory/` não são carregadas a cada mensagem; cada comando lê
  só o que precisa. O que fica sempre presente é o `CLAUDE.md`, propositalmente curto.
- **Consulta de lições por tag.** A `lessons.md` é lida por `grep`/tag, nunca inteira — escala sem encarecer.
- **Subagentes isolam contexto.** `sdk-domain-researcher`, `sdk-reviewer` e `sdk-lesson-curator` fazem o
  trabalho pesado num contexto próprio; só o resultado volta para a conversa principal.
- **Disjuntor anti-loop.** Se o agente falha duas vezes seguidas na mesma coisa sem progresso observável,
  ele **para** e devolve o problema a você, em vez de insistir no escuro queimando token.
- **Uma feature por vez** e, se quiser, um modelo mais barato para etapas mecânicas (tasks, scaffolding).

## Biblioteca de lições

Toda vez que um erro é enfrentado e resolvido, o `/sdk-lesson` registra a **lição generalizada** em
`.specify/memory/lessons.md` — no formato sintoma → causa → correção → **prevenção**, **sem** acoplar ao
projeto (nada de nome de produto ou caminho de arquivo). A ideia: aprender uma vez e não repetir o erro, nem
aqui nem nos próximos projetos.

- O `/sdk-plan` e o `/sdk-review` **consultam** as lições (por tag) para aplicar prevenções conhecidas.
- O subagente `sdk-lesson-curator` generaliza o incidente e deduplica contra o que já existe.
- Já vem **semeada** com lições comuns (cache sem invalidação, segredo no bundle, chamada sem timeout, N+1,
  webhook sem idempotência, "green falso", escopo inflado, migração sem rollback, PII em logs…).

**Uso multi-projeto (transversal).** Para compartilhar a mesma biblioteca entre vários projetos, extraia a
`lessons.md` para um **repositório próprio** e referencie-o em cada projeto. Os comandos sempre leem o caminho
`.specify/memory/lessons.md`, então mantenha esse caminho válido de uma destas formas:

```bash
# opção A — submodule na pasta e um symlink apontando para o arquivo compartilhado
git submodule add <url-do-repo-de-licoes> .specify/memory/lessons-shared
ln -s lessons-shared/lessons.md .specify/memory/lessons.md

# opção B — simplesmente sincronizar/copiar o arquivo entre os projetos
```

Assim cada postmortem novo (em qualquer projeto) contribui de volta, e a biblioteca cresce como um acervo
único, reutilizável e independente de projeto.

## Estrutura do repositório

```
spec-driven-kit/
├── README.md                          # este arquivo
├── INSTALL.md                         # como instalar o kit num projeto
├── COMO-USAR.md                       # guia rápido de bolso (uso no dia a dia)
├── CLAUDE.md                          # regras de base sempre carregadas (curto, p/ economia de token)
├── VERSION                            # versão atual do kit
├── CHANGELOG.md                       # histórico de mudanças do kit
├── install.sh / install.ps1           # instalador seguro (manifest-aware)
│
├── .github/workflows/ci.yml           # validação Linux + Windows + macOS do kit e do instalador
│
├── .specify/                          # memória, contratos e templates do kit
│   ├── memory/                        # bases lidas SOB DEMANDA pelos comandos
│   │   ├── constitution.md            # princípios universais e neutros (8)
│   │   ├── engineering-standards.md   # barra técnica (infra, perf, segurança, testes…)
│   │   ├── decision-guide.md          # ★ catálogo de trade-offs (alimenta /sdk-decide)
│   │   ├── lessons.md                 # ★ biblioteca de lições generalizadas (erros → prevenção)
│   │   ├── state-markers.md           # ★ contrato dos marcadores de estado (valida o /sdk-check e /sdk-doctor)
│   │   └── project-context.md         # GERADO na descoberta (país, leis, decisões)
│   └── templates/                     # moldes de context / spec / plan / tasks / evidence / CI consumidor
│       └── agents-md-template.md      # ★ adaptador p/ ferramentas sem slash commands (ex.: Codex CLI)
│
├── .claude/
│   ├── commands/                      # os slash commands sdk-*
│   └── agents/                        # subagentes (researcher, reviewer, lesson-curator)
│
├── docs/
│   ├── specs/                         # specs aprovadas (uma pasta por feature)
│   ├── plans/                         # planos, tasks e evidência acumulada
│   ├── decisions/                     # ADRs (decisões de arquitetura)
│   ├── example/                       # walkthrough opcional e ilustrativo (não muda o kit)
│   └── epics.md                       # escopo do MVP + ledger de estado (coluna Estado)
│
├── scripts/
│   ├── kit-manifest.txt               # classificação ENGINE/SEED/MERGE/SKIP para o instalador
│   ├── kit-rules.*                    # contrato/check interno do próprio kit (SKIP no bundle)
│   ├── sdk-ci.* + sdk-secrets.sh      # gates portáveis do produto + Gitleaks fixado para CI Ubuntu
│   ├── export-opencode.*              # gera comandos nativos OpenCode sem fonte duplicada
│   └── new-feature + sdk-check        # scaffolding + validação de estado, bash + PowerShell
│
└── tests/                             # fixtures, mutações, gates e secret scan sintético real
```

---

## Princípios de produto (o que nos diferencia)

- **Conversa, não formulário.** Uma pergunta por vez. Você nunca sente que preenche um arquivo.
- **Explicar antes de perguntar.** Toda pergunta vem com o "porquê" e exemplos.
- **Adaptar ao nível.** Técnico → acelera. "Não sei" → simplifica e sugere um default seguro.
- **Decisões com trade-offs.** Em cada bifurcação relevante: facilidade × desempenho × custo × escala, com
  recomendação baseada nas restrições, no risco e no objetivo observável. Sempre: "posso construir qualquer
  um dos dois".
- **Honestidade epistêmica.** Não inventar regras de negócio/lei — pesquisar, citar fontes, sinalizar
  incerteza. Compliance é confirmado por humano.
- **Artefato é a fonte da verdade.** Código serve à spec; se divergem, a spec vence **dentro da feature**
  (acima dela valem `project-context.md` e ADRs — hierarquia no `CLAUDE.md`; em brownfield, o código é a
  verdade do comportamento atual).

---

## Licença

Distribuído sob a licença **MIT** — veja [`LICENSE`](./LICENSE). Uso, cópia e modificação livres, mantendo o
aviso de copyright.
