#!/bin/bash
# Fetch YouTube transcript/subtitles
# Usage: ./fetch-transcript.sh <youtube-url> [output-dir]
#
# Tries in order:
# 1. Manual subtitles (en)
# 2. Auto-generated subtitles (en)
# 3. Any available language

set -euo pipefail

URL="${1:?Usage: fetch-transcript.sh <youtube-url> [output-dir]}"
OUTPUT_DIR="${2:-/tmp/yt-transcripts}"
mkdir -p "$OUTPUT_DIR"

# Get video ID and title for filename
VIDEO_ID=$(yt-dlp --print id "$URL" 2>/dev/null)
VIDEO_TITLE=$(yt-dlp --print title "$URL" 2>/dev/null)
SAFE_TITLE=$(echo "$VIDEO_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | cut -c1-80)

echo "Video: $VIDEO_TITLE"
echo "ID: $VIDEO_ID"
echo ""

# Try manual English subs first, then auto, then any language
SUBTITLE_FILE=""
for ARGS in \
  "--write-subs --sub-langs en --sub-format vtt" \
  "--write-auto-subs --sub-langs 'en.*' --sub-format vtt" \
  "--write-auto-subs --sub-langs all --sub-format vtt"; do

  yt-dlp $ARGS \
    --skip-download \
    --no-playlist \
    -o "$OUTPUT_DIR/${SAFE_TITLE}" \
    "$URL" 2>/dev/null || true

  # Find the subtitle file that was written
  SUBTITLE_FILE=$(ls "$OUTPUT_DIR/${SAFE_TITLE}"*.vtt 2>/dev/null | head -1)
  if [[ -n "$SUBTITLE_FILE" ]]; then
    break
  fi
done

if [[ -z "$SUBTITLE_FILE" ]]; then
  echo "ERROR: No subtitles/transcript available for this video." >&2
  exit 1
fi

# Convert VTT to clean plain text
CLEAN_FILE="$OUTPUT_DIR/${SAFE_TITLE}-transcript.txt"

# Strip VTT headers, timestamps, positioning tags, and deduplicate lines
sed '1,/^$/d' "$SUBTITLE_FILE" \
  | sed '/^[0-9][0-9]:[0-9][0-9]/d' \
  | sed '/^$/d' \
  | sed 's/<[^>]*>//g' \
  | sed 's/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&nbsp;/ /g' \
  | awk '!seen[$0]++' \
  | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
  | grep -v '^$' \
  > "$CLEAN_FILE"

# Prepend metadata
DURATION=$(yt-dlp --print duration_string "$URL" 2>/dev/null || echo "unknown")
CHANNEL=$(yt-dlp --print channel "$URL" 2>/dev/null || echo "unknown")
UPLOAD_DATE=$(yt-dlp --print upload_date "$URL" 2>/dev/null || echo "unknown")

{
  echo "# $VIDEO_TITLE"
  echo ""
  echo "- **URL:** $URL"
  echo "- **Channel:** $CHANNEL"
  echo "- **Duration:** $DURATION"
  echo "- **Uploaded:** ${UPLOAD_DATE:0:4}-${UPLOAD_DATE:4:2}-${UPLOAD_DATE:6:2}"
  echo "- **Video ID:** $VIDEO_ID"
  echo ""
  echo "---"
  echo ""
  cat "$CLEAN_FILE"
} > "${CLEAN_FILE}.tmp" && mv "${CLEAN_FILE}.tmp" "$CLEAN_FILE"

# Clean up VTT file
rm -f "$SUBTITLE_FILE"

echo "Transcript saved to: $CLEAN_FILE"
echo "Lines: $(wc -l < "$CLEAN_FILE")"
echo "Size: $(du -h "$CLEAN_FILE" | cut -f1)"
