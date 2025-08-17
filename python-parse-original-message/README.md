# python-parse-original-message

Сервис принимает сообщения из `monte-rent` (PHP, Symfony) через RabbitMQ. На первом этапе реализован только прием и логирование входящих сообщений. На следующем этапе подключим обработку оригинального сообщения ИИ‑агентом и обратную отправку результата в PHP.

## Что уже работает сейчас

- **Подписка на очередь RabbitMQ**: сервис подключается к очереди `to_parse_by_python_ai_agent` (по умолчанию) и принимает сообщения.
- **Логирование**: каждое поступившее сообщение логируется в контейнер и файл по пути `/home/askar/python-parse-original-message/logs/consumer.log`.
- **Формат сообщений**: ожидается JSON, соответствующий классу `App\Message\ToParseByPythonAiAgentMessage`:
  - `scrappedAdHash: string`
  - `messageOriginalText: string`
  - `hashTokenId: string`

Пример сообщения:

```json
{
  "scrappedAdHash": "e3b0c44298fc1c149afbf4c8996fb924",
  "messageOriginalText": "Сдаю 2к квартиру в центре...",
  "hashTokenId": "8c7f1a0d2a6b4a819a3c"
}
```

Если придет не‑JSON, он будет залогирован в «сыром» виде.

## Переменные окружения

Следующие переменные используются для подключения к RabbitMQ (есть значения по умолчанию):

- `RABBITMQ_HOST` (default: `rabbitmq`)
- `RABBITMQ_PORT` (default: `5672`)
- `RABBITMQ_USER` (default: `guest`)
- `RABBITMQ_PASSWORD` (default: `guest`)
- `RABBITMQ_VHOST` (default: `/`)
- `RABBITMQ_QUEUE` (default: `to_parse_by_python_ai_agent`)

Задайте их через `docker-compose.yml` или `.env` контейнера по необходимости.

## Запуск в Docker

Сервис описан в `docker-compose.yml` как `python-parse-original-message`. Для пересборки после изменений:

```bash
docker compose build python-parse-original-message
docker compose up -d python-parse-original-message
```

## Логи

- В контейнере: `docker logs -f <project>-python-parse-original-message`
- В файловой системе контейнера: `/home/askar/python-parse-original-message/logs/consumer.log`
- На хосте (смонтировано): `./python-parse-original-message/logs/consumer.log`

## Следующие шаги

- Подключить обработку сообщения ИИ‑агентом (на базе существующего `ai-agentt.py` или новой реализации) и возврат результата в `php-fpm` через RabbitMQ/Symfony Messenger.
