import json
import logging
import os
import sys
import time
from typing import Optional

import pika
from dotenv import load_dotenv, find_dotenv

# Load env from .env if present (container env vars still take precedence)
load_dotenv(find_dotenv())

# Configure logging to stdout and file
LOG_DIR = "/home/askar/python-parse-original-message/logs"
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, "consumer.log")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
    ],
)
logger = logging.getLogger(__name__)


def get_env(name: str, default: Optional[str] = None) -> str:
    val = os.getenv(name)
    if val is None or val == "":
        if default is None:
            raise RuntimeError(f"Environment variable {name} is required")
        return default
    return val


def connect_with_retry(max_retries: int = 30, retry_delay: float = 2.0) -> pika.adapters.blocking_connection.BlockingConnection:
    host = get_env("RABBITMQ_HOST", "rabbitmq")
    port = int(get_env("RABBITMQ_PORT", "5672"))
    user = get_env("RABBITMQ_USER", "guest")
    password = get_env("RABBITMQ_PASSWORD", "guest")
    vhost = get_env("RABBITMQ_VHOST", "/")

    credentials = pika.PlainCredentials(user, password)
    params = pika.ConnectionParameters(
        host=host,
        port=port,
        virtual_host=vhost,
        credentials=credentials,
        heartbeat=60,
        blocked_connection_timeout=300,
    )

    attempt = 0
    while True:
        attempt += 1
        try:
            logger.info("Connecting to RabbitMQ at %s:%s vhost=%s user=%s (attempt %s)", host, port, vhost, user, attempt)
            return pika.BlockingConnection(params)
        except Exception as e:
            if attempt >= max_retries:
                logger.exception("Failed to connect to RabbitMQ after %s attempts", attempt)
                raise
            logger.warning("RabbitMQ not ready: %s. Retrying in %ss...", e, retry_delay)
            time.sleep(retry_delay)


def main() -> None:
    queue = get_env("RABBITMQ_QUEUE", "to_parse_by_python_ai_agent")

    connection = connect_with_retry()
    channel = connection.channel()
    channel.queue_declare(queue=queue, durable=True)

    logger.info("Waiting for messages on queue '%s'. Press CTRL+C to exit.", queue)

    def on_message(ch, method, properties, body: bytes):
        raw = body.decode("utf-8", errors="replace")
        # Try to pretty print JSON if possible for readability
        try:
            parsed = json.loads(raw)
            pretty = json.dumps(parsed, ensure_ascii=False, indent=2)
            logger.info("Received message (JSON):\n%s", pretty)
        except json.JSONDecodeError:
            logger.info("Received message (raw): %s", raw)
        finally:
            # We only log for now, acknowledge to remove message
            ch.basic_ack(delivery_tag=method.delivery_tag)

    channel.basic_qos(prefetch_count=10)
    channel.basic_consume(queue=queue, on_message_callback=on_message)

    try:
        channel.start_consuming()
    except KeyboardInterrupt:
        logger.info("Shutting down consumer...")
    finally:
        try:
            if channel.is_open:
                channel.close()
        finally:
            if connection.is_open:
                connection.close()


if __name__ == "__main__":
    main()
