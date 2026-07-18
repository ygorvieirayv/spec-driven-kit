# Contexto do Projeto

> **⚠️ Este arquivo é GERADO durante o `/sdk-bootstrap`.** O conteúdo abaixo é só um esqueleto de exemplo
> para você ver o que vai aqui. O onboarding guiado vai substituí-lo pelo contexto real do seu projeto,
> preenchido por conversa e pesquisa, com fontes citadas e marcas `[VERIFICAR]` no que precisa de validação
> humana.
>
> Este é o "conhecimento do projeto" que o agente lê sob demanda — diferente da constituição (que é o
> "caráter", neutro e universal).

---

## Identidade
- **Produto:** _(o que faz, para quem)_
- **Stack:** _(linguagem, framework, banco — confirmado no bootstrap)_
- **Comandos do projeto:** _(rodar / testar / build / lint — preenchido na descoberta)_
- **Restrições conhecidas:** _(prazo, orçamento, carga esperada, durabilidade/criticidade dos dados,
  capacidade operacional e recuperação — somente o que for relevante)_

## Contrato de CI
- **Workflow do produto:** `.github/workflows/sdk-quality.yml`
- **Runner de quality:** _(a confirmar conforme o stack)_
- **Setup de runtime:** _(a confirmar; actions sempre por SHA completo)_
- **Runner de secret scan:** `ubuntu-24.04`
- **Stack confirmado por:** _(manifests, workspaces, lockfiles e arquivos de versão observados)_
- **Checks remotos estáveis:** `Quality gates` · `Secret scan`
- **Proteção remota:** pendente `[VERIFICAR]`

| Gate | Contrato | Diretório/comando ou motivo N/A |
|------|----------|-------------------------------|
| install | _(required / N/A)_ | _(a definir no bootstrap)_ |
| lint | _(required / N/A)_ | _(a definir no bootstrap)_ |
| typecheck | _(required / N/A)_ | _(a definir no bootstrap)_ |
| test | _(required / N/A)_ | _(a definir no bootstrap)_ |
| build | _(required / N/A)_ | _(a definir no bootstrap)_ |
| dependency-audit | _(required / N/A)_ | _(a definir no bootstrap)_ |

## Princípios específicos deste projeto
> Regras globais de negócio e operação, propostas durante o bootstrap e aprovadas pelo usuário. Precisam
> ser concretas e verificáveis; regra que pertence a uma única feature fica na respectiva spec.

- _(ainda não definido)_

## Jurisdição e usuários
- **País de operação:** `[VERIFICAR]`
- **Países dos usuários:** `[VERIFICAR]`
- **Idiomas / localização:** _(moeda, fuso, formatos)_

## Legal e compliance  *(humano valida — nunca é "garantido" pelo agente)*
- **Proteção de dados:** _(o regime aplicável)_ `[VERIFICAR]` — fonte: _(link oficial)_
- **Fiscal / impostos:** `[VERIFICAR]` — fonte:
- **Acessibilidade:** _(padrão aplicável)_ `[VERIFICAR]` — fonte:
- **Setor específico:** _(saúde, finanças, infantil, etc., se aplicável)_ `[VERIFICAR]`

## Pagamentos
- **Recebe pagamento?** sim / não
- **Métodos do mercado-alvo:** `[VERIFICAR]`
- **Decisão de integração:** ver `docs/decisions/`

## Dados sensíveis
- **Coleta PII / dados sensíveis?** _(quais)_
- **Tratamento exigido:** `[VERIFICAR]` (criptografia, retenção, consentimento)

## Logística (se aplicável)
- **Envio / entrega:** _(transportadoras, prazos, regras)_ `[VERIFICAR]`

## NFRs (requisitos não-funcionais herdados por todas as specs)
- **Desempenho:** _(alvos, ex.: P95 < Xms)_
- **Disponibilidade:** _(expectativa)_
- **Segurança/privacidade:** _(do que acima)_
- **Acessibilidade:** _(do que acima)_

## Decisões de arquitetura
> Registro completo em `docs/decisions/`. Resumo aqui:

| Decisão | Escolha | ADR |
|---------|---------|-----|
| Hospedagem | _(pendente)_ | `docs/decisions/` |
| Banco de dados | _(pendente)_ | |
| Autenticação | _(pendente)_ | |
| _(outras conforme o projeto)_ | | |

## Pendências de verificação
> Lista viva de tudo marcado `[VERIFICAR]`. O agente nunca trata isto como resolvido sem confirmação humana.

- [ ] _(pendência)_
