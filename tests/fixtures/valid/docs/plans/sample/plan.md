# Plano - Sample

- **Spec de referência:** `docs/specs/sample/spec.md`
- **Status:** aprovado
- **Analyze:** consistente — 2026-07-05
- **Review:** —
- **Evidence:** `docs/plans/sample/evidence.md`

---

## Abordagem técnica
Validar marcadores e rastreio AC -> task.

## Alinhamento com os limites de fidelidade
Nao ha simulacao intencional neste fixture.

## Perfis de prova
| Perfil | Aplicabilidade | Motivo | ACs | Prova e critério objetivo de saída |
|--------|----------------|--------|-----|------------------------------------|
| visual | N/A | fixture sem interface | — | — |
| logic | aplicável | valida regras do contrato | AC1, AC3 | ambos os checkers aceitam os estados validos |
| journey | N/A | fixture sem jornada de usuario | — | — |
| data-security | N/A | fixture sem dados, auth ou schema | — | — |
| operational | aplicável | exercita bloqueio externo | AC2 | bloqueio e condicao ficam no recibo |
| delivery | N/A | fixture nao altera build ou deploy | — | — |

## Estratégia de verificação
- Rodar `scripts/sdk-check`.

## Evidência
- Registro acumulado em `docs/plans/sample/evidence.md`.

## Riscos e rollback
- **Risco:** fixture ficar obsoleto -> **Mitigação:** CI executa o check.
