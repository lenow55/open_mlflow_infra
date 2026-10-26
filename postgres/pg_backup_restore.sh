#!/bin/sh

set -e

BACKUP_DIR="/backup"
DUMP_NAME="db.dump"
DUMP_PATH="${BACKUP_DIR}/${DUMP_NAME}"
FLAG_FILE="${BACKUP_DIR}/restored_flag"

DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${POSTGRES_USER:-user}"
DB_NAME="${DB_NAME:-mlflow}"
export PGPASSWORD="${POSTGRES_PASSWORD:-password}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

case "${BACKUP}" in
1)
  log "=== Режим: бэкап БД ==="

  log "Удаляем все файлы в ${BACKUP_DIR}"
  mkdir -p "${BACKUP_DIR}"
  find "${BACKUP_DIR}" -mindepth 1 ! -name "stub" -delete

  log "Создаём дамп базы '${DB_NAME}' (${DB_HOST}:${DB_PORT}) -> ${DUMP_PATH}"
  pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -F c -f "${DUMP_PATH}"

  log "Устанавливаем владельца 1000:1000 и права 666 на ${DUMP_PATH}"
  chown 1000:1000 "${DUMP_PATH}"
  chmod 666 "${DUMP_PATH}"

  log "Бэкап завершён успешно"
  ;;

0)
  log "=== Режим: восстановление БД ==="

  if [ -f "${FLAG_FILE}" ]; then
    log "Данные уже восстановлены. Для повторной загрузки удалите файл-флаг: ${FLAG_FILE}"
    exit 0
  fi

  if [ ! -f "${DUMP_PATH}" ]; then
    log "Предупреждение: дамп ${DUMP_PATH} не найден в ${BACKUP_DIR}, восстановление пропущено"
    exit 0
  fi

  log "Читаем дамп ${DUMP_PATH}"

  log "Восстанавливаем базу '${DB_NAME}' на ${DB_HOST}:${DB_PORT}"
  pg_restore -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" --clean --if-exists --no-owner "${DUMP_PATH}"

  log "Создаём файл-флаг ${FLAG_FILE}"
  touch "${FLAG_FILE}"
  chown 1000:1000 "${FLAG_FILE}"
  chmod 666 "${FLAG_FILE}"

  log "Восстановление завершено успешно"
  ;;

*)
  echo "Ошибка: BACKUP должна быть 1 (бэкап) или 0 (восстановление). Текущее значение: '${BACKUP}'" >&2
  exit 1
  ;;
esac

