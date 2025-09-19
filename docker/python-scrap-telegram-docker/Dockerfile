# Используем официальный образ Python
FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
    build-essential \
    libffi-dev \
    libpq-dev \
    curl ca-certificates

# uv Package Manager
# Download the latest installer
ADD https://astral.sh/uv/install.sh /uv-installer.sh

# Run the installer then remove it
RUN sh /uv-installer.sh && rm /uv-installer.sh

# Ensure the installed binary is on the `PATH`
ENV PATH="/root/.local/bin/:$PATH"

WORKDIR /home/askar/python-scrap-telegram

COPY requirements.txt .

# Use uv to install dependencies
RUN uv pip install -r requirements.txt --system

CMD ["python3", "scrap_telegram.py"]
