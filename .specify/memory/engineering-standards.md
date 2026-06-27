# Padrões de Engenharia

> **O que é isto:** a barra técnica do projeto. Lido sob demanda pelos comandos de plano/revisão/implementação
> (não a cada mensagem). Enquanto a constituição cuida do **caráter** (como o agente pensa), este arquivo cuida
> da **competência** (o que uma entrega técnica precisa respeitar).
>
> **Importante:** este arquivo é **neutro**. Ele diz o que **VERIFICAR** e **PESQUISAR**, não dá respostas
> fixas (que dependem do stack e do projeto). Respostas concretas viram ADRs em `docs/decisions/` ou entram
> no `project-context.md`.

---

## Sempre (inegociável, vale nos dois modos)

- **Segredos nunca no código nem no git.** Chaves, tokens, senhas e strings de conexão vivem em variáveis
  de ambiente / cofre, nunca commitados. `.env` está no `.gitignore`. Conferir também que segredos não
  vazam para o **bundle do cliente** (front-end) nem para logs.
- **Validar toda entrada pública.** Tudo que vem de fora (usuário, API, webhook, arquivo) é não-confiável
  até validado. Validar no servidor, não só na UI.
- **PII fora dos logs.** Dados pessoais, segredos e tokens não vão para logs, mensagens de erro ou
  telemetria. Logar identificadores, não conteúdo sensível.
- **Sem credenciais de exemplo reais.** Placeholders em docs e templates são claramente fictícios.

---

## Infra e Deploy
**VERIFICAR / DECIDIR (ver `decision-guide.md`):**
- Onde roda (VPS única × serviços separados × PaaS) e por quê — registrar como ADR.
- Builds reproduzíveis: versões de runtime e dependências fixadas (lockfile, imagem base pinada).
- Configuração por ambiente (dev/stage/prod) via env vars, não hardcoded.
- Estratégia de migração de banco: versionada, reversível, rodada de forma previsível.
- Backups e plano de restauração para qualquer dado que doa perder. Backup sem restauração testada não é backup.
- Health check e forma de saber que está no ar.

## Integração entre serviços
**VERIFICAR:**
- Contratos explícitos entre partes (schema de request/response, versões).
- Timeouts em **toda** chamada de rede. Nada espera para sempre.
- Retry com backoff só em operações idempotentes; caso contrário, risco de efeito duplicado.
- Idempotência em webhooks e em operações que podem ser reenviadas (chave de idempotência).
- Degradação graciosa: o que acontece quando a dependência externa cai?

## Performance
**VERIFICAR:**
- Definir alvos antes de otimizar (ex.: tempo de resposta P95, tempo de carga). Sem alvo, não há "lento".
- Cuidado com N+1 em acesso a dados; medir antes de assumir.
- Paginação/limite em qualquer listagem que pode crescer.
- Trabalho pesado (LLM, e-mail, processamento de mídia) fora do caminho do request — ver decisão de filas.
- Cache **só com plano de invalidação**. Cache sem invalidação planejada é bug latente.

## Segurança
**VERIFICAR:**
- AuthN (quem é) e AuthZ (pode fazer isto?) checadas no servidor, em toda rota protegida.
- Princípio do menor privilégio para credenciais, tokens e papéis.
- Proteção contra as classes comuns conforme o stack (injeção, XSS, CSRF, SSRF, etc.) — pesquisar o que
  se aplica à tecnologia escolhida.
- Dependências sem vulnerabilidades conhecidas (auditoria de pacotes no CI).
- Dados sensíveis criptografados em trânsito (TLS) e, quando aplicável, em repouso.
- Rate limiting em endpoints públicos e de autenticação.

## Testes
**VERIFICAR (rigor escala com o modo):**
- **PROTOTYPE:** testar o "caminho feliz" da lógica de maior risco; smoke test do fluxo principal.
- **PRODUCTION:** TDD na lógica crítica (RED→GREEN→REFACTOR); cobrir edge cases e modos de falha.
- Testes determinísticos e independentes (sem depender de ordem, rede ou relógio real sem necessidade).
- Cada critério de aceitação da spec mapeia para ao menos uma verificação.
- Teste que nunca falha não testa nada — confirmar que ele pega a regressão que deveria pegar.

## Observabilidade
**VERIFICAR:**
- Logs estruturados com nível adequado (sem PII — ver "Sempre").
- Erros capturados com contexto suficiente para diagnosticar (sem vazar dados sensíveis).
- Métricas/saúde do que importa para o negócio e para a operação.
- Em PRODUCTION: alguma forma de alerta quando algo crítico quebra.

---

## Como usar este arquivo

- O `/sdk-plan` consulta esta barra ao montar o plano técnico.
- O `/sdk-review` usa esta barra como checklist de revisão (achados de segurança/dados sensíveis tendem a
  ser **Crítico**).
- Quando uma escolha desta barra envolve trade-off real, **não decidir sozinho**: abrir `/sdk-decide`,
  apresentar as opções e registrar um ADR.

> Há uma seção editável para padrões próprios do projeto? Sim — adicione abaixo, na descoberta, somente o
> que for específico e verificável.

## Padrões específicos deste projeto
_(Ainda não definido. Será preenchido na descoberta guiada, se necessário.)_
