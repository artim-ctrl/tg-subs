import os
import logging
import subprocess
from uuid import uuid4
from telegram import Update
from telegram.ext import ApplicationBuilder, MessageHandler, ContextTypes, filters

BOT_TOKEN = os.getenv("BOT_TOKEN")

logging.basicConfig(level=logging.INFO)
TMP_DIR = "/data"
os.makedirs(TMP_DIR, exist_ok=True)

def process_whisper(input_file):
    """
    Process video with whisper.cpp to generate transcription and subtitled video
    Equivalent to run_whisper.sh in Python
    """
    basename = os.path.basename(input_file).split('.')[0]
    wav_path = f"/data/{basename}.wav"
    output_base = f"/data/{basename}"
    subtitled_path = f"/data/{basename}_subtitled.mp4"
    model = "/app/whisper.cpp/models/ggml-small.bin"
    
    # Check if model exists
    if not os.path.exists(model):
        raise FileNotFoundError(f"Model file not found: {model}")
    
    # Extract audio
    logging.info("[*] Extracting audio...")
    subprocess.run([
        "ffmpeg", "-y", "-i", input_file, 
        "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", wav_path
    ], check=True)
    
    # Transcribe with whisper.cpp
    logging.info("[*] Transcribing with whisper.cpp...")
    subprocess.run([
        "/app/whisper.cpp/build/bin/whisper-cli", 
        "-m", model, "-l", "ru", "-f", wav_path, 
        "-of", output_base, "-otxt", "-osrt"
    ], check=True)
    
    # Embed subtitles into video
    logging.info("[*] Embedding subtitles into video...")
    srt_path = f"{output_base}.srt"
    subprocess.run([
        "ffmpeg", "-y", "-i", input_file,
        "-vf", f"subtitles='{srt_path}':force_style='FontName=Arial,FontSize=20,Outline=1,Shadow=1,MarginV=20'",
        "-c:a", "copy", subtitled_path
    ], check=True)
    
    logging.info(f"[*] Done. Output: {subtitled_path}")
    return subtitled_path

async def handle_video(update: Update, context: ContextTypes.DEFAULT_TYPE):
    message = update.effective_message

    if message.video_note:
        file = await context.bot.get_file(message.video_note.file_id)
    elif message.video:
        file = await context.bot.get_file(message.video.file_id)
    else:
        await message.reply_text("Please send a video note or video.")
        return

    uid = str(uuid4())[:8]
    mp4_path = os.path.join(TMP_DIR, f"{uid}.mp4")
    srt_path = os.path.join(TMP_DIR, f"{uid}.srt")
    subtitled_path = os.path.join(TMP_DIR, f"{uid}_subtitled.mp4")

    await file.download_to_drive(mp4_path)

    try:
        # Process video with Python function
        process_whisper(mp4_path)

        # Send video back with subtitles
        with open(subtitled_path, "rb") as f:
            await message.reply_video(video=f)

    except subprocess.CalledProcessError as e:
        logging.exception("Error processing video")
        await message.reply_text(f"⚠️ Error processing video.")

    finally:
        # Clean up temporary files
        for file_path in [mp4_path, srt_path, subtitled_path, mp4_path.replace(".mp4", ".wav"), mp4_path.replace(".mp4", ".txt")]:
            try:
                if os.path.exists(file_path):
                    os.remove(file_path)
            except Exception:
                pass

if __name__ == "__main__":
    app = ApplicationBuilder().token(BOT_TOKEN).build()
    app.add_handler(MessageHandler(filters.VIDEO_NOTE | filters.VIDEO, handle_video))
    app.run_polling()
