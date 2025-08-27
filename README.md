# MonteRent

Монорепозиторий для платформы агрегирования и обработки объявлений о недвижимости.

Состоит из нескольких сервисов:
- monte-rent — backend на Symfony/Doctrine (PHP). Первичное сохранение объявлений, нормализация данных, подготовка к обработке ИИ-агентом, публикация событий.
- python-scrap-telegram — сбор объявлений и медиа из Telegram, публикация в очередь RabbitMQ.
- python-parse-original-message — парсинг исходного текста (ИИ/правила), логирование, вспомогательные агенты.

## Архитектура и потоки данных
1. Telegram-скрейпер (`python-scrap-telegram`) получает сообщения и фото, складывает фото в `monte-rent/public/downloads/`, отправляет события в RabbitMQ (очередь `download_telegram_photos`).
2. PHP backend (`monte-rent`) принимает входные данные, сохраняет `ScrappedAdEntity` в PostgreSQL:
   - нормализует текст (удаление хэштегов, очистка);
   - извлекает телефоны/хэштеги/площадь (`Extract*UseCase`);
   - готовит данные к последующей передаче в ИИ-агента (через очередь/события Mercure/Messenger).
3. `python-parse-original-message` читает задачи из `to_parse_by_python_ai_agent`, применяет правила/ИИ и возвращает обогащённые данные обратно в систему.

## Стек и инфраструктура
- Docker Compose: Postgres, RabbitMQ, PHP-FPM/CLI, Nginx, Node, Mercure, Loki/Promtail.
- БД: PostgreSQL (UUID PK, JSON-поля для сущностей Telegram, числовые координаты и проч.).
- Очереди: RabbitMQ (amqp).

## Запуск
- Скопируйте `.env` для docker-compose (если требуется) и задайте переменные окружения.
- Поднимите инфраструктуру:
```
docker compose up -d --build
```
- Инициализируйте схему БД (вариант для начального bootstrap):
```
psql -h localhost -p 54321 -U $DB_USER -d $DB_DATABASE -f init.sql
```
- Внутри PHP CLI контейнера доступны команды `make` (линт/тесты):
```
make phpunit
make cs-fix
make static-analyse
```

## Полезные пути
- Корневой SQL и документация: `init.sql`, `README.md` (этот файл)
- Backend (PHP): `monte-rent/`
- Telegram scraper: `python-scrap-telegram/`
- Python агент парсинга: `python-parse-original-message/`

## Логи и мониторинг
- Nginx: `logs/nginx/`
- PHP (Symfony): `monte-rent/var/log/`
- Прометей/Локи/Промтейл: базовая интеграция через `docker/`

## Лицензия
Проект частный. Все права защищены.
