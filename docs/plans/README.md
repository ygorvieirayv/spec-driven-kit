# Planos

Uma pasta por feature:

- `plan.md` — abordagem e decisões, gerado pelo `/sdk-plan`;
- `tasks.md` — trabalho e estado, gerado pelo `/sdk-tasks` quando a rastreabilidade separada se aplica;
- `evidence.md` — recibos acumulados das verificações, criado pelo `/sdk-implement` na primeira observação real
  e confirmado pelo `/sdk-review`.

Não preencha evidência por antecipação: se algo não foi executado ou observado, registre `not-run` ou
`unavailable`. Uma task implementada fica `verification-pending`; somente o review, após rerodar a verificação
citada em contexto fresco por padrão, pode promovê-la a `done`. Inline é exceção justificada com o mesmo
rerun. Plan/tasks trazem `- **Evidence:**`, obrigatório e apontando para a própria feature. Não há modo
legado: estado que afirma prova sem recibo correspondente é inválido.
