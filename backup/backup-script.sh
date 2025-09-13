#!/bin/bash

# Odoo Database and File-store Backup Script
# This script creates backups of PostgreSQL database and Odoo file-store

set -e

# Configuration
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="odoo"
DB_HOST="postgres-service"
DB_USER="odoo"
DB_PORT="5432"
ODOO_FILESTORE="/var/lib/odoo/filestore"
S3_BUCKET="your-backup-bucket"  # Replace with your S3 bucket
AWS_REGION="us-west-2"  # Replace with your AWS region

# Create backup directory
mkdir -p $BACKUP_DIR

# Database backup
echo "Starting database backup..."
pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME > $BACKUP_DIR/odoo_db_$DATE.sql

# Compress database backup
gzip $BACKUP_DIR/odoo_db_$DATE.sql

# File-store backup
echo "Starting file-store backup..."
if [ -d "$ODOO_FILESTORE" ]; then
    tar -czf $BACKUP_DIR/odoo_filestore_$DATE.tar.gz -C $(dirname $ODOO_FILESTORE) $(basename $ODOO_FILESTORE)
else
    echo "Warning: File-store directory not found at $ODOO_FILESTORE"
fi

# Upload to S3 (requires AWS CLI to be installed and configured)
echo "Uploading backups to S3..."
if command -v aws &> /dev/null; then
    aws s3 cp $BACKUP_DIR/odoo_db_$DATE.sql.gz s3://$S3_BUCKET/database/
    aws s3 cp $BACKUP_DIR/odoo_filestore_$DATE.tar.gz s3://$S3_BUCKET/filestore/
    
    # Clean up local backups older than 7 days
    find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
    find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
    
    echo "Backup completed successfully!"
else
    echo "Warning: AWS CLI not found. Backups saved locally only."
fi

# Send notification (optional - requires curl and webhook URL)
WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"  # Replace with your webhook
if [ ! -z "$WEBHOOK_URL" ] && command -v curl &> /dev/null; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"Odoo backup completed successfully at $(date)\"}" \
        $WEBHOOK_URL
fi
