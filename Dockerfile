FROM debian:bullseye-slim

# Установка зависимостей
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    ffmpeg \
    curl \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Клонируем whisper.cpp и собираем
WORKDIR /app
RUN git clone https://github.com/ggerganov/whisper.cpp.git
WORKDIR /app/whisper.cpp
RUN mkdir -p build && cd build && cmake .. && make -j

# Скачиваем многоязычную модель (русский поддерживается)
RUN mkdir -p /app/whisper.cpp/models && \
    curl -L -o /app/whisper.cpp/models/ggml-tiny.bin \
    https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin

# Копируем скрипт внутрь
COPY run_whisper.sh /app/run_whisper.sh
RUN chmod +x /app/run_whisper.sh

# Команда по умолчанию
ENTRYPOINT ["/app/run_whisper.sh"]
