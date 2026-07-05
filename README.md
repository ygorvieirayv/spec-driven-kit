# Spec Driven Kit

[![CI](https://github.com/ygorvieirayv/spec-driven-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/ygorvieirayv/spec-driven-kit/actions/workflows/ci.yml)

**Um toolkit de desenvolvimento orientado a IA** — no espírito do
[GitHub Spec Kit](https://github.com/github/spec-kit), mas com três diferenciais:

1. **Criação guiada por IA** — o agente conduz a conversa; você responde e aprova. Os artefatos (specs,
   planos, decisões) nascem do diálogo, não de formulários.
2. **Acessível a quem não é técnico** — cada pergunta vem com o "porquê", exemplos e um default seguro.
   Nada de jargão solto.
3. **Decisões conscientes desde o início** — antes de construir, o agente apresenta as escolhas de
   arquitetura/infra como **trade-offs claros** (facilidade × desempenho × custo × escala) e ajuda você a
   escolher — sempre oferecendo construir qualquer caminho.

> O Spec Driven Kit não substitui o Spec Kit oficial. Ele é uma **camada guiada e consultiva**, montada nos
> **mesmos caminhos** do Spec Kit (`.specify/memory/`, `.specify/templates/`), para você começar de forma
> amigável e **migrar para o Spec Kit oficial quando quiser**.

---

## Para quem é

- Quem tem uma ideia e quer sair dela para um sistema **bem especificado** sem se afogar em decisões técnicas.
- Quem quer entender os **trade-offs** de cada escolha (e o custo) antes de construir.
- Quem usa o **Claude Code** e quer um fluxo de specs guiado por slash commands.
- Quem usa outra ferramenta de IA agente que lê `AGENTS.md` (ex.: Codex CLI) — via o adaptador em
  `.specify/templates/agents-md-template.md` (ver `INSTALL.md`, Opção 3).

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
   ▼  /sdk-plan        ── plano técnico (COMO) + tasks
   ▼  /sdk-tasks       ── lista de tasks rastreáveis
   ▼  /sdk-analyze     ── confere consistência spec ↔ plano ↔ tasks ↔ AC (antes de codar)
   ▼  /sdk-implement   ── implementação (TDD em PRODUCTION)
   ▼  /sdk-review      ── revisão do código + QA (risco e rastreabilidade de testes)
   │   ──────────────────────────────────────────────────────────────
   │
   ▼  (volta ao /sdk-roadmap para a próxima feature pronta)

apoio a qualquer momento:  /sdk-decide (escolha com trade-offs) · /sdk-lesson (registrar lição)
perdido / voltando?        /sdk-next — lê o estado do projeto e diz o próximo passo (não executa nada)
algo não bate?             /sdk-doctor — diagnostica drift (read-only) e reconcilia só o que você aprovar
```

> **Nem toda mudança precisa do ciclo inteiro.** A **régua de cerimônia** da `constitution.md` dita quais
> passos entram conforme o **risco da mudança**: trivial (copy/visual) → implementar + review leve; baixo →
> spec curta + implement + review; médio → ciclo padrão; alto (dinheiro, auth, dados pessoais…) → ciclo
> completo com `/sdk-clarify` e TDD. O `/sdk-next` aplica essa régua ao recomendar.

### Os comandos

**Porta de entrada:**

| Comando | O que faz |
|---------|-----------|
| `/sdk-next` | ★ Lê o estado do projeto (ledger de `docs/epics.md`, `Status:` dos artefatos, git) e recomenda **o próximo passo + o porquê**. Read-only; não executa nada sozinho. |

**Núcleo do fluxo:**

| Comando | O que faz |
|---------|-----------|
| `/sdk-bootstrap` | Onboarding guiado completo: do produto ao escopo do MVP, com 5 checkpoints de aprovação. |
| `/sdk-roadmap` | ★ Descobre a **ordem certa** de construir as features (por dependências) e o que está "pronto para começar". |
| `/sdk-spec` | Cria a spec de uma feature por conversa (QUÊ/PORQUÊ). Trava se as dependências não estiverem prontas. |
| `/sdk-plan` | Cria o plano técnico (COMO), consultando os padrões de engenharia e as lições. |
| `/sdk-tasks` | Quebra/atualiza a lista de tasks rastreáveis. |
| `/sdk-analyze` | Confere a **consistência** spec ↔ plano ↔ tasks ↔ AC (read-only), antes de codar. |
| `/sdk-implement` | Implementa seguindo o plano; TDD na lógica crítica em modo PRODUCTION. |
| `/sdk-review` | Revisa o código contra spec + plano + padrões; inclui QA (risco e rastreabilidade de testes). |

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
   - confirmar/recomendar o **stack** e o **modo** (PROTOTYPE ou PRODUCTION);
   - fazer a **descoberta de domínio** (país, leis, pagamentos…) com fontes;
   - conduzir as **decisões de arquitetura** com trade-offs;
   - propor as **regras de negócio** (constituição do projeto);
   - montar o **escopo do MVP** (epics) e a **ordem de construção** (por dependências).
4. A cada checkpoint 🛑, revise e aprove.
5. Rode **`/sdk-roadmap`** para ver qual feature está **pronta para começar** (🟢) — comece por ela.
6. Para essa feature, siga: **`/sdk-spec`** → (se vago, **`/sdk-clarify`**) → **`/sdk-plan`** →
   **`/sdk-tasks`** → **`/sdk-analyze`** → **`/sdk-implement`** → **`/sdk-review`**.
7. Terminou? Volte ao **`/sdk-roadmap`** para a próxima feature desbloqueada.
8. **Perdeu o fio** (pausa de dias, `/clear`, sessão nova)? Rode **`/sdk-next`** — ele lê o estado gravado
   nos arquivos e diz exatamente onde você parou e o que rodar agora.

**Atalho opcional (Fase 4):** `scripts/new-feature.sh "minha-feature"` (ou `.ps1` no Windows) cria as pastas
de spec/plano e uma branch dedicada a partir dos moldes.

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

## Modos: PROTOTYPE × PRODUCTION

O kit escala o **rigor** conforme o modo (definido no `project-context.md`):

- **PROTOTYPE** — rápido e descartável. Menos cerimônia, testes só no essencial, decisões reversíveis.
- **PRODUCTION** — mantido a sério. Verificação rigorosa, TDD na lógica crítica, decisões registradas (ADRs).

Os princípios da constituição valem nos dois modos; o que muda é o **nível de rigor**, nunca a integridade.
A `constitution.md` tem a **matriz de rigor por modo** — o que cada comando (`/sdk-tasks`, `/sdk-analyze`,
`/sdk-implement`, `/sdk-review`) trata diferente em PROTOTYPE × PRODUCTION, e o que **nunca** muda (segredos,
PII, validação de entrada, autorização — esses valem igual nos dois modos, sempre).

---

## Projeto novo ou existente (greenfield × brownfield)

Cada spec declara seu **Tipo**:

- **Greenfield** — algo **novo**. Você especifica do zero, normalmente.
- **Brownfield** — **muda algo que já existe**. Em vez de reespecificar o sistema inteiro, o `/sdk-spec`
  descreve o **comportamento atual** e uma **"delta spec"** (o que é **ADICIONADO / MODIFICADO / REMOVIDO**),
  mais o impacto/migração e o que **não pode quebrar** (vira teste de não-regressão). É a abordagem incremental
  inspirada no [OpenSpec](https://github.com/Fission-AI/OpenSpec), boa para evoluir sistemas em produção sem
  reescrever tudo.

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
- **Disjuntor anti-loop.** Se o agente falha 2–3 vezes na mesma coisa, ele **para** e devolve o problema a
  você, em vez de insistir no escuro queimando token.
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
├── .github/workflows/ci.yml           # validação Linux + Windows do kit e do instalador
│
├── .specify/                          # compatível com o Spec Kit oficial
│   ├── memory/                        # bases lidas SOB DEMANDA pelos comandos
│   │   ├── constitution.md            # princípios universais e neutros (8)
│   │   ├── engineering-standards.md   # barra técnica (infra, perf, segurança, testes…)
│   │   ├── decision-guide.md          # ★ catálogo de trade-offs (alimenta /sdk-decide)
│   │   ├── lessons.md                 # ★ biblioteca de lições generalizadas (erros → prevenção)
│   │   ├── state-markers.md           # ★ contrato dos marcadores de estado (valida o /sdk-check e /sdk-doctor)
│   │   └── project-context.md         # GERADO na descoberta (país, leis, decisões)
│   └── templates/                     # moldes de context / spec / plan / tasks
│       └── agents-md-template.md      # ★ adaptador p/ ferramentas sem slash commands (ex.: Codex CLI)
│
├── .claude/
│   ├── commands/                      # os slash commands sdk-*
│   └── agents/                        # subagentes (researcher, reviewer, lesson-curator)
│
├── docs/
│   ├── specs/                         # specs aprovadas (uma pasta por feature)
│   ├── plans/                         # planos e tasks
│   ├── decisions/                     # ADRs (decisões de arquitetura)
│   ├── example/                       # walkthrough opcional e ilustrativo (não muda o kit)
│   └── epics.md                       # escopo do MVP + ledger de estado (coluna Estado)
│
├── scripts/
│   ├── kit-manifest.txt               # classificação ENGINE/SEED/MERGE/SKIP para o instalador
│   └── new-feature + sdk-check        # scaffolding + validação de estado, bash + PowerShell
│
└── tests/fixtures/                    # fixtures valid/broken para testar o sdk-check e o CI
```

> **Compatibilidade:** `.specify/memory/constitution.md` e `.specify/templates/` seguem os caminhos do Spec
> Kit de propósito. `decision-guide.md`, `engineering-standards.md` e os comandos `sdk-*` são a extensão
> deste kit.

---

## Relação com o Spec Kit oficial e quando migrar

Os artefatos que este kit produz (constituição, project-context, specs, planos) são **consumíveis pelo Spec
Kit oficial**, porque usam os mesmos caminhos.

**Quando migrar:** comece no Spec Driven Kit (onboarding guiado + descoberta + decisões conscientes). Quando o
projeto amadurecer e você quiser a **CLI, a automação e os gates** do Spec Kit, rode `specify init` no mesmo
repositório. A constituição e o `project-context` já estarão no lugar; o pipeline
`/speckit.specify → plan → tasks → implement` assume a partir daí.

### Mapa de equivalência

| Spec Driven Kit | Spec Kit oficial |
|-----------------|------------------|
| `/sdk-bootstrap` (etapas B–F) | `specify init` + `/speckit.constitution` **+ extra nosso**: descoberta de domínio e decisões guiadas |
| `/sdk-next` | (sem equivalente direto — extra nosso: lê o estado e recomenda o próximo passo) |
| `/sdk-roadmap` | (sem equivalente direto — extra nosso: ordem por dependências) |
| `/sdk-spec` | `/speckit.specify` |
| `/sdk-clarify` | `/speckit.clarify` |
| `/sdk-plan` | `/speckit.plan` |
| `/sdk-tasks` | `/speckit.tasks` |
| `/sdk-analyze` | `/speckit.analyze` (read-only de consistência) |
| `/sdk-implement` | `/speckit.implement` |
| `/sdk-review` | (review de código + QA — complementa o `analyze`) |
| `/sdk-doctor` | (sem equivalente direto — extra nosso: diagnóstico global de drift + reconciliação aprovada) |

---

## Princípios de produto (o que nos diferencia)

- **Conversa, não formulário.** Uma pergunta por vez. Você nunca sente que preenche um arquivo.
- **Explicar antes de perguntar.** Toda pergunta vem com o "porquê" e exemplos.
- **Adaptar ao nível.** Técnico → acelera. "Não sei" → simplifica e sugere um default seguro.
- **Decisões com trade-offs.** Em cada bifurcação relevante: facilidade × desempenho × custo × escala, com
  recomendação por modo. Sempre: "posso construir qualquer um dos dois".
- **Honestidade epistêmica.** Não inventar regras de negócio/lei — pesquisar, citar fontes, sinalizar
  incerteza. Compliance é confirmado por humano.
- **Artefato é a fonte da verdade.** Código serve à spec; se divergem, a spec vence **dentro da feature**
  (acima dela valem `project-context.md` e ADRs — hierarquia no `CLAUDE.md`; em brownfield, o código é a
  verdade do comportamento atual).

---

## Licença

Distribuído sob a licença **MIT** — veja [`LICENSE`](./LICENSE). Uso, cópia e modificação livres, mantendo o
aviso de copyright.
