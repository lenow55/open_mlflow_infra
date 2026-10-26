#!/bin/sh

set -e

# --- Константы ---
BACKUP_DIR="/backup"
DATA_DIR="/data"
RESTORE_UID="10001"
ARCHIVE_NAME="data.tar.gz"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"
FLAG_FILE="${BACKUP_DIR}/restored_flag"

# --- Логирование в стандартный вывод ---
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

case "${BACKUP}" in
1)
  log "=== Режим: бэкап ==="

  log "Удаляем все файлы в ${BACKUP_DIR}"
  mkdir -p "${BACKUP_DIR}"
  find "${BACKUP_DIR}" -mindepth 1 ! -name "stub" -delete

  log "Собираем tar-архив ${DATA_DIR} -> ${ARCHIVE_PATH}"
  tar -czf "${ARCHIVE_PATH}" -C / data

  log "Устанавливаем владельца 1000:1000 и права 666 на ${ARCHIVE_PATH}"
  chown 1000:1000 "${ARCHIVE_PATH}"
  chmod 666 "${ARCHIVE_PATH}"

  log "Бэкап завершён успешно"
  ;;

0)
  log "=== Режим: восстановление ==="

  if [ -f "${FLAG_FILE}" ]; then
    log "Данные уже восстановлены. Для повторной загрузки удалите файл-флаг: ${FLAG_FILE}"
    exit 0
  fi

  if [ ! -f "${ARCHIVE_PATH}" ]; then
    log "Предупреждение: архив ${ARCHIVE_PATH} не найден в ${BACKUP_DIR}, восстановление пропущено"
    exit 0
  fi

  log "Читаем архив ${ARCHIVE_PATH}"

  log "RESTORE_UID=${RESTORE_UID}"

  log "Распаковываем архив в ${DATA_DIR}"
  mkdir -p "${DATA_DIR}"
  tar -xzf "${ARCHIVE_PATH}" -C /

  log "Устанавливаем UID ${RESTORE_UID} и права 744 для ${DATA_DIR}"
  chown -R "${RESTORE_UID}:${RESTORE_UID}" "${DATA_DIR}"
  chmod -R 744 "${DATA_DIR}"

  log "Создаём файл-флаг ${FLAG_FILE}"
  touch "${FLAG_FILE}"

  log "Восстановление завершено успешно"
  ;;

*)
  echo "Ошибка: BACKUP должна быть 1 (бэкап) или 0 (восстановление). Текущее значение: '${BACKUP}'" >&2
  exit 1
  ;;
esac
