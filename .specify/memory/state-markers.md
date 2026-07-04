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
| Analyze | `docs/plans/<feature>/plan.md` | `- **Analyze:** <valor> — <data>` | `pendente` · `consistente` · `ajustar` · `bloqueado` | `/sdk-analyze` grava o veredito. `/sdk-plan` e `/sdk-tasks` **voltam para `pendente`** se plano/tasks mudarem depois de uma análise. |
| Review | `docs/plans/<feature>/plan.md` | `- **Review:** <valor> — <data>` | `—` (pendente) · `aprovado` · `aprovado com ressalvas` · `bloqueado` | `/sdk-review` grava o veredito. |
| Estado da task | tabela de tasks (`tasks.md` ou inline no `plan.md`), linha `\| T<n> \| … \|` (coluna **Estado**, a última) | célula da coluna Estado | `backlog` · `ready` · `in-progress` · `done` | `/sdk-tasks` cria/ordena; `/sdk-implement` move (`done` **só** com a verificação da linha passando). |
| Ledger da feature | `docs/epics.md`, tabela "Ordem de construção", coluna **Estado** | célula da coluna Estado | `a fazer` · `em spec` · `em plano` · `em construção` · `em review` · `concluída` | Cada comando de etapa, na linha da própria feature: `/sdk-spec` → `em spec` · `/sdk-plan` → `em plano` · `/sdk-implement` → `em construção` · `/sdk-review` → `em review` e, se aprovado, `concluída`. O `/sdk-roadmap` reordena **sem rebaixar** Estado gravado. |

## Regras transversais

1. **Um marcador, um dono por transição.** Nenhum comando escreve marcador de etapa alheia (exceção: o
   reset de `Analyze` para `pendente` por `/sdk-plan`/`/sdk-tasks`, que é invalidação, não veredito).
2. **Análise velha não vale para plano novo.** Mudou plano ou tasks → `Analyze: pendente`.
3. **Estado não anda para trás no ledger** — salvo decisão explícita do usuário (ex.: reabrir uma feature),
   e aí registra-se o porquê na conversa e o novo valor no arquivo.
4. **Molde não é estado.** Linha ainda com o texto do template (ex.: `rascunho | em revisão | aprovada`)
   conta como "não preenchido" — o `sdk-check` aponta como aviso, não como erro.
5. **AC↔task:** todo `AC<n>` citado numa task deve existir na spec (`- **AC<n>** — …`); todo AC da spec
   deve ter ao menos uma task quando o plano estiver `aprovado`.

## Como validar

`scripts/sdk-check.sh` (ou `.ps1` no Windows) valida tudo acima com regex — zero token, usável em CI
(exit ≠ 0 quando há **ERRO**; **AVISO** não bloqueia). O `/sdk-doctor` roda o script como primeira camada
(T0) antes de qualquer leitura por LLM.
