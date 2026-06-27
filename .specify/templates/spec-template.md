# Spec — <Nome da Feature>

> **Para o agente:** preenchido pelo `/sdk-spec` por conversa guiada. Foco no **QUÊ** e no **PORQUÊ**, não
> no COMO (o COMO vai no plano). Remova ambiguidade perguntando antes de gravar. NFRs herdam do
> `project-context.md` — só repita aqui o que muda para esta feature. Grave em
> `docs/specs/<feature>/spec.md`.

- **Status:** rascunho | em revisão | aprovada
- **Modo:** PROTOTYPE | PRODUCTION
- **Autor / data:** <...>

---

## Contexto e objetivo
<Por que esta feature existe. Que problema resolve, para quem. O resultado esperado em 1–3 frases.>

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
