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
padrões de engenharia, guia de decisões) são markdown carregado em memória.

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

### Subagentes (opcionais, usados pelos comandos)

| Agente | Para quê |
|--------|----------|
| `sdk-domain-researcher` | Pesquisa de domínio/compliance na descoberta — com fontes e marcas `[VERIFICAR]`. Não dá veredito legal. |
| `sdk-reviewer` | Revisão de **contexto fresco** (sem o viés de quem escreveu o código), usada pelo `/sdk-review`. |

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

## Estrutura do repositório

```
spec-driven-kit/
├── README.md                          # este arquivo
├── INSTALL.md                         # como instalar o kit num projeto
│
├── .specify/                          # compatível com o Spec Kit oficial
│   ├── memory/                        # contexto sempre carregado pelo agente
│   │   ├── constitution.md            # princípios universais e neutros
│   │   ├── engineering-standards.md   # barra técnica (infra, perf, segurança, testes…)
│   │   ├── decision-guide.md          # ★ catálogo de trade-offs (alimenta /sdk-decide)
│   │   └── project-context.md         # GERADO na descoberta (país, leis, decisões)
│   └── templates/                     # moldes de context / spec / plan / tasks
│
├── .claude/
│   ├── commands/                      # os slash commands sdk-*
│   └── agents/                        # subagentes (researcher, reviewer)
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
