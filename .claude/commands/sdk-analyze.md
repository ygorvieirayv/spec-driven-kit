---
description: Confere a CONSISTÊNCIA entre spec, plano, tasks e critérios de aceitação (read-only, não conserta). Roda antes de implementar para pegar furos cedo.
argument-hint: "[nome da feature]"
---

# /sdk-analyze — Conferência de consistência (read-only)

Verifique se os artefatos de uma feature **batem entre si** antes de gastar tempo implementando. Este comando
**não conserta nada** — ele aponta os furos para você decidir. É barato e pega problemas cedo.

> Diferença para o `/sdk-review`: o **analyze** olha os **documentos** (spec ↔ plano ↔ tasks) e não toca no
> código; o **review** olha o **código** já feito. Use analyze **antes** de implementar; review **depois**.

Carregue (somente leitura): a spec (`docs/specs/<feature>/spec.md`), o plano e as tasks
(`docs/plans/<feature>/` — `tasks.md` se existir, senão a tabela "Tasks" inline do `plan.md`), o
`project-context.md` (modo) e o `docs/epics.md`.

## O que conferir
> As checagens abaixo rodam **iguais nos dois modos** — o que muda por modo é o que ainda existe pra checar
> (ex.: PROTOTYPE pode não ter ADR) e o quanto um achado bloqueia (ver matriz de rigor da `constitution.md`).
> Nunca pule uma checagem só por "ser PROTOTYPE".

1. **Cobertura de AC:** todo critério de aceitação (AC) da spec tem ≥1 task **e** ≥1 forma de verificação?
   (Vale tanto para `tasks.md` quanto para a tabela inline do `plan.md`.) (AC sem task = vai ficar de fora.)
2. **Tasks válidas:** toda task referencia um AC que **existe** na spec? (Task sem AC = trabalho sem motivo.)
3. **Dependências coerentes:** a ordem das tasks respeita as dependências (sem ciclo)? As dependências
   externas/de outras features citadas na spec **existem/estão prontas**? (Se não, aponte e sugira
   `/sdk-roadmap`.)
4. **Decisões alinhadas:** o plano respeita as decisões de arquitetura do `project-context.md`/`docs/decisions`?
   Nada no plano contradiz um ADR?
5. **NFRs herdados:** os requisitos não-funcionais da spec batem com os globais do `project-context.md`
   (ou explicam por que mudam)? Em PROTOTYPE sem NFR definido ainda, marque N/A — não é bloqueio.
6. **Pendências críticas:** sobrou algum `[VERIFICAR]` que **bloqueia** a implementação (ex.: compliance,
   fonte de dado essencial)?
7. **Escopo:** há algo no plano/tasks que **não** está na spec (escopo inflado), ou algo da spec **fora** do
   plano (lacuna)?
8. **Brownfield (se Tipo = brownfield):** a seção de delta (ADICIONADO/MODIFICADO/REMOVIDO) está preenchida?
   O que **não pode quebrar** virou **teste de não-regressão** nas tasks? Há plano de migração/rollback para
   o que muda em dados existentes?

## Severidade
- **Crítico** — vai quebrar ou implementar a coisa errada (AC sem task, ADR contrariado, dependência ausente).
- **Alto** — provável retrabalho (escopo divergente, NFR ignorado).
- **Médio/Baixo** — ajustes de clareza/rastreio.

## Saída
- Lista de inconsistências **por severidade**, cada uma dizendo **onde** (arquivo/linha ou AC/Task) e **o que
  fazer** (mas sem aplicar).
- Veredito em linguagem simples: **consistente** / **ajustar antes de implementar** / **bloqueado**.
- **Registre o veredito no plano** (**conversa aprova, arquivo registra**): atualize a linha `**Analyze:**`
  do cabeçalho de `docs/plans/<feature>/plan.md` com `<consistente | ajustar | bloqueado> — <data>`. É o
  marcador que o `/sdk-next` lê para não recomendar a análise de novo à toa. O comando continua read-only
  quanto ao **conteúdo** dos artefatos — este registro é só metadado de estado.
- Se houver Crítico, recomende voltar ao `/sdk-spec`, `/sdk-plan`, `/sdk-tasks` ou `/sdk-roadmap` conforme o caso.
