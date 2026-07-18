# Instalação

O **Spec Driven Kit** é, na prática, um conjunto de arquivos markdown (comandos, agentes e bases de
conhecimento) que o **Claude Code** lê. Instalar = colocar esses arquivos no seu projeto. Não há build nem
dependências.

> Pré-requisito: ter o **Claude Code** instalado. Veja https://claude.com/claude-code.

---

## Opção 0 — Instalador automático (recomendado)

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

- **ENGINE** (motor do kit): comandos, agentes, templates, `CLAUDE.md`, `COMO-USAR.md` e scripts. Se o
  arquivo não existe, copia. Se existe e diverge, **não sobrescreve por padrão**: grava `<arquivo>.sdk-new`
  para você comparar. Com `--force`/`-Force`, atualiza somente arquivos ENGINE depois de criar backup
  `<arquivo>.sdk-bak.<data>`.
- **SEED** (arquivos do produto): `project-context.md`, `docs/epics.md`, READMEs de `docs/` e `.gitignore`.
  Copia só quando ausentes. Se já existem, nunca sobrescreve.
- **MERGE**: `lessons.md`. Se já existe, grava `.sdk-new` para merge manual, porque o arquivo acumula
  lições do seu projeto.
- **SKIP**: documentação e infra do repositório do kit (`README.md`, `ROADMAP.md`, `docs/example/`,
  `.github/`, `tests/`, `install.*`, `VERSION`, `CHANGELOG.md`). Nunca são copiados para a raiz do produto.

Ao final de uma instalação real, o instalador roda `sdk-check` no destino e mostra o próximo passo:
abrir o Claude Code no projeto e rodar **`/sdk-bootstrap`**. A distribuição via `npm create`/`npx` é um
caminho futuro; hoje o instalador local é o caminho suportado.

O instalador também registra a versão do kit instalada em `.specify/spec-driven-kit.version`. Esse arquivo é
um selo do kit, não a versão do seu produto, e é seguro commitar. O `VERSION` da raiz do repositório do kit
fica fora do seu projeto para evitar colisão com versionamento próprio da aplicação.

---

## Opção 1 — Começar um projeto novo a partir do kit

Use este repositório como ponto de partida.

```bash
# 1) Clone para a pasta do seu projeto
#    (o repo precisa estar acessível; se ainda estiver privado, o clone pede login no GitHub)
git clone https://github.com/ygorvieirayv/spec-driven-kit.git meu-projeto
cd meu-projeto

# 2) Comece o histórico do SEU projeto do zero
rm -rf .git          # Windows (PowerShell): Remove-Item -Recurse -Force .git
git init

# 3) primeiro commit do seu projeto (necessário antes de /sdk-implement registrar evidence)
git add -A && git commit -m "chore: inicia projeto a partir do Spec Driven Kit"

# 4) abra o Claude Code e rode o onboarding guiado
#   /sdk-bootstrap
```

> **Limpe o que é do kit (não do seu produto).** Após o clone, troque o `README.md` pelo do seu projeto e,
> se quiser, remova `INSTALL.md`, `ROADMAP.md` e `docs/example/` (são documentação do kit). Vale **manter**: `.specify/`,
> `.claude/`, `CLAUDE.md`, `COMO-USAR.md`, `docs/specs|plans|decisions`, `scripts/`. O `LICENSE` é sua
> escolha (o do kit é MIT).

O `/sdk-bootstrap` cuida do resto: estrutura, `.gitignore`, stack, descoberta, decisões e MVP.

---

## Opção 2 — Adicionar o kit a um projeto existente

Copie as peças do kit para a raiz do seu projeto, **sem** sobrescrever seu código:

1. **`.specify/`** — memória (constituição, padrões, guia de decisões, lições, templates).
2. **`.claude/`** — `commands/` (os `sdk-*`) e `agents/` (researcher, reviewer, lesson-curator).
3. **`CLAUDE.md`** — regras de base sempre carregadas (na raiz do projeto).
4. **`docs/`** — pastas de saída (`specs/`, `plans/`, `decisions/`) e `epics.md`.
5. *(Opcional)* **`scripts/`** — scaffolding de feature em bash/PowerShell.

```bash
# a partir da raiz do seu projeto existente
SDK=/caminho/para/spec-driven-kit

cp -r "$SDK/.specify"        ./
cp -r "$SDK/.claude"         ./
cp    "$SDK/CLAUDE.md"       ./
cp    "$SDK/COMO-USAR.md"    ./   # guia rápido (opcional, mas útil)
cp -r "$SDK/docs"            ./
cp -r "$SDK/scripts"         ./   # opcional

# se você ainda não tem um .gitignore, aproveite o do kit (ele protege .env)
[ -f .gitignore ] || cp "$SDK/.gitignore" ./
```

> **Cuidado:** se você já tem `.claude/commands/` ou `docs/` com conteúdo, mescle em vez de sobrescrever.
> Os comandos `sdk-*` não colidem com outros comandos seus (têm prefixo próprio).

Depois, abra o Claude Code e rode `/sdk-bootstrap`. Em repositório existente, ele **lê o seu stack** e
confirma com você, em vez de recriar.

---

## Opção 3 — Usando outra ferramenta (sem slash commands nativos)

O kit foi feito para o Claude Code, mas os comandos são só **markdown em `.claude/commands/`** — nada
impede outra ferramenta de IA agente (ex.: Codex CLI) de ler e seguir esses arquivos, desde que ela saiba
onde procurar. Para isso existe um **adaptador**: um `AGENTS.md` que ensina a ferramenta a interpretar uma
flag de texto (`--sdk-bootstrap`, `--sdk-spec`, ...) como "leia o comando correspondente e siga-o".

```bash
# a partir da raiz do seu projeto (depois de instalar via Opção 1 ou 2)
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

---

## Verificando a instalação

Confira que o Claude Code enxerga os comandos:

```bash
ls .claude/commands     # sdk-next, sdk-bootstrap, sdk-roadmap, sdk-spec, sdk-clarify, sdk-plan, sdk-tasks,
                        # sdk-analyze, sdk-implement, sdk-review, sdk-decide, sdk-lesson, sdk-doctor (.md)
ls .claude/agents       # sdk-domain-researcher.md, sdk-reviewer.md, sdk-lesson-curator.md
ls .specify/memory      # constitution.md, engineering-standards.md, decision-guide.md, lessons.md,
                        # state-markers.md
ls scripts              # new-feature.sh/.ps1, sdk-check.sh/.ps1 (validação de estado)
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
  `.specify/memory/state-markers.md`, `scripts/sdk-check.*`, `CLAUDE.md`, `COMO-USAR.md`,
  `.specify/memory/constitution.md` *(a menos que você tenha editado a seção "Princípios específicos deste
  projeto")*.
- **Nunca sobrescreva** (são **seus**): `.specify/memory/project-context.md`, `docs/specs/`, `docs/plans/`,
  `docs/decisions/`, `docs/epics.md`, e o `AGENTS.md` na raiz **se você usou a Opção 3** (ele foi preenchido
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

Remova `.specify/`, `.claude/commands/sdk-*.md`, `.claude/agents/sdk-*.md`, `CLAUDE.md`, `COMO-USAR.md` e
(se quiser) `docs/` e `scripts/`. Seu código de aplicação não é tocado pelo kit.
