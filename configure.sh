#!/bin/bash

echo "--- Kubernetes Backup CronJob Configurator ---"
echo "Please provide the following details. Press Enter to accept the default value."
echo

# Read user input with defaults
read -p "Enter Kubernetes Namespace [default]: " NAMESPACE
NAMESPACE=${NAMESPACE:-default}

read -p "Enter Docker Image Name [your-repo/backup-tool:v1]: " IMAGE_NAME
IMAGE_NAME=${IMAGE_NAME:-your-repo/backup-tool:v1}

read -p "Enter Cron Schedule [0 2 * * *]: " CRON_SCHEDULE
CRON_SCHEDULE=${CRON_SCHEDULE:-0 2 * * * }

read -p "Enter Backup Path on Node [/mnt/k8s-backups]: " BACKUP_PATH
BACKUP_PATH=${BACKUP_PATH:-/mnt/k8s-backups}

read -p "Enter Database Service Host [postgres-db-service]: " DB_HOST
DB_HOST=${DB_HOST:-postgres-db-service}

read -p "Enter Database Port [5432]: " DB_PORT
DB_PORT=${DB_PORT:-5432}

read -p "Enter Database User [postgres]: " DB_USER
DB_USER=${DB_USER:-postgres}

echo -n "Enter Database Password: "
read -s DB_PASSWORD
echo
echo

# Check if password was entered
if [ -z "$DB_PASSWORD" ]; then
    echo "ERROR: Password cannot be empty."
    exit 1
fi

TEMPLATE_FILE="k8s-manifests.template.yaml"
OUTPUT_FILE="k8s-manifests.yaml"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ERROR: Template file not found: ${TEMPLATE_FILE}"
    exit 1
fi

echo "Generating ${OUTPUT_FILE} from ${TEMPLATE_FILE}..."

# Use a different delimiter for sed to avoid issues with slashes in paths/image names
sed -e "s|__NAMESPACE__|${NAMESPACE}|g" \
    -e "s|__IMAGE_NAME__|${IMAGE_NAME}|g" \
    -e "s|__CRON_SCHEDULE__|${CRON_SCHEDULE}|g" \
    -e "s|__BACKUP_PATH__|${BACKUP_PATH}|g" \
    -e "s|__DB_HOST__|${DB_HOST}|g" \
    -e "s|__DB_PORT__|${DB_PORT}|g" \
    -e "s|__DB_USER__|${DB_USER}|g" \
    -e "s|__DB_PASSWORD__|${DB_PASSWORD}|g" \
    "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

echo "Done. Your manifest file '${OUTPUT_FILE}' has been created."
echo "You can now apply it using: kubectl apply -f ${OUTPUT_FILE}"
