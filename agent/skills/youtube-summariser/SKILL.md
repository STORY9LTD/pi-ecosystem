---
name: youtube-summariser
description: |
  Fetches a YouTube video transcript and produces an intelligent summary. Use when a user shares a
  YouTube URL and wants to understand what the video covers. Handles: transcript extraction via yt-dlp,
  cleaning, reading, analysis, and structured summarisation. Works with manual and auto-generated subtitles.
---

# YouTube Summariser

Fetch a YouTube transcript, read it, and produce a clear structured summary.

## Setup (once)

Requires `yt-dlp` (installed via Homebrew):

```bash
which yt-dlp || brew install yt-dlp
```

## Workflow

### Step 1: Fetch the Transcript

Run the fetch script with the YouTube URL:

```bash
cd "$(dirname "$0")" && bash scripts/fetch-transcript.sh "<youtube-url>"
```

This outputs a clean transcript file to `/tmp/yt-transcripts/` with metadata headers.

Note the output path — you'll need it for Step 2.

### Step 2: Read the Transcript

Use the `read` tool to load the transcript file from the path printed in Step 1.

For long transcripts (>500 lines), read in chunks using offset/limit and process the full content.

### Step 3: Summarise

After reading the full transcript, produce this structured output:

```
## Video Summary

**Title:** {title}
**Channel:** {channel}
**Duration:** {duration}
**URL:** {url}

### TL;DR
{2-3 sentence overview of what the video is about and the key takeaway}

### Key Points
{Bulleted list of the main points/arguments/findings — aim for 5-10 bullets}

### Detailed Breakdown
{For longer videos (>15 min), break into logical sections with timestamps if possible}
{Each section gets a heading and a short paragraph}

### Notable Quotes / Moments
{Any standout quotes, demonstrations, or memorable moments}

### Action Items / Takeaways
{If applicable — things the viewer should do, try, or remember}
```

**Summarisation rules:**
- Be specific, not vague. Use names, numbers, and concrete details from the transcript.
- Preserve the speaker's intent. Don't editorialise.
- If the transcript quality is poor (auto-generated with errors), note this and do your best.
- For technical content, preserve technical terms accurately.
- For tutorials, capture the steps in order.
- For discussions/interviews, capture each participant's key positions.
- Adapt the format to the content — a tutorial summary looks different from a debate summary.

## Usage Examples

```
/skill:youtube-summariser https://www.youtube.com/watch?v=dQw4w9WgXcQ
/skill:youtube-summariser https://youtu.be/abc123 summarise focusing on the technical details
```

If the user provides additional instructions after the URL (e.g., "focus on X", "ignore the intro"), incorporate those into the summary.
