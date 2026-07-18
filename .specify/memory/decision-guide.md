# Guia de Decisões — Catálogo de Trade-offs

> **O que é isto:** a base de conhecimento que alimenta o `/sdk-decide`. Para cada decisão de
> arquitetura/infra, o agente explica em linguagem simples o que está em jogo, mostra os caminhos numa
> tabela (**Facilidade · Desempenho · Custo · Operação/escala**), recomenda conforme fatos observáveis do
> projeto e **sempre** termina com:
> _"posso construir qualquer um dos caminhos — qual preferes?"_
>
> **Regras de uso (para o agente):**
> - Nunca despejar jargão. Traduzir cada termo técnico em 1 frase.
> - A recomendação é um ponto de partida, não uma imposição. A escolha é do usuário.
> - Ancorar no que o usuário já disse: prazo, orçamento, público, carga esperada, durabilidade/criticidade
>   dos dados, capacidade operacional e recuperação necessária. Use só o que for relevante à decisão.
> - "Protótipo", "demo" ou "MVP" descrevem objetivo/escopo; não são licença para reduzir integridade.
> - Após a escolha, registrar um ADR curto em `docs/decisions/<decisao>.md`.
> - Custos são ordens de grandeza ilustrativas — confirmar preços atuais antes de prometer números.

---

## Como ler as tabelas

- **Facilidade** = quão rápido/simples é montar e manter.
- **Desempenho** = velocidade e capacidade sob carga.
- **Custo** = quanto pesa no bolso por mês (ordem de grandeza).
- **Operação/escala** = o que exige para manter, recuperar e crescer com segurança.

Legenda: alta / média / baixa. "+$X/mês" indica custo adicional aproximado.

---

## Gatilhos — quando levantar cada decisão (não deixe passar)

Use estes **sinais do projeto** para garantir que a decisão certa seja proposta — no `/sdk-bootstrap` (etapa D)
ou no `/sdk-plan`. Ao detectar um sinal, **proponha a decisão com trade-offs (incluindo o custo)** e ofereça
construir qualquer caminho. Nunca resolva "por baixo dos panos".

| Sinal no projeto/feature | Decisão a levantar |
|---|---|
| Faz **upload** / **serve imagens**, vídeos ou muitos estáticos | **#4 Imagens e estáticos** (app × CDN, mesmo com pequeno custo) |
| **Processa** mídia/IA/e-mail em massa (tarefa demorada) | **#5 Tarefas pesadas** (inline × fila + worker) |
| Site/conteúdo **público** que precisa aparecer no Google | **#7 Renderização** (SSR/SSG × SPA) |
| Espera **crescer** / muito tráfego / picos | **#1 Hospedagem**, **#2 Banco**, **#9 Cache** |
| Tem **login** de usuários | **#3 Autenticação** |
| **Recebe pagamento** | **#6 Pagamentos** |
| Quer **subir rápido** sem cuidar de servidor | **#8 Deploy** (PaaS × VPS) |
| Partes com escalas muito diferentes / times grandes | **#10 Estrutura** (monolito × serviços) |

---

## 1. Hospedagem  *(decisão-âncora)*

**Em simples:** onde o seu sistema vai morar. Pode ficar tudo junto numa única máquina, ou cada peça
(site, imagens, tarefas pesadas, banco) num lugar otimizado para ela.

| Caminho | Facilidade | Desempenho | Custo | Operação/escala |
|---------|-----------|-----------|-------|-----------------|
| A — Tudo numa VPS (um só Docker) | alta | menor sob carga | menor (1 servidor) | operação simples; ponto único de falha |
| B — Separar (app + CDN p/ estáticos + worker p/ tarefas + DB gerenciado) | menor | alto | +$/mês por peça | isola e escala cada peça |

**Recomendação:** **A** quando carga e picos são modestos, o orçamento é restrito, há pouca capacidade
operacional e o negócio tolera o tempo de recuperação de uma falha nessa máquina. **B** quando latência,
picos, disponibilidade, recuperação ou escala independente justificam as peças extras. Dados duráveis exigem
backup e restauração testada em qualquer caminho.
**Sempre oferecer:** _"posso construir qualquer um dos dois — qual preferes?"_

**Fraseado-modelo:**
> "Dá para pôr **tudo numa única VPS num só Docker** — é mais simples, eu monto tudo junto e o custo inicial
> é menor. A desvantagem é desempenho: sob carga, e comparado a separar as peças, fica mais lento. A
> alternativa é **separar** — CDN para as imagens/estáticos e um worker ligado ao sistema para as tarefas
> pesadas. Fica mais complexo e custa um pouco mais por mês, mas o site abre mais rápido e cada peça pode
> escalar ou se recuperar separadamente. Pelo volume, orçamento e capacidade de operação que você informou,
> sugiro **<A/B>** porque **<fato decisivo>**. Posso construir qualquer um dos dois — qual preferes?"

---

## 2. Banco de dados

**Em simples:** onde os dados ficam guardados. Pode ser um arquivo/serviço simples junto do app, um serviço
gerenciado por terceiros (eles cuidam de backup e atualização), ou um banco dedicado que você administra.

| Caminho | Facilidade | Desempenho | Custo | Operação/escala |
|---------|-----------|-----------|-------|-----------------|
| A — SQLite/Postgres no mesmo container | alta | ok p/ baixo volume | menor | recuperação e escala sob sua responsabilidade |
| B — DB gerenciado (Supabase / Neon / RDS) | média | alto | +$/mês (free tiers comuns) | backup/operação pelo provedor |
| C — Self-hosted dedicado | baixa | alto (você afina) | infra + sua manutenção | controle total; você opera e recupera |

**Recomendação:** **A** quando o volume é baixo e a equipe aceita operar backup/restauração e a falha conjunta
com o app. Para dados importantes que precisam sobreviver e ser recuperados, **B** é o default quando se quer
terceirizar essa operação. **C** só com razão concreta — controle/região/custo em escala — e capacidade real
de atualizar, monitorar, fazer backup e testar restauração.
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 3. Autenticação (login)

**Em simples:** como as pessoas entram na conta. Você pode usar um serviço pronto que entrega login, cadastro
e recuperação de senha "de fábrica", ou montar você mesmo (mais controle, menos custo, mais responsabilidade).

| Caminho | Facilidade | Desempenho | Custo | Operação/escala |
|---------|-----------|-----------|-------|-----------------|
| A — Solução pronta (ex.: Clerk, Auth0) | alta | alto | grátis até X usuários, depois +$/mês | provedor opera o serviço |
| B — Self-hosted (ex.: Better Auth, Auth.js) | média | alto | só infra | controle e manutenção próprios |

**Recomendação:** **A** se prazo curto e baixa capacidade operacional pesam mais. **B** se controle, residência
dos dados ou custo em escala justificam assumir atualização, monitoramento e recuperação. **Atenção:** auth é
área de alto risco em qualquer caminho — não improvisar criptografia de senha; seguir o padrão do framework.
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 4. Imagens e arquivos estáticos

**Em simples:** de onde saem as imagens, CSS e JS. Podem sair do próprio servidor do app, ou de uma CDN —
uma rede que entrega esses arquivos de um ponto perto do usuário, deixando o site mais rápido.

| Caminho | Facilidade | Desempenho | Custo | Operação/escala |
|---------|-----------|-----------|-------|-----------------|
| A — Servir do próprio app | alta | menor (1 origem, mais carga) | incluído | uma origem para operar e recuperar |
| B — CDN dedicada (ex.: R2 + Cloudflare, S3 + CloudFront) | média | alto (cache global) | baixo, escala com uso | distribuição e escala separadas do app |

**Recomendação:** **A** com pouco volume, público próximo e sem alvo exigente de carga/SEO. **B** quando volume,
tráfego, distribuição geográfica ou metas de performance justificam separar a entrega e aliviar o app.
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 5. Tarefas pesadas (LLM, e-mail, processamento de mídia)

**Em simples:** algumas tarefas demoram (chamar uma IA, enviar e-mails, processar vídeo/imagem). Você pode
fazê-las "na hora", enquanto o usuário espera, ou colocá-las numa **fila** processada por um **worker** em
segundo plano.

| Caminho | Facilidade | Desempenho | Custo | Operação/escala |
|---------|-----------|-----------|-------|-----------------|
| A — Inline no request | alta | usuário espera; risco de timeout | incluído | frágil sob carga |
| B — Fila + worker persistente | menor | responde na hora, processa depois | +infra (fila/worker) | confiável, escalável |

**Recomendação:** **A** somente quando a duração fica com folga abaixo do timeout e uma falha não perde nem
duplica efeito importante. Use **B** quando pode demorar, receber pico, precisar de retry/durabilidade ou
continuar após o request. Regra prática: se pode exceder o timeout do servidor, vai para fila.
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 6. Pagamentos

**Em simples:** como você recebe dinheiro. Pode mandar o cliente para uma **tela de pagamento hospedada**
pelo provedor (menos responsabilidade sua com dados de cartão), ou montar o pagamento **dentro da sua
própria tela** (experiência mais integrada, porém mais responsabilidade e conformidade).

| Caminho | Facilidade | Desempenho | Custo | Operação/escala |
|---------|-----------|-----------|-------|-----------------|
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

| Caminho | Facilidade | Desempenho (1ª carga / SEO) | Custo | Operação/escala |
|---------|-----------|-----------|-------|-----------------|
| A — SSR/SSG/ISR (renderiza no servidor) | média | alto / ótimo p/ SEO | server precisa renderizar | adequado a conteúdo público e cacheável |
| B — SPA (renderiza no navegador) | alta | menor 1ª carga / SEO trabalhoso | hospedagem estática barata | ótimo p/ apps internos |

**Recomendação:** site/conteúdo público (precisa de SEO e carga rápida) → **A**. App atrás de login, sem
necessidade de SEO → **B** (mais simples). SSG/ISR quando o conteúdo muda pouco.
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 8. Deploy e operação

**Em simples:** quem cuida de pôr o sistema no ar e mantê-lo rodando. Uma **plataforma gerenciada** faz quase
tudo por você (você dá `git push` e ela publica), ou uma **VPS própria** onde você controla tudo (mais
barato em escala, mais trabalho).

| Caminho | Facilidade | Desempenho | Custo | Operação/escala |
|---------|-----------|-----------|-------|-----------------|
| A — PaaS gerenciado (ex.: Vercel, Railway, Fly) | alta | alto | barato no início, sobe com escala | provedor assume parte da operação |
| B — VPS própria | baixa | alto (você afina) | menor por recurso, mais seu tempo | escala, mas você opera |

**Recomendação:** **A** quando prazo e equipe operacional pequena pesam mais. **B** quando custo em escala,
controle ou região justificam assumir patching, monitoramento, backup e recuperação.
**Sempre oferecer:** _"posso construir qualquer um — qual preferes?"_

---

## 9. Cache

**Em simples:** guardar resultados prontos para responder mais rápido na próxima vez. Acelera muito, mas
**cache sem plano de invalidação é bug** — dados velhos aparecem na hora errada.

| Caminho | Facilidade | Desempenho | Custo | Operação/escala |
|---------|-----------|-----------|-------|-----------------|
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

| Caminho | Facilidade | Desempenho | Custo | Operação/escala |
|---------|-----------|-----------|-------|-----------------|
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

| Caminho | Facilidade | Desempenho | Custo | Operação/escala |
|---------|-----------|-----------|-------|-----------------|
| A — <menor complexidade> | alta | <...> | menor | <o que exige para operar/recuperar> |
| B — <maior capacidade> | menor | <...> | +$X/mês | <o que ganha e passa a exigir> |

**Recomendação:** <A/B> porque <prazo, orçamento, carga, dados, operação ou recuperação observados>.
**Sempre oferecer:** "posso construir qualquer um — qual preferes?"
```
