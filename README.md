# Spec Driven Kit

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
   │                      decisões de arquitetura → regras de negócio → epics
   ▼  /sdk-decide      ── (quando precisar) decide UMA escolha com trade-offs
   │
   ▼  /sdk-spec        ── spec de uma feature (QUÊ e PORQUÊ)
   ▼  /sdk-plan        ── plano técnico (COMO) + tasks
   ▼  /sdk-tasks       ── lista de tasks rastreáveis
   ▼  /sdk-implement   ── implementação (TDD em PRODUCTION)
   ▼  /sdk-review      ── revisão contra spec + padrões (contexto fresco)
   │
   ▼  sistema bem especificado e implementado
```

### Os comandos

| Comando | O que faz |
|---------|-----------|
| `/sdk-bootstrap` | Onboarding guiado completo: do produto ao escopo do MVP, com 5 checkpoints de aprovação. |
| `/sdk-decide` | ★ Assistente de decisão: explica trade-offs de uma escolha e oferece construir qualquer caminho. |
| `/sdk-spec` | Cria a spec de uma feature por conversa (QUÊ/PORQUÊ). |
| `/sdk-plan` | Cria o plano técnico (COMO), consultando os padrões de engenharia. |
| `/sdk-tasks` | Quebra/atualiza a lista de tasks rastreáveis. |
| `/sdk-implement` | Implementa seguindo o plano; TDD na lógica crítica em modo PRODUCTION. |
| `/sdk-review` | Revisa o diff contra spec + plano + padrões; severidade Crítico/Alto/Médio/Baixo. |
| `/sdk-lesson` | Registra uma lição (erro resolvido) de forma generalizada e reutilizável na biblioteca de lições. |

### Subagentes (opcionais, usados pelos comandos)

| Agente | Para quê |
|--------|----------|
| `sdk-domain-researcher` | Pesquisa de domínio/compliance na descoberta — com fontes e marcas `[VERIFICAR]`. Não dá veredito legal. |
| `sdk-reviewer` | Revisão de **contexto fresco** (sem o viés de quem escreveu o código), usada pelo `/sdk-review`. |
| `sdk-lesson-curator` | Generaliza um incidente em lição reutilizável (sem dados do projeto) e deduplica contra as existentes; usado pelo `/sdk-lesson`. |

---

## Começando

> Pré-requisito: ter o **Claude Code** instalado e este repositório aberto na pasta do seu projeto. Veja o
> [`INSTALL.md`](./INSTALL.md) para instalar o kit num projeto novo ou existente.

1. **Abra o Claude Code** na pasta do projeto.
2. Rode **`/sdk-bootstrap`** e descreva, em uma ou duas frases, o que o produto faz e para quem.
3. Responda às perguntas (uma de cada vez). O agente vai:
   - preparar a estrutura e o `.gitignore`;
   - confirmar/recomendar o **stack** e o **modo** (PROTOTYPE ou PRODUCTION);
   - fazer a **descoberta de domínio** (país, leis, pagamentos…) com fontes;
   - conduzir as **decisões de arquitetura** com trade-offs;
   - propor as **regras de negócio** (constituição do projeto);
   - montar o **escopo do MVP** (epics).
4. A cada checkpoint 🛑, revise e aprove.
5. Quando estiver pronto, detalhe a primeira área com **`/sdk-spec`** → **`/sdk-plan`** →
   **`/sdk-implement`** → **`/sdk-review`**.

**Atalho opcional (Fase 4):** `scripts/new-feature.sh "minha-feature"` (ou `.ps1` no Windows) cria as pastas
de spec/plano e uma branch dedicada a partir dos moldes.

---

## Modos: PROTOTYPE × PRODUCTION

O kit escala o **rigor** conforme o modo (definido no `project-context.md`):

- **PROTOTYPE** — rápido e descartável. Menos cerimônia, testes só no essencial, decisões reversíveis.
- **PRODUCTION** — mantido a sério. Verificação rigorosa, TDD na lógica crítica, decisões registradas (ADRs).

Os princípios da constituição valem nos dois modos; o que muda é o **nível de rigor**, nunca a integridade.

---

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

**Uso multi-projeto (transversal).** Para compartilhar a mesma biblioteca entre vários projetos, transforme-a
num repositório próprio e inclua como **git submodule**:

```bash
git submodule add <url-do-repo-de-licoes> .specify/memory/lessons
```

Assim cada postmortem novo (em qualquer projeto) contribui de volta, e a biblioteca cresce como um acervo
único, reutilizável e independente de projeto.

## Estrutura do repositório

```
spec-driven-kit/
├── README.md                          # este arquivo
├── INSTALL.md                         # como instalar o kit num projeto
├── CLAUDE.md                          # regras de base sempre carregadas (curto, p/ economia de token)
│
├── .specify/                          # compatível com o Spec Kit oficial
│   ├── memory/                        # bases lidas SOB DEMANDA pelos comandos
│   │   ├── constitution.md            # princípios universais e neutros (8)
│   │   ├── engineering-standards.md   # barra técnica (infra, perf, segurança, testes…)
│   │   ├── decision-guide.md          # ★ catálogo de trade-offs (alimenta /sdk-decide)
│   │   ├── lessons.md                 # ★ biblioteca de lições generalizadas (erros → prevenção)
│   │   └── project-context.md         # GERADO na descoberta (país, leis, decisões)
│   └── templates/                     # moldes de context / spec / plan / tasks
│
├── .claude/
│   ├── commands/                      # os slash commands sdk-*
│   └── agents/                        # subagentes (researcher, reviewer, lesson-curator)
│
├── docs/
│   ├── specs/                         # specs aprovadas (uma pasta por feature)
│   ├── plans/                         # planos e tasks
│   ├── decisions/                     # ADRs (decisões de arquitetura)
│   └── epics.md                       # escopo do MVP
│
└── scripts/                           # (opcional) scaffolding bash + PowerShell
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
| `/sdk-spec` | `/speckit.specify` (a parte guiada lembra `/speckit.clarify`) |
| `/sdk-plan` | `/speckit.plan` |
| `/sdk-tasks` | `/speckit.tasks` |
| `/sdk-review` | `/speckit.analyze` (porém via revisão, não read-only automático) |
| `/sdk-implement` | `/speckit.implement` |

---

## Princípios de produto (o que nos diferencia)

- **Conversa, não formulário.** Uma pergunta por vez. Você nunca sente que preenche um arquivo.
- **Explicar antes de perguntar.** Toda pergunta vem com o "porquê" e exemplos.
- **Adaptar ao nível.** Técnico → acelera. "Não sei" → simplifica e sugere um default seguro.
- **Decisões com trade-offs.** Em cada bifurcação relevante: facilidade × desempenho × custo × escala, com
  recomendação por modo. Sempre: "posso construir qualquer um dos dois".
- **Honestidade epistêmica.** Não inventar regras de negócio/lei — pesquisar, citar fontes, sinalizar
  incerteza. Compliance é confirmado por humano.
- **Artefato é a fonte da verdade.** Código serve à spec; se divergem, a spec vence.

---

## Licença

Distribuído sob a licença **MIT** — veja [`LICENSE`](./LICENSE). Uso, cópia e modificação livres, mantendo o
aviso de copyright.
