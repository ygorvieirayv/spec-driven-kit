# Como usar (guia rápido)

> Guia de bolso para usar o Spec Driven Kit no dia a dia. Sem jargão. Para a visão completa, veja o
> [`README.md`](./README.md); para instalar, o [`INSTALL.md`](./INSTALL.md).

## A ideia em uma frase
Você **conversa**, o assistente **pergunta e propõe**, você **aprova**. Os arquivos vão sendo criados
sozinhos. Você nunca preenche nada à mão.

## Perdido? Rode `/sdk-next`
Voltou de uma pausa, limpou a conversa (`/clear`), não lembra em que etapa parou? Rode **`/sdk-next`**: ele
lê os arquivos do projeto e responde **onde você está** e **qual comando rodar agora**, com o porquê. Ele só
recomenda — nada acontece sem você aprovar. É o único comando que você precisa decorar.

---

## 1. Uma vez por projeto

1. Abra o **Claude Code** na pasta do projeto.
2. Rode **`/sdk-bootstrap`** e diga o que quer construir — **uma frase** ou um **despejo de tudo que imaginou**
   (telas, recursos, regras). Tanto faz: o agente organiza depois.
3. Responda às perguntas (uma de cada vez). Não sabe? Diga **"não sei"** — ele explica e sugere um caminho seguro.
4. Nos checkpoints 🛑, leia e aprove (ou peça pra mudar).

No fim, o projeto tem: stack, decisões (hospedagem, banco, pagamento…), regras do seu negócio, o **MVP** e a
**ordem de construção** (o que fazer primeiro).

---

## 2. Para cada feature (repete na ordem certa)

Antes de detalhar, rode **`/sdk-roadmap`** para ver o que está **🟢 pronto para começar**. Comece por essa.

Depois, para a feature escolhida, siga a trilha:

| Você digita | O que acontece |
|---|---|
| **`/sdk-spec`** | Ele te entrevista e escreve **o que** essa parte faz. (Trava se faltarem dependências.) |
| **`/sdk-clarify`** | *(Se ficou vago)* tira as dúvidas que faltam da spec. |
| **`/sdk-plan`** | Escreve **como** construir e divide em tarefinhas. |
| **`/sdk-tasks`** | Organiza a lista de tarefas rastreáveis. |
| **`/sdk-analyze`** | Confere se spec, plano e tarefas **batem** — antes de codar. |
| **`/sdk-implement`** | **Constrói** e te explica em português, mostrando que funciona. |
| **`/sdk-review`** | **Confere** o que foi feito (bugs, risco, testes) e aponta problemas. |

Terminou? **Volte ao `/sdk-roadmap`** para a próxima feature desbloqueada.

> 💡 **Planeja uma feature por vez.** O mapa geral (a ordem) é feito uma vez no início; o **detalhe** de cada
> feature acontece só quando chega a vez dela — não se planeja tudo de uma vez de propósito (a feature 1
> ensina coisas que mudam a 2).

> 🛠️ **Mudando algo que já existe?** Diga isso ao `/sdk-spec` — em vez de reespecificar tudo, ele registra só
> o que **muda** (adiciona / modifica / remove) e o que **não pode quebrar**. (É o "modo brownfield".)

---

## 3. Comandos de apoio (quando precisar)

- **`/sdk-decide`** — travou numa escolha ("uso isso ou aquilo?"). Ele mostra prós/contras (facilidade, custo,
  velocidade) e diz: *"posso construir qualquer um — qual prefere?"*
- **`/sdk-lesson`** — algo deu errado e foi resolvido. Ele guarda a lição pra **nunca repetir o erro** (nesse
  projeto e nos próximos).
- **`/sdk-doctor`** — "será que meu projeto se perdeu?". Ele confere se os arquivos batem entre si (spec,
  plano, tarefas, o mapa) e com o código, **sem mudar nada**. Se achar algo torto, te mostra as opções e só
  conserta o que você aprovar, um de cada vez. Bom pra retomar depois de dias parado.

---

## 4. Para gastar pouco (token)
Se a conversa ficar longa entre uma fase e outra, digite **`/clear`** para limpar. **Não perde nada** — está
tudo salvo nos arquivos. Continue do próximo comando.

---

## Resumo de bolso

```
1x por projeto:     /sdk-bootstrap   →   /sdk-roadmap (vê a ordem)

por feature 🟢:     /sdk-spec → (/sdk-clarify se vago) → /sdk-plan → /sdk-tasks
                    → /sdk-analyze → /sdk-implement → /sdk-review
                    → volta ao /sdk-roadmap (próxima feature)

perdido / voltando:   /sdk-next   (diz onde você está e o próximo passo)
travou numa escolha:  /sdk-decide
errou e consertou:    /sdk-lesson
algo não bate:        /sdk-doctor (confere tudo, sem mudar nada; conserta só o que você aprovar)
conversa longa:       /clear   (e segue em frente — /sdk-next retoma)
```

Você sempre só **responde** e **aprova** — o assistente faz o resto.
