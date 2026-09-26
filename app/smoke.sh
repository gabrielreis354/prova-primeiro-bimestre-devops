#!/usr/bin/env bash
# Smoke test da API de Reservas: CRUD completo + casos de erro.
# Uso: BASE_URL=http://localhost:3000 bash smoke.sh
set -u

BASE_URL="${BASE_URL:-http://localhost:3000}"
FALHAS=0

# req METODO CAMINHO [CORPO_JSON] -> define STATUS e CORPO
req() {
  local metodo="$1" caminho="$2" corpo="${3:-}"
  local args=(-s -o /tmp/smoke_body -w '%{http_code}' -X "$metodo" "$BASE_URL$caminho")
  [ -n "$corpo" ] && args+=(-H 'Content-Type: application/json' -d "$corpo")
  STATUS=$(curl "${args[@]}")
  CORPO=$(cat /tmp/smoke_body)
}

# checa DESCRICAO STATUS_ESPERADO [TRECHO_ESPERADO_NO_CORPO]
checa() {
  local descricao="$1" esperado="$2" trecho="${3:-}"
  if [ "$STATUS" = "$esperado" ] && { [ -z "$trecho" ] || [[ "$CORPO" == *"$trecho"* ]]; }; then
    echo "OK    $descricao (HTTP $STATUS)"
  else
    echo "FALHA $descricao: esperado HTTP $esperado${trecho:+ com '$trecho'}, veio HTTP $STATUS -> $CORPO"
    FALHAS=$((FALHAS + 1))
  fi
}

req GET /health;                                   checa "GET /health" 200 '"ok"'

req POST /reservas '{"cliente":"Ana","data":"2026-10-01T14:00:00Z"}'
checa "POST /reservas (status padrão)" 201 '"status":"pendente"'
ID=$(echo "$CORPO" | sed -E 's/.*"id":([0-9]+).*/\1/')

req GET /reservas;                                 checa "GET /reservas lista" 200 '"cliente":"Ana"'
req GET "/reservas/$ID";                           checa "GET /reservas/:id" 200 '"cliente":"Ana"'

req PUT "/reservas/$ID" '{"cliente":"Ana Souza","data":"2026-10-02T10:00:00Z","status":"confirmada"}'
checa "PUT /reservas/:id" 200 '"status":"confirmada"'
req GET "/reservas/$ID";                           checa "GET após PUT reflete a alteração" 200 '"cliente":"Ana Souza"'

req DELETE "/reservas/$ID";                        checa "DELETE /reservas/:id" 200 'Reserva removida'
req GET "/reservas/$ID";                           checa "GET após DELETE" 404

# Erros
req GET /reservas/999999;                          checa "GET id inexistente" 404
req PUT /reservas/999999 '{"cliente":"X","data":"2026-10-01T14:00:00Z","status":"pendente"}'
checa "PUT id inexistente" 404
req DELETE /reservas/999999;                       checa "DELETE id inexistente" 404
req POST /reservas '{"data":"2026-10-01T14:00:00Z"}';        checa "POST sem cliente" 400
req POST /reservas '{"cliente":"Ana"}';                       checa "POST sem data" 400
req POST /reservas '{"cliente":"Ana","data":"lixo"}';         checa "POST data inválida" 400
req POST /reservas '{"cliente":"Ana","data":"2026-10-01T14:00:00Z","status":"xyz"}'
checa "POST status inválido" 400
req PUT /reservas/1 '{"cliente":"Ana","data":"2026-10-01T14:00:00Z"}'
checa "PUT sem status" 400
req GET /reservas/abc;                             checa "GET id não numérico" 400
req GET /reservas/99999999999;                     checa "GET id acima do limite" 400
req POST /reservas '{quebrado';                    checa "POST JSON malformado" 400

echo
if [ "$FALHAS" -eq 0 ]; then echo "SMOKE OK: todos os testes passaram."; else echo "SMOKE FALHOU: $FALHAS teste(s)."; exit 1; fi
