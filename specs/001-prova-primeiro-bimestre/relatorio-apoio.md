# Material de apoio ao relatorio.md (NÃO faz parte da entrega)

> Escrito pela IA (Claude Code) só como **fatos, datas e ponteiros de evidência** para você consultar.
> O texto dissertativo das 4 questões, na sua voz e com a sua análise, é seu (o enunciado pede "com base na sua experiência real").
> Nada aqui deve ser copiado como está. Mínimo do enunciado: 10 linhas por questão; informar a ferramenta de IA no início.

## Perguntas do enunciado (para não esquecer nenhuma parte)
- **Q1** Como conectou as peças (Git → Terraform + módulos + remote state)? Qual ordem seguiu e por quê? Onde cada aula (01 a 07) apareceu na solução?
- **Q2** Qual IA e como usou? Prompts principais, o que a IA gerou bem, o que precisou corrigir, comparação com fazer manualmente (onde economizou e onde atrapalhou).
- **Q3** Arquitetura AWS; por que RDS privado e EC2 pública; como funcionou LabRole/LabInstanceProfile sem IAM próprio; ajustes exigidos pelo Learner Lab (credenciais temporárias, região, restrições de IAM).
- **Q4** Checklist antes do `apply` em código de IA; como validou que estava correto e seguro; o que aconteceria aceitando sem revisar; como Git → Docker → Terraform → Módulos preparou para usar IA com responsabilidade.

## Linha do tempo real (para a Q1)
| Data | O que aconteceu | Onde ver |
|---|---|---|
| 24/09 | Leitura da prova, SPEC, PLAN, TASKS com 3 revisões por subagentes; repo, README, `.gitignore`, feature branch | `specs/`, `evidencias/prompts-log.md` (P02–P10) |
| 25/09 | Análise da API da Aula 07 (não reutilizada), API + PostgreSQL, Dockerfile, Compose, backend, módulos Terraform, validate e plan | `api-aula07-analise.md`, `evidencias/` |
| 26/09 | Merge `--no-ff`, tag, push; apply, CRUD no RDS, evidências, destroy e teardown (adiantado em relação ao PLAN, que previa 29/09) | `git-log-graph.txt`, `terraform-apply.txt`, `terraform-destroy.txt` |
Mapa aula → solução (a confirmar com o seu material das aulas): Git/Docker (01) → repo, commits, Dockerfile; Compose (02) → `docker-compose.yml`; Terraform/VPC/EC2/RDS (03–05) → `infra/`; Módulos e remote state (06) → `infra/modules/`, `infra/backend/`; IA como copiloto (07 e 02) → SDD com spec/plan/tasks e revisores.

## Fatos para a Q2 (processo com IA)
- Ferramenta: Claude Code (modelo Sonnet 5), fluxo SDD: `/spec` → PLAN → TASKS → implementação, com checkpoint seu após cada etapa. Prompts literais: `evidencias/prompts-log.md` (P01–P26).
- Subagentes revisores (prompts B1–B5 no log): SPEC, PLAN, TASKS, README/repo, auditoria de CAs. Achados reais deles: SSL obrigatório no RDS Postgres ≥15; retry de conexão da API; senha vazando pelo `user_data` nas evidências; DynamoDB on-demand fora do free-tier; Node 20 em EOL; `repo_ref` sem tag antes do apply; título exato do PR; `relatorio.md` inexistente com a T05 marcada; verificação pós-destroy sem saída; persistência provada com `restart` e não com recriação.
- Erros da IA registrados no log: log de prompts feito como resumo (P10); `apply -auto-approve` sobre plano não revisado (P21), interrompido antes de criar recursos; datas erradas nas evidências; IP e account-id vazando em evidências (mascarados antes do commit); `tfplan` fora do `.gitignore`; loop de captura do lock que parava cedo (CA8).
- Decisões suas: aprovou SPEC/PLAN/TASKS, declarou Claude Code, exigiu o modelo exato do `entrega.md`, mandou registrar todos os prompts, escolheu interromper e limpar o `apply` indevido (P22), aprovou o plano (T27).
- Para comparar com o manual (é a sua avaliação): tempo de escrita de módulos e scripts; onde a revisão cruzada pegou erro; onde o cuidado extra custou tempo.

## Fatos para a Q3 (infra, segurança, Learner Lab)
- Arquitetura aplicada (19 recursos): VPC 10.0.0.0/16, 2 subnets públicas e 2 privadas em us-east-1a/1b, IGW, sem NAT; EC2 t2.micro pública (AMI AL2023 via SSM, `LabInstanceProfile`, key `vockey`, IMDSv2); RDS PostgreSQL 16.13 db.t3.micro privado; SG EC2 22 (só seu IP/32) e 3000; SG RDS 5432 só a partir do SG da EC2. Evidências: `terraform-plan.txt`, `terraform-apply.txt`, `seguranca-state.txt`.
- Por que RDS privado / EC2 pública: pontos técnicos a explicar com as suas palavras: superfície de ataque, `publicly_accessible=false`, acesso só via SG da EC2, sem NAT (custo) porque o RDS não precisa de saída. Prova: tentativa TCP na 5432 de fora falhou.
- Learner Lab: credenciais temporárias com Session Token (`aws-creds.sh`), role `voclabs`, região `us-east-1`, sem criar IAM (state sem `aws_iam`), `LabInstanceProfile` referenciado por nome. SCP do Lab bloqueia `GetBucketObjectLockConfiguration` → bucket do state criado por `bootstrap.sh` (AWS CLI) e não pelo provider. Credenciais expiram (`ExpiredToken`).
- Outros pontos reais: `dynamodb_table` deprecated no Terraform 1.15 (mantido por exigência do enunciado); DynamoDB PROVISIONED 1/1 para o free-tier; RDS ≥15 exige SSL (`rejectUnauthorized: false` no Lab); senha do RDS no `user_data`/`docker run` (aceitável só com senha descartável, limitação a reconhecer); `terraform destroy` + `teardown.sh` logo após as evidências, nada restou (`verificacao-pos-destroy.txt`).

## Fatos para a Q4 (validação e responsabilidade)
- Checklist aplicado antes do apply (T27): sem IAM; sem NAT; VPC 2 AZs pública/privada; SG EC2 (22 e 3000) e RDS (5432 só do SG da EC2, sem `0.0.0.0/0`); EC2 t2.micro com `LabInstanceProfile`; RDS db.t3.micro privado, criptografado, subnet group privado; tags; sem senha/account-id nas evidências; plano salvo (`-out`) e revisado antes de aplicar.
- Como validou: `terraform validate` e `plan`, revisão do plano, CRUD no RDS via `api_url`, `describe-db-instances`, `describe-security-groups`, state no S3 (versionado/SSE), lock no DynamoDB, e verificação pós-destroy por CLI.
- Caso real de "aceitar sem revisar": o `apply -auto-approve` do P21 (plano novo, não revisado) foi bloqueado e interrompido antes de criar recursos; mostra o risco concreto de custo e de aplicar sem conferir.
- Outros quase-erros que a revisão evitou: senha vazando nas evidências, `0.0.0.0/0` na 5432, DynamoDB fora do free-tier, `tfplan` com senha sem estar no `.gitignore`.

## Limitações honestas que você pode citar
Senha no `user_data`; `rejectUnauthorized: false`; `dynamodb_table` deprecated; SG da 3000 aberta ao mundo (exigência do enunciado); teste de acesso externo ao RDS sem saída textual além do resultado; a EC2 clona o repo por tag pública.
