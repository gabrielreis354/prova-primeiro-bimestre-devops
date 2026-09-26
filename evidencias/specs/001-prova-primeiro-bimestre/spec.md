# SPEC: Prova do 1º Bimestre — API de Reservas (TechNova)

## 1. Objetivo
Entregar, em repositório próprio (`prova-primeiro-bimestre-devops`), a API de Reservas containerizada, com ambiente local via Docker Compose e infraestrutura AWS modularizada com Terraform e remote state, acompanhada de `relatorio.md`. Aluno: Gabriel Reis Cunha, RA 6325149.

## 2. Contexto / Motivação (Why)
- Prova individual de DevOps (Aulas 01–07), enunciado em `devops_20262/provas/prova-primeiro-bimestre.md`.
- Prova em **01/10/2026**; construção na semana anterior (início 24/09/2026).
- O PR de entrega só pode ser aberto no dia da prova, é único e imutável após aberto.
- IA declarada: **Claude Code** (documentar prompts para a Questão 2).

## 3. Escopo
### Dentro do escopo
- API Node.js/Express com CRUD de `reservas` (`id`, `cliente`, `data`, `status`) + `/health`, persistindo em PostgreSQL.
- Dockerfile + `.dockerignore`.
- `docker-compose.yml` (API + Postgres), `.env.example`.
- Terraform modular: `vpc`, `security-group`, `ec2`, `rds`; backend remoto S3 + DynamoDB (`infra/backend/`).
- `evidencias/` (docker-build, compose-ps, terraform-plan, etc.).
- `relatorio.md` (4 questões, ≥10 linhas cada, IA informada no início).
- `entrega.md` (modelo do enunciado), preparado mas **só enviado no dia da prova**.

### Fora do escopo (NÃO fazer)
- Autenticação, front-end, CI/CD, ORM/migrations sofisticadas, testes além do necessário para validar o CRUD.
- Criar IAM users/groups/roles; qualquer recurso AWS fora do free-tier; NAT Gateway.
- Abrir PR, fazer fork/push no repo da disciplina antes de 01/10/2026.
- Extras não pedidos no enunciado (sugestões só em uma linha).

## 4. Requisitos funcionais
- RF1: `POST /reservas` cria reserva validando campos obrigatórios (400 em caso inválido).
- RF2: `GET /reservas` lista todas.
- RF3: `GET /reservas/:id` retorna a reserva ou 404.
- RF4: `PUT /reservas/:id` atualiza reserva existente (404 se não existir).
- RF5: `DELETE /reservas/:id` remove reserva (404 se não existir).
- RF6: `GET /health` responde 200 (usado no healthcheck do Compose).
- RF7: Dados lidos/gravados no PostgreSQL, localmente e no RDS (nunca em memória).
- RF8: Git: ≥6 commits Conventional Commits, feature branch + merge, README com nome/RA/descrição, `.gitignore` (node_modules, .env, .terraform, *.tfstate, *.pem).
- RF9: Dockerfile multi-stage, usuário não-root.
- RF10: Compose com volume nomeado, rede bridge customizada, healthcheck no banco, `depends_on` com `condition`; sobe com um comando.
- RF11: VPC com subnets públicas e privadas em 2 AZs; SGs: EC2 (22, 3000), RDS (5432 só a partir do SG da EC2).
- RF12: EC2 t2.micro em subnet pública rodando a API, com `LabInstanceProfile`.
- RF13: RDS PostgreSQL db.t3.micro em subnets privadas, `publicly_accessible=false`, `storage_encrypted=true`, `db_subnet_group_name` com subnets privadas.
- RF14: Remote state: S3 (versionamento + encriptação) + DynamoDB (lock); backend criado antes do `backend "s3"` principal.
- RF15: Composição entre módulos (outputs → inputs), tags em todos os recursos (inclusive bucket/tabela do backend), outputs: IP da EC2, endpoint do RDS, URL da API.
- RF16: Estrutura do repo conforme enunciado: `README.md`, `.gitignore`, `app/{src,package.json,Dockerfile,.dockerignore}`, `docker-compose.yml`, `.env.example`, `infra/{modules/{vpc,security-group,ec2,rds},main.tf,variables.tf,outputs.tf,providers.tf,backend/}`, `evidencias/`, `relatorio.md`.
- RF17: `infra/backend/` contém `bootstrap.sh` (bucket S3 com versionamento + SSE + block public access, e tabela DynamoDB com chave `LockID`, ambos com tags) e `teardown.sh` (remove bucket e tabela, esvaziando versões).
- RF18: Segurança de Terraform: SG do RDS referencia o SG da EC2 (`referenced_security_group_id`), sem `0.0.0.0/0` na 5432; porta 22 restrita ao IP do aluno (variável); senha do RDS via variável `sensitive` (`TF_VAR_`), `*.tfvars` e `*.tfstate.backup` no `.gitignore`; RDS com `skip_final_snapshot = true`, `allocated_storage` ≤ 20 GB, sem Multi-AZ.
- RF19: Sequência de execução AWS: bootstrap → init → validate → plan → apply → evidências (state/lock, CRUD no RDS) → destroy → teardown do backend → verificação por `aws ... list/describe`.
- RF20: Healthcheck do Compose: `pg_isready` no Postgres e `depends_on: condition: service_healthy`; healthcheck da API em `/health` opcional.
- RF21: Registrar log de prompts do Claude Code desde o início (base da Questão 2), refletindo erros e correções reais.

## 5. Requisitos não-funcionais / Restrições
- AWS Academy Learner Lab: região `us-east-1`, credenciais temporárias, **LabRole/LabInstanceProfile**, sem IAM próprio.
- Regra absoluta de custo: free-tier only; `terraform destroy` imediatamente após capturar evidências; não executar AWS/Terraform se a identidade for root.
- Bucket S3 do backend criado via `bootstrap.sh` (AWS CLI), pois o SCP do Lab bloqueia `GetBucketObjectLockConfiguration` no provider Terraform.
- Segredos fora do Git (`.env`, `*.tfstate`, `*.pem`); `.env.example` versionado.
- Reaproveitar módulos da Aula 06 como base; seguir convenções do repo da disciplina.
- Código simples (KISS/YAGNI), sem código gerado por IA aceito sem revisão.

## 6. Critérios de aceitação (verificáveis)
- [x] CA1: `git log` mostra ≥6 commits convencionais e um merge de feature branch; repo público com README (nome + RA) e `.gitignore` correto.
- [x] CA2: `docker build` conclui e o container responde em `/health`; `evidencias/docker-build.txt` gerado.
- [x] CA3: `docker compose up -d` sobe API + Postgres saudáveis; `docker compose ps` salvo em `evidencias/compose-ps.txt`.
- [x] CA4: Via curl, POST→GET→GET/:id→PUT→DELETE funcionam e os dados persistem após `docker compose restart` (volume).
- [x] CA5: GET/PUT/DELETE de id inexistente → 404; POST inválido → 400.
- [x] CA6: `terraform validate` e `terraform plan` sem erros; saída em `evidencias/terraform-plan.txt`.
- [x] CA7: Após `apply`, a API na EC2 grava/lê no RDS (CRUD verificado por curl na URL do output); RDS não acessível publicamente.
- [x] CA8: State no S3 com lock no DynamoDB; nenhum recurso IAM criado.
- [x] CA9: `terraform destroy` executado e `teardown.sh` do backend rodado só depois de capturar as evidências de state/lock; sem recursos remanescentes (verificado por `aws ... list`); saída em `evidencias/terraform-destroy.txt`.
- [x] CA10: `relatorio.md` completo (4 questões, ≥10 linhas cada, IA informada no início, reflete experiência real); `entrega.md` com nome, RA, data 01/10/2026, ferramenta (Claude Code), URL do repo, evidências coladas e os 13 itens do checklist marcados apenas quando os CA correspondentes passaram.
- [ ] CA11: Nenhum push/PR/fork ao repo da disciplina antes de 01/10/2026; rascunho do `entrega.md` fica só no repo da prova (fora de `entregas/`).
- [ ] CA12: PR único, contendo somente `entregas/provaPrimeiroBi/6325149/entrega.md`, aberto em 01/10/2026 após revisão final completa, sem commits posteriores.
- [x] CA13: `terraform output` mostra `ec2_public_ip`, `rds_endpoint`, `api_url`; recursos taggeáveis com tags (`default_tags`/`tags`).
- [x] CA14: SG do RDS na 5432 usa o SG da EC2 como origem e nenhum `0.0.0.0/0`; `aws s3api get-bucket-versioning/get-bucket-encryption` comprovam versionamento e SSE do bucket.
- [x] CA15: `git ls-files` não lista `.tfstate`, `.terraform/`, `.env`, `*.pem`, `*.tfvars`; merge da feature branch com `--no-ff` e `git log --graph` salvo em `evidencias/`.
- [x] CA16: Evidências completas em `evidencias/`: docker-build (+ `docker run`/`whoami` não-root e curl `/health`), compose-ps, terraform-validate, terraform-plan, terraform-apply/outputs, curl CRUD no RDS, terraform-destroy.
- [x] CA17: Estrutura do repo conforme RF16 (incluindo `.dockerignore`).

## 7. Riscos e questões em aberto
- Tempo: 7 dias; Terraform/AWS é o maior risco → módulos prontos e plan no dia 5 (28/09), primeiro apply no dia 6 (29/09), dia 7 de buffer.
- Credenciais do Lab expiram (`ExpiredToken`) → reiniciar Lab e atualizar `~/.aws/credentials`.
- Como a API chega na EC2 (imagem em registry vs. build via user_data): decisão do Plan, respeitando free-tier.
- Sem NAT Gateway (custo): RDS privado não precisa de saída; a EC2 (pública) puxa dependências.
- Push do repo da prova (público) para o GitHub: criar o repo remoto exige sua confirmação.
- Prioridade pelos pesos: Terraform 25% e relatório 40% (Q1–Q4) — reservar tempo real para ambos.
- Sessão/créditos do Lab são limitados: primeiro apply em 29/09 (dia 6), com 30/09 de folga para repetir.
- Localização do repo: proponho `/mnt/c/Users/gabri/unifaat_4sem/prova-primeiro-bimestre-devops/` (fora do repo da disciplina, para não sujar a `entregas/`).
