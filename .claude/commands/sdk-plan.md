---
description: Cria o plano técnico de uma feature (COMO), avalia os seis perfis de prova e prepara tasks rastreáveis.
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
5. **Alinhe a fidelidade:** confronte a abordagem com `Limites de fidelidade` da spec. Comportamento `real`
   não pode depender só de mock; `sandbox` exercita o ambiente de teste real; `simulada` prova apenas o que
   a spec declarou. Divergência volta para `/sdk-spec` ou `/sdk-clarify`.
6. **Avalie os seis perfis de prova:** preencha todas as linhas da tabela (`visual`, `logic`, `journey`,
   `data-security`, `operational`, `delivery`). Marque `aplicável` ou `N/A`, sempre com motivo. Perfil
   aplicável liga ACs a uma prova com ação/comando, diretório/local, fonte/tool e resultado objetivo. Não
   crie tabela de tasks no plano; `tasks.md` será a única fonte canônica no próximo passo.
7. **Estratégia de verificação:** lógica crítica usa TDD; os demais perfis usam a menor prova segura que
   cobre seus ACs. Garanta que o revisor consiga rerodar tudo sem depender da conversa.
8. **Riscos e rollback:** o que pode dar errado e como reverter. Se `data-security` envolver
   migração/schema, transformação destrutiva/em massa ou operação que exige reversibilidade, o critério
   exige forward e rollback/restore/forward-recovery executados em ambiente seguro — texto não basta.
9. **Critérios de saída e convergência:** congele ACs, perfis e resultados objetivos que encerram a feature.
   Só violação desses critérios, da barra ou da constituição reabre o trabalho; melhoria opcional vai para
   backlog. Declare também a condição objetiva que vira `blocked` em vez de repetição sem progresso.

## Saída
- Grave `docs/plans/<feature>/plan.md` (`Status: rascunho`) e atualize a linha da feature no ledger
  (`docs/epics.md`, "Ordem de construção") para `em plano`. Se o plano **mudou** depois de uma análise,
  volte a linha `**Analyze:**` para `pendente` — análise velha não vale para plano novo. Em plano novo,
  preserve o marker `- **Evidence:**` do template; ele ativa o contrato estrito, mas o arquivo só nasce na
  primeira observação. Ao atualizar uma feature que já tem recibos, preserve IDs e significados históricos;
  mudança semântica vira novo AC/task ou delta feature, nunca reescrita do que já foi provado.
- Em baixo risco, mantenha o plano compacto, mas preserve alinhamento de fidelidade, as seis linhas de
  perfis e critérios de saída. Resuma a abordagem, as decisões e os perfis aplicáveis — as tasks vêm no
  `/sdk-tasks`.
- 🛑 **Peça aprovação.** Aprovado? Atualize a linha `Status:` do plano para `aprovado` (**conversa aprova,
  arquivo registra**). Depois siga: `/sdk-tasks` (refinar a lista) → `/sdk-analyze` (conferir
  consistência) → `/sdk-implement`.
