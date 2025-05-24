# syntax=docker/dockerfile:1
FROM debian:bullseye-slim

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    ffmpeg \
    wget \
    curl \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Клонируем и собираем whisper.cpp
WORKDIR /app
RUN git clone https://github.com/ggerganov/whisper.cpp.git
WORKDIR /app/whisper.cpp
RUN make

# Скачиваем tiny модель
RUN ./models/download-ggml-model.sh tiny

# Копируем скрипт запуска
WORKDIR /app
COPY run_whisper.sh .

# Разрешаем выполнение
RUN chmod +x run_whisper.sh

# Точка входа
ENTRYPOINT ["/app/run_whisper.sh"]
