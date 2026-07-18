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

1. `.specify/memory/project-context.md` — só as linhas de **Identidade** e **Restrições conhecidas** (grep,
   não o arquivo todo).
2. `docs/epics.md` — a tabela **"Ordem de construção (dependências)"** (o ledger: colunas Estado e
   "Pronta p/ começar?").
3. `git branch --show-current` e `git status --porcelain` — o que está em curso (**sinal**, não verdade).
4. **Só da feature ativa:** as linhas `Status:` e `Risco:` de `docs/specs/<feature>/spec.md`; `Status:`,
   `**Analyze:**` e `**Review:**` de `docs/plans/<feature>/plan.md`; e os estados das tasks em `tasks.md`.
   No plano, leia somente as linhas da tabela de perfis marcadas `aplicável`.
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
| Mudança confirmada como trivial, sem lifecycle formal | `/sdk-implement` com verificação objetiva; depois review leve. Se tocar lógica crítica, reclassifique e abra spec |
| Spec `aprovada`, sem plano | `/sdk-plan` — toda feature formal, inclusive risco baixo, registra estratégia e perfis |
| Plano `rascunho` | Terminar/aprovar o plano: `/sdk-plan` |
| Plano `aprovado`, sem `tasks.md` | `/sdk-tasks` — gerar a fonte única de tasks e ligar ACs aos perfis |
| `tasks.md` existe e `**Analyze:**` está `pendente` | `/sdk-analyze` — toda feature formal passa pelo gate antes de código |
| `**Analyze:** ajustar` | Volte ao comando dono apontado no último relatório do `/sdk-analyze` e depois rode `/sdk-analyze` novamente. Não implemente com o gate reprovado |
| `**Analyze:** bloqueado` | Não avance. Siga o comando dono indicado no último relatório do `/sdk-analyze`, resolva o achado Crítico/Alto e depois rode `/sdk-analyze` novamente |
| Analyze `consistente`, há `ready`/`in-progress` | `/sdk-implement`; dependências internas `verification-pending`/`done` já satisfazem a ordem |
| Não há task implementável e há `verification-pending` | `/sdk-review` — revisor fresco reexecuta o menor subconjunto seguro |
| Não há `ready`/`in-progress`/`verification-pending`; há `blocked` ainda não resolvida | Não avance; mostre motivo/condição. Resolvida, `/sdk-implement` retoma por `blocked → ready` |
| `blocked` contradiz marker/realidade | `/sdk-doctor` — reconciliar sem apagar histórico |
| Todas as tasks `done` e `**Review:**` pendente | `/sdk-review` — consolidar veredito; sob contrato estrito, `done` sem recibo review é drift |
| (`**Review:** aprovado` ou `aprovado com ressalvas`) **e** feature `concluída` | `/sdk-roadmap` — ressalvas aceitas já viraram sub-features `a fazer` no ledger; veja o que a conclusão desbloqueou |
| `**Review:** bloqueado`, sem task `blocked` não resolvida, e há task `ready`/`in-progress` | `/sdk-implement` para corrigir/reverificar; depois `/sdk-review` de novo. Não pule direto para review nem avance de feature |
| `**Review:** bloqueado` e há task `blocked` não resolvida | Não avance nem repita `/sdk-review`; mostre a condição do `Bloqueio`. Somente depois de resolvida, `/sdk-implement` retoma por `blocked → ready` |
| `**Review:** bloqueado`, mas os estados das tasks não explicam o bloqueio | `/sdk-doctor` — reconciliar o veredito e os markers sem presumir correção |
| Marcadores contraditórios entre si (ledger × artefatos × git) | `/sdk-doctor` — diagnóstico global read-only + reconciliação aprovada |

- **Leia o risco gravado na spec** e faça uma checagem de sanidade pela definição de lógica crítica da
  `constitution.md`. Ausência ou subestimação pede `/sdk-spec`/`/sdk-doctor`; não recalcule em silêncio.
- **Git como sinal de divergência:** se há mudanças de código na branch mas o ledger/artefatos dizem outra
  coisa (ex.: feature "em spec" com código já mexido), **aponte a divergência** ao usuário em vez de fingir
  que não existe — e sugira `/sdk-doctor`; a hierarquia de fonte da verdade do `CLAUDE.md` decide quem vence.
- Sob contrato estrito, `verification-pending` exige `Registro implement` válido; `done`, recibo `review`
  `pass`/`observed`. Também exige: dependência de `verification-pending` em
  `verification-pending`/`done` e dependência de
  `done` em `done`. Ausência/formato incompleto pede `/sdk-doctor`, nunca presunção.
- O contrato é estrito: a fonte das tasks exige marker `- **Evidence:**` para a própria feature, e estados
  comprovados exigem seus recibos. Ausência/formato incompleto pede `/sdk-doctor`.
- `partial`/`reopened` são inválidos. `blocked` volta a `ready` após sua condição objetiva ser observada.
- **Precedência:** `Analyze: ajustar/bloqueado` impede implementação. Depois do review, uma task `blocked`
  ainda não resolvida prevalece sobre a rota geral de `Review: bloqueado`; nunca transforme impedimento
  externo em nova tentativa automática de implementação.
- Se o último relatório do `/sdk-analyze` não estiver disponível para identificar o comando dono, não
  adivinhe: recomende **somente** `/sdk-analyze` para reconstruir o diagnóstico. A saída continua apontando
  um único comando.
- **Não substitui o `/sdk-roadmap`:** o roadmap decide **qual feature** vem agora (dependências); o next
  decide **qual etapa** da feature atual. Quando a dúvida for "qual feature?", mande para o roadmap.

## Saída (curta, sempre neste formato)

- **Onde estamos:** produto em 1 frase · feature ativa e o estágio dela.
- **Risco:** o nível da régua para a mudança em curso, e o que isso implica no fluxo.
- **Prova:** perfis aplicáveis já declarados (ou o ponto em que ainda serão definidos).
- **Próximo passo:** **um** comando recomendado + o porquê em 1–2 frases.
- **Atalho consciente:** só existe se a mudança for de fato trivial. Nunca sugira pular tasks/analyze de
  uma feature formal para economizar cerimônia.
- Termine perguntando se o usuário quer seguir com o recomendado. **Não execute sem o "sim".**
