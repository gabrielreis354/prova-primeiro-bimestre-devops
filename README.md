# Prova do Primeiro Bimestre — DevOps (API de Reservas · TechNova)

- **Aluno:** Gabriel Reis Cunha
- **RA:** 6325149
- **Disciplina:** DevOps — Análise e Desenvolvimento de Sistemas (2026.2)
- **Ferramenta de IA:** Claude Code

## Descrição

Ambiente completo e reproduzível da **API de Reservas** da TechNova: aplicação Node.js/Express
com CRUD de `reservas` persistido em PostgreSQL, containerizada com Docker, orquestrada
localmente com Docker Compose e provisionada na AWS (Learner Lab) com Terraform
modularizado (VPC, Security Groups, EC2 e RDS) e state remoto (S3 + DynamoDB).

## API

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/reservas` | Cria uma reserva (valida campos obrigatórios) |
| `GET` | `/reservas` | Lista todas as reservas |
| `GET` | `/reservas/:id` | Busca por `id` (404 se não existir) |
| `PUT` | `/reservas/:id` | Atualiza uma reserva |
| `DELETE` | `/reservas/:id` | Remove uma reserva |
| `GET` | `/health` | Health check |

Campos: `id`, `cliente`, `data`, `status`. Valores aceitos em `status`:
`pendente` (padrão), `confirmada`, `cancelada`.

## Estrutura

```
app/          API de Reservas (src/, Dockerfile, .dockerignore)
docker-compose.yml   API + PostgreSQL (ambiente local)
infra/        Terraform (modules/, backend/, main.tf, ...)
evidencias/   Evidências de build, compose, plan/apply/destroy
specs/        SPEC, PLAN e TASKS (Spec-Driven Development)
relatorio.md  Relatório do processo com IA
```

## Como rodar localmente

> Preenchido conforme as etapas de Docker e Compose forem concluídas.

## Infraestrutura AWS

> Preenchido na etapa de Terraform. Usa `LabRole`/`LabInstanceProfile`, região `us-east-1`;
> os recursos são destruídos (`terraform destroy`) após capturar as evidências.
