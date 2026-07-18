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

**B. Produto, restrições e stack:**
> 🤖 "Em uma frase, o que o site faz e para quem?"
> 👩 "Recebe encomendas de bolos com data de entrega, pros meus clientes do bairro."
> 🤖 "Essas encomendas já serão reais? E o pagamento precisa ser automático desde o primeiro dia? Isso
> separa o que precisa funcionar de verdade do que pode ficar fora desta primeira entrega."
> 👩 "Os pedidos serão reais. No começo eu confirmo o Pix manualmente; não preciso integrar um provedor."
> 🤖 "Entendido: cadastro e encomenda serão reais; automação do pagamento fica fora do primeiro recorte e
> não será apresentada como pronta. Como o público inicial é local, o volume esperado é baixo e você quer
> operar sem equipe técnica, sugiro um monolito em Next.js + banco gerenciado. É a opção mais simples para
> manter agora, sem reduzir a segurança dos dados dos clientes. Posso montar assim ou comparar outra stack."
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
> complexo. Para o volume local esperado, o orçamento inicial e a ausência de equipe de operação, sugiro
> **tudo numa máquina**, com backup e um caminho de separação se as métricas mostrarem necessidade. **Posso
> construir qualquer um dos dois — qual prefere?**"
> 👩 "O mais simples."
> O agente grava um ADR (ver Passo 2). Repete para banco e fotos; a automação do Pix só será decidida quando
> entrar no escopo de uma feature futura.
> — 🛑 *Checkpoint 3 aprovado.*

**E. Regras de negócio (constituição):**
> 🤖 "Proponho um princípio do seu negócio: *'toda encomenda precisa de no mínimo 2 dias de antecedência'*.
> Faz sentido?"
> 👩 "Faz, são 3 dias na verdade."
> — 🛑 *Checkpoint 4: grava na constituição do projeto.*

**F. Brief + epics:**
> 🤖 "Resumindo, vejo 4 áreas: catálogo de bolos, carrinho/encomenda, pagamento Pix, e painel da Marta.
> Pro **MVP** (mínimo pra ir ao ar), o essencial é catálogo + encomenda + confirmação manual do Pix. O
> painel e a automação do pagamento ficam pra depois?"
> 👩 "Isso."
> — 🛑 *Checkpoint 5: grava `docs/epics.md`.*

> 🤖 "Pronto! Resumo + pendências `[VERIFICAR]`. Quer detalhar a primeira área: **Encomenda de bolo**?"

---

## Passo 2 — O que o bootstrap deixou no disco

`docs/decisions/hospedagem.md` (ADR gerado pelo `/sdk-decide`):

```
# ADR — Hospedagem
- Data: 2026-06-27 · Status: aceita
## Contexto
Confeitaria caseira; orçamento inicial baixo; público local; pouca carga esperada; sem equipe de operação.
## Opções consideradas
- A — Tudo numa máquina (mono-Docker): simples e barato; menor desempenho sob carga.
- B — Separar (app + CDN + banco gerenciado): mais rápido/escalável; mais caro e complexo.
## Decisão
A — tudo numa máquina. Adequado às restrições atuais de tráfego, orçamento e operação.
## Consequências
Se a loja crescer, migrar para o caminho B (fotos em CDN primeiro).
```

`.specify/memory/project-context.md` (trecho): Brasil, Pix, stack, comandos, princípio "3 dias de
antecedência", tabela de decisões apontando para os ADRs e pendências `[VERIFICAR]`.

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
- **Risco:** alto

## Critérios de aceitação (AC)
- **AC1** — Dado um cliente no catálogo, quando escolhe um bolo, tamanho e data de entrega,
        então a encomenda é criada com status "aguardando pagamento".
- **AC2** — A data de entrega só aceita datas com pelo menos 3 dias de antecedência (regra do negócio).
- **AC3** — Sem telefone válido, a encomenda não é criada.
- **AC4** — Outro cliente não acessa a encomenda; telefone/endereço não aparecem nos logs.
## Limites de fidelidade
- **Limites intencionais:** declarados abaixo

| Superfície | Fidelidade neste ciclo | O que é real | O que não é real | Como o limite fica observável |
|------------|-------------------------|--------------|------------------|--------------------------------|
| encomenda | real | catálogo, validações e persistência | — | registro criado no banco |
| pagamento Pix | fora de escopo | status indica o próximo passo manual | cobrança e confirmação automáticas | texto informa que a confirmação é manual |
## Fora de escopo
- Cupons de desconto; entrega agendada por hora.
```
— 🛑 *Marta aprova a spec.* O agente grava `- **Status:** aprovada` no topo da spec e muda a linha da
feature no ledger (`docs/epics.md`) para `em spec` → depois `em plano` etc. **Conversa aprova, arquivo
registra** — assim, se a Marta fechar tudo e voltar amanhã, o `/sdk-next` sabe exatamente onde ela parou.

---

## Passo 4 — `/sdk-plan` + `/sdk-tasks`

O plano consulta `engineering-standards.md` **e a biblioteca de lições por tag**, e declara as provas que a
feature exige. Trecho de `docs/plans/encomenda-de-bolo/plan.md`:

```
## Perfis de prova
| Perfil | Aplicabilidade | Motivo | ACs | Prova e critério objetivo de saída |
|--------|----------------|--------|-----|------------------------------------|
| visual | N/A | nenhum comportamento visual novo neste recorte | — | — |
| logic | aplicável | antecedência, telefone e status são regras | AC1, AC2, AC3 | testes automatizados válidos e inválidos passam |
| journey | aplicável | o pedido atravessa catálogo, formulário e persistência | AC1 | jornada cria a encomenda no estado esperado |
| data-security | aplicável | telefone e endereço são dados pessoais | AC4 | acesso indevido é negado e logs não contêm PII |
| operational | N/A | sem fila, cron ou integração assíncrona | — | — |
| delivery | aplicável | a feature precisa integrar sem quebrar a aplicação | AC1, AC2, AC3, AC4 | lint, testes e build terminam com exit code 0 |

Não há migração de dados nesta feature; por isso uma execução de rollback de schema não se aplica.
```

Depois da aprovação do plano, o `/sdk-tasks` grava a fonte canônica em
`docs/plans/encomenda-de-bolo/tasks.md`:

```
| ID | Descrição | Depende de | AC | Perfis | Arquivo(s) | Verificação reproduzível | Estado |
|----|-----------|------------|----|--------|------------|--------------------------|--------|
| T1 | Validar antecedência mínima de 3 dias | — | AC2 | logic | `src/encomenda.ts` | `npm test -- antecedencia` na raiz via test runner → testes verdes | backlog |
| T2 | Validar telefone | T1 | AC3 | logic | `src/encomenda.ts` | `npm test -- telefone` na raiz via test runner → inválido recusado no servidor | backlog |
| T3 | Criar encomenda "aguardando pagamento" | T1, T2 | AC1 | journey, delivery | `src/encomenda.ts` | `npm test -- encomenda && npm run build` na raiz → registro esperado e build verde | backlog |
| T4 | Proteger dados da encomenda | T3 | AC4 | data-security | `src/auth.ts`, `src/logger.ts` | `npm test -- encomenda-seguranca` → acesso indevido negado e logs sem PII | backlog |
```

> Consulta a `lessons.md` por `#validação` lembrou: **validar no servidor, não só na UI** (lição L-005).
> O plano e as tasks já incorporam isso; não existe uma segunda tabela de tasks inline para divergir.

**Antes de codar, `/sdk-analyze`** confere que cada AC tem task e verificação, que nenhuma task ficou sem AC e
que as dependências estão prontas:

```
Veredito: consistente — pode implementar. (4 AC, 4 tasks e 4 perfis aplicáveis cobertos; sem [VERIFICAR]
crítico.)
```

Ele grava `- **Analyze:** consistente — <data>` no plano — assim o `/sdk-next` não vai pedir a análise de
novo à toa numa próxima sessão.

> 💡 **Voltando depois de uma pausa?** A Marta digita **`/sdk-next`**. Ele lê o ledger e os marcadores e
> responde: *"Você está na **Encomenda de bolo**; o plano está aprovado e a análise deu consistente. Próximo
> passo: **`/sdk-implement`** (a feature trata dados pessoais; autorização e redação de logs começam pelo
> teste que precisa falhar)."* Ela não
> precisou lembrar de nada.

---

## Passo 5 — `/sdk-implement` (TDD na superfície crítica de dados)

```
RED    → escreve teste: "outro cliente não lê a encomenda e o log não expõe telefone" → falha
GREEN  → implementa autorização no servidor e redação de PII → teste passa
REFACTOR → limpa o código, testes continuam verdes
```

> 🤖 (explain-back) "Em linguagem simples: protegi os dados da encomenda e cobri acesso indevido e logs com
> testes. Rodei as verificações e gravei comando, resultado e SHA em
> `docs/plans/encomenda-de-bolo/evidence.md`. A task T4 está `verification-pending`: implementada e
> verificada por mim, mas ainda não confirmada pelo revisor."

---

## Passo 6 — `/sdk-review` (contexto fresco, via subagente `sdk-reviewer`)

Antes do veredito, o revisor lê o recibo de T4 e reroda o menor subconjunto citado que cobre seu AC. O
novo comando, exit code, resultado e SHA entram como outra entrada em `evidence.md`; só esse recibo fresco
permite mover T4 de `verification-pending` para `done`.

> Para manter o walkthrough curto, os demais blocos foram omitidos do texto. No projeto real, **T1–T4**
> precisam cada uma de recibo `implement` e depois recibo `review` satisfatório, em ordem
> topológica, antes de a feature ser concluída.

```
[ALTO]  app/encomenda.ts:42 — telefone validado só no front-end; falta validação no servidor (AC3). (L-005)
[BAIXO] nome de variável pouco claro em encomenda.ts:31
Veredito: bloqueado — achado Alto impede aprovação. Próximo passo: /sdk-implement para corrigir e
reverificar; depois /sdk-review em contexto fresco.
```

**Fecho de ciclo:** o achado ALTO casa com a lição L-005 (input público sem validação no servidor). Como já
existe, o agente **reforça** a lição em vez de duplicar. A task afetada volta para correção; dependentes que
perderam sua prova também são reclassificadas conforme o contrato. A Marta roda `/sdk-implement` para
corrigir e reverificar; só depois roda `/sdk-review` novamente. O novo review repete as provas relevantes de
`logic`, `journey`, `data-security` e `delivery`. Com T1–T4 em `done` e seus recibos presentes, grava
`- **Review:** aprovado — <data>` no plano e muda o ledger para `concluída`.

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
