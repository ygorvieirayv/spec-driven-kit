# Plano - Sample

- **Spec de referência:** `docs/specs/sample/spec.md`
- **Status:** aprovado
- **Modo:** PROTOTYPE
- **Analyze:** consistente — 2026-07-05
- **Review:** —

---

## Abordagem técnica
Validar marcadores e rastreio AC -> task.

## Tasks
| ID | Descrição | Arquivo(s) | AC | Verificação | Estado |
|----|-----------|-----------|----|-------------|--------|
| T1 | Validar contrato do fixture | `scripts/sdk-check.*` | AC1 | `scripts/sdk-check` | ready |

## Estratégia de teste
- Rodar `scripts/sdk-check`.

## Riscos e rollback
- **Risco:** fixture ficar obsoleto -> **Mitigação:** CI executa o check.
