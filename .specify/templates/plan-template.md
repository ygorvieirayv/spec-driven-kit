# Plano — <Nome da Feature>

> **Para o agente:** preenchido pelo `/sdk-plan` por conversa guiada. Foco no **COMO**. Consulte
> `engineering-standards.md`. Quando houver trade-off real, abra `/sdk-decide` e registre um ADR. Grave em
> `docs/plans/<feature>/plan.md`. O usuário aprova antes da implementação.

- **Spec de referência:** `docs/specs/<feature>/spec.md`
- **Status:** rascunho | aprovado
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

## Alinhamento com os limites de fidelidade
<Diga como a abordagem respeita cada limite da spec. Prova de comportamento real não pode depender apenas
de mock; sandbox/simulação precisam ficar dentro do que a spec autorizou.>

## Perfis de prova
> Avalie os **seis** perfis. Não remova linhas. Use `aplicável` ou `N/A`, sempre com motivo. Para perfil
> aplicável, ligue ACs e defina a prova reproduzível com critério objetivo de saída. O `/sdk-tasks` fará o
> vínculo com tasks; `tasks.md` é a única tabela canônica de tasks.

| Perfil | Aplicabilidade | Motivo | ACs | Prova e critério objetivo de saída |
|--------|----------------|--------|-----|------------------------------------|
| visual | <aplicável \| N/A> | <...> | <AC... \| —> | <... \| —> |
| logic | <aplicável \| N/A> | <...> | <AC... \| —> | <... \| —> |
| journey | <aplicável \| N/A> | <...> | <AC... \| —> | <... \| —> |
| data-security | <aplicável \| N/A> | <...> | <AC... \| —> | <... \| —> |
| operational | <aplicável \| N/A> | <...> | <AC... \| —> | <... \| —> |
| delivery | <aplicável \| N/A> | <...> | <AC... \| —> | <... \| —> |

## Estratégia de verificação
> Cada AC e perfil aplicável mapeia para ao menos uma verificação. A implementação registra cada rodada em
> `evidence.md` e termina em `verification-pending`; somente `/sdk-review` promove para `done` após
> reexecutar a prova. Contexto fresco é o padrão; inline é exceção justificada com o mesmo rerun.

- **Acao/comando:** <comando exato ou passo manual exato>
- **Diretorio:** <diretorio/local exato>
- **Fonte/tool:** <teste, script, preview, log ou ferramenta>
- **Resultado observavel:** <saida, estado ou comportamento objetivo esperado>
- **ACs cobertos:** <AC...>

## Critérios de saída e convergência
- **Pronto quando:** <ACs e critérios dos perfis aplicáveis satisfeitos, sem Crítico/Alto>
- **Melhorias que não reabrem este escopo:** <itens opcionais que, se aceitos, virarão sub-features no ledger | nenhuma>
- **Condição de parada:** <dependência/limite objetivo que leva a blocked em vez de tentativas repetidas>

## Riscos e rollback
- **Risco:** <...> → **Mitigação:** <...>
- **Rollback:** <como reverter; para migração/schema ou transformação destrutiva/em massa, como executar rollback/restore/forward-recovery em ambiente seguro>
