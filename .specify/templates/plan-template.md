# Plano — <Nome da Feature>

> **Para o agente:** preenchido pelo `/sdk-plan` por conversa guiada. Foco no **COMO**. Consulte
> `engineering-standards.md`. Quando houver trade-off real, abra `/sdk-decide` e registre um ADR. Grave em
> `docs/plans/<feature>/plan.md`. O usuário aprova antes da implementação.

- **Spec de referência:** `docs/specs/<feature>/spec.md`
- **Status:** rascunho | aprovado
- **Modo:** PROTOTYPE | PRODUCTION
- **Analyze:** pendente _(atualizado pelo `/sdk-analyze`: `consistente | ajustar | bloqueado` — <data>)_
- **Review:** — _(preenchido pelo `/sdk-review`: veredito e data)_
- **Evidence:** `docs/plans/<feature>/evidence.md` _(criado na primeira observação de implementação)_

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
> A verificação precisa ser reproduzível: ação/comando exato, diretório, fonte/tool e resultado observável.
> O review usa contexto fresco por padrão; inline é somente fallback justificado, com o mesmo rerun.

| ID | Descrição | Depende de | Arquivo(s) | AC | Verificação reproduzível | Estado |
|----|-----------|------------|-----------|----|--------------------------|--------|
| T1 | <...> | — | `<path>` | AC1 | `<comando>` em `<diretório>` via `<fonte/tool>` → `<resultado observável>` | backlog |
| T2 | <...> | T1 | `<path>` | AC2 | `<ação manual exata>` em `<local>` via `<fonte/tool>` → `<resultado observável>` | backlog |

## Estratégia de teste
> Escala com o modo. PROTOTYPE: caminho feliz da lógica de risco. PRODUCTION: TDD na lógica crítica + edge
> cases. Cada AC mapeia para ao menos uma verificação. A implementação registra cada rodada em
> `evidence.md` e termina em `verification-pending`; somente `/sdk-review` pode promover para `done` após
> reexecutar a verificação. Contexto fresco é o padrão; inline é exceção justificada com o mesmo rerun.

- **Acao/comando:** <comando exato ou passo manual exato>
- **Diretorio:** <diretorio/local exato>
- **Fonte/tool:** <teste, script, preview, log ou ferramenta>
- **Resultado observavel:** <saida, estado ou comportamento objetivo esperado>
- **ACs cobertos:** <AC...>

## Riscos e rollback
- **Risco:** <...> → **Mitigação:** <...>
- **Rollback:** <como reverter com segurança se der errado>
