# Roadmap — Spec Driven Kit

Este arquivo mostra o estado atual do produto e as próximas melhorias que afetam quem usa o kit. O histórico
de implementação, as decisões internas e as alternativas rejeitadas ficam em
[`docs/maintainers/evolution-history.md`](./docs/maintainers/evolution-history.md).

## O que já está disponível

- **Descoberta e planejamento guiados:** bootstrap, roadmap, spec, esclarecimento, plano e tasks conduzidos
  por conversa e com checkpoints de aprovação.
- **Estado persistido:** aprovações, implementação, evidência e review ficam registrados nos artefatos do
  projeto; `/sdk-next` retoma o trabalho a partir desses arquivos.
- **Validação e recuperação:** `sdk-check` detecta inconsistências sem gastar tokens e `/sdk-doctor` propõe
  reconciliações sem alterar nada sem aprovação.
- **Prova proporcional ao risco:** cada feature declara seus limites de fidelidade e os perfis de prova
  necessários; segurança e honestidade da evidência permanecem obrigatórias em qualquer entrega.
- **CI do produto:** o bootstrap gera quality gates e secret scan depois que o usuário aprova os comandos e
  as exceções aplicáveis ao stack.
- **Instalação e atualização seguras:** os instaladores preservam artefatos do produto, geram sidecars para
  conflitos e criam backups antes de substituir arquivos do motor.
- **Claude Code, Codex e OpenCode:** comandos nativos no Claude Code, adaptador `AGENTS.md` para Codex e
  export sob demanda para OpenCode.
- **Automação conservadora:** `/sdk-cycle` encadeia apenas `tasks → analyze` e para antes de implementação,
  review, decisões ou qualquer resultado que exija julgamento humano.

## Próximas prioridades

| Prioridade | Melhoria | Resultado esperado |
|------------|----------|--------------------|
| 1 | Ampliar o guia de decisões de produto | Ajudar a decidir permissões, cobrança, painel administrativo, e-mail, analytics, SEO, suporte e políticas de dados com trade-offs claros. |
| 2 | Adicionar exemplos por tipo de produto | Mostrar como aplicar o fluxo em SaaS, e-commerce, sistemas internos e marketplaces sem transformar exemplos em regras do projeto do usuário. |
| 3 | Validar sementes de conversa | Oferecer pontos de partida opcionais somente quando preservarem a descoberta e a confirmação das hipóteses pelo usuário. |
| 4 | Simplificar a distribuição | Avaliar `npm create spec-driven-kit@latest` quando o uso externo justificar manter mais um canal de instalação e atualização. |
| 5 | Exercitar o kit em projetos reais | Usar o retorno de projetos reais para reduzir atrito, custo de contexto e falsos positivos antes de ampliar o motor. |

## Diretrizes para a evolução

- O kit continua leve: comandos markdown e scripts portáveis, sem introduzir uma CLI pesada sem necessidade
  comprovada.
- O estado permanece nos próprios artefatos; não será criada uma segunda base de estado que possa divergir.
- O `/sdk-doctor` não corrige drift sem aprovação humana.
- Novos comandos só entram quando uma capacidade não cabe com clareza nos comandos existentes.
- Funcionalidades adiadas serão retomadas por demanda observada, não apenas por possibilidade técnica.

## Acompanhar mudanças

Mudanças concluídas ficam em [`CHANGELOG.md`](./CHANGELOG.md). O histórico técnico usado por quem mantém o
kit está em [`docs/maintainers/evolution-history.md`](./docs/maintainers/evolution-history.md).
