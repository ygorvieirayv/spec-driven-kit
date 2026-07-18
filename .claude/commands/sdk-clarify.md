---
description: Passo dedicado de tirar ambiguidade de uma spec — faz perguntas certeiras nos pontos vagos e atualiza a spec. Use entre /sdk-spec e /sdk-plan.
argument-hint: "[nome da feature]"
---

# /sdk-clarify — Tirar a ambiguidade da spec

Pegue uma spec já rascunhada e **elimine os pontos vagos** com perguntas certeiras, antes de planejar. Spec
ambígua vira plano errado vira retrabalho — este passo é a rede de proteção barata.

## Motor de conversa (regras inegociáveis)
- Uma pergunta por vez; explicar o porquê; oferecer opções (não pergunta aberta quando der para listar).
- Adaptar ao nível: técnico → acelera; "não sei" → simplifica e sugere um default seguro.
- Traduzir qualquer termo técnico em 1 frase.
- Confirmar antes de gravar; nunca avançar no escuro.

Carregue: a spec (`docs/specs/<feature>/spec.md`) e o `project-context.md` (para não reperguntar o que já é
global). Se `evidence.md` existir, leia por grep os `Registro`: AC já citado não pode ser apagado, renumerado
ou reinterpretado. Esclarecimento que muda seu significado cria novo AC/task ou delta feature.

---

## Onde procurar ambiguidade (varra a spec por estes pontos)

1. **AC vagos ou não-verificáveis** — "deve ser rápido" (quanto?), "amigável" (como se mede?). Torne binário.
2. **Edge cases não ditos** — vazio, valor máximo/mínimo, duplicado, concorrência, dependência fora do ar.
3. **Regras de negócio implícitas** — números, prazos, limites que ninguém fixou (ex.: "antecedência mínima").
4. **Entradas e saídas** — formato, obrigatoriedade, o que acontece quando falta um campo.
5. **Fronteiras de escopo** — o que parece incluído mas talvez não seja (mande para "Fora de escopo").
6. **Dependências/atores** — de onde vêm os dados, quem dispara a ação, que sistema externo entra.

## Como conduzir
- Faça **no máximo 1–2 perguntas por vez**, começando pelas que mais mudam o plano.
- Para cada resposta, proponha o texto de AC/regra ajustado e **confirme** antes de gravar.
- Pare quando não houver mais ambiguidade que afete o plano. Não invente perguntas para "encher".

## Saída
- Atualize a spec em `docs/specs/<feature>/spec.md` (AC mais nítidos, edge cases, regras explícitas, escopo).
- Liste o que ficou esclarecido e o que (se algo) continua em aberto como `[VERIFICAR]`.
- Sugira o próximo passo: `/sdk-plan` (ou `/sdk-analyze` se já houver plano/tasks).
