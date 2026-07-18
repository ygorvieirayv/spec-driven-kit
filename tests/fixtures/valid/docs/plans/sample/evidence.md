# Evidencias - Sample

> Fixture deterministico do contrato de evidencia.

## Entradas

### E1 - 2026-07-17T20:00:00Z - T1 - implement
- **Registro:** T1 | AC1 | implement | pass | worktree@b2b5356
- **Acao/comando:** `scripts/sdk-check`
- **Diretorio:** raiz do fixture
- **Fonte:** terminal
- **Exit code:** 0
- **Saida/referencia:** contrato validado
- **Branch:** fixture
- **Limitacoes:** nenhuma

### E2 - 2026-07-17T20:01:00Z - T2 - implement
- **Registro:** T2 | AC2 | implement | pass | worktree@b2b5356
- **Acao/comando:** preparar integracao externa do fixture
- **Diretorio:** raiz do fixture
- **Fonte:** terminal
- **Exit code:** 0
- **Saida/referencia:** implementacao local verificada
- **Branch:** fixture
- **Limitacoes:** verificacao externa ainda nao executada

### E3 - 2026-07-17T20:02:00Z - T2 - review
- **Registro:** T2 | AC2 | review | unavailable | commit@b2b5356
- **Acao/comando:** consultar servico externo do fixture
- **Diretorio:** raiz do fixture
- **Fonte:** terminal em contexto fresco
- **Exit code:** unavailable
- **Saida/referencia:** credencial do fixture ausente
- **Branch:** fixture
- **Limitacoes:** dependencia externa indisponivel
- **Bloqueio:** T2 | credencial externa ausente | disponibilizar a credencial de teste

### E4 - 2026-07-17T20:03:00Z - T3 - implement
- **Registro:** T3 | AC3 | implement | pass | worktree@b2b5356
- **Acao/comando:** `scripts/sdk-check`
- **Diretorio:** raiz do fixture
- **Fonte:** terminal
- **Exit code:** 0
- **Saida/referencia:** verificacao inicial passou
- **Branch:** fixture
- **Limitacoes:** nenhuma

### E5 - 2026-07-17T20:04:00Z - T3 - review
- **Registro:** T3 | AC3 | review | pass | commit@b2b5356
- **Acao/comando:** `scripts/sdk-check`
- **Diretorio:** raiz do fixture
- **Fonte:** terminal em contexto fresco
- **Exit code:** 0
- **Saida/referencia:** subconjunto relevante rerodado
- **Branch:** fixture
- **Limitacoes:** nenhuma

### E6 - 2026-07-17T20:05:00Z - T1 - review
- **Registro:** T1 | AC1 | review | not-run | unavailable
- **Acao/comando:** iniciar rerun independente de `scripts/sdk-check`
- **Diretorio:** raiz do fixture
- **Fonte:** orquestracao de review
- **Exit code:** not-applicable
- **Saida/referencia:** review ainda nao iniciado
- **Branch:** fixture
- **Limitacoes:** revisor fresco ainda nao executado

## Resumo atual
- **Arquivos alterados:** fixture apenas
- **AC com evidencia:** AC1, AC2, AC3
- **Evidencia faltante:** review conclusivo de T1
- **Falhas conhecidas:** bloqueio intencional de T2
