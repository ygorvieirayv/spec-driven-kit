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
- Limites de fidelidade por feature registram explicitamente o que é real, simulado/sandbox e fora de escopo,
  sem transformar um pedido de protótipo em redução global de qualidade.
- Perfis de prova independentes e combináveis (`visual`, `logic`, `journey`, `data-security`, `operational`,
  `delivery`) são selecionados no plano e cobrados no review; rollback de `data-security` só conta quando a
  verificação aplicável foi executada.
- `scripts/kit-rules.txt` + `kit-rules.sh` formam o contrato executável interno das dez invariantes
  transversais do motor; testes negativos provam que mutações reais são rejeitadas com o ID correto.
- Matriz compartilhada de grafo cobre DAGs, referências inexistentes, gramática inválida, duplicatas,
  auto-ciclo e ciclos longos em ambos os `sdk-check`.
- `scripts/sdk-ci.sh` valida e executa, sem atalhos fail-open, os seis gates canônicos do produto; o wrapper
  `sdk-ci.ps1` dá a mesma entrada local no Windows sem duplicar a regra.
- `scripts/sdk-secrets.sh` fixa versão e checksum do Gitleaks CLI e varre histórico Git completo e árvore
  atual; a fixture real comprova aprovação limpa, bloqueio por segredo removido e saída redigida.
- Template de workflow do consumidor com checks estáveis `Quality gates` e `Secret scan`, checkout fixado
  por SHA completo e histórico integral para a varredura de segredos.

### Fixed

- `sdk-review`: achados **Crítico** e **Alto** bloqueiam sempre; dívida anotada não pode lavar um bloqueador.
- `sdk-review`: rastreabilidade de QA alinhada ao vocabulário dos demais comandos — mapa **AC → verificação**
  (teste automatizado ou checagem manual legítima), com exceção explícita: AC de lógica crítica exige teste
  automatizado.
- `new-feature.sh`/`.ps1` materializam o slug e criam somente a spec; plano/tasks nascem em suas etapas, sem
  placeholders que fariam `/sdk-next` pular o fluxo. O probe Git do PowerShell também não aborta quando o
  kit instalado ainda não está dentro de um repositório.
- `sdk-check` Bash/PowerShell agora rejeita risco duplicado/inválido, ausência do contrato de fidelidade ou
  dos seis perfis, coluna `Perfis` ausente, markers `Analyze`/`Review` ausentes e tabela `Tasks` inline; a
  extração Bash de AC passou a ler somente a coluna canônica, em paridade com PowerShell.
- `sdk-check` Bash/PowerShell validam `Depende de` em qualquer estado e rejeitam ID/coluna/célula inválida,
  tabela sem task canônica, referência inexistente ou repetida e ciclo determinístico com o caminho observado.
- Fronteira motor × produto reconciliada com o manifesto: `lessons.md` e `project-context.md` são dados do
  projeto; `new-feature.*` e `COMO-USAR.md` fazem parte do motor. Princípios específicos foram movidos da
  constituição atualizável para o `project-context.md`, evitando perda em atualização forçada.
- `engineering-standards.md` deixou de acumular uma seção editável do produto; escolhas específicas ficam
  somente no `project-context.md`.

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
- O rigor deixou de ser um modo global do projeto: a barra de integridade é única, a cerimônia escala pelo
  risco da feature e as decisões técnicas se ancoram nas restrições e objetivos observáveis do produto.
- `tasks.md` passou a ser a fonte canônica das tasks de toda feature formal; o plano não mantém uma tabela
  inline concorrente.
- O CI substituiu regras Python embutidas pelo `kit-rules` canônico e agora verifica todos os caminhos do
  bundle a partir de `kit-manifest.txt`, incluindo ausência de cada item `SKIP`.
- Instalação manual por clone/cópia recursiva deixou de ser documentada como suportada; projetos novos e
  existentes usam o instalador manifest-aware para não carregar fixtures e infraestrutura interna.
- O bootstrap propõe runner, setup e a matriz dos seis gates a partir de evidência do stack, só os
  materializa após o Checkpoint 1 e preserva workflow/gates como dados do produto. O runner compara a
  matriz aprovada com os arquivos executáveis. Review remoto separa o SHA de implementação registrado do
  gate externo do commit final, sem criar ciclo de recibos.

### Planned

- Trilha de portabilidade F12 — export OpenCode e `/sdk-cycle`.
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
