#!/bin/sh

set -e

# --- Константы ---
BACKUP_DIR="/backup"
DATA_DIR="/data"
DB_DIR="/db"

DATA_ARCHIVE="${BACKUP_DIR}/data.tar.gz"
DB_ARCHIVE="${BACKUP_DIR}/db.tar.gz"
FLAG_FILE="${BACKUP_DIR}/restored_flag"

# --- Логирование в стандартный вывод ---
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# --- Справка по использованию ---
usage() {
  cat <<EOF
Использование: $0 [ОПЦИЯ]

Опции:
  --backup    Создать архивы директорий ${DATA_DIR} и ${DB_DIR} в ${BACKUP_DIR} (перезаписывает существующие)
  --restore   Восстановить данные из архивов, если отсутствует флаг ${FLAG_FILE}
EOF
}

# Если аргументы не переданы, выводим справку и выходим с кодом 0
if [ $# -eq 0 ]; then
  usage
  exit 0
fi

case "$1" in
--backup)
  log "=== Режим: бэкап ==="

  mkdir -p "${BACKUP_DIR}"

  # Бэкап /data (tar -czf перезаписывает существующий архив по умолчанию)
  if [ -d "${DATA_DIR}" ]; then
    log "Собираем tar-архив ${DATA_DIR} -> ${DATA_ARCHIVE}"
    tar -czf "${DATA_ARCHIVE}" -C / data
    log "Устанавливаем широкие права (666) на ${DATA_ARCHIVE}"
    chmod 666 "${DATA_ARCHIVE}"
  else
    log "Предупреждение: директория ${DATA_DIR} не существует, пропускаем"
  fi

  # Бэкап /db
  if [ -d "${DB_DIR}" ]; then
    log "Собираем tar-архив ${DB_DIR} -> ${DB_ARCHIVE}"
    tar -czf "${DB_ARCHIVE}" -C / db
    log "Устанавливаем широкие права (666) на ${DB_ARCHIVE}"
    chmod 666 "${DB_ARCHIVE}"
  else
    log "Предупреждение: директория ${DB_DIR} не существует, пропускаем"
  fi

  log "Бэкап завершён успешно"
  ;;

--restore)
  log "=== Режим: восстановление ==="

  if [ -f "${FLAG_FILE}" ]; then
    log "ВНИМАНИЕ: Данные уже были восстановлены ранее. Для повторной загрузки удалите файл-флаг: ${FLAG_FILE}"
    exit 0
  fi

  RESTORED_ANY=0

  # Восстановление /data
  if [ -f "${DATA_ARCHIVE}" ]; then
    log "Распаковываем архив ${DATA_ARCHIVE} в ${DATA_DIR}"
    mkdir -p "${DATA_DIR}"
    tar -xzf "${DATA_ARCHIVE}" -C /
    RESTORED_ANY=1
  else
    log "Предупреждение: архив ${DATA_ARCHIVE} не найден, восстановление ${DATA_DIR} пропущено"
  fi

  # Восстановление /db
  if [ -f "${DB_ARCHIVE}" ]; then
    log "Распаковываем архив ${DB_ARCHIVE} в ${DB_DIR}"
    mkdir -p "${DB_DIR}"
    tar -xzf "${DB_ARCHIVE}" -C /
    RESTORED_ANY=1
  else
    log "Предупреждение: архив ${DB_ARCHIVE} не найден, восстановление ${DB_DIR} пропущено"
  fi

  # Создаём флаг только если хотя бы один архив был распакован
  if [ "${RESTORED_ANY}" -eq 1 ]; then
    log "Создаём файл-флаг ${FLAG_FILE}"
    touch "${FLAG_FILE}"
    log "Восстановление завершено успешно"
  else
    log "Предупреждение: ни один архив не был найден, файл-флаг не создан"
  fi
  ;;

*)
  usage
  exit 0
  ;;
esac
