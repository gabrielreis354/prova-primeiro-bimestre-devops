# Análise: a API da Aula 07 pode ser usada na prova?

Fonte analisada: `devops_20262/entregas/aula-07/6325149/` (`server.js`, `package.json`) e `aula-07/TF.md`.
Referência: requisitos da API da prova (enunciado, seção "Rotas obrigatórias") e SPEC RF1–RF7.

| Requisito da prova | API da Aula 07 | Atende? |
|---|---|---|
| Recurso `reservas` com `id`, `cliente`, `data`, `status` | Reserva tem `id`, `salaId`, `funcionario`, `inicio`, `fim` (sem `cliente`, `data`, `status`) | Não |
| `POST /reservas` valida campos obrigatórios | Existe, mas valida outro modelo (funcionario, inicio, fim, salaId) | Parcial |
| `GET /reservas` lista todas | Existe (com filtro `?funcionario=`) | Sim (modelo diferente) |
| `GET /reservas/:id` (404 se não existir) | **Não existe** | Não |
| `PUT /reservas/:id` | **Não existe** | Não |
| `DELETE /reservas/:id` | Existe (retorna 200 com mensagem) | Sim |
| `GET /health` | Existe como `/saude` | Não (nome diferente) |
| Persistir em **PostgreSQL** (nunca em memória) | Dados em arrays em memória (por exigência do TF07) | **Não — eliminatório** |
| Config via env para banco (`DB_*`), SSL no RDS, retry | Ausente (só `PORT`) | Não |
| Roda em Docker/Compose/EC2 com RDS | Sem Dockerfile, sem driver de banco | Não |
| Extras não pedidos | Recurso `salas`, conflito de horário (409) | Fora do escopo da prova (SPEC: sem extras) |

## Veredito
**Não usar como base.** Atende ~2 de 7 rotas e viola o requisito central (PostgreSQL). Adaptar exigiria trocar o modelo, criar 2 rotas, renomear `/saude`, reescrever a persistência e remover `salas`: praticamente uma API nova.

## O que se reaproveita (padrões, não código)
- Stack Express + `express.json()` e estrutura simples de rotas.
- Validação manual com `400` e mensagem clara; `404` com id inexistente.
- Normalização com `trim()`; `201` em criação.

## Ressalvas de conformidade
- O enunciado pede o CRUD "do zero" e o histórico Git deve refletir trabalho real (Regra 4); copiar a API da Aula 07 geraria commits sem evolução real e um modelo que não é o da prova.
- O repo da prova é separado da entrega da Aula 07; nada de lá deve ser copiado para `entregas/` ou vice-versa.
- `express@4.18.2` (fixado na Aula 07): na API da prova usar Express 4 atual (`^4`), verificado com `npm audit` na T06.
