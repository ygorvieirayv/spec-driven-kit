---
description: Revisa o diff contra a spec, o plano e os padrões de engenharia. Severidade Crítico/Alto/Médio/Baixo; Crítico bloqueia sempre, Alto bloqueia em PRODUCTION.
argument-hint: "[nome da feature, opcional]"
---

# /sdk-review — Revisão contra spec + padrões

Revise o trabalho feito contra a **spec**, o **plano** e a **barra de engenharia**. O objetivo é pegar
divergências, regressões e riscos antes de considerar pronto.

## Contexto fresco (padrão, não sugestão)
A melhor revisão acontece com **contexto limpo** — sem o viés de quem escreveu o código (autorrevisão é um
viés documentado). O caminho **padrão** é delegar ao subagente **`sdk-reviewer`** (via Task), passando
apenas: a spec, o plano e o diff. Ele revisa de fora e retorna os achados. Revisar **inline é exceção
justificada** (ex.: ambiente sem suporte a subagentes) — registre o motivo junto do veredito, e siga o
mesmo roteiro abaixo.

## Insumos
- O **diff** a revisar (`git diff` da branch/feature, ou as mudanças não commitadas).
- A spec: `docs/specs/<feature>/spec.md`.
- O plano: `docs/plans/<feature>/plan.md`.
- A barra: `.specify/memory/engineering-standards.md` e a `constitution.md`.

Ao começar, atualize a linha da feature no ledger (`docs/epics.md`, "Ordem de construção") para `em review`.

## O que checar
1. **Spec ↔ código:** cada AC foi atendido? Há comportamento fora do escopo declarado?
2. **Plano ↔ código:** seguiu a abordagem e as decisões (ADRs)? Desvios justificados?
3. **Barra de engenharia — percorra item a item** (não troque pela leitura corrida; o detalhe de cada item
   está em `.specify/memory/engineering-standards.md`). Roda **igual nos dois modos** — o que muda com o
   modo é só o quanto um achado fora da barra "Sempre" bloqueia ou vira dívida anotada (ver matriz de rigor
   da `constitution.md`):
   - [ ] Segredos fora do código/git/bundle/logs (inclui o bundle que vai pro navegador)
   - [ ] Toda entrada pública validada **no servidor** (não só na UI)
   - [ ] PII fora de logs, mensagens de erro e telemetria
   - [ ] AuthN (quem é) e AuthZ (pode fazer isto?) checadas no servidor em toda rota protegida
   - [ ] Timeouts em toda chamada de rede; retry só em operação idempotente
   - [ ] Rate limiting em endpoint público/autenticação, se aplicável
   - [ ] Sem N+1 óbvio; paginação em listagem que pode crescer
   - [ ] Trabalho pesado (mídia, e-mail, IA) fora do caminho do request
   - [ ] Cache, se houver, tem plano de invalidação
   - [ ] Testes cobrindo os AC (ver QA abaixo)

   O que não se aplica, marque **N/A com 1 linha do porquê** — nunca pule em silêncio.
4. **Constituição:** mudança cirúrgica? Simples? Verificável? Sem regra de domínio inventada?
5. **Lições conhecidas:** consulte `.specify/memory/lessons.md` por tag relevante (grep) e verifique se o
   diff cai em algum padrão já catalogado (ex.: `#cache`, `#segredos`, `#integração`). Se um erro novo
   aparecer aqui, sugira registrá-lo com `/sdk-lesson` depois de corrigido.
6. **Fronteira motor × produto:** o diff toca arquivos do **motor do kit** (`.claude/commands/sdk-*`,
   `.claude/agents/sdk-*`, `.specify/memory/` — exceto `project-context.md` —, `.specify/templates/`,
   `scripts/sdk-*`, `scripts/new-feature.*`, `CLAUDE.md`, `COMO-USAR.md`)? Isso **não** é parte da feature:
   reporte como drift **Crítico** e trate a mudança do kit como evolução separada — nunca como efeito
   colateral corrigido em silêncio.

## QA — risco e rastreabilidade de testes
Além de achar bugs, faça uma leitura de QA (no espírito de um "test architect", mas simples):

- **Rastreabilidade:** monte um mapa **AC → verificação**. Todo AC tem ao menos uma verificação que o cobre —
  teste automatizado **ou** checagem manual legítima e registrada? Liste os AC **sem** verificação — são
  buracos (tendem a Médio/Alto). **Exceção sem flexibilidade:** AC de **lógica crítica** (definição única na
  `constitution.md`) exige **teste automatizado**; checagem manual não basta, e AC crítico coberto só por
  checagem manual é achado **Alto**.
- **Avaliação de risco:** aponte as 1–3 áreas com **maior chance de quebrar × maior impacto** (ex.: dinheiro,
  dados do usuário, segurança). Diga onde valeria um teste extra ou um par de olhos humano.
- **Teste que não testa:** desconfie de teste que nunca falha (ver lição `#testes`). Confirme que ele pega a
  regressão que deveria pegar.

Mantenha leve: o objetivo é direcionar atenção para o que é arriscado, não burocratizar.

## Severidade
- **Crítico** — segurança, perda de dados, vazamento de segredo/PII, AC essencial quebrado. **Bloqueia
  sempre, nos dois modos.**
- **Alto** — bug provável, desvio relevante da spec/plano, AC sem nenhuma verificação (ou AC crítico sem
  teste automatizado). **Bloqueia em PRODUCTION** (matriz de rigor da constituição); em PROTOTYPE pode
  virar dívida anotada, nunca ignorada.
- **Médio** — qualidade, manutenção, cobertura de verificação insuficiente.
- **Baixo** — estilo, melhorias opcionais.

## Saída
- Lista de achados **agrupada por severidade**, cada um com arquivo:linha e sugestão de correção.
- Veredito: **aprovado** / **aprovado com ressalvas** / **bloqueado**. Crítico bloqueia sempre; **Alto
  bloqueia em PRODUCTION** — só em PROTOTYPE um Alto pode descer para "aprovado com ressalvas", com a
  dívida anotada.
- **Registre o veredito no plano** (**conversa aprova, arquivo registra**): atualize a linha `**Review:**`
  do cabeçalho de `docs/plans/<feature>/plan.md` com `<veredito> — <data>`. Se **aprovado**, atualize a
  linha da feature no ledger (`docs/epics.md`) para `concluída`; senão, ela continua `em review` até a
  correção passar por nova revisão.
- Não conserte em silêncio durante a revisão — reporte; a correção é um passo à parte.

## Fecho de ciclo (alimentar a biblioteca de lições)
Se algum achado revelou um erro **generalizável** — um padrão que poderia acontecer em qualquer projeto, não
um detalhe pontual deste código —, **proponha registrá-lo com `/sdk-lesson`** assim que for corrigido. É
assim que a biblioteca aprende com o erro **uma vez só**. Não force: se o achado é trivial/específico, siga
em frente. Um bom gatilho: achado **Crítico** ou **Alto** que casa com (ou amplia) uma tag de `lessons.md`.
