#!/bin/bash

# Find the script's own directory to reliably locate config files
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export PGPASSFILE="${SCRIPT_DIR}/.pgpass"

set -euo pipefail

# --- Default Configuration ---
BACKUP_DIR="backups"
DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"
LOG_FILE="db_backup.log"

# --- Script Variables ---
TEMP_DIR=$(mktemp -d)

# --- Functions ---
log_message() {
  # Check if LOG_FILE is set and not empty, otherwise just echo
  if [ -n "${LOG_FILE:-}" ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "${LOG_FILE}"
  else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
  fi
}

display_help() {
    echo "Usage: $0 [-d BACKUP_DIR] [-u DB_USER] [-h DB_HOST] [-p DB_PORT] [-l LOG_FILE]"
    echo ""
    echo "A script to back up PostgreSQL databases."
    echo ""
    echo "Options:"
    echo "  -d    Path to the backup directory. Default: ${BACKUP_DIR}"
    echo "  -u    Database user. Default: ${DB_USER}"
    echo "  -h    Database host. Default: ${DB_HOST}"
    echo "  -p    Database port. Default: ${DB_PORT}"
    echo "  -l    Path to the log file. Default: ${LOG_FILE}"
    echo ""
    echo "Password should be configured in the .pgpass file in the script's directory."
    echo "The file must have permissions set to 600 (e.g., chmod 600 .pgpass)."
    echo ""
    echo "Format:  hostname:port:database:username:password"
    echo "Example: localhost:5432:*:postgres:mysecretpassword"
    exit 0
}

cleanup() {
  if [ -d "${TEMP_DIR}" ]; then
    log_message "INFO: Cleaning up temporary files..."
    rm -rf "${TEMP_DIR}"
  fi
}

trap cleanup EXIT

# --- Main Logic ---
main() {
  # Handle --help as a special case before getopts
  if [[ " $@ " =~ " --help " ]]; then
    display_help
  fi

  # Parse command-line options
  while getopts ":d:u:h:p:l:" opt; do
    case ${opt} in
      d ) BACKUP_DIR=$OPTARG;;
      u ) DB_USER=$OPTARG;;
      h ) DB_HOST=$OPTARG;;
      p ) DB_PORT=$OPTARG;;
      l ) LOG_FILE=$OPTARG;;
      \? ) display_help;;
    esac
  done
  shift $((OPTIND - 1))

  # --- Start Execution ---
  log_message "INFO: --- Backup process started for ${DB_HOST}:${DB_PORT} ---"

  mkdir -p "${BACKUP_DIR}"
  
  # Dynamic variables that depend on config
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  ARCHIVE_NAME="pg_backup_${TIMESTAMP}.tar.gz"
  ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"

  log_message "INFO: Fetching database list..."
  DB_LIST=$(psql -l -t -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d' | grep -v -E '^(template0|template1|postgres)$' || true)

  if [ -z "${DB_LIST}" ]; then
    log_message "WARNING: No user databases found to back up. Exiting."
    exit 0
  fi

  log_message "INFO: Databases to be backed up:\n${DB_LIST}"

  log_message "INFO: Starting database dumps..."
  for db in ${DB_LIST}; do
    log_message "INFO: Dumping database: ${db}..."
    pg_dump -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${db}" -f "${TEMP_DIR}/${db}.sql"
    log_message "INFO: Dump of ${db} completed."
  done
  log_message "INFO: All database dumps completed successfully."

  log_message "INFO: Creating compressed archive..."
  tar -czf "${ARCHIVE_PATH}" -C "${TEMP_DIR}" .
  log_message "INFO: Archive created at ${ARCHIVE_PATH}"

  log_message "INFO: Testing archive integrity..."
  if gzip -t "${ARCHIVE_PATH}"; then
    log_message "INFO: Archive integrity test passed."
  else
    log_message "ERROR: Archive is corrupt! Removing invalid backup."
    rm "${ARCHIVE_PATH}"
    exit 1
  fi

  log_message "SUCCESS: --- Backup process finished successfully ---"
}

# --- Execution ---
main "$@"