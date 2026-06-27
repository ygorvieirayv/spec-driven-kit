# Instalação

O **Spec Driven Kit** é, na prática, um conjunto de arquivos markdown (comandos, agentes e bases de
conhecimento) que o **Claude Code** lê. Instalar = colocar esses arquivos no seu projeto. Não há build nem
dependências.

> Pré-requisito: ter o **Claude Code** instalado. Veja https://claude.com/claude-code.

---

## Opção 1 — Começar um projeto novo a partir do kit

Use este repositório como ponto de partida.

```bash
# clone e renomeie para o seu projeto
git clone https://github.com/ygorvieirayv/spec-driven-kit.git meu-projeto
cd meu-projeto

# comece o histórico do seu projeto do zero
rm -rf .git
git init

# abra o Claude Code e rode o onboarding guiado
#   /sdk-bootstrap
```

O `/sdk-bootstrap` cuida do resto: estrutura, `.gitignore`, stack, descoberta, decisões e MVP.

---

## Opção 2 — Adicionar o kit a um projeto existente

Copie as três peças do kit para a raiz do seu projeto, **sem** sobrescrever seu código:

1. **`.specify/`** — memória (constituição, padrões, guia de decisões, templates).
2. **`.claude/`** — `commands/` (os `sdk-*`) e `agents/` (researcher e reviewer).
3. **`docs/`** — pastas de saída (`specs/`, `plans/`, `decisions/`) e `epics.md`.
4. *(Opcional)* **`scripts/`** — scaffolding de feature em bash/PowerShell.

```bash
# a partir da raiz do seu projeto existente
SDK=/caminho/para/spec-driven-kit

cp -r "$SDK/.specify"        ./
cp -r "$SDK/.claude"         ./
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
ls .claude/commands     # deve listar sdk-bootstrap.md, sdk-decide.md, ...
ls .claude/agents       # sdk-domain-researcher.md, sdk-reviewer.md
ls .specify/memory      # constitution.md, engineering-standards.md, decision-guide.md
```

No Claude Code, digite `/` e veja se os comandos `sdk-*` aparecem. Pronto: rode **`/sdk-bootstrap`**.

---

## Atualizando o kit

Para puxar melhorias do kit sem perder seus artefatos:

- **Seguro de sobrescrever** (são o "motor" do kit): `.claude/commands/`, `.claude/agents/`,
  `.specify/templates/`, `.specify/memory/decision-guide.md`, `.specify/memory/engineering-standards.md`,
  `.specify/memory/constitution.md` *(a menos que você tenha editado a seção "Princípios específicos deste
  projeto")*.
- **Nunca sobrescreva** (são **seus**): `.specify/memory/project-context.md`, `docs/specs/`, `docs/plans/`,
  `docs/decisions/`, `docs/epics.md`.

---

## Desinstalar

Remova `.specify/`, `.claude/commands/sdk-*.md`, `.claude/agents/sdk-*.md` e (se quiser) `docs/` e
`scripts/`. Seu código de aplicação não é tocado pelo kit.
