# Molde — Contexto de Domínio

> **Para o agente:** preencha este molde durante a descoberta do `/sdk-bootstrap` e grave em
> `.specify/memory/project-context.md`. Pergunte **uma coisa de cada vez**, explique o porquê, pesquise o
> que for legal/fiscal e **cite fontes**. Marque com `[VERIFICAR]` tudo que precisa de validação humana —
> compliance nunca é "garantido" pelo agente.

---

## Identidade
- **Produto:** <o que faz, para quem>
- **Stack:** <linguagem / framework / banco>
- **Comandos do projeto:** rodar `<...>` · testar `<...>` · build `<...>` · lint `<...>`
- **Restrições conhecidas:** <prazo, orçamento, carga esperada, durabilidade/criticidade dos dados,
  capacidade operacional e recuperação — somente o que for relevante>

## Princípios específicos deste projeto
> Regras globais de negócio/operação explicadas e aprovadas pelo usuário. Mantenha-as concretas e
> verificáveis; regra que pertence a uma feature fica na respectiva spec.

- <princípio e efeito observável>

## Jurisdição e usuários
- **País de operação:** <...> `[VERIFICAR]`
- **Países dos usuários:** <...> `[VERIFICAR]`
- **Idiomas / localização:** <moeda, fuso, formatos de data/número>

## Legal e compliance  *(humano valida)*
- **Proteção de dados:** <regime aplicável> `[VERIFICAR]` — fonte: <link oficial>
- **Fiscal / impostos:** <...> `[VERIFICAR]` — fonte: <link>
- **Acessibilidade:** <padrão aplicável> `[VERIFICAR]` — fonte: <link>
- **Regras de setor:** <saúde / finanças / infantil / etc., se aplicável> `[VERIFICAR]`

## Pagamentos
- **Recebe pagamento?** sim / não
- **Métodos do mercado-alvo:** <...> `[VERIFICAR]`
- **Decisão de integração:** ver ADR em `docs/decisions/`

## Dados sensíveis
- **Coleta PII / dados sensíveis?** <quais>
- **Tratamento exigido:** criptografia / retenção / consentimento `[VERIFICAR]`

## Logística (se aplicável)
- **Envio / entrega:** <transportadoras, prazos, regras> `[VERIFICAR]`

## NFRs (herdados por todas as specs)
- **Desempenho:** <alvos>
- **Disponibilidade:** <expectativa>
- **Segurança / privacidade:** <do que acima>
- **Acessibilidade:** <do que acima>

## Decisões de arquitetura
> Detalhe em `docs/decisions/`. Resumo:

| Decisão | Escolha | ADR |
|---------|---------|-----|
| <decisão> | <escolha> | `docs/decisions/<arquivo>.md` |

## Pendências de verificação
- [ ] <tudo marcado `[VERIFICAR]`>
