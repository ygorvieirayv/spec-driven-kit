# Changelog

Todas as mudanças relevantes do Spec Driven Kit serão registradas neste arquivo.

O formato segue a ideia do [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o versionamento
segue SemVer enquanto o kit amadurece. Versões `0.x` ainda podem mudar contratos internos do kit.

## [Unreleased]

### Planned

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
