---
description: Revisa o diff contra a spec, o plano e os padrões de engenharia. Severidade Crítico/Alto/Médio/Baixo; Crítico bloqueia.
argument-hint: "[nome da feature, opcional]"
---

# /sdk-review — Revisão contra spec + padrões

Revise o trabalho feito contra a **spec**, o **plano** e a **barra de engenharia**. O objetivo é pegar
divergências, regressões e riscos antes de considerar pronto.

## Contexto fresco (recomendado)
A melhor revisão acontece com **contexto limpo** — sem o viés de quem escreveu o código. Sempre que possível,
**delegue ao subagente `sdk-reviewer`** (via Task), passando apenas: a spec, o plano e o diff. Ele revisa de
fora e retorna os achados. Se preferir revisar inline, siga o mesmo roteiro abaixo.

## Insumos
- O **diff** a revisar (`git diff` da branch/feature, ou as mudanças não commitadas).
- A spec: `docs/specs/<feature>/spec.md`.
- O plano: `docs/plans/<feature>/plan.md`.
- A barra: `.specify/memory/engineering-standards.md` e a `constitution.md`.

## O que checar
1. **Spec ↔ código:** cada AC foi atendido? Há comportamento fora do escopo declarado?
2. **Plano ↔ código:** seguiu a abordagem e as decisões (ADRs)? Desvios justificados?
3. **Barra de engenharia:** segredos fora do código/git/bundle, validação de input público, PII fora de
   logs, timeouts, autorização no servidor, testes cobrindo os AC, etc.
4. **Constituição:** mudança cirúrgica? Simples? Verificável? Sem regra de domínio inventada?
5. **Lições conhecidas:** consulte `.specify/memory/lessons.md` por tag relevante (grep) e verifique se o
   diff cai em algum padrão já catalogado (ex.: `#cache`, `#segredos`, `#integração`). Se um erro novo
   aparecer aqui, sugira registrá-lo com `/sdk-lesson` depois de corrigido.

## Severidade
- **Crítico** — segurança, perda de dados, vazamento de segredo/PII, AC essencial quebrado. **Bloqueia.**
- **Alto** — bug provável, desvio relevante da spec/plano.
- **Médio** — qualidade, manutenção, cobertura de teste insuficiente.
- **Baixo** — estilo, melhorias opcionais.

## Saída
- Lista de achados **agrupada por severidade**, cada um com arquivo:linha e sugestão de correção.
- Veredito: **aprovado** / **aprovado com ressalvas** / **bloqueado** (se houver Crítico).
- Não conserte em silêncio durante a revisão — reporte; a correção é um passo à parte.
