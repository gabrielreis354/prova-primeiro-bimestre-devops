# Log de prompts — Claude Code (base da Questão 2 do relatório)

**Regra:** todos os prompts do aluno, sem exceção, transcritos literalmente e em ordem, seguidos do que a IA fez e do que precisou de correção. Prompts enviados pela IA a subagentes revisores também constam (seção própria). Nenhum segredo/account-id.

Sessão: Claude Code (modelo Sonnet 5) · início em 24/09/2026.

---

## A. Prompts do aluno (literais)

**P01** — comandos locais da sessão (não são pedidos ao modelo): `/reload-plugins` e `/mcp`.

**P02**
> Faça a leitura do provas/prova_primeiro_bimestre

→ IA: o arquivo real é `provas/prova-primeiro-bimestre.md` (hífens); localizou com `ls`, leu e resumiu. *Divergência de nome corrigida pela IA.*

**P03**
> Antes eu quero que voce carregue o contexto das regras e das dicas isso [e muito importante. Vamos executar passo a passo cada uma para garantir a entrega no tempo adequado, temos uma semana

→ IA: salvou regras e dicas na memória do projeto; propôs cronograma de 7 dias e perguntou data da prova e IA usada.

**P04**
> 01/10; Claude Code

→ IA: registrou data da prova (01/10/2026) e IA declarada; invocou `/spec` e gerou a SPEC.

**P05**
> Dispare um subagent com somente as regras e CAs da prova e dispare para ele encontrar erro na sua SPEC. 2. Pode usar

→ IA: disparou revisor da SPEC (ver B1). Corrigiu a SPEC com as lacunas apontadas. *Nota: o revisor recebeu o enunciado completo, não apenas "regras e CAs" — interpretação da IA do pedido.*

**P06**
> aprovado, siga para o Plan, depois voce deve disparar um novo subagent com o contexto do .md da prova

→ IA: escreveu o PLAN e disparou revisor (B2). Corrigiu o PLAN (SSL do RDS, retry, DynamoDB provisioned, Node 22, ordem do cronograma etc.).

**P07**
> gere o tasks.md

→ IA: gerou `tasks.md` (41 tarefas).

**P08**
> Dispare um revisor validando se as regras citadas no arquivo da prova e os requisitos de cada parte estao sendo seguidas

→ IA: disparou revisor (B3). Aplicou ajustes (título do PR, tag `v0.9-apply`, variáveis do plan etc.).

**P09**
> Aprovo; Sobre a Questao 2 o professor autorizou qualquer LLM, entao pode falar que e Claude Code. Sobre o entrega.md e para seguir exatamente o modelo fornecido pela prova para a entrega do professor.

→ IA: executou T01–T05 (git init, .gitignore, README, 3 commits em `main`, branch `feature/api-reservas`, log de prompts). **Falha da IA:** registrou o log apenas como resumo, omitindo prompts.

**P10**
> Voce esta armazenando os prompts? Devem ser todos sem exceção

→ IA: admitiu que não; reescreveu este arquivo com todos os prompts literais e passou a registrar cada novo prompt a cada turno.

---

## B. Prompts enviados pela IA a subagentes revisores (literais)

**B1 — revisor da SPEC**
```
Você é um revisor crítico independente. Tarefa somente de leitura: NÃO edite nem crie arquivos, não rode comandos com efeito colateral.

Leia dois arquivos:
1. Enunciado oficial da prova: /mnt/c/Users/gabri/unifaat_4sem/devops_20262/provas/prova-primeiro-bimestre.md — considere como fonte da verdade apenas: as seções de requisitos (Partes 1 a 6), o checklist do modelo entrega.md, a seção "Regras" (1 a 10), as "Dicas" e os critérios de avaliação.
2. A SPEC a auditar: /mnt/c/Users/gabri/unifaat_4sem/prova-primeiro-bimestre-devops/specs/001-prova-primeiro-bimestre/spec.md

Objetivo: encontrar ERROS na SPEC em relação ao enunciado. Procure:
- Requisitos ou itens do checklist do enunciado que a SPEC omite ou cobre de forma incompleta (ex.: RDS, SGs, tags, outputs, evidências, estrutura de pastas, relatório).
- Contradições ou divergências (valores, portas, tipos de instância, regiões, nomes de pastas/arquivos, prazos, pesos).
- Critérios de aceitação (CA) que não são verificáveis, estão errados ou não cobrem um requisito/regra.
- Riscos de violar regras da prova (PR único, PR só no dia da prova, entrega imutável, .gitignore, IAM, destroy, apenas entrega.md no PR).
- Ambiguidades ou inconsistências internas na SPEC.

Responda em português, em lista priorizada (crítico / importante / menor), cada item com: trecho da SPEC (ou "ausente"), o que o enunciado exige (cite a linha/seção) e a correção sugerida. Se algo estiver correto, não liste. Seja conciso.
```

**B2 — revisor do PLAN**
```
Você é um revisor crítico independente. Tarefa somente de leitura: NÃO edite nem crie arquivos, não rode comandos com efeito colateral.

Leia:
1. Enunciado oficial da prova (fonte da verdade): /mnt/c/Users/gabri/unifaat_4sem/devops_20262/provas/prova-primeiro-bimestre.md — leia inteiro (requisitos, checklist, regras 1-10, dicas, critérios).
2. O PLAN técnico a auditar: /mnt/c/Users/gabri/unifaat_4sem/prova-primeiro-bimestre-devops/specs/001-prova-primeiro-bimestre/plan.md
3. Para conferir consistência, a SPEC aprovada: /mnt/c/Users/gabri/unifaat_4sem/prova-primeiro-bimestre-devops/specs/001-prova-primeiro-bimestre/spec.md

Objetivo: encontrar ERROS e RISCOS no PLAN em relação ao enunciado e à SPEC:
- Decisões técnicas que violem ou não atendam um requisito/regra do enunciado (Learner Lab: LabRole/LabInstanceProfile, sem IAM próprio, us-east-1, free-tier, destroy).
- Erros técnicos reais em Terraform/AWS/Docker/Compose/Node (ex.: backend S3 não aceita variáveis; dependência/ciclo entre módulos; RDS/subnet group exigindo 2 AZs; AMI/SSM param; user_data; postgres 16 no RDS db.t3.micro; senha do RDS; free-tier de EC2/RDS/EBS; ordem do bootstrap; DynamoDB lock; `terraform destroy` quebrando).
- Requisitos da SPEC (RF/CA) sem cobertura no plano.
- Cronograma irreal ou que colida com a regra "PR só no dia da prova (01/10/2026)".
- Riscos de violar o regra de custos: nada fora do free-tier, sem NAT, destruir tudo logo após o uso.

Responda em português, lista priorizada (crítico / importante / menor); cada item: trecho do PLAN, o problema (cite seção/linha do enunciado quando aplicável) e a correção sugerida. Omita o que está correto. Seja conciso.
```

**B3 — revisor das TASKS**
```
Você é um revisor crítico independente. Tarefa somente de leitura: NÃO edite nem crie arquivos, não rode comandos com efeito colateral.

Leia:
1. Enunciado oficial da prova (fonte da verdade): /mnt/c/Users/gabri/unifaat_4sem/devops_20262/provas/prova-primeiro-bimestre.md — inteiro.
2. Plano de tarefas a validar: /mnt/c/Users/gabri/unifaat_4sem/prova-primeiro-bimestre-devops/specs/001-prova-primeiro-bimestre/tasks.md
3. Para contexto: spec.md e plan.md na mesma pasta.

Objetivo: validar, item a item, se o tasks.md (e, por consequência, spec/plan) SEGUE:
(a) as 10 regras da seção "Regras" do enunciado;
(b) os requisitos de cada Parte (1 a 6), incluindo a estrutura de repositório, o checklist do modelo entrega.md, o formato do PR (só entrega.md em entregas/provaPrimeiroBi/RA/) e as questões do relatório;
(c) as observações do Learner Lab (LabRole/LabInstanceProfile, us-east-1, sem IAM, destroy).

Entregue: 
1. Uma tabela "Regra/Requisito | Coberto por (task) | Status (OK / parcial / ausente) ".
2. Uma lista priorizada apenas dos itens parcial/ausente ou em conflito, com a correção sugerida (seja específico: qual task alterar/adicionar).
Português, conciso. Não repita o que está correto além da tabela.
```

**B0 — argumentos passados à skill `/spec` (P04)**
> Prova do 1º bimestre DevOps: API de Reservas (Node/Express + PostgreSQL), Docker, Compose, Terraform modular (vpc, security-group, ec2, rds) com remote state S3+DynamoDB no AWS Academy Learner Lab. Enunciado em provas/prova-primeiro-bimestre.md. Prova em 01/10/2026; IA: Claude Code.

---

## C. Registro de decisões e correções (humano × IA)
- Humano aprovou SPEC, PLAN e TASKS; decidiu declarar Claude Code e seguir o modelo do `entrega.md` do enunciado sem alterações.
- Erros reais que a revisão cruzada (subagentes) pegou na saída da IA: SSL obrigatório no RDS Postgres ≥15; retry de conexão da API; senha no `user_data` vazando em evidências; DynamoDB on-demand fora do free-tier; Node 20 em EOL; `repo_ref` sem tag antes do apply; título do PR exigido pelo workflow da disciplina.
- Falha da IA no processo: log de prompts feito como resumo (corrigido em P10).

---

## D. Continuação (prompts a partir de P11 são anexados abaixo, literais, a cada turno)

**P11** (25/09/2026)
> O tf07 foi finalizado e nele tem API que nesse caso tambem pede na prova valide a API da aula 07 de acordo com os requisitos da API da prova e valide se ela pode ser usada

→ IA: localizou o TF/API da Aula 07 e validou contra os requisitos da API da prova (ver abaixo, resultado registrado após a análise).

→ Resultado (IA): a API da Aula 07 (`entregas/aula-07/6325149/server.js`, Reserva de Salas, em memória) **não atende** a API da prova: rotas, campos e persistência divergem. Decisão: **não reutilizar o código**; reaproveitar apenas padrões (Express, validação manual, códigos 400/404). Detalhes na resposta ao aluno e em `specs/001-prova-primeiro-bimestre/api-aula07-analise.md`.

**P12** (25/09/2026)
> siga para o dia 2

→ IA: executa T06–T10 (API + PostgreSQL local).

**P13** (25/09/2026) — comando local `/model` (manteve Sonnet 5) e prompt:
> Vamos continuar

→ IA: retomou T09/T10 após uma chamada interrompida pelo sistema; conferiu o estado (API parada, Postgres temporário ativo) e reexecutou o smoke test na porta 3100, pois a 3000 é usada por outra aplicação local ("Sistema de Gestão de Hotel Backend").
