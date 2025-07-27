#!/usr/bin/env python3
"""
FFmpeg Bookmark Extractor
Reads bookmarks from MPV bookmark file and extracts video segments
"""

import re
import os
import subprocess
import sys
from pathlib import Path


def parse_bookmarks(bookmark_file):
    """Parse the bookmark file and return list of bookmarks"""
    bookmarks = {}

    if not os.path.exists(bookmark_file):
        print(f"Bookmark file '{bookmark_file}' not found!")
        return bookmarks

    with open(bookmark_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            # Parse format: "DATE TIME | FILENAME | HH:MM:SS.mmm | seconds_value seconds | FILENAME"
            parts = line.split(' | ')
            if len(parts) >= 4:
                date_time = parts[0]
                filename = parts[1]
                timestamp = parts[2]
                seconds_part = parts[3]

                # Extract seconds value
                seconds_match = re.search(r'([\d.]+)', seconds_part)
                if seconds_match:
                    seconds = float(seconds_match.group(1))

                    if filename not in bookmarks:
                        bookmarks[filename] = []

                    bookmarks[filename].append({
                        'timestamp': timestamp,
                        'seconds': seconds
                    })

    return bookmarks


def extract_segments(video_path, bookmarks, segment_duration=30, output_dir="extracted_segments"):
    """Extract video segments using ffmpeg"""

    # Create output directory
    Path(output_dir).mkdir(exist_ok=True)

    video_name = Path(video_path).stem
    half_duration = float(segment_duration) / 2

    for i, bookmark in enumerate(bookmarks):
        start_time = bookmark['seconds']
        output_filename = f"{video_name}_segment_{i+1:03d}_{bookmark['timestamp'].replace(':', '-').replace(' seconds','')}.mp4"
        output_path = os.path.join(output_dir, output_filename)

        # FFmpeg command to extract segment
        cmd = [
            'ffmpeg',
            '-ss', str(start_time - half_duration),    # Start time
            '-i', video_path,                          # Input file
            '-t', str(segment_duration),               # Duration (30 seconds default)
            '-c:a', 'aac',                             # Copy streams (faster, no re-encoding)
            '-c:v', 'libx264',                         # Copy streams (faster, no re-encoding)
            '-y',                                      # Overwrite output files
            output_path
        ]

        print(f"Extracting segment {i+1}: {bookmark['timestamp']} -> {output_filename}")

        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                print(f"Error extracting segment: {result.stderr}")
            else:
                print(f"✓ Successfully extracted: {output_filename}")
        except FileNotFoundError:
            print("Error: ffmpeg not found. Please install ffmpeg and add it to your PATH.")
            return False

    return True


def main():
    bookmark_file = "bookmarks.txt"

    if len(sys.argv) < 3:
        print("Usage: python extract_segments.py <video_file> [segment_duration_seconds] [output_directory]")
        print("Example: python extract_segments.py myvideo.mp4 45")
        sys.exit(1)

    video_path = sys.argv[1]
    segment_duration = int(sys.argv[2]) if len(sys.argv) > 2 else 30
    output_directory = sys.argv[3]

    if not os.path.exists(video_path):
        print(f"Video file '{video_path}' not found!")
        sys.exit(1)

    if not os.path.isdir(output_directory):
        print(f"Output directory '{output_directory}' not found!")
        sys.exit(1)

    bookmarks = parse_bookmarks(bookmark_file)

    if not bookmarks:
        print("No bookmarks found!")
        sys.exit(1)

    # Find bookmarks for this video file
    video_filename = os.path.basename(video_path)
    matching_bookmarks = []

    # Try to match video filename with bookmarks
    for filename in bookmarks.keys():
        if filename in video_filename or video_filename in filename:
            matching_bookmarks = bookmarks[filename]
            break

    if not matching_bookmarks:
        print(f"No bookmarks found for video: {video_filename}")
        print("Available videos in bookmarks:")
        for filename in bookmarks.keys():
            print(f"  - {filename}")
        sys.exit(1)

    print(f"Found {len(matching_bookmarks)} bookmarks for {video_filename}")
    print(f"Extracting {segment_duration}-second segments...")

    # Extract segments
    success = extract_segments(video_path, matching_bookmarks, segment_duration, output_directory)

    if success:
        print(f"\n✓ Done! Extracted {len(matching_bookmarks)} segments to 'extracted_segments/' folder")


if __name__ == "__main__":
    main()
