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

Se estiver atualizando uma feature que já possui `evidence.md`, leia por grep somente os `Registro`: ID e
texto de AC já citados são históricos e não podem ser apagados, renumerados ou ganhar outro significado.
Evolução semântica vira novo AC e nova task (ou uma delta feature), preservando a prova anterior.

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

## Calibre a cerimônia (régua de risco — antes de tudo)
Estime o risco da mudança pela **régua de cerimônia** da `constitution.md` (e pela definição única de
lógica crítica que está lá):
- **Trivial** (copy, ajuste visual, rename): diga que **nem precisa de spec** — implementar + review leve
  resolve. Não crie uma feature formal por hábito. Se surgir comportamento, dado ou integração, reclassifique
  antes de implementar. **Encerre este comando aqui** e encaminhe para `/sdk-implement`; não execute o
  roteiro nem a saída formal abaixo.
- **Baixo** (comportamento isolado, sem dado sensível): ofereça a **spec curta** — só Contexto/objetivo,
  Limites de fidelidade, AC e Fora de escopo (ver nota no template). Mesmo compacta, ela segue para plano
  e tasks compactos: o contrato de evidence exige rastreio antes de implementar.
- **Médio/Alto**: roteiro completo abaixo. Em **alto risco** (lógica crítica), qualquer ambiguidade ou
  `[VERIFICAR]` relevante torna `/sdk-clarify` obrigatório antes do plano; se a própria spec já fechou tudo,
  não crie uma etapa vazia.
Na dúvida entre dois níveis, use o de cima — e diga isso ao usuário.
Quando houver spec, registre no marker exatamente um valor: `baixo | medio | alto`.

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
3. **Limites de fidelidade:** descubra se alguma superfície será `real`, `sandbox`, `simulada` ou ficará
   `fora de escopo`. Registre o que é e não é real e como o limite fica observável. Se não houver limite,
   preserve `- **Limites intencionais:** nenhum`. Sandbox/simulação não reduzem o rigor e não podem ser
   apresentados como operação real.
4. **Histórias de uso:** "como <usuário>, quero <ação> para <benefício>".
5. **Requisitos funcionais (FR):** o que o sistema faz — numerados.
6. **Requisitos não-funcionais (NFR):** só o que **muda** em relação aos NFRs globais do
   `project-context.md`.
7. **Critérios de aceitação (AC):** verificáveis e binários (Dado/Quando/Então). Cada AC precisa ser
   testável. Quando alguém puder confundir uma simulação com comportamento real, a sinalização vira AC.
8. **Edge cases e modos de falha:** entrada inválida, vazio, limites, concorrência, dependência fora do ar.
9. **Fora de escopo:** o que esta feature **não** faz.
10. **Dependências e pressupostos:** features, serviços, dados, decisões de arquitetura (link p/
   `docs/decisions/`).

**Remova a ambiguidade** fazendo perguntas de esclarecimento — não pare enquanto houver `[VERIFICAR]` crítico
ou AC vago. Se surgir uma decisão de arquitetura nova, sugira `/sdk-decide`.

## Saída
- Grave `docs/specs/<feature>/spec.md` (`Status: rascunho`) e atualize a linha da feature no ledger
  (`docs/epics.md`, "Ordem de construção") para `em spec`.
- Resuma os AC e as questões em aberto.
- 🛑 **Peça aprovação** do usuário. Se ainda houver pontos vagos, sugira `/sdk-clarify` antes do plano; caso
  contrário, sugira `/sdk-plan` — inclusive para baixo risco, em versão compacta. Não comece o plano sem o
  "ok".
- **Aprovado? Registre no arquivo** — atualize a linha `Status:` da spec para `aprovada`. Regra do kit:
  **conversa aprova, arquivo registra**; estado que não está gravado não existe para os outros comandos.
- Se uma spec já tinha plano e esta rodada alterou risco, limites de fidelidade, AC ou escopo, volte
  `**Analyze:**` para `pendente` e sinalize quais partes do plano/tasks precisam ser reconciliadas. Não
  preserve uma análise anterior contra um contrato novo.
