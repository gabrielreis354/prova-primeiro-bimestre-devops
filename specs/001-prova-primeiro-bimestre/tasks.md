# TASKS: Prova do 1º Bimestre — API de Reservas

Spec e Plan aprovados. Cada task é pequena, ordenada e tem **Verificação** (saída real). Marcar `[x]` só após verificar.
**Log de prompts (Parte 5 / Q2):** ao fim de cada task que use a IA, atualizar `evidencias/prompts-log.md` (prompt, o que a IA gerou, o que foi corrigido; marcar o que é gerado por IA: Dockerfile, compose, módulos). Sem segredos/account-id.
Convenção de commit: Conventional Commits com corpo (o quê + porquê) + `Co-Authored-By`. Nunca commitar na `main` durante a feature; merge com `--no-ff`.
🛑 = guardrail de custo/regra. Nenhum push/PR ao repo da disciplina antes de 01/10.

## Dia 1 — 24/09: Repositório e Git (RF8, CA1)
- [x] T01 `git init` em `prova-primeiro-bimestre-devops`, branch `main`. **V:** `git status`.
- [x] T02 `.gitignore` (node_modules, .env, .terraform, *.tfstate, *.tfstate.backup, *.pem, *.tfvars, `!*.tfvars.example`, backend.hcl; NÃO ignorar `.terraform.lock.hcl`). **V:** `git check-ignore -v` nos padrões.
- [x] T03 `README.md` (nome, RA 6325149, descrição, como rodar, enum de `status`). **V:** leitura.
- [x] T04 Commit `docs: adiciona SPEC, PLAN e TASKS` + `chore: adiciona .gitignore` + `docs: adiciona README` em `main` (baseline). **V:** `git log --oneline`.
- [x] T05 Criar `feature/api-reservas`; iniciar `evidencias/prompts-log.md` (sem segredos) e rascunho de `relatorio.md`. **V:** `git branch`.

## Dia 2 — 25/09: API + Postgres local (RF1–RF7, CA4, CA5)
- [ ] T06 `app/package.json` (express, pg; Node 22) + `npm install`. **V:** `npm ls`.
- [ ] T07 `src/db.js`: Pool com env `DB_*`/`DB_SSL`, retry/backoff, `CREATE TABLE IF NOT EXISTS reservas (id SERIAL, cliente, data, status)`. **V:** conecta ao Postgres local (container temporário `docker run postgres:16-alpine`).
- [ ] T08 `src/routes/reservas.js` + `src/index.js`: CRUD, `/health`, validação (400/404, `:id` inteiro). **V:** subir API e testar com curl.
- [ ] T09 `app/smoke.sh`: POST→GET→GET/:id→PUT→DELETE, 404, 400, param inválido; sai com código ≠ 0 se falhar. **V:** `bash smoke.sh` verde.
- [ ] T10 Commit `feat(api): implementa CRUD de reservas com PostgreSQL`. **V:** `git log`.

## Dia 3 — 26/09: Docker (RF9, CA2, CA16)
- [ ] T11 `app/Dockerfile` multi-stage (`node:22-alpine`, `USER node`) + `.dockerignore`. **V:** `docker build` ok.
- [ ] T12 Executar container contra Postgres; `curl /health`; `docker exec … whoami` = node. **V:** salvar `evidencias/docker-build.txt` (build + run + whoami + curl).
- [ ] T13 Commit `feat(docker): adiciona Dockerfile multi-stage e dockerignore`.

## Dia 4 — 27/09: Compose (RF10, RF20, CA3, CA4)
- [ ] T14 `.env.example` (sem senhas reais) e `.env` local ignorado. **V:** `git ls-files | grep .env` só mostra `.env.example`.
- [ ] T15 `docker-compose.yml`: `db` (postgres:16-alpine, volume nomeado `pgdata`, `pg_isready`), `api` (`depends_on: condition: service_healthy`), rede `reservas-net` com `driver: bridge` explícito. **V:** `docker compose config`; após subir, `docker network inspect` mostra driver bridge.
- [ ] T16 `docker compose up -d --build`; `smoke.sh`; `docker compose restart`; confirmar persistência. **V:** salvar `evidencias/compose-ps.txt`.
- [ ] T17 Commit `feat(compose): adiciona ambiente local API + PostgreSQL`.

## Dia 5 — 28/09: Terraform e backend (RF11–RF19, CA6, CA8, CA13, CA14)
- [ ] T18 🛑 Guardrail: `aws sts get-caller-identity` (abortar se root; confirmar LabRole/usuário do Lab) e região `us-east-1`. **V:** saída sem `:root`.
- [ ] T19 `infra/backend/bootstrap.sh` e `teardown.sh` (bucket com versioning, SSE, block public access, tags; DynamoDB PROVISIONED 1/1 com `LockID`, tags; gera `backend.hcl`). Rodar `shellcheck`/`bash -n` antes. **V:** `bash -n`.
- [ ] T20 Executar `bootstrap.sh`. **V:** `get-bucket-versioning`, `get-bucket-encryption`, `describe-table`. 🛑 Backend vivo = custo ~0, mas será removido no dia 6.
- [ ] T21 `aws rds describe-orderable-db-instance-options` (postgres 16, db.t3.micro) e `describe-availability-zones`; fixar versão/AZs. **V:** saída anotada.
- [ ] T22 Módulo `vpc` (2 AZs, subnets pub/priv, IGW, rota pública, sem NAT). **V:** `terraform validate`.
- [ ] T23 Módulo `security-group` (regras opcionais `cidr_blocks` ou `referenced_security_group_id`). Instâncias: SG EC2 com 22 (`ssh_cidr`) e 3000; SG RDS com 5432 só por `referenced_security_group_id` = SG EC2. **V:** `validate`.
- [ ] T24 Módulo `rds`: postgres 16, `db.t3.micro`, `publicly_accessible=false`, `storage_encrypted=true`, `db_subnet_group_name` com as subnets privadas, db_name/username, `skip_final_snapshot`. **V:** `validate`.
- [ ] T25 Módulo `ec2`: `t2.micro`, subnet pública, AMI SSM AL2023, `iam_instance_profile = "LabInstanceProfile"`, `vockey`, `user_data` que sobe a API (clone em `repo_ref`, docker build/run, retry). **V:** `validate`; testar o script do `user_data` com `bash -n`.
- [ ] T26 🛑 Exportar antes do plan `TF_VAR_db_password` (descartável) e `TF_VAR_ssh_cidr` (seu IP/32). Raiz: `providers.tf` (backend parcial, `default_tags`, versões), `variables.tf`, `main.tf` (composição), `outputs.tf` (`ec2_public_ip`, `rds_endpoint`, `api_url`), `terraform.tfvars.example`. Garantir que a senha não apareça nas evidências. **V:** `terraform init -backend-config=backend.hcl`, `validate`, `plan` → `evidencias/terraform-validate.txt` e `terraform-plan.txt`.
- [ ] T27 Revisão humana do plan, conferindo cada ponto: sem IAM; sem NAT; VPC 2 AZs pub/priv; SG EC2 (22, 3000) e RDS (5432 só do SG EC2, sem `0.0.0.0/0`); EC2 t2.micro pública com `LabInstanceProfile`; RDS db.t3.micro privado, criptografado, subnet group privado; tags; `grep` de senha/account-id nas evidências. **V:** checklist assinado por você.
- [ ] T28 Commits (`feat(infra): …` por módulo), merge `feature/api-reservas` → `main` com `--no-ff`, salvar `git log --graph` em `evidencias/`, tag intermediária `v0.9-apply` (é o `repo_ref` do `user_data`). **V:** ≥6 commits convencionais.
- [ ] T29 ⚠️ **Confirmação sua:** criar repo público `prova-primeiro-bimestre-devops` no GitHub e `git push --tags`. (Não é o repo da disciplina.) **V:** `git ls-files` sem proibidos; URL abre.

## Dia 6 — 29/09: Apply, evidências e destroy (RF19, CA7, CA9, CA16) — 🛑 destruir logo após
- [ ] T30 🛑 Guardrail T18 novamente; senha descartável via `TF_VAR_db_password`; `TF_VAR_ssh_cidr` = seu IP/32. **V:** identidade e variáveis ok.
- [ ] T31 `terraform apply`. **V:** outputs; `evidencias/terraform-apply.txt` (revisar segredos).
- [ ] T32 Aguardar boot; `curl api_url/health`; `smoke.sh` contra `api_url`. **V:** `evidencias/curl-crud-rds.txt`. Se falhar: `get-console-output`/SSH com `vockey`.
- [ ] T33 Evidências de segurança/state: `describe-db-instances` (`PubliclyAccessible=false`, `StorageEncrypted=true`), `describe-security-groups`, `terraform state list`, `s3 ls` do state, `describe-table`, prova de não haver IAM criado. **V:** arquivos em `evidencias/`.
- [ ] T34 🛑 **Imediatamente:** `terraform destroy` → `evidencias/terraform-destroy.txt`.
- [ ] T35 🛑 `teardown.sh` (bucket + tabela). **V:** `aws ec2/rds/s3api/dynamodb list/describe` vazios, sem EIP/ENI/volumes órfãos; avisar você se sobrar algo.
- [ ] T36 Commit `docs: adiciona evidências de infraestrutura`.

## Dia 7 — 30/09: Relatório, entrega e congelamento (CA10–CA12, CA15, CA17)
- [ ] T37 `relatorio.md`: Claude Code informado no início; Q1–Q4, ≥10 linhas de texto cada (sem contar título/código), experiência real (erros e correções do `prompts-log.md`). Q1: mapa aulas 01–07 → solução e ordem seguida com motivo. Q2: prompts principais, acertos, correções, manual vs IA; sem Kiro, descrever o fluxo SDD spec→plan→tasks. Q3: arquitetura (diagrama opcional), RDS privado × EC2 pública, LabRole/LabInstanceProfile, ajustes do Lab (credenciais temporárias, região, SCP do Object Lock). Q4: checklist pré-apply, validação, risco de aceitar sem revisar, evolução Git→Docker→TF→Módulos. **V:** contagem de linhas por questão.
- [ ] T38 Rascunho de `entrega.md` seguindo EXATAMENTE o modelo do enunciado, sem seções extras (aprovado pelo usuário; data 01/10/2026; **Ferramenta de IA: Claude Code**; URL do repo; evidências coladas no corpo; checklist marcado só com CA verificados) mantido **no repo da prova**, fora de `entregas/`. **V:** cada item do checklist ↔ CA.
- [ ] T39 Auditoria final: CA1–CA17 um a um; `git ls-files`; estrutura do RF16; repo público acessível; tag `v1.0`. Conferir na `main` remota (`git ls-tree`/`gh api`) `README.md`, `.gitignore`, `docker-compose.yml`, `relatorio.md`, `app/`, `infra/`, `infra/modules/{vpc,security-group,ec2,rds}` e que os links de evidência do `entrega.md` existem lá. Se o código mudou depois do apply, repetir o apply (nova tag em `repo_ref`) e destruir na hora. **V:** tabela CA → evidência.
- [ ] T40 Commits finais e push (com sua confirmação). Todo o material (relatório, evidências, entrega.md rascunho, tag `v1.0`) fica commitado e pushado no repo da prova antes de 01/10. Nada a mais depois da tag.

## 01/10 — Dia da prova (somente com você presente)
- [ ] T41 ⚠️ Fork/clone do repo da disciplina, criar `entregas/provaPrimeiroBi/6325149/entrega.md` (só esse arquivo), commit, push, **um único PR** com título exato `[Prova Primeiro Bimestre] RA: 6325149 - Gabriel Reis Cunha` (o workflow da disciplina usa o título para aplicar as regras de PR único e imutável). O PR não pode tocar `.github/`, `TF.md` nem `provas/`. Sem commits depois. **V:** PR contém 1 arquivo; título confere.

## Mapa CA → tasks
CA1 T04,T28 · CA2 T11–12 · CA3 T16 · CA4/5 T09,T16 · CA6 T26 · CA7 T32–33 · CA8 T20,T33 · CA9 T34–35 · CA10 T37–38 · CA11 T38 · CA12 T41 · CA13 T26,T31 · CA14 T20,T33 · CA15 T28–29 · CA16 T12,T16,T26,T31–34 · CA17 T39
