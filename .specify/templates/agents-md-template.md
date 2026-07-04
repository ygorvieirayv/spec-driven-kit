# AGENTS.md — adaptador do Spec Driven Kit (template)

> **Para quem é este arquivo:** ferramentas de IA agente que leem `AGENTS.md` por convenção mas **não**
> suportam slash commands customizados (ex.: Codex CLI). Se você usa o **Claude Code**, não precisa disto —
> os comandos já existem como `/sdk-*` em `.claude/commands/`.
>
> **Como usar:** copie este arquivo para `AGENTS.md` na raiz do seu projeto (fora de `.specify/templates/`)
> e preencha os placeholders `<...>` com o que o bootstrap gerou em `.specify/memory/project-context.md`.
> Não duplique de forma solta — se `project-context.md` mudar, atualize aqui também, ou troque o placeholder
> por uma referência ao arquivo.

## Identidade do Projeto
<Nome do produto> é construído com o **Spec Driven Kit**. A forma correta de evoluir o sistema é guiada por
specs: você usa os comandos do kit, responde perguntas, aprova checkpoints, e a IA cria os artefatos
necessários no disco.

Trate specs, planos, tarefas, decisões e lições (`docs/`, `.specify/memory/`) como **fonte da verdade**. A
conversa ajuda a descobrir informação; os arquivos persistidos guardam o conhecimento do projeto.

**Em conflito entre artefatos, vale a ordem** (o de cima vence): `project-context.md` → ADRs
(`docs/decisions/`) → spec da feature → plano → tasks → README. Exceção brownfield: o código existente é a
verdade do comportamento **atual**; a delta spec, a da **mudança desejada** — divergência se aponta ao
usuário, nunca se resolve em silêncio.

**Conversa aprova, arquivo registra:** todo checkpoint aprovado vira escrita de estado — a linha `Status:`
do artefato (spec `aprovada`, plano `aprovado`, linhas `**Analyze:**`/`**Review:**` do plano) e a coluna
**Estado** do ledger em `docs/epics.md` (vocabulário fixo: `a fazer · em spec · em plano · em construção ·
em review · concluída`). Estado que não está gravado não existe. A **régua de cerimônia** da
`constitution.md` diz quais passos do fluxo entram conforme o **risco da mudança** (trivial não precisa do
ciclo inteiro; lógica crítica exige o ciclo completo).

## Fluxo Spec Driven Kit (via flags, não slash commands)
Esta ferramenta não reconhece slash commands customizados como `/sdk-plan`. Por isso, quando o usuário
escrever uma flag textual `--sdk-alguma-coisa` em qualquer prompt, interprete como: **"leia
`.claude/commands/sdk-alguma-coisa.md` e siga o significado daquele comando do Spec Driven Kit."**

Exemplos:
- `--sdk-bootstrap` → carregue e siga `.claude/commands/sdk-bootstrap.md`.
- `--sdk-spec carrinho` → carregue e siga `.claude/commands/sdk-spec.md` para a feature indicada.
- `--sdk-plan docs/specs/carrinho/spec.md` → carregue e siga `.claude/commands/sdk-plan.md` com esse alvo.

Se a flag apontar para um arquivo inexistente em `.claude/commands/`, avise que o comando não foi encontrado
e liste os disponíveis (`ls .claude/commands`). **Sempre leia o arquivo do comando antes de agir** — ele é a
fonte da verdade daquela etapa (entradas, artefatos, checkpoints); não improvise a partir do nome da flag.

Ordem usual:
1. `--sdk-bootstrap` — contexto, stack, domínio e MVP.
2. `--sdk-roadmap` — escolher a próxima feature desbloqueada.
3. `--sdk-spec` — o que a feature deve fazer.
4. `--sdk-clarify` — quando a spec estiver ambígua.
5. `--sdk-plan` — como construir.
6. `--sdk-tasks` — quebrar em tarefas rastreáveis.
7. `--sdk-analyze` — conferir consistência antes de codar.
8. `--sdk-implement` — implementar.
9. `--sdk-review` — revisar bugs, riscos e testes.

Apoio: `--sdk-decide` (escolha com trade-offs) e `--sdk-lesson` (registrar erro resolvido como aprendizado
reutilizável). Perdido ou voltando de pausa: `--sdk-next` — lê o estado gravado (ledger em `docs/epics.md`,
linhas `Status:` dos artefatos, git) e recomenda o próximo passo sem executar nada.

Planeje e implemente **uma feature por vez**. Em mudanças brownfield, registre só o que adiciona, altera ou
remove, e o que **não pode quebrar**.

## Subagentes sem suporte nesta ferramenta
Alguns comandos (`sdk-bootstrap.md`, `sdk-review.md`, `sdk-lesson.md`) sugerem delegar uma etapa a um
subagente do Claude Code (`sdk-domain-researcher`, `sdk-reviewer`, `sdk-lesson-curator`) via uma ferramenta
chamada "Task". **Se esta ferramenta não tiver esse mecanismo, não pule a etapa**: execute-a **você mesmo,
inline**, seguindo o papel descrito no arquivo correspondente em `.claude/agents/<nome>.md` (ele diz o
objetivo, os limites e o que retornar). Avise que foi feito inline, sem o benefício do contexto separado.

## Higiene de Contexto e Memória
Leia só o necessário para a fase atual. Os arquivos em `.specify/memory/` são lidos **sob demanda**, nunca
todos de uma vez:
- `constitution.md` — princípios e critérios gerais (inclui a matriz de rigor PROTOTYPE × PRODUCTION).
- `engineering-standards.md` — padrões técnicos, quando relevantes.
- `decision-guide.md` — decisões com trade-offs (e a tabela de gatilhos).
- `project-context.md` — stack, domínio, decisões tomadas e pendências deste projeto.
- `lessons.md` — **apenas por busca/tag/grep**, nunca carregando o arquivo inteiro sem motivo.

Depois de limpar o contexto ou trocar de fase, recarregue a spec/plano/tasks da feature atual em vez de
depender do histórico da conversa. Se uma informação não estiver em arquivo nem confirmada pelo usuário,
marque `[VERIFICAR]` ou pergunte — nunca invente.

## Princípios de Trabalho
- Pense antes de codar: entenda a spec, o impacto e o critério de sucesso.
- Simplicidade e YAGNI: não crie abstrações, telas ou integrações além do necessário.
- Mudanças cirúrgicas: altere só os arquivos ligados à tarefa.
- Não invente regra de negócio, obrigação legal, fluxo de pagamento ou comportamento de entrega — descubra,
  cite a fonte quando houver, ou marque `[VERIFICAR]`. Compliance é sempre confirmado por um humano.
- Disjuntor anti-loop: se a mesma coisa falhar 2–3 vezes sem progresso, pare, resuma o que tentou e devolva
  opções ao usuário.
- Ao terminar, explique em linguagem simples o que mudou, por que mudou e qual verificação comprova.

## <Estrutura do código deste projeto>
> Preencha após o bootstrap, a partir do `project-context.md` — mantenha sincronizado; se divergir, o
> `project-context.md` vence.

<estrutura de pastas do seu projeto>

## <Comandos do projeto>
> Preencha após o bootstrap. Trate o `package.json` (ou equivalente) como autoridade — se esta lista citar
> um script que não existe mais, não assuma que existe.

<comandos de instalar / rodar / testar / build / lint>

## Segurança
Segredos vivem em variáveis de ambiente / `.env` (nunca no código ou no git). Revise com cuidado qualquer
mudança em autenticação, autorização, permissões, pagamento e dados pessoais — use a checklist do
`sdk-review.md` (carregue-o quando for revisar) mesmo fora do fluxo formal do kit.
