# Instalação

O **Spec Driven Kit** é, na prática, um conjunto de arquivos markdown (comandos, agentes e bases de
conhecimento) que o **Claude Code** lê. Instalar = colocar esses arquivos no seu projeto. Não há build nem
dependências.

> Pré-requisito: ter o **Claude Code** instalado. Veja https://claude.com/claude-code.

---

## Instalação suportada — instalador manifest-aware

Use esta opção para adicionar ou atualizar o kit em um projeto sem copiar pastas manualmente. O instalador
roda a partir de um clone do Spec Driven Kit e copia só o que pertence ao projeto de destino.

```bash
# 1) Clone o kit em qualquer pasta temporária/de ferramentas
git clone https://github.com/ygorvieirayv/spec-driven-kit.git spec-driven-kit
cd spec-driven-kit

# 2) Veja o plano sem escrever nada
bash install.sh --target /caminho/do/seu-projeto --dry-run --yes

# 3) Instale de fato
bash install.sh --target /caminho/do/seu-projeto --yes
```

No Windows PowerShell:

```powershell
git clone https://github.com/ygorvieirayv/spec-driven-kit.git spec-driven-kit
cd spec-driven-kit

.\install.ps1 -Target C:\caminho\do\seu-projeto -DryRun -Yes
.\install.ps1 -Target C:\caminho\do\seu-projeto -Yes
```

O instalador segue o manifesto `scripts/kit-manifest.txt`:

- **ENGINE** (motor do kit): comandos, agentes, templates, `CLAUDE.md`, `COMO-USAR.md` e scripts, incluindo
  `sdk-ci.sh`/`.ps1` e `sdk-secrets.sh`. Se o
  arquivo não existe, copia. Se existe e diverge, **não sobrescreve por padrão**: grava `<arquivo>.sdk-new`
  para você comparar. Com `--force`/`-Force`, atualiza somente arquivos ENGINE depois de criar backup
  `<arquivo>.sdk-bak.<data>`.
- **SEED** (arquivos do produto): `project-context.md`, `docs/epics.md`, READMEs de `docs/` e `.gitignore`.
  Copia só quando ausentes. Se já existem, nunca sobrescreve.
- **MERGE**: `lessons.md`. Se já existe, grava `.sdk-new` para merge manual, porque o arquivo acumula
  lições do seu projeto.
- **SKIP**: documentação e infra do repositório do kit (`README.md`, `ROADMAP.md`, `docs/example/`,
  `.github/`, `tests/`, `install.*`, `VERSION`, `CHANGELOG.md`). Nunca são copiados para a raiz do produto.

Antes da primeira escrita, o instalador valida o destino e cada componente de caminho que utilizará.
Symlink, junction ou reparse point capaz de redirecionar arquivo, sidecar, selo ou backup para fora do
projeto interrompe a instalação sem mutação parcial.

Ao final de uma instalação real, o instalador roda `sdk-check` no destino e mostra o próximo passo:
abrir o Claude Code no projeto e rodar **`/sdk-bootstrap`**. A distribuição via `npm create`/`npx` é um
caminho futuro; hoje o instalador local é o caminho suportado.

O instalador também registra a versão do kit instalada em `.specify/spec-driven-kit.version`. Esse arquivo é
um selo do kit, não a versão do seu produto, e é seguro commitar. O `VERSION` da raiz do repositório do kit
fica fora do seu projeto para evitar colisão com versionamento próprio da aplicação.

---

## Projetos novos e existentes

Use o mesmo instalador acima nos dois casos. Em pasta nova, ele cria somente os arquivos declarados no
manifesto; em repositório existente, preserva código e dados do produto, gerando sidecar quando encontra
conflito de motor. Clonar este repositório como se fosse o produto ou copiar `docs/`/`scripts/`
recursivamente não é caminho suportado: isso levaria CI, fixtures e documentação interna marcados como
`SKIP` para dentro da aplicação.

Depois da instalação, abra a ferramenta de IA no projeto e rode `/sdk-bootstrap`. Em brownfield, o comando
lê o stack e o comportamento existentes antes de propor qualquer mudança.

Depois que você aprovar stack, runner/setup e a matriz dos seis gates no Checkpoint 1, o bootstrap cria
`.github/workflows/sdk-quality.yml` e um contrato explícito em `.specify/ci/gates/`. Esses arquivos são
dados do produto, ficam fora do manifesto e não são sobrescritos nem mesmo por uma atualização com
`--force`/`-Force`.

---

## Outras ferramentas

### Codex CLI e ferramentas sem comandos nativos

O kit foi feito para o Claude Code, mas os comandos são só **markdown em `.claude/commands/`** — nada
impede outra ferramenta de IA agente (ex.: Codex CLI) de ler e seguir esses arquivos, desde que ela saiba
onde procurar. Para isso existe um **adaptador**: um `AGENTS.md` que ensina a ferramenta a interpretar uma
flag de texto (`--sdk-bootstrap`, `--sdk-spec`, ...) como "leia o comando correspondente e siga-o".

```bash
# a partir da raiz do seu projeto (depois de usar o instalador manifest-aware)
cp .specify/templates/agents-md-template.md ./AGENTS.md
```

Preencha os placeholders `<...>` do `AGENTS.md` copiado (nome do produto, estrutura, comandos) conforme o
que o bootstrap gerar em `project-context.md`. O restante do fluxo é idêntico — em vez de `/sdk-plan`, você
digita `--sdk-plan` (ou o equivalente que sua ferramenta aceitar como texto livre).

> **Se você usa Claude Code, ignore esta opção** — os comandos já existem como `/sdk-*` nativamente.

> **Codex CLI:** este adaptador é o caminho **recomendado** (não um fallback) para o Codex. Os "custom
> prompts" dele foram descontinuados — e mesmo quando existiam viviam na pasta do usuário
> (`~/.codex/prompts/`), sem viajar com o repositório. Já o `AGENTS.md` é lido pelo Codex a cada início,
> como regra permanente do projeto.

### OpenCode com comandos nativos

Depois da instalação, gere `.opencode/commands/sdk-*.md` a partir da fonte canônica em
`.claude/commands/`:

```bash
bash scripts/export-opencode.sh
bash scripts/export-opencode.sh --check
```

No Windows PowerShell:

```powershell
.\scripts\export-opencode.ps1
.\scripts\export-opencode.ps1 -Check
```

O export é sob demanda e idempotente. Ele atualiza ou remove somente arquivos que carregam seu marcador
de geração, preserva comandos manuais e recusa colisão de nome em vez de sobrescrever. Não escolha modelo
nem agente automaticamente. Rode novamente depois de atualizar o kit; `--check`/`-Check` apenas confirma
que o diretório gerado está atual, sem alterar o projeto. Os `sdk-*.md` gerados ficam ignorados pelo `.gitignore` do
kit porque a fonte versionada é `.claude/commands/`; em projeto existente cujo `.gitignore` é preservado,
adicione `.opencode/commands/sdk-*.md`. Mantenha também um `AGENTS.md` preenchido se quiser que o
OpenCode receba as regras permanentes e o fallback inline dos subagentes do projeto.

---

## Verificando a instalação

Confira que o Claude Code enxerga os comandos:

```bash
ls .claude/commands     # sdk-next, sdk-cycle, sdk-bootstrap, sdk-roadmap, sdk-spec, sdk-clarify, sdk-plan,
                        # sdk-tasks, sdk-analyze, sdk-implement, sdk-review, sdk-decide, sdk-lesson,
                        # sdk-doctor (.md)
ls .claude/agents       # sdk-domain-researcher.md, sdk-reviewer.md, sdk-lesson-curator.md
ls .specify/memory      # constitution.md, engineering-standards.md, decision-guide.md, lessons.md,
                        # state-markers.md, project-context.md
ls scripts              # new-feature.*, export-opencode.*, sdk-check.*, sdk-ci.* e sdk-secrets.sh
cat .specify/spec-driven-kit.version  # versão do Spec Driven Kit instalada neste projeto
```

No Claude Code, digite `/` e veja se os comandos `sdk-*` aparecem. Pronto: rode **`/sdk-bootstrap`**.

---

## Atualizando o kit

Para puxar melhorias do kit sem perder seus artefatos:

- **Com instalador:** atualize o clone do kit (`git pull`) e rode novamente `bash install.sh --target
  /caminho/do/projeto --yes` ou `.\install.ps1 -Target C:\caminho\do\projeto -Yes`. Sem `--force`, conflitos
  do motor viram `.sdk-new`. Com `--force`, só arquivos ENGINE são atualizados, sempre com backup
  `.sdk-bak.<data>`. Antes de atualizar, consulte o [`CHANGELOG.md`](./CHANGELOG.md); durante a instalação,
  o instalador mostra a transição de versão, por exemplo `installed: 0.1.0 -> 0.2.0`.
- **Seguro de sobrescrever** (são o "motor" do kit): `.claude/commands/`, `.claude/agents/`,
  `.specify/templates/`, `.specify/memory/decision-guide.md`, `.specify/memory/engineering-standards.md`,
  `.specify/memory/state-markers.md`, `scripts/sdk-check.*`, `scripts/sdk-ci.*`, `scripts/sdk-secrets.sh`,
  `scripts/new-feature.*`, `scripts/export-opencode.*`, `CLAUDE.md`, `COMO-USAR.md` e
  `.specify/memory/constitution.md`. Princípios
  específicos ficam no `project-context.md`, nunca na
  constituição atualizável do motor.
- **Nunca sobrescreva** (são **seus**): `.specify/memory/project-context.md`, `.specify/ci/gates/`,
  `.github/workflows/sdk-quality.yml`, `docs/specs/`, `docs/plans/`, `docs/decisions/`, `docs/epics.md`, e o
  `AGENTS.md` na raiz **se você usa o adaptador** (ele foi preenchido
  com dados do seu projeto — só o molde em `.specify/templates/agents-md-template.md` é seguro de atualizar).
- **Evidence é estrito:** plan/tasks exige marker `- **Evidence:**` para a própria feature. O arquivo só
  nasce na primeira observação real, mas `verification-pending`, `done` e `blocked` não são aceitos sem os
  recibos correspondentes. Nunca invente recibos para satisfazer o checker.
- **`.specify/memory/lessons.md`** — caso à parte: as **sementes** vêm do kit, mas o arquivo **acumula** as
  suas lições. Faça **merge**, não sobrescreva. (Se usar a biblioteca como submodule, ela é versionada à
  parte e não há conflito.)
- **Depois de atualizar, reconcilie os sidecars.** Um `arquivo.sdk-new` é a versão nova do motor quando a
  sua divergia: compare (`diff arquivo arquivo.sdk-new`), incorpore o que fizer sentido e **apague o
  sidecar**. Para `lessons.md.sdk-new`, faça o merge das lições novas do kit para dentro do seu arquivo.
  Backups `*.sdk-bak.*` (criados pelo `--force`) podem ser apagados quando você confirmar que está tudo bem.
  Sidecar esquecido não é inofensivo — o `/sdk-doctor` avisa se encontrar.

---

## Desinstalar

Remova `.specify/`, `.claude/commands/sdk-*.md`, `.claude/agents/sdk-*.md`, os arquivos gerados
`.opencode/commands/sdk-*.md`, `CLAUDE.md`, `COMO-USAR.md` e (se quiser) `docs/` e `scripts/`. Seu código de
aplicação não é tocado pelo kit.
