# Exemplo guiado — um projeto do início ao fim

> **Isto é opcional e ilustrativo.** Não faz parte do funcionamento do kit e não é lido por nenhum comando.
> É só uma leitura para quem quer **ver como um projeto flui** pelos comandos `sdk-*` antes de mexer no seu.
> Tudo aqui é **fictício** (projeto, números, diálogos). Se você já entendeu o fluxo, ignore este arquivo e
> rode `/sdk-bootstrap` no seu projeto.

O projeto-exemplo: **"Dona Bolo"** — um site para uma confeitaria caseira receber encomendas de bolos online.
A dona não é técnica. Vamos do "tenho uma ideia" até a primeira feature implementada e revisada.

---

## Passo 0 — A pessoa só tem uma ideia

> Dona Marta: *"Quero um site pra vender meus bolos por encomenda. Não entendo nada de programação."*

Ela abre o Claude Code na pasta do projeto e digita **`/sdk-bootstrap`**.

---

## Passo 1 — `/sdk-bootstrap` (onboarding guiado)

O agente conduz **uma pergunta por vez**, explicando o porquê. Versão condensada:

**A. Terreno (mecânico):**
> 🤖 "Preparei a estrutura do projeto e o `.gitignore` (com `.env` protegido). Agora me conta sobre o produto."

**B. Produto + stack + modo:**
> 🤖 "Em uma frase, o que o site faz e para quem?"
> 👩 "Recebe encomendas de bolos com data de entrega, pros meus clientes do bairro."
> 🤖 "Isso é um **protótipo** pra validar rápido, ou algo pra **manter a sério** desde já? (No protótipo eu
> priorizo velocidade; no de produção, capricho em testes e segurança.)"
> 👩 "Validar rápido."
> 🤖 "Combinado: modo **PROTOTYPE**. Como você não é da área, sugiro uma stack simples e barata: um site só
> (monolito) em Next.js + um banco gerenciado no plano gratuito. Eu explico cada peça quando chegarmos lá.
> Pode ser, ou prefere indicar alguma tecnologia?"
> 👩 "Pode ser."
> — 🛑 *Checkpoint 1 aprovado.*

**C. Descoberta de domínio** (aqui ele usa o subagente `sdk-domain-researcher`):
> 🤖 "Em que país você opera e onde estão seus clientes? Isso muda regras de dados, imposto e pagamento."
> 👩 "Brasil, clientes do meu bairro."
> 🤖 "Pesquisei o aplicável e marquei o que **um humano precisa confirmar**:
> - Proteção de dados: há lei de proteção de dados pessoais no Brasil `[VERIFICAR]` — fonte: [gov.br].
> - Pagamento: Pix é dominante no mercado-alvo `[VERIFICAR]`.
> - Você vai guardar dados sensíveis? Cartão você mesma processa?"
> 👩 "Só nome, telefone e endereço de entrega. Pagamento queria por Pix."
> — 🛑 *Checkpoint 2: ela confirma os itens `[VERIFICAR]` (compliance é validação humana).*

**D. Decisões de arquitetura** (lógica do `/sdk-decide`, uma de cada vez). Exemplo — hospedagem:
> 🤖 "Sobre onde o site vai morar: dá pra pôr **tudo numa máquina só** — mais simples e barato, eu monto
> tudo junto. A desvantagem é desempenho sob carga. A alternativa é **separar** (site + uma CDN pras fotos
> dos bolos + banco gerenciado) — abre mais rápido e é mais profissional, mas custa um pouco mais e é mais
> complexo. Pra um protótipo eu sugiro **tudo numa máquina**. **Posso construir qualquer um dos dois — qual
> prefere?**"
> 👩 "O mais simples."
> O agente grava um ADR (ver Passo 2). Repete para banco, pagamento (Pix → checkout hospedado), fotos, etc.
> — 🛑 *Checkpoint 3 aprovado.*

**E. Regras de negócio (constituição):**
> 🤖 "Proponho um princípio do seu negócio: *'toda encomenda precisa de no mínimo 2 dias de antecedência'*.
> Faz sentido?"
> 👩 "Faz, são 3 dias na verdade."
> — 🛑 *Checkpoint 4: grava na constituição do projeto.*

**F. Brief + epics:**
> 🤖 "Resumindo, vejo 4 áreas: catálogo de bolos, carrinho/encomenda, pagamento Pix, e painel da Marta.
> Pro **MVP** (mínimo pra ir ao ar), o essencial é catálogo + encomenda + Pix. O painel fica pra depois?"
> 👩 "Isso."
> — 🛑 *Checkpoint 5: grava `docs/epics.md`.*

> 🤖 "Pronto! Resumo + pendências `[VERIFICAR]`. Quer detalhar a primeira área: **Encomenda de bolo**?"

---

## Passo 2 — O que o bootstrap deixou no disco

`docs/decisions/hospedagem.md` (ADR gerado pelo `/sdk-decide`):

```
# ADR — Hospedagem
- Data: 2026-06-27 · Modo: PROTOTYPE · Status: aceita
## Contexto
Confeitaria caseira validando a ideia; orçamento baixo; público local; pouca carga esperada.
## Opções consideradas
- A — Tudo numa máquina (mono-Docker): simples e barato; menor desempenho sob carga.
- B — Separar (app + CDN + banco gerenciado): mais rápido/escalável; mais caro e complexo.
## Decisão
A — tudo numa máquina. Adequado a um protótipo de baixo tráfego.
## Consequências
Se a loja crescer, migrar para o caminho B (fotos em CDN primeiro).
```

`.specify/memory/project-context.md` (trecho): modo PROTOTYPE, Brasil, Pix, princípio "3 dias de
antecedência", tabela de decisões apontando para os ADRs, e pendências `[VERIFICAR]`.

---

## Passo 2.5 — `/sdk-roadmap` (a ordem certa)

Antes de sair detalhando, o agente monta a ordem por dependências em `docs/epics.md`. A coluna **Estado** é
o **ledger** do projeto (é o que o `/sdk-next` lê depois):

```
| Ordem | Sub-feature | Epic | Depende de | Estado | Pronta p/ começar? |
| 1 | Catálogo de bolos | Produtos | — (fundacional) | a fazer | 🟢 sim |
| 2 | Encomenda de bolo | Encomenda | Catálogo, preço | a fazer | 🔴 não (falta catálogo) |
| 3 | Pagamento Pix | Pagamento | Encomenda | a fazer | 🔴 não |
```

> 🤖 "Faz sentido começar pelo **catálogo**: a encomenda precisa saber quais bolos e preços existem. Correr
> pro pagamento agora seria construir no ar. Quer detalhar o **Catálogo** primeiro?"
> 👩 "Ah, verdade. Vamos pelo catálogo."

(Para encurtar o exemplo, seguimos mostrando a feature **Encomenda de bolo** — já com o catálogo pronto.)

---

## Passo 3 — `/sdk-spec` (a feature "Encomenda de bolo")

Conversa de esclarecimento até não sobrar ambiguidade. Trecho do resultado em
`docs/specs/encomenda-de-bolo/spec.md`:

```
## Critérios de aceitação (AC)
- AC1 — Dado um cliente no catálogo, quando escolhe um bolo, tamanho e data de entrega,
        então a encomenda é criada com status "aguardando pagamento".
- AC2 — A data de entrega só aceita datas com pelo menos 3 dias de antecedência (regra do negócio).
- AC3 — Sem telefone válido, a encomenda não é criada.
## Fora de escopo
- Cupons de desconto; entrega agendada por hora.
```
— 🛑 *Marta aprova a spec.* O agente grava `- **Status:** aprovada` no topo da spec e muda a linha da
feature no ledger (`docs/epics.md`) para `em spec` → depois `em plano` etc. **Conversa aprova, arquivo
registra** — assim, se a Marta fechar tudo e voltar amanhã, o `/sdk-next` sabe exatamente onde ela parou.

---

## Passo 4 — `/sdk-plan` + `/sdk-tasks`

O plano consulta `engineering-standards.md` **e a biblioteca de lições por tag**. Trecho de
`docs/plans/encomenda-de-bolo/plan.md`:

```
## Tasks
| ID | Descrição | AC | Verificação | Estado |
|----|-----------|----|-------------|--------|
| T1 | Validar antecedência mínima de 3 dias | AC2 | teste unitário | backlog |
| T2 | Validar telefone | AC3 | teste unitário | backlog |
| T3 | Criar encomenda "aguardando pagamento" | AC1 | teste de integração | backlog |
```

> Consulta a `lessons.md` por `#validação` lembrou: **validar no servidor, não só na UI** (lição L-005).
> O plano já incorpora isso.

**Antes de codar, `/sdk-analyze`** confere que cada AC tem task e verificação, que nenhuma task ficou sem AC e
que as dependências estão prontas:

```
Veredito: consistente — pode implementar. (3 AC, 3 tasks, todas com verificação; sem [VERIFICAR] crítico.)
```

Ele grava `- **Analyze:** consistente — <data>` no plano — assim o `/sdk-next` não vai pedir a análise de
novo à toa numa próxima sessão.

> 💡 **Voltando depois de uma pausa?** A Marta digita **`/sdk-next`**. Ele lê o ledger e os marcadores e
> responde: *"Você está na **Encomenda de bolo**; o plano está aprovado e a análise deu consistente. Próximo
> passo: **`/sdk-implement`** (a regra dos 3 dias é lógica crítica, então vai com teste primeiro)."* Ela não
> precisou lembrar de nada.

---

## Passo 5 — `/sdk-implement` (TDD, porque a regra dos 3 dias é crítica)

```
RED    → escreve teste: "encomenda com 2 dias de antecedência é rejeitada" → falha (função não existe)
GREEN  → implementa a validação mínima → teste passa
REFACTOR → limpa o código, testes continuam verdes
```

> 🤖 (explain-back) "Em linguagem simples: criei a regra que recusa datas com menos de 3 dias e cobri com um
> teste que comprova. Rodei os testes: **3 passaram**. A task T1 está `done`."

---

## Passo 6 — `/sdk-review` (contexto fresco, via subagente `sdk-reviewer`)

```
[ALTO]  app/encomenda.ts:42 — telefone validado só no front-end; falta validação no servidor (AC3). (L-005)
[BAIXO] nome de variável pouco claro em encomenda.ts:31
Veredito: aprovado com ressalvas — corrigir o ALTO antes do merge.
```

**Fecho de ciclo:** o achado ALTO casa com a lição L-005 (input público sem validação no servidor). Como já
existe, o agente **reforça** a lição em vez de duplicar — e segue. Corrigido o ALTO, o `/sdk-review` grava
`- **Review:** aprovado — <data>` no plano e muda o ledger da feature para `concluída`.

---

## Passo 6.5 — `/sdk-doctor` (quando algo "não bate")

Semanas depois, a Marta mexeu num arquivo à mão e não lembra se ficou tudo coerente. Ela roda
**`/sdk-doctor`**. Ele começa pelo `scripts/sdk-check` (grátis, valida o contrato dos marcadores) e, como
esse passa limpo, sobe para a camada T1, que **cruza** ledger × artefatos — tudo **sem mudar nada**:

```
T0 sdk-check: limpo (marcadores dentro do contrato).
T1 (ledger × artefatos):
[ALTO] docs/epics.md — "Encomenda de bolo" está "concluída", mas o plano não tem "Review: aprovado".
Veredito: drift pontual. Nada foi alterado.

Reconciliação — como você quer resolver?
A) Corrigir o ledger: a feature não foi de fato revisada e aprovada → volta para "em review". (Recomendado)
B) Se ela foi revisada fora do kit, gravar o veredito no plano conscientemente.
C) Registrar como débito e seguir.
```

> 👩 "Ah, eu tinha voltado pra mexer nela. Opção A."

O agente aplica **só** a opção A, mostra o diff, re-roda o `sdk-check` (agora limpo) e para. Nada é
consertado "no escuro" — cada mudança precisa do "ok" dela, um item por vez.

---

## Passo 7 — `/sdk-lesson` (quando aparece um erro novo)

Mais tarde, as fotos dos bolos demoram a carregar e a Marta reclama. Investigando, era falta de limite de
tamanho no upload. Resolvido, ela roda **`/sdk-lesson`**. O subagente `sdk-lesson-curator` **generaliza** (sem
citar "Dona Bolo") e grava:

```
### L-011 · Upload sem limite de tamanho degrada o sistema
- Sintoma: páginas lentas e uso alto de banda/armazenamento após usuários enviarem arquivos.
- Gatilho: aceitar upload sem limitar tamanho/dimensão nem otimizar a imagem.
- Causa raiz: arquivos grandes servidos como vieram.
- Correção: limitar tamanho no servidor; redimensionar/otimizar; (se crescer) servir de CDN.
- Prevenção: todo upload tem limite e otimização definidos antes de ir ao ar.
- Tags: #performance #upload · Aplicabilidade: qualquer projeto que aceite upload de arquivo.
```

Essa lição agora vale para **qualquer projeto futuro** — não só o da Marta. Esse é o ponto da biblioteca.

---

## O que este exemplo mostrou

- O agente **conduz** e a pessoa **aprova** — ninguém preenche formulário.
- Cada decisão veio com **trade-offs** e "posso construir qualquer um".
- Os **artefatos no disco** (ADR, spec, plano, lição) são a fonte da verdade — dá pra `/clear` e voltar.
- O **estado fica gravado nos arquivos** (Status, Analyze, Review, ledger): o `/sdk-next` retoma de onde parou
  e o `/sdk-doctor` recupera o projeto se algo divergir — sem depender do histórico do chat.
- A **biblioteca de lições** transforma um erro pontual em prevenção reutilizável.

Pronto para o seu projeto de verdade? Rode **`/sdk-bootstrap`**.
