#!/bin/bash
# process-media.sh — Automated video clip extraction and gallery preparation
# Processes raw videos from Google Drive into short clips + stills for the gallery

set -euo pipefail

RAW_DIR="media/drive-raw"
OUTPUT_DIR="ghost/content/images/gallery"
CLIPS_DIR="ghost/content/images/gallery/clips"
STILLS_DIR="ghost/content/images/gallery/stills"
REPORT_FILE="media/processing-report.txt"

# Max clip duration in seconds
CLIP_DURATION=10
# Target width for web output
TARGET_WIDTH=1280
# JPEG quality for stills
STILL_QUALITY=85

mkdir -p "$CLIPS_DIR" "$STILLS_DIR"
> "$REPORT_FILE"

log() {
    echo "$1" | tee -a "$REPORT_FILE"
}

log "=== Cooperation Tulsa Media Processing ==="
log "Started: $(date)"
log ""

# Step 1: Inventory all media files
log "--- INVENTORY ---"
video_count=0
image_count=0

find "$RAW_DIR" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" \) | sort > /tmp/video_list.txt
find "$RAW_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort > /tmp/image_list.txt

video_count=$(wc -l < /tmp/video_list.txt | tr -d ' ')
image_count=$(wc -l < /tmp/image_list.txt | tr -d ' ')

log "Videos found: $video_count"
log "Images found: $image_count"
log ""

# Step 2: Analyze and process each video
log "--- PROCESSING VIDEOS ---"

process_video() {
    local input_file="$1"
    local basename=$(basename "$input_file" | sed 's/\.[^.]*$//')
    local parent_dir=$(basename "$(dirname "$input_file")")
    local prefix="${parent_dir}_${basename}"

    # Clean prefix for filenames
    prefix=$(echo "$prefix" | sed 's/[^a-zA-Z0-9_-]/_/g')

    # Get video info
    local duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$input_file" 2>/dev/null | cut -d. -f1)
    local resolution=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$input_file" 2>/dev/null)

    if [ -z "$duration" ] || [ "$duration" = "N/A" ]; then
        log "  SKIP (can't read): $input_file"
        return
    fi

    log "  Processing: $input_file (${duration}s, ${resolution})"

    # Strategy for clip extraction:
    # - For short videos (<15s): use the whole thing
    # - For medium videos (15-60s): extract the middle segment
    # - For longer videos (>60s): extract 2-3 clips at scene changes

    if [ "$duration" -le 15 ]; then
        # Short video — convert whole thing as a clip
        local clip_out="$CLIPS_DIR/${prefix}_full.mp4"
        if [ ! -f "$clip_out" ]; then
            ffmpeg -y -i "$input_file" \
                -vf "scale=${TARGET_WIDTH}:-2" \
                -c:v libx264 -preset fast -crf 28 \
                -c:a aac -b:a 96k \
                -movflags +faststart \
                "$clip_out" 2>/dev/null
            log "    -> clip: $(basename "$clip_out")"
        fi

        # Extract 1 still from the middle
        local mid=$((duration / 2))
        local still_out="$STILLS_DIR/${prefix}_still.webp"
        if [ ! -f "$still_out" ]; then
            ffmpeg -y -ss "$mid" -i "$input_file" \
                -vframes 1 -vf "scale=${TARGET_WIDTH}:-2" \
                -quality "$STILL_QUALITY" \
                "$still_out" 2>/dev/null
            log "    -> still: $(basename "$still_out")"
        fi

    elif [ "$duration" -le 60 ]; then
        # Medium video — take a clip from the most active part
        # Use the segment from 20%-70% of the video
        local start=$(( duration * 20 / 100 ))
        local clip_out="$CLIPS_DIR/${prefix}_clip.mp4"
        if [ ! -f "$clip_out" ]; then
            ffmpeg -y -ss "$start" -i "$input_file" \
                -t "$CLIP_DURATION" \
                -vf "scale=${TARGET_WIDTH}:-2" \
                -c:v libx264 -preset fast -crf 28 \
                -c:a aac -b:a 96k \
                -movflags +faststart \
                "$clip_out" 2>/dev/null
            log "    -> clip: $(basename "$clip_out")"
        fi

        # Extract 2 stills — one from each third
        for i in 1 2; do
            local ss=$(( duration * i / 3 ))
            local still_out="$STILLS_DIR/${prefix}_still_${i}.webp"
            if [ ! -f "$still_out" ]; then
                ffmpeg -y -ss "$ss" -i "$input_file" \
                    -vframes 1 -vf "scale=${TARGET_WIDTH}:-2" \
                    -quality "$STILL_QUALITY" \
                    "$still_out" 2>/dev/null
                log "    -> still: $(basename "$still_out")"
            fi
        done

    else
        # Long video — detect scene changes and extract clips at the best moments
        # Use ffmpeg's scene detection to find interesting transitions
        local scenes=$(ffmpeg -i "$input_file" -vf "select='gt(scene,0.3)',showinfo" -f null - 2>&1 \
            | grep "showinfo" | head -5 \
            | sed -n 's/.*pts_time:\([0-9.]*\).*/\1/p')

        local clip_num=0
        for scene_time in $scenes; do
            clip_num=$((clip_num + 1))
            [ "$clip_num" -gt 3 ] && break

            local scene_int=${scene_time%.*}
            # Make sure we don't go past end of video
            if [ "$((scene_int + CLIP_DURATION))" -gt "$duration" ]; then
                scene_int=$((duration - CLIP_DURATION))
                [ "$scene_int" -lt 0 ] && scene_int=0
            fi

            local clip_out="$CLIPS_DIR/${prefix}_clip_${clip_num}.mp4"
            if [ ! -f "$clip_out" ]; then
                ffmpeg -y -ss "$scene_int" -i "$input_file" \
                    -t "$CLIP_DURATION" \
                    -vf "scale=${TARGET_WIDTH}:-2" \
                    -c:v libx264 -preset fast -crf 28 \
                    -c:a aac -b:a 96k \
                    -movflags +faststart \
                    "$clip_out" 2>/dev/null
                log "    -> clip: $(basename "$clip_out")"
            fi

            # Also grab a still at the scene change
            local still_out="$STILLS_DIR/${prefix}_still_${clip_num}.webp"
            if [ ! -f "$still_out" ]; then
                ffmpeg -y -ss "$scene_int" -i "$input_file" \
                    -vframes 1 -vf "scale=${TARGET_WIDTH}:-2" \
                    -quality "$STILL_QUALITY" \
                    "$still_out" 2>/dev/null
                log "    -> still: $(basename "$still_out")"
            fi
        done

        # If scene detection found nothing, fall back to even sampling
        if [ "$clip_num" -eq 0 ]; then
            for i in 1 2 3; do
                local ss=$(( duration * i / 4 ))
                local clip_out="$CLIPS_DIR/${prefix}_clip_${i}.mp4"
                if [ ! -f "$clip_out" ]; then
                    ffmpeg -y -ss "$ss" -i "$input_file" \
                        -t "$CLIP_DURATION" \
                        -vf "scale=${TARGET_WIDTH}:-2" \
                        -c:v libx264 -preset fast -crf 28 \
                        -c:a aac -b:a 96k \
                        -movflags +faststart \
                        "$clip_out" 2>/dev/null
                    log "    -> clip: $(basename "$clip_out")"
                fi

                local still_out="$STILLS_DIR/${prefix}_still_${i}.webp"
                if [ ! -f "$still_out" ]; then
                    ffmpeg -y -ss "$ss" -i "$input_file" \
                        -vframes 1 -vf "scale=${TARGET_WIDTH}:-2" \
                        -quality "$STILL_QUALITY" \
                        "$still_out" 2>/dev/null
                    log "    -> still: $(basename "$still_out")"
                fi
            done
        fi
    fi
}

# Process videos sequentially
while IFS= read -r video; do
    process_video "$video"
done < /tmp/video_list.txt

# Step 3: Process raw images — convert to webp for gallery
log ""
log "--- PROCESSING IMAGES ---"
while IFS= read -r image; do
    local_basename=$(basename "$image" | sed 's/\.[^.]*$//')
    parent_dir=$(basename "$(dirname "$image")")
    prefix="${parent_dir}_${local_basename}"
    prefix=$(echo "$prefix" | sed 's/[^a-zA-Z0-9_-]/_/g')

    out="$STILLS_DIR/${prefix}.webp"
    if [ ! -f "$out" ]; then
        ffmpeg -y -i "$image" \
            -vf "scale='min(${TARGET_WIDTH},iw)':-2" \
            -quality "$STILL_QUALITY" \
            "$out" 2>/dev/null
        log "  -> $(basename "$out")"
    fi
done < /tmp/image_list.txt

# Step 4: Summary
log ""
log "--- SUMMARY ---"
clip_count=$(find "$CLIPS_DIR" -name "*.mp4" 2>/dev/null | wc -l | tr -d ' ')
still_count=$(find "$STILLS_DIR" -name "*.webp" 2>/dev/null | wc -l | tr -d ' ')
log "Clips generated: $clip_count"
log "Stills generated: $still_count"
log "Completed: $(date)"

# Step 5: Generate a manifest for gallery template updates
echo ""
echo "=== MANIFEST FOR GALLERY ==="
echo "CLIPS:"
find "$CLIPS_DIR" -name "*.mp4" -exec basename {} \; | sort
echo ""
echo "STILLS:"
find "$STILLS_DIR" -name "*.webp" -exec basename {} \; | sort
