#!/bin/bash

# Odoo Database and File-store Backup Script
# Hardened: strict mode, env-driven configuration, optional S3 upload, configurable retention

set -Eeuo pipefail
IFS=$'\n\t'

# Configuration via environment variables (with sane defaults)
BACKUP_DIR=${BACKUP_DIR:-"/backups"}
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME=${DB_NAME:-"odoo"}
DB_HOST=${DB_HOST:-"postgres-service"}
DB_USER=${DB_USER:-"odoo"}
DB_PORT=${DB_PORT:-"5432"}
# Use PGPASSWORD from env for pg_dump authentication when provided
# export PGPASSWORD before running this script or inject via Kubernetes Secret
ODOO_FILESTORE=${ODOO_FILESTORE:-"/var/lib/odoo/filestore"}
RETENTION_DAYS=${RETENTION_DAYS:-"7"}

# S3 upload controls
ENABLE_S3_UPLOAD=${ENABLE_S3_UPLOAD:-"false"}  # true/false
S3_BUCKET=${S3_BUCKET:-""}
S3_DB_PREFIX=${S3_DB_PREFIX:-"database"}
S3_FILESTORE_PREFIX=${S3_FILESTORE_PREFIX:-"filestore"}
AWS_REGION=${AWS_REGION:-""}

echo "[INFO] Starting Odoo backup at $(date)"
echo "[INFO] Backup directory: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

# Database backup
echo "[INFO] Creating database backup for '${DB_NAME}'..."
DB_BACKUP_PATH="${BACKUP_DIR}/odoo_db_${DATE}.sql"
COMPRESSED_DB_BACKUP_PATH="${DB_BACKUP_PATH}.gz"
pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" > "${DB_BACKUP_PATH}"
gzip "${DB_BACKUP_PATH}"

# File-store backup
echo "[INFO] Creating filestore backup from '${ODOO_FILESTORE}'..."
FILESTORE_BACKUP_PATH="${BACKUP_DIR}/odoo_filestore_${DATE}.tar.gz"
if [ -d "${ODOO_FILESTORE}" ]; then
  tar -czf "${FILESTORE_BACKUP_PATH}" -C "$(dirname "${ODOO_FILESTORE}")" "$(basename "${ODOO_FILESTORE}")"
else
  echo "[WARN] Filestore directory not found at '${ODOO_FILESTORE}'. Skipping filestore backup."
  FILESTORE_BACKUP_PATH=""
fi

# Optional S3 upload
if [ "${ENABLE_S3_UPLOAD}" = "true" ]; then
  if command -v aws &> /dev/null; then
    if [ -n "${AWS_REGION}" ]; then
      AWS_ARGS=("--region" "${AWS_REGION}")
    else
      AWS_ARGS=()
    fi
    if [ -z "${S3_BUCKET}" ]; then
      echo "[ERROR] ENABLE_S3_UPLOAD=true but S3_BUCKET is not set." >&2
      exit 1
    fi
    echo "[INFO] Uploading backups to s3://${S3_BUCKET}/..."
    aws "${AWS_ARGS[@]}" s3 cp "${COMPRESSED_DB_BACKUP_PATH}" "s3://${S3_BUCKET}/${S3_DB_PREFIX}/"
    if [ -n "${FILESTORE_BACKUP_PATH}" ]; then
      aws "${AWS_ARGS[@]}" s3 cp "${FILESTORE_BACKUP_PATH}" "s3://${S3_BUCKET}/${S3_FILESTORE_PREFIX}/"
    fi
  else
    echo "[WARN] AWS CLI not found. Skipping S3 upload."
  fi
fi

# Local retention policy
echo "[INFO] Applying local retention policy: keep ${RETENTION_DAYS} days"
find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +"${RETENTION_DAYS}" -delete || true
find "${BACKUP_DIR}" -name "*.tar.gz" -mtime +"${RETENTION_DAYS}" -delete || true

echo "[INFO] Backup completed successfully at $(date)"

# Optional notification (Slack webhook)
WEBHOOK_URL=${WEBHOOK_URL:-""}
if [ -n "${WEBHOOK_URL}" ] && command -v curl &> /dev/null; then
  curl -sS -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"Odoo backup completed successfully at $(date)\"}" \
    "${WEBHOOK_URL}" || true
fi
