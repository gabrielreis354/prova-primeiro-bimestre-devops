#!/bin/bash
# Sobe a API de Reservas: clona o repositório na versão fixada, builda a imagem e roda o
# container apontando para o RDS. Log em /var/log/cloud-init-output.log.
# (Sem "set -x": o comando docker run contém a senha do banco.)
set -euo pipefail

dnf install -y docker git
systemctl enable --now docker

# A rede pode demorar alguns segundos após o boot: tenta o clone algumas vezes.
for i in 1 2 3 4 5; do
  git clone ${repo_url} /opt/app && break
  sleep 10
done
cd /opt/app
git checkout ${repo_ref}

docker build -t api-reservas ./app
docker run -d --name api --restart unless-stopped -p 3000:3000 \
  -e DB_HOST='${db_host}' \
  -e DB_NAME='${db_name}' \
  -e DB_USER='${db_user}' \
  -e DB_PASSWORD='${db_password}' \
  -e DB_SSL=true \
  api-reservas
