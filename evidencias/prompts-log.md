# Log de prompts — Claude Code (base da Questão 2 do relatório)

Registro honesto do uso da IA: o que foi pedido, o que ela gerou e o que precisou ser corrigido.

## 24/09/2026 — Especificação (SDD)
- **Prompt:** "Faça a leitura do provas/prova_primeiro_bimestre" → resumo do enunciado. Nome real do arquivo divergia (`prova-primeiro-bimestre.md`); a IA localizou pelo `ls`.
- **Prompt:** "Carregue o contexto das regras e dicas" → regras/dicas salvas na memória do projeto.
- **Prompt:** `/spec` com o enunciado → SPEC gerada (RF/CA).
- **Revisão crítica por subagente (SPEC):** encontrou lacunas — teardown do backend criado via CLI, CA do PR único, tags/outputs sem CA, estrutura de pastas, `skip_final_snapshot`. Corrigido na SPEC.
- **Revisão crítica por subagente (PLAN):** encontrou erros reais — RDS Postgres ≥15 exige SSL, API precisa de retry até o RDS aceitar conexão, senha no `user_data` pode vazar nas evidências, DynamoDB on-demand fora do free-tier, Node 20 em EOL, `repo_ref` sem tag antes do apply. Corrigido no PLAN.
- **Revisão crítica por subagente (TASKS):** achou o formato exigido do título do PR (validado no workflow da disciplina), variáveis obrigatórias no plan, tag intermediária para o `user_data`. Corrigido nas TASKS.
- **Decisão minha (humano):** aprovei SPEC/PLAN/TASKS; professor autorizou qualquer LLM, então declaro Claude Code; `entrega.md` segue exatamente o modelo do enunciado.
