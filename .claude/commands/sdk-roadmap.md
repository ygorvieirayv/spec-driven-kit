---
description: Descobre a ORDEM certa de construir as features (por dependências) e diz o que já está "pronto para começar". Evita correr para uma parte antes das que ela depende.
argument-hint: "[opcional: foco, ex.: \"o que faço depois do catálogo?\"]"
---

# /sdk-roadmap — Ordem de construção por dependências

Ajude a decidir **em que ordem** construir as features, com base no que cada uma **precisa que já exista**.
O objetivo é evitar o erro clássico: correr para uma parte "lá na frente" (ex.: checkout) sem ter as que ela
depende (produtos, preço, cálculo de frete).

> **Dependência, em 1 frase:** é algo que precisa existir **antes**, senão a feature não tem como funcionar.
> Exemplo: o **checkout** depende de ter **produtos**, uma **fonte de preço** e o **valor do frete** (que pode
> vir de uma API da transportadora). Sem esses três, não dá para começar o checkout.

## Motor de conversa (regras inegociáveis)
- Uma ideia por vez; explicar o porquê; oferecer opções.
- Traduzir qualquer termo técnico em 1 frase.
- Adaptar ao nível; nunca avançar no escuro; confirmar antes de gravar.

Carregue: `docs/epics.md` (áreas e MVP), e o estado das features em `docs/specs/` e `docs/plans/`
(o que já tem spec, plano, ou está implementado).

---

## Roteiro

1. **Liste as features/áreas** do `docs/epics.md` (e as que já têm spec). 
2. **Mapeie as dependências de cada uma.** Para cada feature, descubra o que ela precisa que já exista:
   - dados de que depende (ex.: "precisa dos produtos e dos preços");
   - features das quais é continuação (ex.: "carrinho depende do catálogo");
   - **entradas externas** (ex.: "o frete vem de uma API da transportadora").
   Se não der para inferir do material, **pergunte em linguagem simples** (uma de cada vez).
3. **Classifique cada feature:**
   - 🟢 **Pronta para começar** — todas as dependências já existem/estão prontas.
   - 🟡 **Fundacional** — não depende de nada; é por onde se começa.
   - 🔴 **Bloqueada** — falta alguma dependência (diga **qual**).
4. **Monte a ordem** (do fundacional para o dependente). Detecte e avise se houver **dependência circular**
   (A precisa de B e B precisa de A) — isso precisa ser quebrado antes de seguir.
5. **Recomende a próxima feature** a detalhar, **explicando o porquê** em linguagem simples. Se o usuário
   quiser pular para uma feature 🔴, avise o que falta e qual feature deveria vir antes.

## Saída
- Uma lista ordenada do que construir, com o estado (🟢/🟡/🔴) de cada item.
- A recomendação do **próximo passo** com a justificativa.
- Grave/atualize a seção **"Ordem de construção (dependências)"** em `docs/epics.md`:

```
## Ordem de construção (dependências)
| Ordem | Feature | Depende de | Estado | Pronta p/ começar? |
|-------|---------|-----------|--------|--------------------|
| 1 | Catálogo de produtos | — (fundacional) | a fazer | 🟢 sim |
| 2 | Preço e estoque | Catálogo | a fazer | 🔴 não (falta catálogo) |
| 3 | Cálculo de frete (API transportadora) | Endereço do cliente | a fazer | 🔴 não |
| 4 | Checkout | Produtos, Preço, Frete | a fazer | 🔴 não (faltam 3) |
```

- Sugira: "a próxima pronta é **[X]** — quer detalhar com `/sdk-spec`?"

> Rode este comando **depois do `/sdk-bootstrap`** e sempre que **terminar uma feature**, para saber o que
> ficou desbloqueado.
