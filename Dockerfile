FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    ffmpeg \
    python3 \
    python3-pip \
    python3-venv \
    libsndfile1 \
    libavdevice-dev \
    libavfilter-dev \
    libavformat-dev \
    libavcodec-dev \
    libswresample-dev \
    libswscale-dev \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Clone whisper.cpp
RUN git clone https://github.com/ggerganov/whisper.cpp.git /app/whisper.cpp

WORKDIR /app/whisper.cpp

# Build whisper.cpp
RUN mkdir -p build && cd build && \
    cmake .. && \
    make -j

# Download small model using repo script (better accuracy than tiny)
RUN ./models/download-ggml-model.sh small

WORKDIR /app

COPY requirements.txt /app/

RUN pip3 install --no-cache-dir -r requirements.txt

# Copy bot files
COPY bot.py /app/

# Verify model exists and is valid
RUN ls -la /app/whisper.cpp/models/ggml-small.bin && \
    test -s /app/whisper.cpp/models/ggml-small.bin

CMD ["python3", "/app/bot.py"]
