# Roadmap de Evolução — Spec Driven Kit

> **O que é isto:** o plano de evolução do **próprio kit** (não de um projeto que o usa). Nasceu da
> avaliação de uma análise externa (jul/2026) sobre dores comuns de SDD — spec drift, excesso de cerimônia,
> projeto que "se perde" entre sessões. Este arquivo registra o que foi **adotado**, o que foi **adaptado**,
> o que foi **rejeitado** (e por quê), e a ordem de execução. Se você instalou o kit no seu projeto, pode
> apagar este arquivo (ver `INSTALL.md`).

## Tese

O kit não precisa de mais comandos nem mais Markdown — precisa ficar **orientado por estado**: saber onde o
projeto está, qual o risco da mudança em curso e qual o próximo passo, sem o usuário decorar o fluxo.

A boa notícia: o substrato de estado **já existe pela metade** — `spec.md` e `plan.md` têm linha `Status:`,
as tasks têm estados (`backlog → ready → in-progress → done`), e o `epics.md` tem a tabela "Ordem de
construção" com coluna Estado. O que falta é fechar o circuito:

1. os comandos **escreverem de volta** o estado nos checkpoints (hoje o 🛑 aprova em conversa e o arquivo
   continua `rascunho` para sempre);
2. uma porta de entrada que **leia** esse estado e diga o próximo passo (`/sdk-next`);
3. um diagnóstico global com reconciliação aprovada (`/sdk-doctor`).

Regra de ouro do desenho: **conversa aprova, arquivo registra.** O que não estiver gravado num endereço
fixo de estado não é estado.

## O que muda (resumo)

| # | Entrega | Tipo | Fase |
|---|---------|------|------|
| F1 | Estado vivo: comandos gravam aprovação/estágio nos artefatos e no ledger (`epics.md`) | edição de comandos/templates | P0 |
| F2 | Hierarquia de fonte da verdade no `CLAUDE.md` (com exceção brownfield) | edição | P0 |
| F3 | Régua de cerimônia por **risco da mudança** (trivial/baixo/médio/alto) na constituição + spec curta | edição | P0 |
| F4 | `/sdk-next` — porta de entrada: onde estou → próximo passo + porquê | comando novo | P0 |
| F5 | `/sdk-doctor` — diagnóstico global read-only + reconciliação item a item com aprovação | comando novo | P1 |
| F6 | `scripts/sdk-check.sh` / `.ps1` — validação determinística dos artefatos (zero token) | script novo | P1 |
| F7 | README, COMO-USAR, INSTALL e `docs/example/` atualizados para o fluxo com next/doctor | docs | P0/P1 |
| F8 | Instalador seguro · decisões de produto no decision-guide · starter packs · CI do kit · versionamento | produto | P2 |

Total de comandos: 11 → **13**. Nada além disso — as demais ideias viram comportamento dos comandos que já
existem, não comandos novos.

## Onde o estado mora (o desenho que faltava na análise)

"Orientado por estado" só funciona se o estado tiver **endereço fixo e barato de ler** (grep numa linha,
não leitura integral de arquivo):

1. **Ledger de features** — a tabela "Ordem de construção (dependências)" do `docs/epics.md` ganha
   vocabulário fixo na coluna **Estado**: `a fazer · em spec · em plano · em construção · em review ·
   concluída`. Cada comando atualiza a linha da feature ao concluir sua etapa. O `/sdk-roadmap` continua
   dono da tabela; os demais comandos só tocam a linha da própria feature. *(É o mapa global.)*
2. **Status do artefato** — `spec.md` e `plan.md` já têm a linha `Status:`; após o "ok" do usuário no 🛑,
   o comando atualiza para `aprovada`/`aprovado`. O `/sdk-review` grava o veredito no plano
   (`**Review:** aprovado — <data>`). *(É o detalhe local.)*
3. **Estados de task** — já existem; nada muda.
4. **Git** — branch atual e `git status` dizem o que está em curso; o `/sdk-next` usa como **sinal**, nunca
   como verdade da spec.

## Hierarquia de fonte da verdade (F2)

Em conflito entre artefatos, vale a ordem (1 vence 6):

1. `.specify/memory/project-context.md` — fatos e decisões vigentes do projeto
2. `docs/decisions/*.md` — ADRs
3. `docs/specs/<feature>/spec.md`
4. `docs/plans/<feature>/plan.md`
5. `tasks.md` / tabela de tasks do plano
6. `README.md` e documentação explicativa

**Exceção brownfield:** o código existente é a verdade do comportamento **atual**; a spec (delta) é a
verdade da **mudança desejada**. Divergência nunca se resolve em silêncio — aponta-se ao usuário (papel do
`/sdk-doctor`).

## Régua de cerimônia por risco (F3)

A definição de **lógica crítica / alto risco** (hoje dentro do `/sdk-implement`) sobe para a constituição e
vira a definição única que implement, review, next e a régua referenciam. A régua é **por mudança**,
ortogonal ao modo:

| Risco | Exemplos | Fluxo mínimo |
|-------|----------|--------------|
| Trivial | copy, ajuste visual, rename simples | implementar → review leve |
| Baixo | tela simples, CRUD sem dado sensível, comportamento isolado | **spec curta** → implement → review |
| Médio | regra de negócio nova, integração, mudança em fluxo existente | spec → plan → tasks → analyze → implement → review |
| Alto | dinheiro, auth, PII, migração, deleção de dados, integração crítica | ciclo completo + clarify + TDD + doctor antes do merge |

- **Spec curta** = só Contexto/objetivo + AC + Fora de escopo (vira nota no `spec-template.md`).
- O modo (PROTOTYPE × PRODUCTION) continua modulando o rigor **dentro** de cada passo (matriz de rigor
  existente); a régua decide **quais passos** entram.
- Em dúvida entre dois níveis, usa-se o de cima. A barra "Sempre" da engenharia não se negocia em nenhum nível.

## `/sdk-next` (F4)

Porta de entrada diária: "quero continuar". Lê **nesta ordem, e só isto** (economia de token):

1. modo/identidade do `project-context.md` (linhas, não o arquivo inteiro);
2. ledger do `epics.md`;
3. branch atual e `git status`;
4. linhas `Status:`/estados **só da feature ativa**.

Responde: onde o projeto está · a feature ativa e seu estágio · o risco da mudança (régua) · **o próximo
comando recomendado + porquê** · o atalho consciente ("dá para pular X; o custo é Y").

- **Nunca executa o passo sozinho** — recomenda e para (preserva os checkpoints).
- Sem `epics.md` → sugere `/sdk-bootstrap`. Feature revisada → sugere `/sdk-roadmap` (próxima 🟢).
- Não substitui o roadmap: o **roadmap** decide *qual feature*; o **next** decide *qual etapa* da atual.

## `/sdk-doctor` (F5)

Diagnóstico global **read-only**, incremental (só desce de camada se necessário):

- **T0 (grátis):** roda `scripts/sdk-check` (validações determinísticas).
- **T1 (grep nos artefatos):** ledger × disco (spec existe mas Estado diz "a fazer"?) · spec aprovada sem AC
  binário · AC sem task · task sem AC · `[VERIFICAR]` crítico aberto · feature "concluída" sem review gravado.
- **T2 (leitura dirigida):** plano contradiz ADR · brownfield sem delta/regressão preenchidos.
- **T3 (git, sob pedido):** arquivos alterados na branch fora dos declarados no plano.

Saída no formato do review: achados por severidade, `arquivo:linha`, veredito. Depois, **reconciliação item
a item** — para cada achado, opções:

- **A)** corrigir o artefato/código de baixo para obedecer o de cima (default recomendado — segue a
  hierarquia F2);
- **B)** mudar conscientemente o artefato de cima (decisão de produto — pode abrir `/sdk-decide`);
- **C)** registrar como débito/task e seguir.

Aplica **uma** correção por vez, só após aprovação explícita, e reroda a checagem daquele item. Sem
aprovação, não toca em nada. *(Isto absorve o "fix-drift" proposto na análise: não existe correção fora do
doctor, e não existe correção sem aprovação.)*

## `scripts/sdk-check` (F6)

Shell puro (bash + PowerShell), zero token, exit ≠ 0 em falha (serve para CI):

- toda spec/plano tem linha `Status:` com valor do vocabulário;
- AC referenciados nas tasks existem na spec (IDs);
- estados de task e Estado do ledger dentro do vocabulário;
- contagem de `[VERIFICAR]` por arquivo (informativo).

## Fases

### P0 — estado + porta de entrada
1. **F1** — comandos gravam estado (`sdk-spec`, `sdk-plan`, `sdk-tasks`, `sdk-implement`, `sdk-review`,
   `sdk-roadmap` + templates + `epics.md`). Critério de pronto: nenhum 🛑 aprovado sem escrita de
   Status/ledger.
2. **F2** — hierarquia de fonte da verdade no `CLAUDE.md` (~12 linhas).
3. **F3** — régua na constituição + definição única de lógica crítica + nota de spec curta no template.
4. **F4** — `/sdk-next` + README/COMO-USAR apontando-o como entrada ("perdido? rode `/sdk-next`").

### P1 — visibilidade e recuperação
5. **F6** — `sdk-check.sh` / `.ps1`.
6. **F5** — `/sdk-doctor`.
7. **F7** — walkthrough do `docs/example/` com next/doctor; INSTALL ("Verificando a instalação" inclui os
   novos comandos).

### P2 — produto
8. Instalador seguro (`install.sh` / `.ps1`, merge-aware; npx só se houver demanda comprovada).
9. Decisões de **produto** no `decision-guide.md` (papéis/permissões, cobrança/planos, painel admin,
   e-mail transacional — no mesmo molde de tabela de trade-offs).
10. Starter packs (SaaS, e-commerce, app interno).
11. CI do próprio kit rodando `sdk-check` nos templates e no example.
12. `CHANGELOG.md` + versionamento dos templates.

## Rejeitado (e por quê)

- **`/sdk-status` e `/sdk-reconcile` como comandos separados** — redundantes: o next mostra o estado; o
  doctor propõe e aplica a reconciliação. Quatro comandos novos contradiz a própria tese da análise ("a
  direção não é adicionar comandos").
- **`docs/status.md` persistido** — relatório envelhece e vira mentira; o estado se lê dos endereços fixos
  do desenho acima. (O doctor pode gravar um relatório sob pedido, nunca por padrão.)
- **Dividir `lessons.md` por domínio** — o índice de tags + consulta por grep já resolvem; dividir agora é
  estrutura especulativa (YAGNI).
- **"Padronizar PT-BR"** — o kit já é 100% PT-BR; tokens de estado em inglês (`ready`, `done`, PROTOTYPE…)
  são vocabulário fixo, não idioma.
- **"Permitir tasks inline em PROTOTYPE" e "checkpoints verificáveis por task"** — já existem (matriz de
  rigor da constituição; coluna Verificação das tasks + porta "done só com verificação passando").
- **npx como P0** — clone/cópia funciona hoje; empacotar npm antes de ter demanda é custo de manutenção sem
  retorno. Primeiro o script de instalação (P2); npx quando houver tração.
