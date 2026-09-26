#!/usr/bin/env bash
# Cria o backend do remote state (S3 + DynamoDB) ANTES do terraform init.
# Feito via AWS CLI porque o SCP do Learner Lab bloqueia GetBucketObjectLockConfiguration
# no provider Terraform (aws_s3_bucket). Idempotente. Uso: bash bootstrap.sh
set -euo pipefail

REGION="us-east-1"
RA="6325149"
TABLE="technova-tflock"
KEY="prova/terraform.tfstate"
TAGS_S3='TagSet=[{Key=Project,Value=prova-primeiro-bimestre},{Key=Owner,Value=Gabriel-Reis-Cunha},{Key=RA,Value=6325149},{Key=ManagedBy,Value=bootstrap.sh}]'
TAGS_DDB='Key=Project,Value=prova-primeiro-bimestre Key=Owner,Value=Gabriel-Reis-Cunha Key=RA,Value=6325149 Key=ManagedBy,Value=bootstrap.sh'
export AWS_PAGER="" AWS_DEFAULT_REGION="$REGION"

# Guardrail: nunca operar como root.
ARN=$(aws sts get-caller-identity --query Arn --output text)
[[ "$ARN" == *":root" ]] && { echo "ERRO: identidade root. Use o usuário/role do Lab."; exit 1; }
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="technova-tfstate-${RA}-${ACCOUNT_ID}"

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Bucket $BUCKET já existe."
else
  echo "Criando bucket $BUCKET..."
  aws s3api create-bucket --bucket "$BUCKET"   # us-east-1 não aceita LocationConstraint
fi
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-tagging --bucket "$BUCKET" --tagging "$TAGS_S3"

if aws dynamodb describe-table --table-name "$TABLE" >/dev/null 2>&1; then
  echo "Tabela $TABLE já existe."
else
  echo "Criando tabela $TABLE (PROVISIONED 1 RCU/1 WCU, free-tier)..."
  # shellcheck disable=SC2086
  aws dynamodb create-table --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PROVISIONED --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --tags $TAGS_DDB >/dev/null
  aws dynamodb wait table-exists --table-name "$TABLE"
fi

# Config parcial do backend (o bloco backend "s3" não aceita variáveis); fica fora do Git.
cat > "$(dirname "$0")/../backend.hcl" <<HCL
bucket         = "$BUCKET"
key            = "$KEY"
region         = "$REGION"
dynamodb_table = "$TABLE"
encrypt        = true
HCL
echo "Backend pronto. Gerado infra/backend.hcl (ignorado pelo Git)."
echo "Próximo passo: cd infra && terraform init -backend-config=backend.hcl"
