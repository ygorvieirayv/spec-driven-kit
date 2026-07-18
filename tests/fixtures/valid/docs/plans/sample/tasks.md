# Tasks - Sample

- **Plano de referência:** `docs/plans/sample/plan.md`
- **Spec de referência:** `docs/specs/sample/spec.md`
- **Evidence:** `docs/plans/sample/evidence.md`

---

## Tabela de tasks

| ID | Descrição | Depende de | AC | Perfis | Arquivo(s) | Verificação | Estado |
|----|-----------|------------|----|---------|-----------|-------------|--------|
| T1 | Registrar verificacao de implementacao | — | AC1 | logic | `scripts/sdk-check.*` | `scripts/sdk-check` | verification-pending |
| T2 | Registrar bloqueio externo | T1 | AC2 | operational | `docs/plans/sample/evidence.md` | inspecao do recibo | blocked |
| T3 | Confirmar verificacao em review | — | AC3 | logic | `scripts/sdk-check.*` | `scripts/sdk-check` | done |

## Cobertura de AC e perfis
- <nenhum AC descoberto>
- <nenhum perfil aplicável descoberto>
