#!/bin/bash

# Create a directory for trimmed files
mkdir -p "./trimmed"

# Iterate through all .mp4 files in the current directory
for file in *.mp4; do
    if [ -f "$file" ]; then
        echo "Finding silence intervals for $file..."

        # Get silence intervals using silencedetect
        silence_info=$(ffmpeg -hide_banner -i "$file" -af "silencedetect=n=-50dB:d=3" -f null - 2>&1)

        selectionsList=()
        timeSelection="between(t,0,"
        end=""
        start=""

        # Read silence information from the provided variable
        while IFS= read -r line; do
            # Detect a start of silence, which is an end of our selection
            end=$(echo "$line" | grep -o "silence_start: [0-9]\+\(\.[0-9]\+\)\?" | cut -d' ' -f2)
            # Detect an end of silence, which is a start of our selection
            start=$(echo "$line" | grep -o "silence_end: [0-9]\+\(\.[0-9]\+\)\?" | cut -d' ' -f2)

            if [ -n "$start" ]; then
                timeSelection="between(t,$start,"
            fi

            if [ -n "$end" ]; then
                timeSelection+="$end)"
                selectionsList+=("$timeSelection")
            fi

        done <<< "$silence_info"

        # Note: silencedetect apparently handles properly files that start and/or end in silence
        # so we don't need to check for that and complete filters with no start or no end
        selectionFilter="'$(IFS=+; echo "${selectionsList[*]}")'"

        echo "Saving output file for $file..."

        # Extract filename without extension
        full_filename=$(basename "$file" | cut -d. -f1)

        # Extract file extension
        extension=$(basename "$file" | awk -F. '{if (NF>1) {print $NF}}')

        # Create trimmed filename with extension
        outfile="${full_filename}_trimmed.$extension"

        # Output ffmpeg command, automatic overwrite
        ffmpeg -hide_banner -loglevel error -y -i "$file" -vf "select=$selectionFilter,setpts=N/FRAME_RATE/TB" -af "aselect=$selectionFilter,asetpts=N/SR/TB" -c:v libx264 -c:a aac -strict experimental "trimmed/$outfile"
    fi
done

