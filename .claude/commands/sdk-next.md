---
description: Porta de entrada diária — lê o estado do projeto (ledger, artefatos, git) e recomenda o próximo passo com o porquê. Read-only; não executa nada sozinho.
argument-hint: "[opcional: nome da feature]"
---

# /sdk-next — Onde estou e qual o próximo passo

Responda, sem que o usuário precise lembrar o fluxo: **onde o projeto está**, em que etapa está a feature
ativa, qual o **risco** da mudança em curso e **qual comando rodar agora** — com o porquê em linguagem
simples.

> Este comando é **read-only e barato** de propósito: lê marcadores de estado (linhas, não arquivos
> inteiros) e recomenda. Ele **nunca executa** o passo recomendado sozinho — recomendar e parar é o que
> preserva os checkpoints de aprovação.

## O que ler (nesta ordem, e só isto — economia de token)

1. `.specify/memory/project-context.md` — só as linhas de **Identidade/Modo** (grep, não o arquivo todo).
2. `docs/epics.md` — a tabela **"Ordem de construção (dependências)"** (o ledger: colunas Estado e
   "Pronta p/ começar?").
3. `git branch --show-current` e `git status --porcelain` — o que está em curso (**sinal**, não verdade).
4. **Só da feature ativa:** a linha `Status:` de `docs/specs/<feature>/spec.md` e de
   `docs/plans/<feature>/plan.md`, as linhas `**Analyze:**` e `**Review:**` do plano, e os estados das
   tasks (`tasks.md` ou a tabela inline do plano).
5. Se existir `docs/plans/<feature>/evidence.md`, leia só o resumo, os `Registro` mais recentes das tasks
   ativas e `Bloqueio`. A ref SHA é apenas proveniência; não compare com HEAD nem use
   `current`/`historical`.

Não carregue spec/plano inteiros, nem `decision-guide`, `engineering-standards` ou `lessons` — isso é papel
dos comandos de cada etapa.

## Como decidir a recomendação

| Situação observada | Próximo passo recomendado |
|--------------------|---------------------------|
| Não há `docs/epics.md` preenchido (ou está no esqueleto) | `/sdk-bootstrap` — o projeto ainda não fez o onboarding |
| Ledger existe; nenhuma feature em andamento; há 🟢 | `/sdk-spec` da próxima 🟢 (ou `/sdk-roadmap` se a ordem parece desatualizada) |
| Spec `rascunho` / `em revisão` | Terminar a spec: `/sdk-spec` (ou `/sdk-clarify`, se o que falta é tirar ambiguidade) |
| Spec `aprovada`, sem plano | Risco médio/alto → `/sdk-plan` · risco trivial/baixo → a régua permite encurtar (ver abaixo) |
| Plano `rascunho` | Terminar/aprovar o plano: `/sdk-plan` |
| Plano `aprovado`, linha `**Analyze:**` ainda `pendente` | `/sdk-analyze` (médio/alto) ou direto `/sdk-implement` (baixo, régua dispensa) |
| Analyze `consistente` (ou dispensado), há `ready`/`in-progress` | `/sdk-implement`; dependências internas `verification-pending`/`done` já satisfazem a ordem |
| Não há task implementável e há `verification-pending` | `/sdk-review` — revisor fresco reexecuta o menor subconjunto seguro |
| Não há `ready`/`in-progress`/`verification-pending`; há `blocked` ainda não resolvida | Não avance; mostre motivo/condição. Resolvida, `/sdk-implement` retoma por `blocked → ready` |
| `blocked` contradiz marker/realidade | `/sdk-doctor` — reconciliar sem apagar histórico |
| Todas as tasks `done` e `**Review:**` pendente | `/sdk-review` — consolidar veredito; sob contrato estrito, `done` sem recibo review é drift |
| `**Review:** aprovado` / feature `concluída` | `/sdk-roadmap` — ver o que a conclusão desbloqueou, e seguir para a próxima 🟢 |
| `**Review:** bloqueado` ou `aprovado com ressalvas` | `/sdk-implement` para corrigir/reverificar; depois `/sdk-review` de novo. Não pule direto para review nem avance de feature |
| Marcadores contraditórios entre si (ledger × artefatos × git) | `/sdk-doctor` — diagnóstico global read-only + reconciliação aprovada |

- **Estime o risco** aplicando a definição de lógica crítica e a **régua de cerimônia** da
  `constitution.md` ao que a feature toca. Na dúvida entre dois níveis, use o de cima — e diga isso.
- **Git como sinal de divergência:** se há mudanças de código na branch mas o ledger/artefatos dizem outra
  coisa (ex.: feature "em spec" com código já mexido), **aponte a divergência** ao usuário em vez de fingir
  que não existe — e sugira `/sdk-doctor`; a hierarquia de fonte da verdade do `CLAUDE.md` decide quem vence.
- Sob contrato estrito, `verification-pending` exige `Registro implement` válido; `done`, recibo `review`
  `pass`/`observed`. Também exige: dependência de `verification-pending` em
  `verification-pending`/`done` e dependência de
  `done` em `done`. Ausência/formato incompleto pede `/sdk-doctor`, nunca presunção.
- O contrato é estrito: a fonte das tasks exige marker `- **Evidence:**` para a própria feature, e estados
  comprovados exigem seus recibos. Ausência/formato incompleto pede `/sdk-doctor`; não há modo legado.
- `partial`/`reopened` são inválidos. `blocked` volta a `ready` após sua condição objetiva ser observada.
- **Não substitui o `/sdk-roadmap`:** o roadmap decide **qual feature** vem agora (dependências); o next
  decide **qual etapa** da feature atual. Quando a dúvida for "qual feature?", mande para o roadmap.

## Saída (curta, sempre neste formato)

- **Onde estamos:** produto/modo em 1 frase · feature ativa e o estágio dela.
- **Risco:** o nível da régua para a mudança em curso, e o que isso implica no fluxo.
- **Próximo passo:** **um** comando recomendado + o porquê em 1–2 frases.
- **Alternativa consciente:** se der para encurtar (ex.: pular `/sdk-tasks` em PROTOTYPE), diga qual etapa e
  qual o custo de pular.
- Termine perguntando se o usuário quer seguir com o recomendado. **Não execute sem o "sim".**
