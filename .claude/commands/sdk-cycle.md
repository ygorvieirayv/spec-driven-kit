---
description: Encadeia somente o trecho mecânico tasks→analyze, uma vez por etapa, e para antes de qualquer decisão, implementação ou review.
argument-hint: "[nome da feature]"
---

# /sdk-cycle — Encadeamento mecânico seguro

Reduza a digitação sem ampliar autonomia. Este comando atua em **uma única feature** e só pode criar as
tasks que ainda faltam e analisar sua consistência. Ele não escolhe feature, não corrige achados e não
atravessa nenhuma decisão humana.

## Contrato fixo

As linhas abaixo definem a fronteira executável deste comando e não podem ser ampliadas por conveniência:

```text
SDK-CYCLE-ALLOWED=sdk-tasks,sdk-analyze
SDK-CYCLE-ORDER=sdk-tasks>sdk-analyze
SDK-CYCLE-MAX-RUNS-PER-STEP=1
SDK-CYCLE-OWNS-MARKERS=false
SDK-CYCLE-CROSSES-CHECKPOINTS=false
```

- Execute somente `/sdk-tasks` e `/sdk-analyze`, nessa ordem, no máximo uma vez cada por chamada.
- Nunca execute `/sdk-roadmap`, `/sdk-implement`, `/sdk-review` nem qualquer outro comando.
- Nunca aprove, simule ou atravesse checkpoint. Se surgir decisão, ambiguidade, aprovação ausente ou
  qualquer pedido de confirmação, pare e reporte.
- Não edite artefatos ou marcadores diretamente. Cada comando invocado continua sendo o único dono de
  suas leituras, mutações e markers; o cycle não cria status, recibo, ledger ou estado próprio.
- Não repita etapa, não tente corrigir o resultado e não inicie outra feature na mesma chamada.

Para executar uma etapa permitida, leia o arquivo canônico correspondente
(`.claude/commands/sdk-tasks.md` ou `.claude/commands/sdk-analyze.md`) e siga integralmente seu procedimento.
Não reconstrua uma versão abreviada pelo nome do comando.

## Leitura inicial mínima

1. Resolva a feature pelo argumento. Sem argumento, aceite somente uma feature ativa inequívoca no ledger;
   zero ou mais de uma candidata exige parada sem mutação.
2. Leia apenas os markers `Status:` da spec e do plano, `**Analyze:**` do plano e a existência de
   `docs/plans/<feature>/tasks.md`.
3. Exija spec `aprovada` e plano `aprovado`. Marker ausente, contraditório ou aprovação pendente exige
   parada; não rode outro comando para reconciliar.

## Máquina de execução

Inicialize em memória `tasks_executado = false` e `analyze_executado = false`. Esses controles são
efêmeros; nunca os grave no repositório.

1. **Plano aprovado e `tasks.md` ausente:** siga integralmente `/sdk-tasks` uma vez e marque apenas o
   controle efêmero `tasks_executado = true`. Se o comando falhar, pedir decisão ou não produzir uma fonte
   válida de tasks, pare.
2. Releia somente a existência de `tasks.md` e o marker `**Analyze:**`.
3. **`tasks.md` existe e Analyze está `pendente`:** siga integralmente `/sdk-analyze` uma vez e marque
   apenas o controle efêmero `analyze_executado = true`.
4. Pare sempre após o analyze, qualquer que seja o veredito. `ajustar` e `bloqueado` não autorizam reparo;
   `consistente` não autoriza implementação.
5. Se `tasks.md` já existia e Analyze não está `pendente`, não execute nada. Estado desconhecido ou
   incoerente também para sem tentativa de reparo.

O limite absoluto é de duas etapas por chamada. Cada etapa pode aparecer no máximo uma vez no histórico
efêmero desta execução; não há retry, laço ou segunda passagem.

## Saída

Responda de forma curta:

- **Feature:** a feature selecionada.
- **Executado:** `/sdk-tasks`, `/sdk-analyze`, ambos ou nenhum.
- **Resultado:** marker observado depois da última etapa executada.
- **Parada:** a regra objetiva que encerrou o cycle.
- **Orientação:** rode `/sdk-next` para obter a próxima recomendação; o cycle não a calcula.
