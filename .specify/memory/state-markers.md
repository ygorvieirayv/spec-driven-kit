# Contrato dos Marcadores de Estado

> **O que é isto:** a definição **normativa e única** de onde o estado do projeto mora, o formato exato de
> cada marcador e quem o escreve. É o contrato que `scripts/sdk-check` valida por regex e que `/sdk-next` e
> `/sdk-doctor` leem. Se um comando e este arquivo divergirem, **este arquivo vence** — corrija o comando.
>
> **Por que linhas markdown, e não TOML/YAML/JSONL:** decisão registrada no `ROADMAP.md` ("Decisão de
> formatos"). Resumo: o consumidor é LLM + grep + regex — linha markdown é tolerante a erro de geração,
> legível por humano, renderiza no GitHub e não cria segunda fonte de estado.

## Regra de ouro

**Conversa aprova, arquivo registra.** Todo checkpoint 🛑 aprovado vira escrita imediata no marcador
correspondente. Estado que não está gravado não existe para os outros comandos.

## Os marcadores

| Marcador | Arquivo | Formato exato da linha | Vocabulário permitido | Quem escreve, quando |
|----------|---------|------------------------|----------------------|----------------------|
| Status da spec | `docs/specs/<feature>/spec.md` | `- **Status:** <valor>` | `rascunho` · `em revisão` · `aprovada` | `/sdk-spec`: `rascunho` ao gravar; `aprovada` após o 🛑 aprovado. `/sdk-clarify` mantém/atualiza. |
| Status do plano | `docs/plans/<feature>/plan.md` | `- **Status:** <valor>` | `rascunho` · `aprovado` | `/sdk-plan`: `rascunho` ao gravar; `aprovado` após o 🛑. |
| Analyze | `docs/plans/<feature>/plan.md` | pendente: `- **Analyze:** pendente` · com veredito: `- **Analyze:** <valor> — <data>` | `pendente` · `consistente` · `ajustar` · `bloqueado` | `/sdk-analyze` grava o veredito (com data). `/sdk-plan` e `/sdk-tasks` **voltam para `pendente`** (sem data) se plano/tasks mudarem depois de uma análise. |
| Review | `docs/plans/<feature>/plan.md` | pendente: `- **Review:** —` · com veredito: `- **Review:** <valor> — <data>` | `—` (pendente) · `aprovado` · `aprovado com ressalvas` · `bloqueado` | `/sdk-review` grava o veredito (com data). |
| Estado da task | tabela de tasks (`tasks.md` ou inline no `plan.md`), linha `\| T<n> \| … \|` (coluna **Estado**, a última) | célula da coluna Estado | `backlog` · `ready` · `in-progress` · `verification-pending` · `done` · `blocked` | `/sdk-tasks` cria/ordena; `/sdk-implement` move até `verification-pending` ou `blocked`; somente `/sdk-review` promove para `done`. |
| Ativação do evidence | `plan.md` ou `tasks.md` | `- **Evidence:** docs/plans/<feature>/evidence.md` (crases opcionais no caminho) | caminho da própria feature | Templates novos gravam o marcador; sua presença ativa o contrato estrito mesmo antes de o arquivo nascer. |
| Recibo de evidência | `docs/plans/<feature>/evidence.md` | `- **Registro:** T1 \| AC1, AC2 \| implement \| pass \| worktree@<SHA>` | fase `implement`/`review`; resultado `pass`/`fail`/`observed`/`not-run`/`unavailable`; ref `commit@<SHA>`/`worktree@<SHA>`/`unavailable` | `/sdk-implement` cria o arquivo na primeira observação e anexa cada rodada; `/sdk-review` anexa cada reexecução independente. Entradas são append-only. |
| Bloqueio de task | `docs/plans/<feature>/evidence.md` | `- **Bloqueio:** T1 \| motivo observado \| condição objetiva para voltar a ready` | task, motivo e condição não vazios | O comando que observa o impedimento registra o marcador na mesma entrada que move a task para `blocked`. O histórico não é apagado após desbloqueio. |
| Reclassificação | `docs/plans/<feature>/evidence.md` | `- **Reclassificacao:** T1 \| done \| ready \| <ISO-8601> \| motivo/referencia` | task, origem `done`, destino `ready`, data/hora e motivo/referência não vazios | `/sdk-review` registra no mesmo bloco `review | not-run` quando uma dependência que falhou invalida uma task já `done`; é append-only. |
| Ledger da feature | `docs/epics.md`, tabela "Ordem de construção", coluna **Estado** | célula da coluna Estado | `a fazer` · `em spec` · `em plano` · `em construção` · `em review` · `concluída` | Cada comando avança, nunca rebaixa, a linha da feature: `/sdk-spec` → `em spec` · `/sdk-plan` → `em plano` · `/sdk-implement` → no mínimo `em construção` (preserva `em review` durante correção) · `/sdk-review` → `em review` e, se aprovado, `concluída`. O `/sdk-roadmap` reordena **sem rebaixar** Estado gravado. |

## Regras transversais

1. **Um marcador, um dono por transição.** Nenhum comando escreve marcador de etapa alheia (exceção: o
   reset de `Analyze` para `pendente` por `/sdk-plan`/`/sdk-tasks`, que é invalidação, não veredito).
   `/sdk-implement` nunca escreve `done`; `/sdk-review` é o único dono dessa promoção.
2. **Análise velha não vale para plano novo.** Mudou plano ou tasks → `Analyze: pendente`.
3. **Estado não anda para trás no ledger** — salvo decisão explícita do usuário (ex.: reabrir uma feature),
   e aí registra-se o porquê na conversa e o novo valor no arquivo.
4. **Molde não é estado.** Linha ainda com o texto do template (ex.: `rascunho | em revisão | aprovada`)
   conta como "não preenchido" — o `sdk-check` aponta como aviso, não como erro.
5. **AC↔task:** todo `AC<n>` citado numa task **deve** existir na spec (`- **AC<n>** — …`) — o `sdk-check`
   trata a violação como **ERRO** (task referenciando AC fantasma quebra o rastreio). Já **AC sem task** é
   **AVISO** no `sdk-check`: a cobertura completa é responsabilidade do gate `/sdk-analyze` (que a bloqueia
   conforme a severidade), não do validador sintático — que só sinaliza para você não esquecer.
   Sob contrato estrito, task em `verification-pending` ou `done` precisa declarar ao menos um AC; recibo
   de outro AC existente não preenche uma linha de task vazia.
6. **Contrato estrito desde o início:** toda tabela de tasks precisa do marcador `- **Evidence:**` apontando
   para a própria feature. Ausência ou caminho divergente é erro. O arquivo nasce somente na primeira
   observação real, mas `verification-pending`, `done` e `blocked` nunca têm exceção sem seus recibos.
7. **Identidade comprovada é imutável:** depois do primeiro `Registro`, não apague nem reutilize o ID da
   task, sua descrição/semântica, dependências, ACs ou verificação; os IDs e textos dos ACs citados também
   ficam históricos. Mudança semântica ganha novo AC e nova task (ou delta feature). Uma task não concluída
   que saiu do escopo permanece na tabela em `backlog`, com o texto original seguido de
   `[DESCONTINUADA: <decisão/referência>]`; uma task `done` permanece histórica em `done`. Nunca altere o
   passado para fazer a prova antiga parecer cobrir um requisito novo.

## Ciclo normativo das tasks

As regras de evidence e dependência desta seção têm enforcement estrito. O marcador `Evidence` é obrigatório
na fonte das tasks; o arquivo só pode faltar enquanto nenhuma observação/estado exigir recibo.

```txt
backlog -> ready -> in-progress -> verification-pending -> done
                         |                    |
                         +------> blocked <---+
                                   |
                                   +------> ready
```

- Para **implementar**, uma task só pode entrar em `verification-pending` se todas as dependências internas
  estiverem em `verification-pending` ou `done`. Para **concluir**, uma task só pode ficar `done` se todas
  as dependências internas também estiverem `done`.
- `/sdk-implement` registra cada rodada. O `Registro implement` mais recente precisa cobrir todos os ACs
  declarados na task, ser `pass`/`observed` e usar ref
  `commit@SHA`/`worktree@SHA`; `unavailable` nunca promove. `fail` corrigível mantém `in-progress`;
  impedimento externo ou disjuntor leva a `blocked`.
- `/sdk-review` processa as tasks em ordem topológica e usa por padrão revisor fresco; sem suporte a
  subagente, aceita inline apenas como exceção justificada que reexecute a mesma prova. Cada rerun vira
  entrada `review`. Detecção mecânica de ciclos fica fora deste PR e permanece prevista para a F11/PR IV.
- `done` exige que o `Registro review` mais recente cubra todos os ACs declarados na task, seja
  `pass`/`observed`, tenha ref `commit@SHA`/`worktree@SHA` e apareça depois do `Registro implement` mais
  recente.
- Falha na revisão move a task para `ready`; a correção passa por `/sdk-implement` e só depois volta a
  `/sdk-review`. Verificação externa indisponível move para `blocked`. Sem recibo de revisão bem-sucedido,
  a task não fica `done`.
- Se uma task falhar ou ficar bloqueada no review, reclassifique **transitivamente** cada dependente em
  `verification-pending` ou `done` para `ready`, em ordem topológica. Para cada dependente, anexe um bloco
  `review | not-run` explicando que a prova não foi executada porque a dependência deixou de estar `done`.
  Se o dependente estava `done`, inclua nesse mesmo bloco o marcador canônico `Reclassificacao`.
- Depois do `Registro implement` mais recente, uma task ainda pode ficar `verification-pending` somente se
  não houver review posterior ou se o review posterior for `not-run`. `pass`/`observed` promove para `done`;
  `fail` volta a `ready`; `unavailable` leva a `blocked`.
- `blocked` exige que o `Registro` cronologicamente mais recente da task (de `implement` ou `review`) seja
  `fail`, `not-run` ou `unavailable` e que o marcador `Bloqueio` esteja **no mesmo bloco**. O handoff da
  parada fica nos campos `Saida/referencia` e `Limitacoes` desse bloco; entrada separada serve somente para
  uma pausa não bloqueante.
- `blocked` é um desvio, não estado final: satisfeita a condição objetiva registrada, a task volta a `ready`.
- Uma decisão explícita de retirar do escopo uma task ainda não concluída e que já possui `Registro` pode
  estacioná-la em `backlog` com `[DESCONTINUADA: <decisão/referência>]`, preservando ID, texto original e
  recibos. Task sem recibo ainda pode ser removida. Task `done` não é apagada nem rebaixada por descontinuação;
  a remoção do comportamento entregue é trabalho novo rastreado separadamente.
- Sob contrato estrito, se uma task `done` revelar problema, anexe bloco `review | not-run` com o fato
  observado e `Reclassificacao`, mova-a para `ready` e siga `/sdk-implement` → `/sdk-review`. Não use
  `reopened`; `partial` também é inválido.
- `Reclassificacao` não fabrica histórico: antes do bloco precisa existir implement válido seguido de
  review `pass`/`observed` válido, sem `fail`/`unavailable` entre esse implement e o success usado como
  prova. Um negativo posterior ao success pode ser justamente o achado que dispara a reclassificação.
  Sem implement posterior ao marker, o estado atual é `ready`; com nova implementação, o ciclo pode
  avançar normalmente.
- Se já existe review bem-sucedido antes do implement mais recente, esse novo implement só é legítimo
  quando há `review | not-run` + `Reclassificacao` entre os dois. `/sdk-implement` nunca reabre `done`
  diretamente.

## Contrato de evidence

Arquivo por feature: `docs/plans/<feature>/evidence.md`.

Use `.specify/templates/evidence-template.md`. O arquivo nasce na primeira observação feita por
`/sdk-implement`; não o crie vazio durante spec/plano/tasks. O marcador `- **Evidence:**` dos templates é
obrigatório e ativa o contrato antes de o arquivo nascer. Não existe modo legado nem recibo retrospectivo:
sem prova real, a task não avança para um estado que afirme prova.

Se `evidence.md` existir, precisa conter ao menos um bloco canônico preenchido. Arquivo vazio ou apenas com
resumo é drift e falha no `sdk-check`.

Cada entrada tem título com data/hora e contém, no mínimo:

```md
### E1 - 2026-07-17T21:57:18Z - T1 - implement
- **Registro:** T1 | AC1, AC2 | implement | pass | worktree@<SHA>
- **Acao/comando:** <...>
- **Diretorio:** <...>
- **Fonte:** <...>
- **Exit code:** <inteiro | not-applicable | unavailable>
- **Saida/referencia:** <...>
- **Branch:** <...>
- **Limitacoes:** <...>
```

- Entradas são **append-only**; somente o `Resumo atualizável` pode mudar.
- O cabeçalho usa exatamente `### E<n> - <ISO-8601> - T<n> - <implement|review>`. A sequência começa
  em `E1` e avança de um em um, sem duplicata, inversão ou salto. Task e fase precisam coincidir com a
  linha `Registro` do mesmo bloco.
- Cada bloco contém exatamente um `Registro` seguido pelos sete campos ASCII canônicos, todos preenchidos:
  `Acao/comando`, `Diretorio`, `Fonte`, `Exit code`, `Saida/referencia`, `Branch`, `Limitacoes`. Não deixe
  placeholders; não grave `Registro` fora de um bloco canônico.
- A linha `Registro` possui exatamente cinco campos: task, lista de ACs, fase, resultado e ref.
- Para autorizar `verification-pending`/`done`, a lista do recibo precisa conter **todos** os ACs declarados
  na linha da própria task; citar outro AC existente não substitui o AC correto.
- Fase: `implement`, `review`.
- Resultado: `pass`, `fail`, `observed`, `not-run`, `unavailable`.
- Ref: `commit@<7-40 hex>`, `worktree@<7-40 hex>` ou `unavailable`.
- Semântica de `Exit code`: `pass` exige `0`; `fail` exige inteiro diferente de zero; `observed` e
  `not-run` exigem `not-applicable`; `unavailable` exige `unavailable`.
- Resultado `pass`/`observed` com ref `unavailable` não autoriza `verification-pending` nem `done`.
- Nesta versão, a ref guarda apenas proveniência: não classifique `current`/`historical` nem a compare ao
  HEAD para decidir validade.
- Antes da primeira implementação, o repositório precisa ter um commit baseline: `worktree@SHA` referencia
  o HEAD sobre o qual o worktree foi observado. Repositório unborn não inventa SHA e não avança com
  `unavailable`.
- Texto da IA sem ação, fonte, resultado e referência observáveis não é recibo.
- Task `done` exige recibo `review` bem-sucedido cobrindo sua task e seus ACs; recibo `implement` sozinho
  nunca autoriza `done`.
- O marcador `Reclassificacao`, quando necessário, fica dentro do bloco `review | not-run` correspondente e
  usa exatamente cinco campos: task, estado anterior `done`, estado novo `ready`, ISO-8601 e
  motivo/referência. Ele não substitui o `Registro` do bloco nem vale sem a prova anterior de `done`.

## Como validar

`scripts/sdk-check.sh` (ou `.ps1` no Windows) valida forma, unicidade, referências, estados e histórico
estrutural com regex — zero token, usável em CI (exit ≠ 0 quando há **ERRO**; **AVISO** não bloqueia).
Imutabilidade de significado não cabe em regex: `/sdk-spec`, `/sdk-clarify`, `/sdk-plan` e `/sdk-tasks`
preservam as identidades, e `/sdk-review` confronta o diff. O `/sdk-doctor` roda o script como primeira
camada (T0) antes da leitura dirigida.
