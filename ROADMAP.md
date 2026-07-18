# Roadmap de Evolução — Spec Driven Kit

> **O que é isto:** o plano de evolução do **próprio kit** (não de um projeto que o usa). Nasceu da
> avaliação de uma análise externa (jul/2026) sobre dores comuns de SDD — spec drift, excesso de cerimônia,
> projeto que "se perde" entre sessões. Este arquivo registra o que foi **adotado**, o que foi **adaptado**,
> o que foi **rejeitado** (e por quê), e a ordem de execução. Se você instalou o kit no seu projeto, pode
> apagar este arquivo (ver `INSTALL.md`).

## Próximas Melhorias Planejadas

Esta é a visão curta para quem quer entender rapidamente o que ainda está no radar. O detalhe técnico e o
histórico das decisões ficam nas seções seguintes.

### Já entregue

- **Núcleo orientado por estado:** os comandos gravam `Status`, `Analyze`, `Review` e ledger de features.
- **Retomada simples:** `/sdk-next` lê o estado e recomenda o próximo passo.
- **Recuperação de drift:** `/sdk-doctor` diagnostica inconsistências e só reconcilia com aprovação.
- **Validação determinística:** `scripts/sdk-check.sh` e `.ps1` validam marcadores sem depender de LLM.
- **Instalação segura:** `install.sh` e `install.ps1` instalam/atualizam sem sobrescrever artefatos do produto.
- **Versionamento:** `VERSION`, `CHANGELOG.md` e selo `.specify/spec-driven-kit.version` tornam updates auditáveis.
- **CI do kit:** Linux e Windows rodam checks, fixtures e instalação ponta a ponta.

### Próximas prioridades

| Prioridade | Melhoria | Por que importa |
|------------|----------|-----------------|
| P2.1 | Expandir o `decision-guide.md` para decisões de produto | Ajuda usuários menos técnicos a decidir permissões, cobrança, admin, e-mails, analytics, SEO, suporte e políticas de dados sem depender só de intuição. |
| P2.2 | Adicionar exemplos reais por nicho | Entrega confiança sem assumir regras de domínio do usuário; exemplos são read-only e fictícios. |
| P2.3 | Decidir starter packs como sementes de conversa | Só entram se forem hipóteses a validar, não projetos prontos que pulem a descoberta do `/sdk-bootstrap`. |
| P2.4 | Publicar distribuição npm quando fizer sentido | Permite `npm create spec-driven-kit@latest`, mas só vale depois de uso externo suficiente para justificar manutenção. |

### Trilha de rigor e portabilidade (F11–F12) — aprovada em jul/2026

> Nasceu de um documento de melhorias consolidado (duas revisões externas + auditoria do
> `lovable-driven-kit`), triado item a item contra o repo real. Corre em paralelo à trilha de conteúdo
> (F10). Fatias na ordem:

| PR | Conteúdo | Estado |
|----|----------|--------|
| I — Coerência e honestidade | Alto bloqueia no review · verificação vs teste alinhados · reviewer em contexto fresco como **padrão** · fronteira motor×produto (CLAUDE/implement/review/doctor) · handoff ao parar no meio · reconciliação de sidecars documentada + doctor avisa · auto-relato de carga · nota Codex/AGENTS.md | ✅ |
| II — Evidência e estados | `evidence.md` por feature (com referência ao SHA observado) · estados de task novos: `blocked` e `verification-pending` · review reroda o subconjunto de verificação citado antes de confirmar `done` · contrato/sdk-check/fixtures atualizados | ✅ |
| III — Rigor unificado, fidelidade e perfis de prova | Remove o modo global · escala cerimônia pelo risco da feature · registra limites de fidelidade na spec · perfis independentes (`visual` · `logic` · `journey` · `data-security` · `operational` · `delivery`) declarados no plano e cobrados no review · rollback de `data-security` exige verificação **executada** · `tasks.md` vira fonte canônica de toda feature formal | ✅ |
| IV — Integridade do kit | Contrato executável das instruções (`kit-rules` texto+shell, sem JSON/node) com **teste negativo** no CI · detecção de ciclo de dependências no `sdk-check` | planejada |
| V — CI do consumidor | Bootstrap gera workflow fail-closed por stack (check esperado ausente = falha) + varredura de segredos (gitleaks ou equivalente) | planejada |
| VI — Portabilidade | Export dos comandos para OpenCode via **script sob demanda** (fonte única = `.claude/commands/`) · `/sdk-cycle`: encadeia só o mecânico (`tasks → analyze`; roadmap pós-review), **para** em todo 🛑, em implement/review e em qualquer veredito não-limpo | planejada |

**Decisões registradas:** estados novos = só `blocked` + `verification-pending` (rejeitados `partial` —
task parcial é task mal fatiada — e `reopened` — volta a `ready` com registro canônico) · evidência em arquivo próprio
por feature (não seção do plano: evidência acumula) · contrato de regras no idioma do kit (texto + shell) ·
export OpenCode gerado sob demanda, nunca cópia commitada (fonte dupla = fábrica de drift) · `/sdk-cycle`
será o 14º comando — exceção consciente à regra "13 e nada além", por ser orquestrador dos existentes.

**Simplificação registrada no PR III:** não existe mais modo global de rigor. Pedido de protótipo, mock ou
sandbox vira **limite de fidelidade da feature**, nunca licença para reduzir integridade. O fluxo escala pelo
risco; o plano combina os perfis de prova aplicáveis; achados Crítico/Alto bloqueiam sempre. Toda feature que
entra no fluxo formal usa `tasks.md` como fonte canônica — não há tabela inline concorrente no plano.

**Adiado com gatilho:** SCHEMA_VERSION por artefato (gatilho: existir uma base instalada que precise de
migração entre contratos). O PR II pode ser estrito porque o kit ainda não possui consumidores legados; a
primeira necessidade real de migração acionará versionamento de schema. · marcador
"claimed by" para sessões concorrentes (gatilho: uso multi-agente real) · evals com
modelo/e2e — níveis 4–5 da pirâmide (P3; os níveis 1–3 saem do PR IV + fixtures existentes).

### Fora do próximo ciclo

- Transformar tudo em CLI pesada: o kit continua sendo slash commands + markdown + scripts pequenos.
- Criar um índice de estado duplicado em JSONL/TOML: o estado segue em markdown padronizado, validado pelo
  contrato de marcadores.
- Automatizar correção de drift sem aprovação humana: o `/sdk-doctor` permanece conservador por desenho.

## Tese

O kit não precisa de mais comandos nem mais Markdown — precisa ficar **orientado por estado**: saber onde o
projeto está, qual o risco da mudança em curso e qual o próximo passo, sem o usuário decorar o fluxo.

A boa notícia: o substrato de estado nasceu desses marcadores — `spec.md` e `plan.md` têm linha `Status:`,
as tasks usam o ciclo validado em `state-markers.md`, e o `epics.md` tem a tabela "Ordem de construção" com
coluna Estado. A evolução fechou o circuito ao fazer:

1. os comandos **escreverem de volta** o estado nos checkpoints (hoje o 🛑 aprova em conversa e o arquivo
   continua `rascunho` para sempre);
2. uma porta de entrada que **leia** esse estado e diga o próximo passo (`/sdk-next`);
3. um diagnóstico global com reconciliação aprovada (`/sdk-doctor`).

Regra de ouro do desenho: **conversa aprova, arquivo registra.** O que não estiver gravado num endereço
fixo de estado não é estado.

## O que muda (resumo)

| # | Entrega | Tipo | Fase |
|---|---------|------|------|
| F1 | Estado vivo: comandos gravam aprovação/estágio nos artefatos e no ledger (`epics.md`) | edição de comandos/templates | P0 ✅ |
| F2 | Hierarquia de fonte da verdade no `CLAUDE.md` (com exceção brownfield) | edição | P0 ✅ |
| F3 | Régua de cerimônia por **risco da mudança** (trivial/baixo/médio/alto) na constituição + spec curta | edição | P0 ✅ |
| F4 | `/sdk-next` — porta de entrada: onde estou → próximo passo + porquê | comando novo | P0 ✅ |
| F5 | `/sdk-doctor` — diagnóstico global read-only + reconciliação item a item com aprovação | comando novo | P1 ✅ |
| F6 | `scripts/sdk-check.sh` / `.ps1` — validação determinística dos artefatos (zero token) + contrato de marcadores (`state-markers.md`) | script novo | P1 ✅ |
| F7 | README, COMO-USAR, INSTALL e `docs/example/` atualizados para o fluxo com next/doctor | docs | P0/P1 ✅ |
| F8 | Instalador seguro + CI do kit | produto | P2 ✅ |
| F9 | Versionamento do kit | produto | P2 ✅ |
| F10 | Decisões de produto no decision-guide · exemplos por nicho · starter packs como sementes · distribuição npm | produto | P2/P3 |
| F11 | Trilha de rigor: coerência, evidência persistida, estados honestos, fidelidade explícita, perfis de prova, integridade do kit, CI do consumidor (PRs I–V acima) | edições + scripts | PRs I–III ✅ · IV–V planejados |
| F12 | Trilha de portabilidade: export OpenCode + `/sdk-cycle` (PR VI acima) | script + comando novo | planejada |

Total de comandos: 11 → **13**. Única exceção futura aprovada: `/sdk-cycle` (14º, na F12) — orquestrador
dos comandos existentes, não capacidade nova. Fora isso, as demais ideias viram comportamento dos comandos
que já existem, não comandos novos.

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
3. **Estados de task** — o implementador avança até `verification-pending`; somente o review que reroda a
   verificação promove a `done`. `blocked` registra impedimento externo real com condição de desbloqueio.
   Os recibos acumulam em `docs/plans/<feature>/evidence.md` com referência ao SHA observado.
4. **Git** — branch atual e `git status` dizem o que está em curso; o `/sdk-next` usa como **sinal**, nunca
   como verdade da spec.

## Hierarquia de fonte da verdade (F2)

Em conflito entre artefatos, vale a ordem (1 vence 6):

1. `.specify/memory/project-context.md` — fatos e decisões vigentes do projeto
2. `docs/decisions/*.md` — ADRs
3. `docs/specs/<feature>/spec.md`
4. `docs/plans/<feature>/plan.md`
5. `tasks.md`
6. `README.md` e documentação explicativa

**Exceção brownfield:** o código existente é a verdade do comportamento **atual**; a spec (delta) é a
verdade da **mudança desejada**. Divergência nunca se resolve em silêncio — aponta-se ao usuário (papel do
`/sdk-doctor`).

## Régua de cerimônia por risco (F3)

A definição de **lógica crítica / alto risco** (antes duplicada no `/sdk-implement`) sobe para a constituição
e vira a definição única que implement, review, next e a régua referenciam. A régua é **por feature** e
substitui qualquer classificação global de rigor:

| Risco | Exemplos | Fluxo mínimo |
|-------|----------|--------------|
| Trivial | copy, ajuste visual, rename simples | implementar → review leve; sem lifecycle formal |
| Baixo | tela simples, CRUD sem dado sensível, comportamento isolado | **spec curta** → plano/tasks compactos → analyze → implement → review |
| Médio | regra de negócio nova, integração, mudança em fluxo existente | spec → plan → tasks → analyze → implement → review |
| Alto | dinheiro, auth, PII, migração, deleção de dados, integração crítica | ciclo completo + clarify quando houver ambiguidade + TDD |

- **Spec curta** = Contexto/objetivo + Limites de fidelidade + AC + Fora de escopo (vira nota no
  `spec-template.md`).
- A barra de integridade é única; a régua decide **quais passos** entram e os perfis de prova dizem **o que**
  precisa ser demonstrado dentro deles.
- Em dúvida entre dois níveis, usa-se o de cima. A barra "Sempre" da engenharia não se negocia em nenhum nível.

## `/sdk-next` (F4)

Porta de entrada diária: "quero continuar". Lê **nesta ordem, e só isto** (economia de token):

1. identidade/stack do `project-context.md` (linhas, não o arquivo inteiro);
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

### P0 — estado + porta de entrada ✅ *(entregue)*
1. **F1** — comandos gravam estado (`sdk-spec`, `sdk-plan`, `sdk-tasks`, `sdk-implement`, `sdk-review`,
   `sdk-roadmap` + templates + `epics.md`). Critério de pronto: nenhum 🛑 aprovado sem escrita de
   Status/ledger.
2. **F2** — hierarquia de fonte da verdade no `CLAUDE.md` (~12 linhas).
3. **F3** — régua na constituição + definição única de lógica crítica + nota de spec curta no template.
4. **F4** — `/sdk-next` + README/COMO-USAR apontando-o como entrada ("perdido? rode `/sdk-next`").

### P1 — visibilidade e recuperação ✅ *(entregue)*
5. **F6** — `sdk-check.sh` / `.ps1` + o **contrato dos marcadores** em `.specify/memory/state-markers.md`
   (a fonte normativa que o script valida — ver "Decisão de formatos").
6. **F5** — `/sdk-doctor`.
7. **F7** — walkthrough do `docs/example/` com next/doctor; INSTALL ("Verificando a instalação" inclui os
   novos comandos).

### P2 — produto *(em andamento)*
8. **Entregue neste ciclo:** instalador seguro (`install.sh` / `.ps1`) guiado por
   `scripts/kit-manifest.txt`, com dry-run, sidecars `.sdk-new`, backup `.sdk-bak.<data>` em `--force` e
   proteção para nunca sobrescrever artefatos do produto.
9. **Entregue neste ciclo:** CI Linux + Windows validando `sdk-check`, fixtures `valid`/`broken`,
   instalador ponta a ponta, guarda ASCII para PowerShell e cobertura completa do manifest.
10. **Entregue neste ciclo:** versionamento do kit com `VERSION`, `CHANGELOG.md`, validação em CI e selo
    `.specify/spec-driven-kit.version` no projeto instalado.
11. Decisões de **produto** no `decision-guide.md` (papéis/permissões, cobrança/planos, painel admin,
    e-mail transacional — no mesmo molde de tabela de trade-offs).
12. Exemplos reais por nicho (SaaS, e-commerce, app interno, marketplace) como material read-only.
13. Starter packs apenas se forem desenhados como **sementes de conversa**: hipóteses e perguntas a validar,
    não projeto pronto.
14. Distribuição npm (`npm create spec-driven-kit@latest`) quando houver demanda real ou uso externo
    suficiente para justificar a superfície de manutenção.

## Distribuição npm — desenho futuro

O instalador atual foi desenhado para virar o motor de uma distribuição npm sem retrabalho, mas o pacote
não é criado agora para evitar uma segunda superfície de manutenção sem usuários exercitando.

Desenho preferido quando chegar a hora:

1. Publicar um pacote `create-spec-driven-kit` com `bin` pequeno.
2. O comando público fica `npm create spec-driven-kit@latest` (equivalente a `npx create-spec-driven-kit`).
3. O `bin` baixa um release tarball versionado do kit ou empacota os arquivos do release, preservando o
   mesmo contrato do `scripts/kit-manifest.txt`.
4. A lógica de cópia continua sendo a mesma: `ENGINE` atualizável com backup, `SEED` nunca sobrescrito,
   `MERGE` por sidecar, `SKIP` fora do projeto.
5. O CI do pacote precisa rodar os mesmos testes ponta a ponta do instalador antes de publicar.

Gatilho para implementar: usuários externos pedirem instalação sem clone manual, necessidade de versionar
releases instaláveis, ou adoção suficiente para justificar suporte a atualização via registry.

## Decisão de formatos (estado = linhas markdown; sem TOML/JSONL por ora)

> Decisão tomada em jul/2026, após análise comparativa de formatos (Markdown × TOML × YAML × JSON/JSONL ×
> TSV) com medição de tokens, e consenso entre duas revisões independentes.

**Decidido:** o estado do kit vive em **linhas markdown padronizadas** ("front matter de pobre") — os
marcadores de `.specify/memory/state-markers.md` — validadas por regex via `scripts/sdk-check`. Markdown
segue sendo o corpo de tudo que é narrativa e julgamento.

**Por quê:**
- O consumidor dos metadados é **LLM + grep + regex** — todos indiferentes ao formato; linha markdown é a
  opção mais tolerante a erro de geração (bullet não "quebra parse"; TOML com aspa faltando, sim).
- A medição de tokens mostrou **TOML mais caro** que a própria tabela markdown (≈192–197 × 148–165 na
  amostra) e **JSONL também** (≈161–164) — os formatos "estruturados" não pagam nem o próprio custo aqui.
- Um índice gerado (`features.jsonl`) seria uma **segunda cópia do estado** — exatamente a classe de drift
  que o `/sdk-doctor` existe para caçar. O ledger na escala-alvo (dezenas de features) custa ~200 tokens.
- O "schema" que o TOML daria, o **contrato + `sdk-check`** entregam sem migração nenhuma.

**Gatilhos objetivos para reavaliar** (qualquer um): ledger passar de ~100 features · parsing por regex se
provar frágil na prática · surgir uma CLI externa consumindo o estado · os checks ficarem impraticáveis em
regex. Se um dia houver front matter formal, a escolha é **YAML** (`---`), não TOML — é a convenção do
ecossistema (Claude Code, GitHub, geradores de docs).

## Rejeitado (e por quê)

- **`/sdk-status` e `/sdk-reconcile` como comandos separados** — redundantes: o next mostra o estado; o
  doctor propõe e aplica a reconciliação. Quatro comandos novos contradiz a própria tese da análise ("a
  direção não é adicionar comandos").
- **`docs/status.md` persistido** — relatório envelhece e vira mentira; o estado se lê dos endereços fixos
  do desenho acima. (O doctor pode gravar um relatório sob pedido, nunca por padrão.)
- **Dividir `lessons.md` por domínio** — o índice de tags + consulta por grep já resolvem; dividir agora é
  estrutura especulativa (YAGNI).
- **"Padronizar PT-BR"** — o kit já é 100% PT-BR; tokens de estado em inglês (`ready`, `done`…)
  são vocabulário fixo, não idioma.
- **"Permitir duas fontes de tasks"** — rejeitado no PR III: toda feature formal usa `tasks.md`; a coluna
  Verificação e a porta "done só após review com evidência" preservam o rastreio sem tabela inline concorrente.
- **npx como P0** — clone/cópia funciona hoje; empacotar npm antes de ter demanda é custo de manutenção sem
  retorno. Primeiro o script de instalação (P2); npx quando houver tração.
