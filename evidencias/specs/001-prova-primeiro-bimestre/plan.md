# PLAN: Prova do 1º Bimestre — API de Reservas

Spec: `spec.md` (aprovada). Este plano é o COMO.

## 1. Decisões técnicas e trade-offs

| Tema | Decisão | Por quê / alternativa descartada |
|---|---|---|
| Runtime | Node 22 LTS (`node:22-alpine`; Node 20 já está em EOL), Express 4 | Simples, imagem pequena. |
| Acesso ao banco | `pg` (Pool) com SQL direto | KISS/YAGNI; ORM está fora do escopo. |
| Schema | `CREATE TABLE IF NOT EXISTS reservas` executado no boot da API (`src/db.js`) | Sem migrations; funciona igual no Compose e no RDS. Alternativa (init.sql do Postgres) não funcionaria no RDS. |
| Config | Variáveis `DB_HOST/PORT/USER/PASSWORD/NAME`, `DB_SSL`, `PORT` | 12-factor; `.env` local, `TF_VAR_`/user_data na AWS. |
| Conexão | `pg` Pool com retry/backoff no boot (API não morre se o RDS ainda não aceita conexões); `DB_SSL=true` → `ssl: { rejectUnauthorized: false }` (RDS Postgres ≥15 força SSL); local sem SSL | Erro real que quebraria CA7. |
| Validação | Manual: `cliente` (string não vazia), `data` (ISO válida), `status` (enum: `pendente`,`confirmada`,`cancelada`; default `pendente`); `id SERIAL` e param `:id` validado como inteiro (inválido → 400, nunca 500 do Postgres) | Sem libs extras. Enum é decisão minha, não do enunciado (registrar em README). |
| Testes | Script `smoke.sh` com curl cobrindo CA4/CA5 (sem framework) | Verificação real e evidência salva; YAGNI de jest. |
| Docker | Multi-stage (deps → runtime), `USER node`, `.dockerignore`, `HEALTHCHECK` opcional | RF9. |
| Compose | Serviços `db` (postgres:16-alpine) e `api`; volume `pgdata`; rede `reservas-net` (bridge); `pg_isready`; `depends_on: service_healthy`; vars via `.env` | RF10, RF20. |
| Entrega da API na EC2 | `user_data` (Amazon Linux 2023): instala docker + git, clona o repo público, `docker build` e `docker run --restart unless-stopped` com env do RDS (`DB_SSL=true`); `repo_ref` (tag/commit) fixa o código clonado | Sem registry/ECR (evita custo e IAM). Trade-off: boot mais lento (~3–5 min); aceitável. Exige repo público já no GitHub e código pushado/tagueado antes do apply (criação do remote só com sua confirmação, dia 5). Alternativa Docker Hub: exige conta/push extra. |
| Módulos TF | `vpc`, `security-group`, `ec2`, `rds`, adaptados do padrão da Aula 06 (`aula-06/laboratorio-*.md`, `TF.md`) | Reuso recomendado pela dica. |
| VPC | 10.0.0.0/16; 2 subnets públicas + 2 privadas em 2 AZs; IGW; route table pública; **sem NAT** | Custo. RDS privado não precisa de saída. |
| SGs | EC2: 22 (var `ssh_cidr` **sem default**, IP do aluno /32 via `curl ifconfig.me`) e 3000 (0.0.0.0/0); RDS: 5432 com `referenced_security_group_id` = SG EC2 | RF18. Módulo `security-group` com regras opcionais (`cidr_blocks` OU `referenced_security_group_id`, variáveis nullable), usando `aws_vpc_security_group_ingress_rule`; duas instâncias, sem ciclo. |
| EC2 | t2.micro, AMI via `data "aws_ssm_parameter"` (AL2023), `iam_instance_profile = "LabInstanceProfile"`, `key_name = "vockey"` (key pair já existente do Lab, nenhum `.pem` no repo) para depurar `cloud-init-output.log`; também `aws ec2 get-console-output` | Sem IAM próprio (RF12). |
| RDS | postgres 16 (validar antes com `aws rds describe-orderable-db-instance-options` e fixar minor), `db_name = "reservas"`, `username = "reservas"` (não reservado), `aws_db_subnet_group` dentro do módulo `rds`, AZs `us-east-1a/1b` via variável (evita AZs sem suporte a t2.micro), db.t3.micro, 20 GB gp2, `storage_encrypted`, `publicly_accessible=false`, subnet group privado, `skip_final_snapshot=true`, `multi_az=false`, `backup_retention_period=0` | Free-tier + destroy limpo (RF13, RF18). |
| Senha do RDS | `variable "db_password" { sensitive = true }` via `TF_VAR_db_password`, senha descartável só desta prova; nunca em tfvars versionado. Como ela vai no `user_data`, revisar com `grep` todos os `.txt` de evidência antes de commitar | RF18. |
| Backend | `infra/backend/bootstrap.sh` (AWS CLI): bucket `technova-tfstate-6325149-<account-id>`, versioning, SSE AES256, block public access, tags; tabela DynamoDB `technova-tflock` (**PROVISIONED 1 RCU/1 WCU**, free-tier; `LockID`, tags). `teardown.sh` inverso (esvazia versões e delete markers via `list-object-versions` + `delete-objects`; `aws s3 rm` não basta) | Memória: SCP bloqueia `GetBucketObjectLockConfiguration` no `aws_s3_bucket`. |
| Backend no `providers.tf` | bloco parcial `backend "s3" {}` + `backend.hcl` gerado pelo `bootstrap.sh` (no `.gitignore`; bucket, key, region, `dynamodb_table`, `encrypt = true`); `terraform init -backend-config=backend.hcl`. Fixar `required_version` e versão do provider AWS; versionar `.terraform.lock.hcl` | Backend não aceita variáveis; evita account-id no Git. Após `teardown.sh` é preciso rodar `bootstrap.sh` de novo. |
| Tags | `default_tags` no provider (`Project`, `Owner`, `RA`, `ManagedBy`) + `tags` nos módulos | CA13. |
| Outputs | `ec2_public_ip`, `rds_endpoint`, `api_url` | CA13. |
| Git | Repo local `prova-primeiro-bimestre-devops`; `main` + `feature/api-reservas` (merge `--no-ff`), Conventional Commits com corpo | CA1, CA15. Remote GitHub criado só com sua confirmação. |

## 2. Estrutura de arquivos (RF16)

```
prova-primeiro-bimestre-devops/
├── README.md  .gitignore  .env.example  docker-compose.yml  relatorio.md
├── evidencias/specs/001-prova-primeiro-bimestre/{spec.md,plan.md,tasks.md}
├── app/{package.json, Dockerfile, .dockerignore, smoke.sh, src/{index.js,db.js,routes/reservas.js}}
├── infra/
│   ├── main.tf variables.tf outputs.tf providers.tf terraform.tfvars.example
│   ├── backend/{bootstrap.sh, teardown.sh}
│   └── modules/{vpc,security-group,ec2,rds}/{main.tf,variables.tf,outputs.tf}
└── evidencias/
```
`prompts-log.md` (RF21) fica em `evidencias/` ou como rascunho local e alimenta a Questão 2.

## 3. Composição dos módulos

`vpc` → outputs: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`
`security-group` (ec2) ← `vpc_id`; → `sg_id`
`security-group` (rds) ← `vpc_id`, `source_sg_id` = SG da EC2
`rds` ← `private_subnet_ids`, `rds_sg_id`, `db_password` → `endpoint`, `address`
`ec2` ← `public_subnet_ids[0]`, `ec2_sg_id`, `db_host = rds.address`, `db_password` → `public_ip`

## 4. Sequência de verificação (mapa CA → como provar)

- CA1/CA15: `git log --oneline --graph`, `git ls-files | grep -E '\.tfstate|\.env$|\.pem|\.tfvars$'` vazio.
- CA2–CA5: `docker build`, `docker run`, `docker compose up -d`, `docker compose ps`, `smoke.sh` (inclui restart + persistência).
- CA6/CA14/CA16: `bootstrap.sh` → `terraform init/validate/plan` → `apply` → `smoke.sh` contra `api_url` → `aws s3api get-bucket-versioning/encryption`, `terraform state list`, `aws dynamodb describe-table`.
- CA9: `terraform destroy` → `teardown.sh` → `aws ec2/rds/s3/dynamodb list` vazios.
- Guardrails AWS antes de qualquer comando: `aws sts get-caller-identity` (abortar se root; usar só LabRole/IAM do Lab), região us-east-1.

## 5. Cronograma (hoje 24/09 → prova 01/10)

| Dia | Data | Entrega |
|---|---|---|
| 1 | 24/09 | Plan/Tasks aprovados; repo, README, .gitignore, feature branch; início do `prompts-log.md` e rascunho do relatório |
| 2 | 25/09 | API + Postgres local (`smoke.sh` verde) |
| 3 | 26/09 | Dockerfile + evidências |
| 4 | 27/09 | Compose + evidências |
| 5 | 28/09 | Backend bootstrap; módulos vpc/sg/ec2/rds escritos; validar engine/orderable options; `validate` + `plan`; merge, tag e push do repo público (com sua confirmação) |
| 6 | 29/09 | Primeiro `apply` → CRUD no RDS → evidências → `destroy` + `teardown` imediatos |
| 7 | 30/09 | Buffer para repetir apply; `relatorio.md` final; dry-run do `entrega.md`; tag `v1.0` |
| — | 01/10 | Abrir o PR (único), presencial |

## 5b. Verificações adicionais
- CA7 (RDS não público): `aws rds describe-db-instances --query 'DBInstances[].PubliclyAccessible'` = false e `psql`/`nc` de fora falhando.
- Após destroy + teardown: `aws ec2 describe-instances/describe-volumes/describe-addresses/describe-network-interfaces`, `rds describe-db-instances`, `s3api list-buckets`, `dynamodb list-tables` sem sobras; se sobrar algo, alertar imediatamente (regra de custos).
- Antes de commitar evidências e `prompts-log.md`: grep por senha, account-id, ARNs.
- Evidência do lock: capturar `describe-table` e o item de lock durante o `apply` (antes do teardown).

## 6. Riscos e mitigação
- `ExpiredToken`: reiniciar Lab, atualizar `~/.aws/credentials`.
- `user_data` falha silenciosa: checar `/var/log/cloud-init-output.log` por SSM/SSH; teste local do script antes.
- AZ/AMI indisponível no Lab: usar `data "aws_availability_zones"`.
- Ciclo entre SGs: regra do RDS como `aws_security_group_rule`/`ingress` com `referenced_security_group_id` no módulo, sem referência recíproca.
- Lab expira entre apply e destroy: reiniciar Lab, atualizar credenciais e destruir na hora (state remoto preservado). ENIs/SG podem dar `DependencyViolation`: repetir o destroy.
- Destroy travando no RDS: `skip_final_snapshot=true`, `deletion_protection=false`.
