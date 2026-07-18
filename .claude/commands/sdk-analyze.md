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
(`docs/plans/<feature>/` — `tasks.md` é a fonte canônica), o `project-context.md`, a seção "Perfis de
prova" de `.specify/memory/engineering-standards.md` e o `docs/epics.md`.

## O que conferir
> As checagens abaixo valem para toda feature formal. O risco registrado na spec define profundidade e
> cerimônia, não abre exceção de integridade.

1. **Risco:** existe exatamente um marker `- **Risco:** <valor>`, preenchido com um item do vocabulário
   `baixo | medio | alto`, e ele condiz com a definição de lógica crítica da constituição? Se
   houver dúvida, use o risco maior.
2. **Limites de fidelidade:** a seção existe e usa o default canônico `nenhum` ou declara cada superfície.
   O plano respeita o que é `real`, `sandbox`, `simulada` ou `fora de escopo`? Prova por mock não sustenta
   alegação real; limite que alguém possa confundir com real precisa de AC observável.
3. **Perfis de prova:** o plano contém exatamente uma linha para cada um dos seis perfis, todos como
   `aplicável` ou `N/A` e com motivo? Todo aplicável liga ACs a prova objetiva; todo N/A tem justificativa.
   Todo perfil aplicável tem ≥1 task, nenhuma task cita N/A e toda task cita ≥1 perfil aplicável?
4. **Cobertura de AC:** todo critério de aceitação (AC) da spec tem ≥1 task **e** ≥1 forma de verificação?
   AC sem task fica fora da entrega.
5. **Tasks válidas:** toda task referencia um AC que **existe** na spec? (Task sem AC = trabalho sem motivo.)
6. **Verificação reproduzível:** cada task/AC/perfil informa ação ou comando **exato**, diretório/local,
   fonte/tool e resultado observável? Passo manual é legítimo, mas precisa ser igualmente exato. Se o
   revisor não conseguir rerodar a prova só com os artefatos, marque **bloqueado** até o plano/tasks ser
   corrigido; narrativa genérica (“testar”, “validar manualmente”) não passa.
7. **Dependências coerentes:** a ordem das tasks respeita as dependências (sem ciclo)? As dependências
   externas/de outras features citadas na spec **existem/estão prontas**? (Se não, aponte e sugira
   `/sdk-roadmap`.)
8. **Decisões alinhadas:** o plano respeita as decisões de arquitetura do `project-context.md`/`docs/decisions`?
   Nada no plano contradiz um ADR?
9. **NFRs herdados:** os requisitos não-funcionais da spec batem com os globais do `project-context.md`
   ou explicam por que mudam? NFR aplicável sem definição suficiente é pendência, não N/A silencioso.
10. **Pendências críticas:** sobrou algum `[VERIFICAR]` que **bloqueia** a implementação (ex.: compliance,
   fonte de dado essencial)?
11. **Escopo e convergência:** há algo no plano/tasks que **não** está na spec (escopo inflado), ou algo da
   spec **fora** do plano (lacuna)? Ideia opcional descoberta na análise vai ao backlog; não amplie
   critérios já aprovados.
12. **Brownfield (se Tipo = brownfield):** a seção de delta (ADICIONADO/MODIFICADO/REMOVIDO) está preenchida?
   O que **não pode quebrar** virou **teste de não-regressão** nas tasks? Há plano de migração/rollback para
   o que muda em dados existentes?

## Severidade
- **Crítico** — vai quebrar ou implementar a coisa errada (AC sem task, ADR contrariado, dependência ausente,
  fidelidade real provada apenas por simulação, falha de segurança/dados, verificação que não pode ser rerodada).
- **Alto** — provável retrabalho ou prova insuficiente (perfil aplicável sem task/prova, escopo divergente,
  NFR ignorado). **Crítico e Alto bloqueiam a implementação.**
- **Médio/Baixo** — ajustes de clareza/rastreio.

## Saída
- Lista de inconsistências **por severidade**, cada uma dizendo **onde** (arquivo/linha ou AC/Task) e **o que
  fazer** (mas sem aplicar).
- Veredito em linguagem simples: **consistente** / **ajustar antes de implementar** / **bloqueado**.
  Qualquer achado Crítico/Alto resulta em **bloqueado**; Médio/Baixo pode resultar em **ajustar**.
- **Registre o veredito no plano** (**conversa aprova, arquivo registra**): atualize a linha `**Analyze:**`
  do cabeçalho de `docs/plans/<feature>/plan.md` com `<consistente | ajustar | bloqueado> — <data>`. É o
  marcador que o `/sdk-next` lê para não recomendar a análise de novo à toa. O comando continua read-only
  quanto ao **conteúdo** dos artefatos — este registro é só metadado de estado.
- Se houver Crítico ou Alto, recomende voltar ao `/sdk-spec`, `/sdk-plan`, `/sdk-tasks` ou `/sdk-roadmap`
  conforme o caso.
