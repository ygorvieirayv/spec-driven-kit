# Spec — <Nome da Feature>

> **Para o agente:** preenchido pelo `/sdk-spec` por conversa guiada. Foco no **QUÊ** e no **PORQUÊ**, não
> no COMO (o COMO vai no plano). Remova ambiguidade perguntando antes de gravar. NFRs herdam do
> `project-context.md` — só repita aqui o que muda para esta feature. Grave em
> `docs/specs/<feature>/spec.md`.
>
> **Spec curta (risco baixo):** pela régua de cerimônia da `constitution.md`, mudança de baixo risco pode
> preencher só **Contexto e objetivo**, **Critérios de aceitação** e **Fora de escopo** — apague as demais
> seções em vez de deixá-las vazias. Se a mudança toca lógica crítica, não é baixo risco: spec completa.

- **Status:** rascunho | em revisão | aprovada
- **Modo:** PROTOTYPE | PRODUCTION
- **Tipo:** greenfield (algo novo) | brownfield (muda algo que já existe)
- **Autor / data:** <...>

---

## Contexto e objetivo
<Por que esta feature existe. Que problema resolve, para quem. O resultado esperado em 1–3 frases.>

## Mudança em sistema existente (delta) — *só se brownfield*
> Preencha **apenas** quando esta spec altera comportamento que **já existe** (estilo "delta spec"). Descreva
> o que muda em relação a hoje, para não reespecificar o sistema inteiro. Apague esta seção se for greenfield.

- **Comportamento atual:** <como funciona hoje>
- **ADICIONADO:** <o que passa a existir>
- **MODIFICADO:** <o que muda — de "como é" para "como fica">
- **REMOVIDO:** <o que deixa de existir>
- **Impacto / migração:** <dados a migrar, compatibilidade, o que pode quebrar, como reverter>
- **Regressão:** <o que precisa continuar funcionando igual — vira teste de não-regressão>

## Histórias / cenários de uso
- Como <tipo de usuário>, quero <ação> para <benefício>.

## Requisitos funcionais (FR)
> O que o sistema **faz**. Numerados para rastreio.

- **FR1** — <...>
- **FR2** — <...>

## Requisitos não-funcionais (NFR)
> O que muda em relação aos NFRs globais (`project-context.md`). Desempenho, segurança, acessibilidade,
> privacidade específicos desta feature.

- **NFR1** — <... ou "herda do project-context">

## Critérios de aceitação (AC)
> Verificáveis e binários. Cada AC vira ao menos uma verificação no plano/tasks.

- **AC1** — Dado <contexto>, quando <ação>, então <resultado observável>.
- **AC2** — <...>

## Edge cases e modos de falha
- <entrada inválida, vazio, limite, concorrência, dependência fora do ar, etc.>

## Fora de escopo
> O que esta feature **não** faz (evita expansão silenciosa).

- <...>

## Dependências e pressupostos
- <features, serviços, dados, decisões de arquitetura (link p/ `docs/decisions/`) de que isto depende>

## Questões em aberto
- [ ] <ambiguidade ainda não resolvida — não avançar para o plano com `[VERIFICAR]` crítico em aberto>
