---
description: Cria o plano técnico de uma feature (COMO) por conversa guiada, consultando os padrões de engenharia, e quebra em tasks.
argument-hint: "[nome da feature ou caminho da spec]"
---

# /sdk-plan — Plano técnico (guiado)

Transforme uma spec aprovada em um plano de **COMO** construir. Preencha o `plan-template.md` e grave em
`docs/plans/<feature>/plan.md`.

## Motor de conversa (regras inegociáveis)
- Uma ideia por vez; nunca despeje um bloco de perguntas.
- Explicar o porquê antes de perguntar; dar exemplos; oferecer opções.
- Adaptar ao nível: técnico → acelera; "não sei" → simplifica e sugere default.
- Traduzir qualquer termo técnico em 1 frase.
- Confirmar antes de gravar no artefato.
- Nunca avançar no escuro; mostrar progresso de leve.
- Seguir a constituição e a barra de engenharia.
- Rodar comandos mecânicos você mesmo.

Carregue: a spec da feature (`docs/specs/<feature>/spec.md`), `.specify/memory/engineering-standards.md`,
`.specify/memory/constitution.md`, `.specify/memory/project-context.md` e
`.specify/templates/plan-template.md`.

---

## Roteiro

1. **Releia a spec** e confirme que entende todos os AC. Se algum AC estiver vago, volte para `/sdk-spec`.
2. **Abordagem técnica:** descreva em alto nível como construir — componentes, fluxo de dados, integrações.
3. **Decisões técnicas:** para cada trade-off real, **não decida sozinho** — abra `/sdk-decide`, e registre
   um ADR (curto no plano + completo em `docs/decisions/` quando for decisão de arquitetura). Confira os
   **"Gatilhos"** do `decision-guide.md`: se esta feature dispara um sinal (ex.: upload/serve imagem → CDN;
   tarefa pesada → fila; precisa de SEO → renderização), levante a decisão correspondente com o custo na mesa.
4. **Consulte a barra de engenharia** (`engineering-standards.md`): infra, integração, performance,
   segurança, testes, observabilidade. Verifique o que se aplica a esta feature.
   **E consulte a biblioteca de lições** (`.specify/memory/lessons.md`) por **tag** relevante (grep — não
   carregue o arquivo inteiro): aplique as prevenções já conhecidas ao plano (ex.: tem cache? veja `#cache`).
5. **Quebre em tasks** na tabela do template: ID, descrição, arquivo(s), AC que satisfaz, verificação,
   estado. Ordene por dependência.
6. **Estratégia de teste:** escala com o modo (PROTOTYPE: caminho feliz da lógica de risco; PRODUCTION: TDD
   na lógica crítica + edge cases). Garanta que cada AC mapeia para ao menos uma verificação.
7. **Riscos e rollback:** o que pode dar errado e como reverter.

## Saída
- Grave `docs/plans/<feature>/plan.md` (status: rascunho).
- Resuma a abordagem, as decisões e a lista de tasks.
- 🛑 **Peça aprovação.** Depois siga: `/sdk-tasks` (refinar a lista) → `/sdk-analyze` (conferir
  consistência) → `/sdk-implement`.
