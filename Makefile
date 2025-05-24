BOT_TOKEN ?= token

.PHONY: build run clean

build:
	docker build -t whisper-bot .

run:
	docker run --rm -e BOT_TOKEN=${BOT_TOKEN} whisper-bot

clean:
	rm -f data/*.wav data/*.txt data/*.srt data/*.mp4
