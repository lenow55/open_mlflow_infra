# Mlflow Compose

## Назначение

Репозиторий, предоставляющий шаблон для развёртывания
инфраструктуры mlflow.

Основная идея при создании этого проекта:
Mlflow поддерживает работу только с экспериментами,
которые не сепарированы между проектами.
Мне хотелось иметь разные серверы Mlflow для разных
рабочих проектов, чтобы эксперименты не перемешивались.

## Архитектура шаблона

<p align="center">
  <a href="https://gist.githubusercontent.com/angryflaren/31d6b0081d05f51a53c14a798a682e82/raw/mlflow_infra_overview.svg" target="_blank">
    <img src="https://gist.githubusercontent.com/angryflaren/31d6b0081d05f51a53c14a798a682e82/raw/mlflow_infra_overview.svg" alt="Архитектура MLflow" width="100%">
  </a>
  <br>
  <sub><i>💡 Нажмите на схему, чтобы открыть версию в полном размере</i></sub>
</p>

<details>
<summary><b>📂 Структура директорий и файлов проекта</b></summary>
<br>

```txt
open_mlflow_infra
 ├╴  rustfs
 │ ├╴  buckets_list.txt - список бакетов rustfs под разные проекты
 │ ├╴  rustfs.env - переменные для контейнера rustfs
 │ └╴  rustfs_init.sh - команды для создания бакетов в rustfs
 ├╴  rustfs_data - локальная директория для хранения данных S3 (bind-mount)
 ├╴  mlflow
 │ ├╴  envs - папка с окружениями mlflow
 │ │ └╴  test_project.env - окружение тестового проекта в mlflow
 │ │ ... - сюда можно добавлять свои окружения
 │ ├╴  clean_del.sql - команды sql для полного удаления экспериментов из БД
 │ ├╴  entrypoint.sh - команда запуска mlflow сервера (можно поменять на свою)
 │ └╴  s3_connect.env - переменные для подключения к S3 (rustfs) из mlflow
 ├╴  postgres
 │ ├╴  postgres.env - переменные для postgres контейнера
 │ └╴  projects_db_configs.json - json список с базами данных для проектов
 ├╴  postgres_data - локальная директория для хранения данных БД (bind-mount)
 ├╴  README.md - документация по проекту
 ├╴  compose.yaml - файл с инфраструктурой для mlflow (db, s3, init db/s3)
 ├╴  .env - здесь можно задать какой проект запускать
 └╴  test_flow.compose.yaml - compose файл с сервером mlflow для проекта
```
</details>

## Запуск

### Тестовый проект

Для запуска тестового проекта нужно ввести:

```bash
docker compose up -d
```

После этого поднимется инфраструктура Mlflow.

Адреса:

- Mlflow: `http://localhost:5801`
- postgres: `localhost:8533`
- rustfs api: `localhost:9574`
- rustfs ui: `http://localhost:9321`

По умолчанию будет создан бакет `bucket1` в rustfs.
В postgres будет создана база `mlflow` для проекта test

### Рабочий проект

Для запуска рабочего проекта необходимо добавить его имя compose
конфигурации в файл `.env`.

Например, вы создали новый проект в файле `new-project.compose.yaml`.
Вам для его запуска нужно ввести команду:

```bash
docker compose -f compose.yaml -f new-project.compose.yaml up -d
```

Можно не вводить эту длинную команду, а изменить `.env` файл:

```env
COMPOSE_FILE='./compose.yaml,./new-project.compose.yaml'
COMPOSE_PATH_SEPARATOR=','
```

## Настройка

Чтобы создать свой проект, нужно провести следующие манипуляции:

1. указать имя бакета для проекта в файле `rustfs/buckets_list.txt`
(сохранять файл нужно обязательно в unix формате **LF line end**)
[info](https://labex.io/tutorials/linux-how-to-normalize-line-endings-in-linux-text-files-418212)
2. в файле `postgres/projects_db_configs.json` добавить конфигурацию бд
проекта в список `db_projects_configs`. Нужно указать
пользователя, имя бд, пароль подключения
3. в папку `mlflow/envs/` добавить файл с переменными окружения
mlflow для подключения к базе и s3. Создавать по аналогии с
[примером](./mlflow/envs/test_project.env)
4. наконец, по аналогии с [файлом](./test_flow.compose.yaml)
создать свою конфигурацию compose для проекта.
Обязательно нужно поменять:

## Используемые контейнеры

В данном проекте используются кастомные контейнеры:

- [lenow/mlflow-server](https://hub.docker.com/r/lenow/mlflow-server) - сервер mlflow
- [lenow/sql-initer](https://hub.docker.com/r/lenow/sql-initer) - создание баз данных
по конфигурации

Посмотреть код этих контейнеров и собрать их самостоятельно
можно [здесь](https://github.com/lenow55/open_mlflow_docker)
