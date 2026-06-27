# CLAUDE.md — regras de base do Spec Driven Kit

> Este arquivo é **sempre** carregado pelo Claude Code. Por isso é curto: as bases grandes
> (`constitution`, `engineering-standards`, `decision-guide`, `lessons`) ficam em `.specify/memory/` e são
> lidas **sob demanda** pelos comandos `sdk-*`, não a cada mensagem.

## O que é este projeto
Um toolkit de specs guiado por IA. O fluxo vive em `.claude/commands/sdk-*.md`. Os artefatos (specs, planos,
decisões, lições) são a **fonte da verdade** e ficam no disco — não na memória da conversa.

## Princípios (resumo — detalhe em `.specify/memory/constitution.md`)
1. Pensar antes de codar · 2. Simples/YAGNI · 3. Mudanças cirúrgicas · 4. Critério de sucesso + verificação ·
5. Spec é a verdade · 6. Honestidade epistêmica (não inventar; citar; `[VERIFICAR]`) · 7. Regras de domínio
são descobertas, não assumidas · 8. Aprender com o erro **uma vez** e registrar de forma reutilizável.

## Higiene de contexto (economia de token — leia isto)
- **Artefato no disco = memória.** Entre fases, o usuário pode `/clear`; recarregue só o arquivo da feature
  atual (a spec/plano), não o histórico inteiro do chat.
- **Carregue memória sob demanda.** Cada comando diz o que ler. Não carregue `decision-guide`,
  `engineering-standards` ou `lessons` inteiros se não forem necessários àquele passo.
- **`lessons.md` consulta-se por tag/grep**, nunca carregando o arquivo todo — assim escala sem encarecer.
- **Use subagentes para trabalho pesado/isolado** (`sdk-domain-researcher`, `sdk-reviewer`,
  `sdk-lesson-curator`): o contexto deles não polui a conversa principal; só o resultado volta.
- **Uma feature por vez.** Não abra várias frentes na mesma sessão.

## Disjuntor anti-loop (corta o maior ralo de token)
Se você tentar resolver a **mesma** coisa **2–3 vezes sem progresso**: **pare**. Não insista no escuro.
Resuma o que tentou, o que observou e onde travou, e **devolva ao usuário** com opções. Loop silencioso
queimando token é falha, não esforço.

## Depois de implementar
Explique, em **linguagem simples**, o que mudou e por quê — o usuário não deve aceitar código que não
entende. Mostre a verificação que comprova (teste/checagem que passou).

## Comandos
- **Núcleo:** `/sdk-bootstrap` → `/sdk-roadmap` → `/sdk-spec` → `/sdk-plan` → `/sdk-tasks` →
  `/sdk-analyze` → `/sdk-implement` → `/sdk-review`.
- **Apoio:** `/sdk-decide` (escolha com trade-offs) · `/sdk-clarify` (tirar ambiguidade da spec) ·
  `/sdk-lesson` (registrar lição). Veja o `README.md`.
