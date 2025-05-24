#!/bin/bash

# Проверка аргумента
if [ -z "$1" ]; then
    echo "Usage: docker run -v \$(pwd):/data whisper /data/video.mp4"
    exit 1
fi

INPUT="$1"
BASENAME=$(basename "$INPUT" | cut -d. -f1)
WAV="/data/${BASENAME}.wav"
MODEL="/app/whisper.cpp/models/ggml-tiny.bin"

# Извлекаем аудио
echo "[*] Extracting audio..."
ffmpeg -y -i "$INPUT" -ar 16000 -ac 1 -c:a pcm_s16le "$WAV"

# Распознаём
echo "[*] Transcribing with whisper.cpp..."
/app/whisper.cpp/build/bin/whisper-cli -m "$MODEL" -f "$WAV" -of "/data/${BASENAME}" -otxt -osrt

echo "[*] Done. Output: /data/${BASENAME}.srt and .txt"
