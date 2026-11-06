#!/usr/bin/env bash
# mpd-add-yt - Search YouTube and queue audio streams to MPD

for cmd in yt-dlp fzf mpc; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

QUERY="$*"
[ -z "$QUERY" ] && { echo "Usage: $0 <search query or URL>"; exit 1; }

# 1. Determine if input is a direct URL or a search query
if [[ "$QUERY" =~ ^https?:// ]]; then
    TARGET="$QUERY"
else
    echo "Searching YouTube for: $QUERY..."

    LIST=$(yt-dlp "ytsearch20:$QUERY" \
        --flat-playlist \
        --print "%(title)s [%(duration_string)s] (%(channel)s):::%(id)s" \
        2>/dev/null | sed 's/\[NA\]/[LIVE]/g')

    [ -z "$LIST" ] && { echo "No results found or yt-dlp failed."; exit 1; }

    SELECTION=$(echo "$LIST" | fzf \
        --prompt="YT Search> " \
        --reverse \
        --delimiter=':::' \
        --with-nth=1)

    [ -z "$SELECTION" ] && exit 0

    VIDEO_ID="${SELECTION##*:::}"
    TARGET="https://www.youtube.com/watch?v=$VIDEO_ID"
fi

echo "Extracting audio stream(s)..."

# Get the stream URLs exactly as before.
mapfile -t STREAMS < <(
    yt-dlp -f bestaudio --yes-playlist -g "$TARGET" 2>/dev/null
)

if [ ${#STREAMS[@]} -eq 0 ]; then
    echo "Failed to extract stream (URL may be invalid or DRM protected)." >&2
    exit 1
fi

# Get basic metadata separately.
mapfile -t TITLES < <(
    yt-dlp -f bestaudio --yes-playlist \
        --print '%(title)s' "$TARGET" 2>/dev/null
)

mapfile -t ARTISTS < <(
    yt-dlp -f bestaudio --yes-playlist \
        --print '%(artist,uploader)s' "$TARGET" 2>/dev/null
)

# Queue each stream.
for i in "${!STREAMS[@]}"; do
    stream="${STREAMS[$i]}"

    mpc add "$stream" >/dev/null || continue

    # Get the ID of the song we just added.
    id=$(mpc playlist -f '%id%' 2>/dev/null | tail -n 1)

    title="${TITLES[$i]}"
    artist="${ARTISTS[$i]}"

    # Escape characters required by the MPD protocol.
    title=${title//\\/\\\\}
    title=${title//\"/\\\"}
    artist=${artist//\\/\\\\}
    artist=${artist//\"/\\\"}

    # Send addtagid through the MPD TCP protocol.
    {
        printf 'addtagid %s Title "%s"\n' "$id" "$title"

        if [ -n "$artist" ]; then
            printf 'addtagid %s Artist "%s"\n' "$id" "$artist"
        fi

        printf 'close\n'
    } > /dev/tcp/${MPD_HOST:-localhost}/${MPD_PORT:-6600} 2>/dev/null

done

echo "Successfully added ${#STREAMS[@]} item(s) to MPD queue."
mpc play
