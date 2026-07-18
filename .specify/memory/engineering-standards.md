# Padrões de Engenharia

> **O que é isto:** a barra técnica do projeto. Lido sob demanda pelos comandos de plano/revisão/implementação
> (não a cada mensagem). Enquanto a constituição cuida do **caráter** (como o agente pensa), este arquivo cuida
> da **competência** (o que uma entrega técnica precisa respeitar).
>
> **Importante:** este arquivo é **neutro**. Ele diz o que **VERIFICAR** e **PESQUISAR**, não dá respostas
> fixas (que dependem do stack e do projeto). Respostas concretas viram ADRs em `docs/decisions/` ou entram
> no `project-context.md`.

---

## Sempre (inegociável)

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
**VERIFICAR (rigor escala com o risco e com as superfícies alteradas):**
- Lógica crítica usa TDD (RED→GREEN→REFACTOR) e cobre edge cases e modos de falha.
- Mudança não crítica usa a menor prova reproduzível que ainda demonstra os critérios de aceitação.
- Testes determinísticos e independentes (sem depender de ordem, rede ou relógio real sem necessidade).
- Cada critério de aceitação da spec mapeia para ao menos uma verificação.
- Teste que nunca falha não testa nada — confirmar que ele pega a regressão que deveria pegar.

## CI do consumidor (fail-closed)

- O bootstrap confirma stack, runner de quality e setup de runtime e só então **renderiza**
  `.github/workflows/sdk-quality.yml` a partir do template. O job de quality usa o runner aprovado; o scan
  de segredos permanece em Ubuntu. Actions de setup usam SHA completo. O workflow gerado pertence ao
  produto; atualizações do kit nunca o sobrescrevem.
- O job `Quality gates` executa primeiro `scripts/sdk-check.ps1` e depois `scripts/sdk-ci.ps1`, que delega
  ao runner Bash canônico. Existem
  exatamente seis gates do projeto, nesta ordem: `install`, `lint`, `typecheck`, `test`, `build` e
  `dependency-audit`.
- Cada gate possui exatamente um `.specify/ci/gates/<gate>.sh` real **ou** `<gate>.skip` com motivo
  estrutural aprovado. Ausência, duplicidade, placeholder, `--if-present`, `|| true` ou `set +e` bloqueiam
  antes de qualquer comando. A coluna `Contrato` do `project-context.md` usa exatamente `required` ou
  `N/A` e precisa coincidir com `.sh`/`.skip`; assim, trocar um check aprovado por skip não fica verde.
  Falta de scaffold/comando ainda não criado não é N/A: o CI permanece vermelho. No Windows, use
  `scripts/sdk-ci.ps1`, que encontra o Git Bash e delega ao mesmo runner canônico.
- O job `Secret scan` é sempre obrigatório e roda `scripts/sdk-secrets.sh` em Ubuntu com histórico completo.
  Gitleaks é baixado em versão fixa, verificado por SHA-256 e executado sobre histórico e árvore atual;
  falha/download indisponível nunca viram sucesso. Isto detecta **segredos**, não PII geral.
- `.gitleaks.toml` customizado preserva as regras padrão com `[extend] useDefault = true`. Exceção é estreita,
  justificada e revisada como `data-security`; baseline ou allowlist ampla automática são proibidos.
- Os nomes remotos estáveis são `Quality gates` e `Secret scan`. Para impedir que apagar o workflow vire
  bypass, configure branch protection/ruleset exigindo ambos quando a plataforma permitir. Essa mutação
  externa exige aprovação explícita; sem ruleset, descreva honestamente apenas "fail-closed quando executado".
- Verde remoto prova somente o `head_sha` observado pelo provedor. O review pode registrar o CI do commit
  de implementação observado e criar um commit **somente de estado/evidence**; os checks desse commit final
  são um gate externo de merge e nunca geram outro recibo/commit. Mudança posterior de produto invalida a
  prova; resultado antigo/indisponível não promove prova `delivery` que exige CI.

## Perfis de prova

> Perfis descrevem **que superfície precisa ser provada**; não são níveis de qualidade nem uma sequência
> fixa. O `/sdk-plan` avalia os seis para cada feature, marca cada um como `aplicável` ou `N/A` com motivo e
> combina quantos forem necessários. O risco da mudança define a profundidade da prova dentro do perfil.

| Perfil | Quando se aplica | Prova mínima esperada |
|--------|------------------|-----------------------|
| `visual` | Interface, layout, estados visuais, responsividade ou acessibilidade observável mudam | Inspeção nos estados e dimensões relevantes, com artefato reproduzível (screenshot, preview ou equivalente) e resultado objetivo |
| `logic` | Regra, cálculo, transformação, validação ou ramificação muda | Teste automatizado determinístico; lógica crítica segue RED→GREEN→REFACTOR |
| `journey` | Um AC atravessa telas, componentes, serviços ou uma integração e representa uma jornada do usuário | Fluxo ponta a ponta reproduzível, incluindo o limite externo permitido pela spec e ao menos o modo de falha relevante |
| `data-security` | Há persistência, schema, migração, PII, autenticação, autorização, permissão ou deleção | Provas de integridade e negativas de acesso; migração/schema, transformação destrutiva/em massa ou operação que exige reversibilidade tem forward e rollback/restore/forward-recovery **executados** em ambiente seguro, nunca apenas descritos |
| `operational` | Há rede, fila, job, cron, retry, timeout, idempotência, concorrência, recuperação ou saúde operacional | Falha controlada e recuperação observável; verificar os mecanismos aplicáveis e seus sinais em logs/métricas sem PII |
| `delivery` | Build, dependência, configuração, empacotamento, deploy ou execução no ambiente-alvo podem mudar | Lint/typecheck/test/build aplicáveis e smoke do artefato/ambiente afetado; CI quando fizer parte da entrega |

### Regras de seleção e rastreio

- `N/A` nunca fica sem motivo. Ausência de interface não torna `visual` implicitamente N/A; o plano registra
  a razão. O mesmo vale para todos os perfis.
- Todo perfil `aplicável` mapeia para ao menos um AC e, em `tasks.md`, para ao menos uma task. Toda task cita
  ao menos um perfil aplicável.
- Se uma task citar vários perfis, sua verificação precisa provar todos; se as provas forem independentes,
  fatie a task.
- Os limites de fidelidade da spec controlam o que vale como prova: comportamento declarado `real` não pode
  ser aprovado só com mock; `sandbox` precisa exercitar o ambiente de teste real; `simulada` pode usar um
  double desde que a simulação e o que ela não prova estejam explícitos.
- O rastreio reutiliza os artefatos existentes: **perfil → AC → task → Registro em `evidence.md`**. Não
  acrescente campos ao recibo de evidence para repetir o perfil.
- Critérios de saída aprovados encerram a validação. Achado novo só reabre trabalho quando viola AC, perfil
  aplicável, esta barra ou a constituição; melhoria aceita como dívida vira sub-feature no ledger.

## Observabilidade
**VERIFICAR:**
- Logs estruturados com nível adequado (sem PII — ver "Sempre").
- Erros capturados com contexto suficiente para diagnosticar (sem vazar dados sensíveis).
- Métricas/saúde do que importa para o negócio e para a operação.
- Alguma forma de alerta quando algo crítico para a operação quebra.

---

## Como usar este arquivo

- O `/sdk-plan` consulta esta barra ao montar o plano técnico.
- O `/sdk-review` usa esta barra como checklist de revisão (achados de segurança/dados sensíveis tendem a
  ser **Crítico**).
- Quando uma escolha desta barra envolve trade-off real, **não decidir sozinho**: abrir `/sdk-decide`,
  apresentar as opções e registrar um ADR.

> Padrões próprios do produto ficam no `project-context.md` ou em ADR, nunca neste arquivo atualizável do
> motor.
