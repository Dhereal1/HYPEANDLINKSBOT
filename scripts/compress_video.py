#!/usr/bin/env python3
"""Compress a video file to approximately target_size_mb, keeping the extension."""
import os
import re
import subprocess

# Use imageio-ffmpeg's bundled ffmpeg (includes ffmpeg only, not ffprobe)
try:
    import imageio_ffmpeg
    FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
except Exception:
    FFMPEG = "ffmpeg"


def get_duration_seconds(path: str) -> float:
    """Get video duration in seconds (ffmpeg -i stderr parsing)."""
    result = subprocess.run(
        [FFMPEG, "-i", path],
        capture_output=True, text=True
    )
    # Parse "Duration: 00:01:30.50," from stderr
    m = re.search(r"Duration:\s*(\d+):(\d+):(\d+)[.,](\d+)", result.stderr)
    if not m:
        raise RuntimeError("Could not determine video duration")
    h, mm, s = map(int, m.groups()[:3])
    frac = m.group(4)
    frac_sec = int(frac) / (10 ** len(frac))
    return h * 3600 + mm * 60 + s + frac_sec


def compress_video(
    input_path: str,
    output_path: str | None = None,
    target_mb: float = 22.0,
    audio_bitrate: str = "128k",
) -> str:
    """Compress video to ~target_mb. Returns output path."""
    if not os.path.isfile(input_path):
        raise FileNotFoundError(f"Input not found: {input_path}")

    base, ext = os.path.splitext(input_path)
    if output_path is None:
        output_path = f"{base}_compressed{ext}"

    duration = get_duration_seconds(input_path)
    # Request ~15% over target; encoder often undershoots
    target_bits = int(target_mb * 1.15 * 8 * 1024 * 1024)
    audio_bps = 128 * 1024
    video_bps = int((target_bits / duration) - audio_bps)
    video_bps = max(100_000, video_bps)
    video_k = f"{video_bps // 1000}k"

    # Single-pass CRF-like targeting; two-pass would be more accurate but slower
    # Using -b:v for target bitrate
    cmd = [
        FFMPEG, "-y", "-i", input_path,
        "-c:v", "libx264", "-b:v", video_k, "-maxrate", video_k, "-bufsize", f"{video_bps * 2 // 1000}k",
        "-c:a", "aac", "-b:a", audio_bitrate,
        output_path
    ]
    subprocess.run(cmd, check=True)
    return output_path


def main():
    input_path = r"C:\Users\ASUS\Videos\2026-02-17 02-38-02.mp4"
    out = compress_video(input_path, target_mb=30.0)  # Encoder undershoots; ~22 MB output
    size_mb = os.path.getsize(out) / (1024 * 1024)
    print(f"Created: {out}")
    print(f"Size: {size_mb:.2f} MB")


if __name__ == "__main__":
    main()
