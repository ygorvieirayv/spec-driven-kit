# Plano — <Nome da Feature>

> **Para o agente:** preenchido pelo `/sdk-plan` por conversa guiada. Foco no **COMO**. Consulte
> `engineering-standards.md`. Quando houver trade-off real, abra `/sdk-decide` e registre um ADR. Grave em
> `docs/plans/<feature>/plan.md`. O usuário aprova antes da implementação.

- **Spec de referência:** `docs/specs/<feature>/spec.md`
- **Status:** rascunho | aprovado
- **Modo:** PROTOTYPE | PRODUCTION
- **Analyze:** pendente _(atualizado pelo `/sdk-analyze`: `consistente | ajustar | bloqueado` — <data>)_
- **Review:** — _(preenchido pelo `/sdk-review`: veredito e data)_

---

## Abordagem técnica
<Como vamos construir, em alto nível. Componentes envolvidos, fluxo de dados, pontos de integração.>

## Decisões (ADRs curtos)
> Uma entrada por decisão técnica relevante. Se for uma das decisões do `decision-guide.md`, link para o ADR
> completo em `docs/decisions/`.

### ADR — <título>
- **Contexto:** <o problema/escolha>
- **Opções:** <A × B (× C)>
- **Escolha:** <...>
- **Consequência:** <trade-off aceito>

## Tasks
> Ordenadas por dependência. Cada task referencia o(s) AC que satisfaz e como será verificada.

| ID | Descrição | Arquivo(s) | AC | Verificação | Estado |
|----|-----------|-----------|----|-------------|--------|
| T1 | <...> | `<path>` | AC1 | <teste/checagem> | backlog |
| T2 | <...> | `<path>` | AC2 | <...> | backlog |

## Estratégia de teste
> Escala com o modo. PROTOTYPE: caminho feliz da lógica de risco. PRODUCTION: TDD na lógica crítica + edge
> cases. Cada AC mapeia para ao menos uma verificação.

- <...>

## Riscos e rollback
- **Risco:** <...> → **Mitigação:** <...>
- **Rollback:** <como reverter com segurança se der errado>
