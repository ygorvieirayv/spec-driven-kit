# Epics — Escopo do Produto

> **O que é isto:** o mapa do produto em áreas (epics) e o recorte do **MVP**. Gerado/atualizado pelo
> `/sdk-bootstrap` (etapa Brief + epics) e revisado quando o escopo muda. Cada área vira, depois, uma ou
> mais specs em `docs/specs/`.

- **Produto:** _(preenchido no bootstrap)_
- **Atualizado em:** _(data)_

---

## Áreas do produto

| Área | O que entrega | No MVP? | Specs |
|------|---------------|---------|-------|
| _(ex.: Contas e login)_ | _(...)_ | sim/não | `docs/specs/<feature>/` |
| _(ex.: Catálogo)_ | _(...)_ | sim/não | |

## Recorte do MVP
> O conjunto **mínimo** que entrega valor e pode ir ao ar. Tudo que não é essencial fica em "Depois do MVP".

**Essencial (MVP):**
- _(...)_

**Depois do MVP:**
- _(...)_

## Ordem de construção (dependências)
> Gerada/atualizada pelo `/sdk-roadmap`. Cada epic é decomposto em **sub-features** (só os títulos — o detalhe
> vem depois, no `/sdk-spec`, uma por vez). A ordem se baseia no que cada sub-feature **precisa que já exista**.
> Estados: 🟢 pronta para começar · 🟡 fundacional (não depende de nada) · 🔴 bloqueada (falta dependência).
> Atualize ao terminar cada sub-feature (algo novo pode ter desbloqueado).
>
> A coluna **Estado** é o **ledger** do projeto (é o que o `/sdk-next` lê) e usa vocabulário fixo:
> `a fazer · em spec · em plano · em construção · em review · concluída`. Quem a atualiza é o comando de
> cada etapa (`/sdk-spec`, `/sdk-plan`, `/sdk-implement`, `/sdk-review`), sempre na linha da própria feature.

| Ordem | Sub-feature | Epic | Depende de | Estado | Pronta p/ começar? |
|-------|-------------|------|-----------|--------|--------------------|
| 1 | _(ex.: Catálogo de produtos)_ | Produtos | — (fundacional) | a fazer | 🟡/🟢 |
| 2 | _(ex.: Preço e estoque)_ | Produtos | Catálogo | a fazer | 🔴 (falta catálogo) |
| 3 | _(ex.: Checkout)_ | Checkout | Produtos, Preço, Frete | a fazer | 🔴 (faltam 3) |

## Próximo passo
> Qual área detalhar primeiro com `/sdk-spec`. Deve ser a próxima 🟢 da ordem acima. O agente só avança
> quando o usuário escolhe.

- Sugerido: _(área)_ — _(por quê: é fundacional / suas dependências já estão prontas)_
