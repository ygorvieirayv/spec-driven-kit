---
description: Cria a spec de uma feature por conversa guiada (QUÊ e PORQUÊ) e grava em docs/specs/<feature>/spec.md.
argument-hint: "[nome ou descrição da feature]"
---

# /sdk-spec — Spec de uma feature (guiado)

Conduza uma conversa que produz a especificação de **uma** feature, focada no **QUÊ** e no **PORQUÊ** (o COMO
fica no plano). Preencha o `spec-template.md` e grave em `docs/specs/<feature>/spec.md`.

## Motor de conversa (regras inegociáveis)
- Uma ideia por vez; nunca despeje um bloco de perguntas.
- Explicar o porquê antes de perguntar; dar exemplos; oferecer opções.
- Adaptar ao nível: técnico → acelera; "não sei" → simplifica e sugere default.
- Traduzir qualquer termo técnico em 1 frase.
- Confirmar antes de gravar no artefato.
- Continuar até a ambiguidade sumir; nunca avançar no escuro.
- Mostrar progresso de leve.
- Seguir a constituição: não inventar regras de domínio; citar fontes; compliance = humano confirma.
- Rodar comandos mecânicos você mesmo.

Carregue: `.specify/memory/constitution.md`, `.specify/memory/project-context.md` (NFRs e decisões herdam
daqui), `.specify/templates/spec-template.md` e `docs/epics.md` (para situar a feature no escopo).

---

## Pré-checagem de dependências (antes de detalhar)
Antes de gastar tempo nesta feature, confirme que ela **pode** ser construída agora:
- Veja a ordem em `docs/epics.md` ("Ordem de construção") ou rode `/sdk-roadmap`.
- Esta feature depende de algo que **ainda não existe**? (dados, outra feature, uma entrada externa como o
  valor do frete vindo da API da transportadora).
- Se faltam dependências, **avise em linguagem simples** e sugira detalhar primeiro a feature da qual esta
  depende. Não corra para uma feature "lá na frente" (ex.: checkout sem ter produtos, preço e frete).
- Só siga para o roteiro abaixo quando as dependências estiverem prontas (ou o usuário decidir conscientemente
  seguir mesmo assim).

## Greenfield ou brownfield? (decida cedo)
Descubra se esta feature é **algo novo** (greenfield) ou **muda algo que já existe** (brownfield):
- **Greenfield:** especifique normalmente (roteiro abaixo); apague a seção de delta do template.
- **Brownfield:** antes de especificar o novo, **descreva o comportamento atual** (leia o código/specs se
  preciso) e preencha a seção **"Mudança em sistema existente (delta)"** do template — o que é ADICIONADO,
  MODIFICADO, REMOVIDO em relação a hoje. Assim você descreve **só o que muda**, sem reespecificar o sistema
  inteiro (estilo "delta spec"). Marque o **Tipo: brownfield** no topo da spec e atenção ao que **não pode
  quebrar** (vira teste de não-regressão).

## Roteiro

1. **Situe a feature** no produto (qual epic de `docs/epics.md`). Confirme o nome/slug da feature.
2. **Contexto e objetivo:** que problema resolve, para quem, qual o resultado esperado.
3. **Histórias de uso:** "como <usuário>, quero <ação> para <benefício>".
4. **Requisitos funcionais (FR):** o que o sistema faz — numerados.
5. **Requisitos não-funcionais (NFR):** só o que **muda** em relação aos NFRs globais do
   `project-context.md`.
6. **Critérios de aceitação (AC):** verificáveis e binários (Dado/Quando/Então). Cada AC precisa ser
   testável.
7. **Edge cases e modos de falha:** entrada inválida, vazio, limites, concorrência, dependência fora do ar.
8. **Fora de escopo:** o que esta feature **não** faz.
9. **Dependências e pressupostos:** features, serviços, dados, decisões de arquitetura (link p/
   `docs/decisions/`).

**Remova a ambiguidade** fazendo perguntas de esclarecimento — não pare enquanto houver `[VERIFICAR]` crítico
ou AC vago. Se surgir uma decisão de arquitetura nova, sugira `/sdk-decide`.

## Saída
- Grave `docs/specs/<feature>/spec.md` (status: rascunho).
- Resuma os AC e as questões em aberto.
- 🛑 **Peça aprovação** do usuário. Se ainda houver pontos vagos, sugira `/sdk-clarify` antes do plano; caso
  contrário, sugira `/sdk-plan`. Não comece o plano sem o "ok".
