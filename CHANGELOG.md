# Changelog

Todas as mudanças relevantes do Spec Driven Kit serão registradas neste arquivo.

O formato segue a ideia do [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o versionamento
segue SemVer enquanto o kit amadurece. Versões `0.x` ainda podem mudar contratos internos do kit.

## [Unreleased]

### Added

- `docs/plans/<feature>/evidence.md` como registro acumulativo e auditável de cada verificação, com task,
  AC, comando/fonte, resultado, exit code, referência, limitações e SHA observado, em blocos canônicos
  append-only.
- Estados de task `verification-pending` (implementada e comprovada, aguardando revisão fresca) e `blocked`
  (impedimento externo com motivo e condição de desbloqueio).
- `sdk-check` Bash e PowerShell validam o formato dos recibos, a unicidade de IDs canônicos de task/AC e
  impedem marker ausente/divergente, estado comprovado sem recibo, reabertura/rebaixamento silencioso ou
  recibo citando AC de outra task. Fixtures cobrem caminhos válidos e corrompidos.

### Fixed

- `sdk-review`: achado **Alto** agora bloqueia explicitamente em PRODUCTION (alinhado à matriz de rigor da
  constituição, que já mandava bloquear); em PROTOTYPE segue podendo virar dívida anotada.
- `sdk-review`: rastreabilidade de QA alinhada ao vocabulário dos demais comandos — mapa **AC → verificação**
  (teste automatizado ou checagem manual legítima), com exceção explícita: AC de lógica crítica exige teste
  automatizado.

### Changed

- `sdk-review`: revisão em contexto fresco (subagente `sdk-reviewer`) passou de recomendação a **padrão**;
  revisar inline é exceção justificada e registrada.
- Fronteira **motor × produto** explícita: diff de feature que toca arquivos do kit é drift Crítico
  (regra no `CLAUDE.md`, checagem no `sdk-review` item 6, guarda no `sdk-implement` e no `sdk-doctor` T3).
- `sdk-implement`: ao verificar com sucesso, grava o recibo e encerra a task em `verification-pending`, nunca
  diretamente em `done`; handoff ao parar no meio também fica no `evidence.md`.
- `sdk-review`: reroda o menor subconjunto seguro de verificações citado nos recibos e só promove a task a
  `done` quando a reexecução satisfatória também foi registrada.
- Dependência interna em `verification-pending` já libera implementação dependente; `done` exige todas as
  dependências em `done`. Falha upstream reclassifica transitivamente dependentes
  `verification-pending`/`done` para `ready`
  com recibo `review | not-run` e marker `Reclassificacao` quando necessário.
- O contrato novo é estrito porque o kit ainda não possui base instalada a migrar: não há modo legado nem
  evidência retroativa. IDs e significados de task/AC já comprovados ficam históricos; evolução usa novos
  IDs ou delta feature.
- `sdk-doctor` T1 avisa sobre sidecars `*.sdk-new`/`*.sdk-bak.*` esquecidos; `INSTALL.md` documenta o passo
  de reconciliação pós-atualização.
- Higiene de contexto: cada comando relata em 1 linha o que carregou (auditabilidade da carga sob demanda).
- `INSTALL.md`: adaptador `AGENTS.md` documentado como caminho **recomendado** para Codex CLI (custom
  prompts do Codex foram descontinuados).

### Planned

- Restante da trilha de rigor e portabilidade (F11–F12) — ver ROADMAP: perfis de prova, contrato executável
  das instruções do kit, CI fail-closed do consumidor, export OpenCode e `/sdk-cycle`.
- Expandir o `decision-guide.md` para decisões de produto.
- Adicionar exemplos reais por nicho.
- Avaliar starter packs como sementes de conversa, não como projetos prontos.
- Publicar distribuição npm quando o versionamento estiver amadurecido.

## [0.1.0] - 2026-07-05

### Added

- Núcleo orientado por estado com `Status`, `Analyze`, `Review` e ledger de features.
- `/sdk-next` para retomada guiada por estado.
- `/sdk-doctor` para diagnóstico de drift e reconciliação aprovada.
- `scripts/sdk-check.sh` e `scripts/sdk-check.ps1` para validação determinística.
- `install.sh` e `install.ps1` com instalação segura, dry-run, sidecars e backups para arquivos ENGINE.
- `scripts/kit-manifest.txt` como fonte única de classificação `ENGINE`, `SEED`, `MERGE` e `SKIP`.
- CI Linux e Windows com fixtures válidos/quebrados e testes ponta a ponta do instalador.
- Roadmap público com próximas melhorias planejadas.

### Changed

- O kit passou de um conjunto de artefatos guiados por IA para um harness orientado por estado, verificável
  e instalável com segurança.
