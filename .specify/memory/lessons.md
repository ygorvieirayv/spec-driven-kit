# Biblioteca de Lições

> **O que é isto:** um catálogo de **erros já enfrentados e como foram resolvidos**, escrito de forma
> **generalizada e reutilizável** — sem nome de projeto, sem caminho específico. Cada lição é um padrão que
> serve a *qualquer* projeto. O objetivo é: aprender com um erro **uma vez** e nunca mais repeti-lo (8º
> princípio da constituição).
>
> **Como usar (para o agente):**
> - **Consulte por tag/grep**, não carregue o arquivo inteiro (economia de token). Ex.: ao planejar algo com
>   cache, procure `#cache`.
> - `/sdk-plan` e `/sdk-review` consultam aqui para aplicar prevenções conhecidas.
> - `/sdk-lesson` adiciona novas lições (via o subagente `sdk-lesson-curator`, que generaliza e deduplica).
>
> **Regra de ouro ao gravar:** nada que identifique o projeto. Descreva o **padrão**, não o incidente.
> Em vez de "o checkout da Loja X mostrou preço velho", escreva "cache sem invalidação serve dado velho".

> **Uso multi-projeto:** para compartilhar estas lições entre vários projetos, extraia este arquivo para um
> **repositório próprio** e referencie-o em cada projeto, mantendo válido o caminho `.specify/memory/lessons.md`
> (via submodule numa pasta + symlink, ou sincronizando o arquivo). Cada postmortem novo contribui de volta, e
> a biblioteca cresce transversalmente. Veja o README, seção "Biblioteca de lições".

---

## Formato de cada lição

```
### L-### · <título curto do padrão>
- **Sintoma:** <o que se observa, genérico>
- **Gatilho:** <quando costuma aparecer>
- **Causa raiz:** <por que acontece>
- **Correção:** <como resolver>
- **Prevenção:** <regra acionável para não repetir>
- **Tags:** #tag1 #tag2   · **Aplicabilidade:** <a que tipo de projeto serve>
```

IDs são sequenciais (`L-001`, `L-002`, …) e **nunca reusados**.

---

## Lições

### L-001 · Cache sem invalidação serve dado velho
- **Sintoma:** o usuário vê informação desatualizada após uma alteração que deveria aparecer.
- **Gatilho:** adicionou cache para acelerar, sem definir quando ele expira.
- **Causa raiz:** cache sem plano de invalidação.
- **Correção:** invalidar a entrada na escrita, ou usar TTL curto + chave por versão do dado.
- **Prevenção:** nunca adicionar cache sem uma regra explícita de invalidação. Cache "no escuro" é bug.
- **Tags:** #cache #performance · **Aplicabilidade:** qualquer projeto que use cache.

### L-002 · Segredo no código, no git ou no bundle do cliente
- **Sintoma:** chave/token aparece no repositório, em logs, ou exposto no JavaScript do navegador.
- **Gatilho:** colou a chave direto no código "só para testar", ou usou variável sem prefixo correto no
  front-end.
- **Causa raiz:** segredo tratado como configuração comum.
- **Correção:** mover para variável de ambiente/cofre; rotacionar o segredo exposto; remover do histórico.
- **Prevenção:** `.env` no `.gitignore`; segredo nunca vai para o cliente; revisar diffs por padrões de chave.
- **Tags:** #segurança #segredos · **Aplicabilidade:** qualquer projeto com credenciais.

### L-003 · Chamada de rede sem timeout trava o sistema
- **Sintoma:** uma requisição "pendura" e segura recursos; sob carga, o serviço degrada ou cai.
- **Gatilho:** chamou uma API/serviço externo confiando que sempre responde rápido.
- **Causa raiz:** ausência de timeout (a espera é infinita).
- **Correção:** definir timeout em toda chamada de rede; tratar o estouro com erro/fallback.
- **Prevenção:** nenhuma chamada externa sem timeout. Adicionar retry com backoff **só** se for idempotente.
- **Tags:** #integração #confiabilidade · **Aplicabilidade:** qualquer projeto que chame serviços externos.

### L-004 · N+1 em acesso a dados
- **Sintoma:** uma tela/endpoint fica lento conforme a quantidade de itens cresce.
- **Gatilho:** carregar uma lista e, para cada item, fazer outra consulta.
- **Causa raiz:** uma consulta por item em vez de uma consulta agregada.
- **Correção:** buscar em lote (join/`IN`/eager loading) e medir antes/depois.
- **Prevenção:** desconfiar de qualquer loop que consulta dados; medir com dados realistas.
- **Tags:** #performance #dados · **Aplicabilidade:** qualquer projeto com banco de dados.

### L-005 · Input público sem validação no servidor
- **Sintoma:** dado inválido/malicioso entra; erro inesperado ou brecha de segurança.
- **Gatilho:** confiar na validação só da UI, ou confiar em dado vindo de fora.
- **Causa raiz:** entrada externa tratada como confiável.
- **Correção:** validar e sanitizar no servidor toda entrada pública (usuário, API, webhook, arquivo).
- **Prevenção:** validação no servidor é obrigatória; a da UI é só conveniência.
- **Tags:** #segurança #validação · **Aplicabilidade:** qualquer projeto com entrada externa.

### L-006 · Webhook sem idempotência causa efeito duplicado
- **Sintoma:** uma ação acontece duas vezes (cobrança dupla, e-mail repetido) quando o provedor reenvia.
- **Gatilho:** processar todo webhook como se fosse único.
- **Causa raiz:** provedores reenviam eventos; sem chave de idempotência, o efeito repete.
- **Correção:** registrar o ID do evento e ignorar reentregas; tornar o processamento idempotente.
- **Prevenção:** todo webhook/operação reenviável precisa de chave de idempotência.
- **Tags:** #integração #pagamentos · **Aplicabilidade:** qualquer projeto que receba webhooks.

### L-007 · "Green falso" — teste que não pega a regressão
- **Sintoma:** os testes passam, mas o bug continua acontecendo em produção.
- **Gatilho:** escrever o código primeiro e o teste depois, "para confirmar"; ou teste que nunca falha.
- **Causa raiz:** o teste foi moldado ao código existente, não ao comportamento esperado — não testa nada.
- **Correção:** escrever o teste antes (RED), vê-lo falhar pela razão certa, então implementar (GREEN).
- **Prevenção:** em lógica crítica, TDD; sempre confirmar que o teste **falha** quando o comportamento quebra.
- **Tags:** #testes #qualidade · **Aplicabilidade:** qualquer projeto com lógica crítica.

### L-008 · Escopo inflado (feature além do combinado)
- **Sintoma:** a entrega cresce, atrasa e traz funcionalidades que ninguém pediu.
- **Gatilho:** "já que estou aqui, aproveito e faço também…".
- **Causa raiz:** falta de recorte explícito do que está **fora de escopo**.
- **Correção:** voltar à spec, cortar o que não é AC do MVP, registrar o resto em "Depois do MVP".
- **Prevenção:** toda spec declara "Fora de escopo"; mudanças cirúrgicas; combinar antes de expandir.
- **Tags:** #escopo #processo · **Aplicabilidade:** qualquer projeto.

### L-009 · Migração de banco sem rollback nem versionamento
- **Sintoma:** uma mudança de schema quebra produção e não há como voltar com segurança.
- **Gatilho:** alterar o banco "na mão" ou sem migração reversível.
- **Causa raiz:** migração não versionada e sem caminho de reversão.
- **Correção:** versionar migrações; escrever a reversão; testar o rollback antes de aplicar em produção.
- **Prevenção:** toda mudança de schema é uma migração versionada e reversível, com backup antes.
- **Tags:** #infra #dados · **Aplicabilidade:** qualquer projeto com banco de dados.

### L-010 · PII em logs
- **Sintoma:** dados pessoais/sensíveis aparecem em logs, erros ou telemetria.
- **Gatilho:** logar o objeto inteiro "para depurar".
- **Causa raiz:** ausência de cuidado sobre o que vai para o log.
- **Correção:** remover PII dos logs; logar identificadores, não conteúdo sensível.
- **Prevenção:** PII/segredos/tokens nunca em logs; revisar o que é logado em código novo.
- **Tags:** #segurança #privacidade #observabilidade · **Aplicabilidade:** qualquer projeto que trate PII.

---

## Índice de tags
`#cache` `#performance` `#dados` `#segurança` `#segredos` `#validação` `#privacidade` `#integração`
`#confiabilidade` `#pagamentos` `#testes` `#qualidade` `#escopo` `#processo` `#infra` `#observabilidade`

> Próximo ID livre: **L-011**.
