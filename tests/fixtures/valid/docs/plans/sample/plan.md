# Plano - Sample

- **Spec de referência:** `docs/specs/sample/spec.md`
- **Status:** aprovado
- **Modo:** PROTOTYPE
- **Analyze:** consistente — 2026-07-05
- **Review:** —
- **Evidence:** `docs/plans/sample/evidence.md`

---

## Abordagem técnica
Validar marcadores e rastreio AC -> task.

## Tasks
| ID | Descrição | Arquivo(s) | AC | Verificação | Estado |
|----|-----------|-----------|----|-------------|--------|
| T1 | Registrar verificacao de implementacao | `scripts/sdk-check.*` | AC1 | `scripts/sdk-check` | verification-pending |
| T2 | Registrar bloqueio externo | `docs/plans/sample/evidence.md` | AC2 | inspecao do recibo | blocked |
| T3 | Confirmar verificacao em review | `scripts/sdk-check.*` | AC3 | `scripts/sdk-check` | done |

## Estratégia de teste
- Rodar `scripts/sdk-check`.

## Evidência
- Registro acumulado em `docs/plans/sample/evidence.md`.

## Riscos e rollback
- **Risco:** fixture ficar obsoleto -> **Mitigação:** CI executa o check.
