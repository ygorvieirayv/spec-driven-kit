# Instalação

O **Spec Driven Kit** é, na prática, um conjunto de arquivos markdown (comandos, agentes e bases de
conhecimento) que o **Claude Code** lê. Instalar = colocar esses arquivos no seu projeto. Não há build nem
dependências.

> Pré-requisito: ter o **Claude Code** instalado. Veja https://claude.com/claude-code.

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

# 3) primeiro commit do seu projeto (quando quiser)
git add -A && git commit -m "chore: inicia projeto a partir do Spec Driven Kit"

# 4) abra o Claude Code e rode o onboarding guiado
#   /sdk-bootstrap
```

> **Limpe o que é do kit (não do seu produto).** Após o clone, troque o `README.md` pelo do seu projeto e,
> se quiser, remova `INSTALL.md` e `docs/example/` (são documentação do kit). Vale **manter**: `.specify/`,
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

## Verificando a instalação

Confira que o Claude Code enxerga os comandos:

```bash
ls .claude/commands     # sdk-bootstrap, sdk-roadmap, sdk-spec, sdk-clarify, sdk-plan, sdk-tasks,
                        # sdk-analyze, sdk-implement, sdk-review, sdk-decide, sdk-lesson (.md)
ls .claude/agents       # sdk-domain-researcher.md, sdk-reviewer.md, sdk-lesson-curator.md
ls .specify/memory      # constitution.md, engineering-standards.md, decision-guide.md, lessons.md
```

No Claude Code, digite `/` e veja se os comandos `sdk-*` aparecem. Pronto: rode **`/sdk-bootstrap`**.

---

## Atualizando o kit

Para puxar melhorias do kit sem perder seus artefatos:

- **Seguro de sobrescrever** (são o "motor" do kit): `.claude/commands/`, `.claude/agents/`,
  `.specify/templates/`, `.specify/memory/decision-guide.md`, `.specify/memory/engineering-standards.md`,
  `CLAUDE.md`, `COMO-USAR.md`, `.specify/memory/constitution.md` *(a menos que você tenha editado a seção
  "Princípios específicos deste projeto")*.
- **Nunca sobrescreva** (são **seus**): `.specify/memory/project-context.md`, `docs/specs/`, `docs/plans/`,
  `docs/decisions/`, `docs/epics.md`.
- **`.specify/memory/lessons.md`** — caso à parte: as **sementes** vêm do kit, mas o arquivo **acumula** as
  suas lições. Faça **merge**, não sobrescreva. (Se usar a biblioteca como submodule, ela é versionada à
  parte e não há conflito.)

---

## Desinstalar

Remova `.specify/`, `.claude/commands/sdk-*.md`, `.claude/agents/sdk-*.md`, `CLAUDE.md`, `COMO-USAR.md` e
(se quiser) `docs/` e `scripts/`. Seu código de aplicação não é tocado pelo kit.
