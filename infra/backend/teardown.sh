#!/usr/bin/env bash
# Remove o backend do remote state (bucket S3 versionado + tabela DynamoDB).
# Rodar SÓ depois do terraform destroy e de capturar as evidências de state/lock.
# aws s3 rm não basta: é preciso apagar todas as versões e delete markers. Uso: bash teardown.sh
set -euo pipefail

REGION="us-east-1"
RA="6325149"
TABLE="technova-tflock"
export AWS_PAGER="" AWS_DEFAULT_REGION="$REGION"

ARN=$(aws sts get-caller-identity --query Arn --output text)
[[ "$ARN" == *":root" ]] && { echo "ERRO: identidade root. Use o usuário/role do Lab."; exit 1; }
BUCKET="technova-tfstate-${RA}-$(aws sts get-caller-identity --query Account --output text)"

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Esvaziando versões e delete markers de $BUCKET..."
  for CAMPO in Versions DeleteMarkers; do
    while :; do
      LOTE=$(aws s3api list-object-versions --bucket "$BUCKET" --max-items 1000 \
        --query "{Objects: ${CAMPO}[].{Key:Key,VersionId:VersionId}}" --output json)
      [[ "$LOTE" == *'"Objects": null'* || "$LOTE" == *'"Objects": []'* ]] && break
      aws s3api delete-objects --bucket "$BUCKET" --delete "$LOTE" >/dev/null
    done
  done
  aws s3api delete-bucket --bucket "$BUCKET"
  echo "Bucket $BUCKET removido."
else
  echo "Bucket $BUCKET não existe."
fi

if aws dynamodb describe-table --table-name "$TABLE" >/dev/null 2>&1; then
  aws dynamodb delete-table --table-name "$TABLE" >/dev/null
  aws dynamodb wait table-not-exists --table-name "$TABLE"
  echo "Tabela $TABLE removida."
else
  echo "Tabela $TABLE não existe."
fi
rm -f "$(dirname "$0")/../backend.hcl"
