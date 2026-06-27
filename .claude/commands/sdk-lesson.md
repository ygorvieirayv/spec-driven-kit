---
description: Registra uma lição aprendida (erro enfrentado e como foi resolvido) de forma generalizada e reutilizável na biblioteca de lições.
argument-hint: "[o que deu errado, em 1 frase]"
---

# /sdk-lesson — Registrar uma lição

Capture um erro que foi enfrentado e resolvido, e grave-o como um **padrão reutilizável** na biblioteca de
lições (`.specify/memory/lessons.md`). O ponto é: aprender uma vez e não repetir — em **qualquer** projeto.

## Princípio (inegociável)
**Grave generalizado, nunca acoplado ao projeto.** Sem nome de produto, sem caminho de arquivo, sem dado
real. Descreva o **padrão** (sintoma → causa → correção → prevenção), não o incidente. Se a lição só faz
sentido citando o projeto, ela ainda não está generalizada — generalize mais.

## Fluxo

1. **Entenda o incidente** com no máximo 3 perguntas curtas (explique o porquê de cada uma):
   - O que se observou (o sintoma)?
   - O que estava sendo feito quando apareceu (o gatilho)?
   - O que resolveu (a correção)?
2. **Generalize e deduplique** via o subagente **`sdk-lesson-curator`** (Task): passe o incidente cru; ele
   remove tudo que é específico do projeto, confere se já existe lição equivalente na `lessons.md` e devolve
   uma entrada limpa no formato padrão (ou aponta a lição existente a reforçar).
3. **Confirme com o usuário** o texto generalizado antes de gravar.
4. **Grave** a entrada em `.specify/memory/lessons.md`:
   - Use o próximo ID livre (veja "Próximo ID livre" no fim do arquivo) e atualize esse marcador.
   - Adicione as tags ao "Índice de tags" se forem novas.
   - Se for duplicata, **reforce a lição existente** em vez de criar outra (melhore prevenção/exemplo).

## Formato da entrada (igual ao da biblioteca)
```
### L-### · <título curto do padrão>
- **Sintoma:** <genérico>
- **Gatilho:** <quando aparece>
- **Causa raiz:** <por quê>
- **Correção:** <como resolver>
- **Prevenção:** <regra acionável>
- **Tags:** #t1 #t2   · **Aplicabilidade:** <a que projetos serve>
```

## Saída
- A lição gravada (ou reforçada), mostrada ao usuário.
- Lembrete: se a biblioteca for um submodule compartilhado, faça commit/push no repo de lições para os outros
  projetos receberem.
