# Guia de Decisões — Catálogo de Trade-offs

> **O que é isto:** a base de conhecimento que alimenta o `/sdk-decide`. Para cada decisão de
> arquitetura/infra, o agente explica em linguagem simples o que está em jogo, mostra os caminhos numa
> tabela (**Facilidade · Desempenho · Custo · Escala/Profissional**), recomenda conforme o **modo**
> (PROTOTYPE × PRODUCTION) e o contexto do usuário, e **sempre** termina com:
> _"posso construir qualquer um dos caminhos — qual preferes?"_
>
> **Regras de uso (para o agente):**
> - Nunca despejar jargão. Traduzir cada termo técnico em 1 frase.
> - A recomendação é um ponto de partida, não uma imposição. A escolha é do usuário.
> - Ancorar no que o usuário já disse (orçamento, público, expectativa de escala, prazo).
> - Após a escolha, registrar um ADR curto em `docs/decisions/<decisao>.md`.
> - Custos são ordens de grandeza ilustrativas — confirmar preços atuais antes de prometer números.

---

## Como ler as tabelas

- **Facilidade** = quão rápido/simples é montar e manter.
- **Desempenho** = velocidade e capacidade sob carga.
- **Custo** = quanto pesa no bolso por mês (ordem de grandeza).
- **Escala/Profissional** = quão bem aguenta crescer e quão "produção séria" é.

Legenda: alta / média / baixa. "+$X/mês" indica custo adicional aproximado.

---

## 1. Hospedagem  *(decisão-âncora)*

**Em simples:** onde o seu sistema vai morar. Pode ficar tudo junto numa única máquina, ou cada peça
(site, imagens, tarefas pesadas, banco) num lugar otimizado para ela.

| Caminho | Facilidade | Desempenho | Custo | Escala/Profissional |
|---------|-----------|-----------|-------|---------------------|
| A — Tudo numa VPS (um só Docker) | alta | menor sob carga | menor (1 servidor) | ok para validar |
| B — Separar (app + CDN p/ estáticos + worker p/ tarefas + DB gerenciado) | menor | alto | +$/mês por peça | produção séria, escalável |

**Recomendação:** PROTOTYPE → **A** (monto tudo junto, sobe rápido, barato). PRODUCTION / vai crescer → **B**
(site abre mais rápido, melhor nota de velocidade, mais profissional).
**Sempre oferecer:** _"posso construir qualquer um dos dois — qual preferes?"_

**Fraseado-modelo:**
> "Dá para pôr **tudo numa única VPS num só Docker** — é mais simples, eu monto tudo junto e o custo inicial
> é menor. A desvantagem é desempenho: sob carga, e comparado a separar as peças, fica mais lento. A
> alternativa é **separar** — CDN para as imagens/estáticos e um worker ligado ao sistema para as tarefas
> pesadas. Fica mais complexo e custa um pouco mais por mês, mas o site abre mais rápido e é mais
> escalável. Para um protótipo eu sugeriria o caminho único; para algo que vai crescer, o separado. Posso
> construir qualquer um dos dois — qual preferes?"

---

## 2. Banco de dados

**Em simples:** onde os dados ficam guardados. Pode ser um arquivo/serviço simples junto do app, um serviço
gerenciado por terceiros (eles cuidam de backup e atualização), ou um banco dedicado que você administra.

| Caminho | Facilidade | Desempenho | Custo | Escala/Profissional |
|---------|-----------|-----------|-------|---------------------|
| A — SQLite/Postgres no mesmo container | alta | ok p/ baixo volume | menor | limitado |
| B — DB gerenciado (Supabase / Neon / RDS) | média | alto | +$/mês (free tiers comuns) | escala bem, backup incluso |
| C — Self-hosted dedicado | baixa | alto (você afina) | infra + sua manutenção | escala, mas você é o DBA |

**Recomendação:** PROTOTYPE → **A** (ou **B** no free tier). PRODUCTION → **B** (backup, alta disponibilidade
e atualizações por sua conta). **C** só se houver razão forte (dados que não podem sair do seu controle, custo
em grande escala).
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 3. Autenticação (login)

**Em simples:** como as pessoas entram na conta. Você pode usar um serviço pronto que entrega login, cadastro
e recuperação de senha "de fábrica", ou montar você mesmo (mais controle, menos custo, mais responsabilidade).

| Caminho | Facilidade | Desempenho | Custo | Escala/Profissional |
|---------|-----------|-----------|-------|---------------------|
| A — Solução pronta (ex.: Clerk, Auth0) | alta | alto | grátis até X usuários, depois +$/mês | muito profissional, rápido |
| B — Self-hosted (ex.: Better Auth, Auth.js) | média | alto | só infra | profissional, você mantém |

**Recomendação:** PROTOTYPE → **A** (login pronto em minutos). PRODUCTION → depende: **A** se velocidade de
entrega e telas prontas importam mais; **B** se controle total, custo em escala ou dados de usuário sob seu
domínio pesam mais. **Atenção:** segurança de auth é área de alto risco — não improvisar criptografia de senha;
seguir o padrão do framework escolhido.
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 4. Imagens e arquivos estáticos

**Em simples:** de onde saem as imagens, CSS e JS. Podem sair do próprio servidor do app, ou de uma CDN —
uma rede que entrega esses arquivos de um ponto perto do usuário, deixando o site mais rápido.

| Caminho | Facilidade | Desempenho | Custo | Escala/Profissional |
|---------|-----------|-----------|-------|---------------------|
| A — Servir do próprio app | alta | menor (1 origem, mais carga) | incluído | ok para começar |
| B — CDN dedicada (ex.: R2 + Cloudflare, S3 + CloudFront) | média | alto (cache global) | baixo, escala com uso | profissional, escalável |

**Recomendação:** PROTOTYPE → **A**. PRODUCTION com imagens/tráfego relevantes → **B** (carrega mais rápido
no mundo todo, alivia o app, melhora SEO/velocidade).
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 5. Tarefas pesadas (LLM, e-mail, processamento de mídia)

**Em simples:** algumas tarefas demoram (chamar uma IA, enviar e-mails, processar vídeo/imagem). Você pode
fazê-las "na hora", enquanto o usuário espera, ou colocá-las numa **fila** processada por um **worker** em
segundo plano.

| Caminho | Facilidade | Desempenho | Custo | Escala/Profissional |
|---------|-----------|-----------|-------|---------------------|
| A — Inline no request | alta | usuário espera; risco de timeout | incluído | frágil sob carga |
| B — Fila + worker persistente | menor | responde na hora, processa depois | +infra (fila/worker) | confiável, escalável |

**Recomendação:** PROTOTYPE com tarefa rápida → **A**. Qualquer tarefa que passe de alguns segundos, ou
PRODUCTION → **B** (não derruba o request, dá retry, aguenta pico). Regra prática: se pode exceder o timeout
do servidor, vai para fila.
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 6. Pagamentos

**Em simples:** como você recebe dinheiro. Pode mandar o cliente para uma **tela de pagamento hospedada**
pelo provedor (menos responsabilidade sua com dados de cartão), ou montar o pagamento **dentro da sua
própria tela** (experiência mais integrada, porém mais responsabilidade e conformidade).

| Caminho | Facilidade | Desempenho | Custo | Escala/Profissional |
|---------|-----------|-----------|-------|---------------------|
| A — Checkout hospedado (redirect) | alta | ok | taxa por transação | menos escopo PCI, seguro |
| B — Integração na própria UI | menor | melhor UX | taxa + mais sua responsabilidade | controle total da experiência |

**Recomendação:** quase sempre começar em **A** (menos exposição a PCI/compliance, sobe rápido). **B** só
quando a experiência de checkout for um diferencial e houver fôlego para a responsabilidade extra.
**Atenção:** regras fiscais e de pagamento variam por país — marcar `[VERIFICAR]` e confirmar com humano.
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 7. Renderização web

**Em simples:** quem monta a página. No **servidor** (a página chega pronta — mais rápido para ver e melhor
para Google), ou no **navegador** (SPA — mais simples de construir, mas a primeira carga é mais lenta e o SEO
exige cuidado extra).

| Caminho | Facilidade | Desempenho (1ª carga / SEO) | Custo | Escala/Profissional |
|---------|-----------|-----------|-------|---------------------|
| A — SSR/SSG/ISR (renderiza no servidor) | média | alto / ótimo p/ SEO | server precisa renderizar | profissional p/ sites públicos |
| B — SPA (renderiza no navegador) | alta | menor 1ª carga / SEO trabalhoso | hospedagem estática barata | ótimo p/ apps internos |

**Recomendação:** site/conteúdo público (precisa de SEO e carga rápida) → **A**. App atrás de login, sem
necessidade de SEO → **B** (mais simples). SSG/ISR quando o conteúdo muda pouco.
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 8. Deploy e operação

**Em simples:** quem cuida de pôr o sistema no ar e mantê-lo rodando. Uma **plataforma gerenciada** faz quase
tudo por você (você dá `git push` e ela publica), ou uma **VPS própria** onde você controla tudo (mais
barato em escala, mais trabalho).

| Caminho | Facilidade | Desempenho | Custo | Escala/Profissional |
|---------|-----------|-----------|-------|---------------------|
| A — PaaS gerenciado (ex.: Vercel, Railway, Fly) | alta | alto | barato no início, sobe com escala | profissional, pouco ops |
| B — VPS própria | baixa | alto (você afina) | menor por recurso, mais seu tempo | escala, mas você opera |

**Recomendação:** PROTOTYPE e a maioria dos PRODUCTION → **A** (foco no produto, não em servidor). **B**
quando custo em escala dói, ou há necessidade específica de controle/região.
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 9. Cache

**Em simples:** guardar resultados prontos para responder mais rápido na próxima vez. Acelera muito, mas
**cache sem plano de invalidação é bug** — dados velhos aparecem na hora errada.

| Caminho | Facilidade | Desempenho | Custo | Escala/Profissional |
|---------|-----------|-----------|-------|---------------------|
| A — Sem cache | alta | dados sempre frescos, mais lento | incluído | simples |
| B — Redis / edge cache | menor | alto | +$/mês (serviço de cache) | escalável, exige disciplina |

**Recomendação:** começar **sem cache** até ter um gargalo medido. Adicionar **B** quando houver alvo de
desempenho e um **plano explícito de invalidação** (quando e como o dado expira). Nunca cachear "no escuro".
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 10. Estrutura (monolito × serviços)

**Em simples:** o sistema como uma peça só, ou quebrado em vários serviços que conversam entre si. Um peça só
é mais simples de construir e operar; vários serviços isolam falhas e escalam partes separadamente — ao custo
de muito mais complexidade.

| Caminho | Facilidade | Desempenho | Custo | Escala/Profissional |
|---------|-----------|-----------|-------|---------------------|
| A — Monolito | alta | ótimo p/ a maioria | menor | escala vertical, simples |
| B — Serviços separados | baixa | bom, mas com latência de rede | +infra + +operação | isola/escala por parte |

**Recomendação:** quase sempre **A** (monolito bem organizado escala muito mais do que se imagina). **B** só
com motivo concreto: times grandes, partes com escala muito diferente, ou isolamento de falha obrigatório.
Não comece por microserviços "por via das dúvidas".
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## Template para novas decisões

Use este molde ao adicionar uma decisão não listada:

```
## <Decisão>
**Em simples:** <o que está em jogo, sem jargão>

| Caminho | Facilidade | Desempenho | Custo | Escala/Profissional |
|---------|-----------|-----------|-------|---------------------|
| A — <simples>  | alta  | menor | menor   | ok p/ validar |
| B — <robusto>  | menor | alto  | +$X/mês | produção séria |

**Recomendação:** PROTOTYPE → A · PRODUCTION (se vai crescer) → B.
**Sempre oferecer:** "posso construir qualquer um — qual preferes?"
```
