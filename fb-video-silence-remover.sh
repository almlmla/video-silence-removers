#!/bin/bash

# Create a directory for trimmed files
mkdir -p "./trimmed"

# Function to check and perform ffmpeg cut
perform_cut() {
    local start="$1"
    local end="$2"
    local file="$3"
    local num_cuts="$4"
    
    if (( $(echo "$end > $start" | bc -l) )); then
        local cut_file="cut${num_cuts}.mp4"
        ffmpeg -hide_banner -loglevel error -y -ss "$start" -to "$end" -i "$file" -c copy "${cut_file}"
        cut_files+=("${cut_file}")
    fi
}

# Iterate through all .mp4 files in the current directory
for file in *.mp4; do
    if [ -f "$file" ]; then
        echo "Finding silence intervals for $file..."

        # Get silence intervals using silencedetect
        silence_info=$(ffmpeg -hide_banner -i "$file" -af "silencedetect=n=-50dB:d=3" -f null - 2>&1)

        num_cuts=0
        cut_files=()
        end=""
        find_start=""
        start=0

        # Read silence information from the provided variable
        while IFS= read -r line; do
            # Detect a start of silence, which is an end of our selection
            end=$(echo "$line" | grep -o "silence_start: [0-9]\+\(\.[0-9]\+\)\?" | cut -d' ' -f2)
            # Detect an end of silence, which is a start of our selection
            find_start=$(echo "$line" | grep -o "silence_end: [0-9]\+\(\.[0-9]\+\)\?" | cut -d' ' -f2)

            if [ -n "$find_start" ]; then
                start=$find_start
            fi

            if [ -n "$end" ]; then
                perform_cut "$start" "$end" "$file" "$num_cuts"
                num_cuts=$((num_cuts+1))
            fi

        done <<< "$silence_info"

        # Perform a final cut for the last segment
        perform_cut "$start" "end" "$file" "$num_cuts"

        echo "Saving output file for $file..."

        # Extract filename without extension
        full_filename=$(basename "$file" | cut -d. -f1)

        # Extract file extension
        extension=$(basename "$file" | awk -F. '{if (NF>1) {print $NF}}')

        # Create trimmed filename with extension
        outfile="${full_filename}_trimmed.$extension"

        # Output ffmpeg command, automatic overwrite
        ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i <(for f in "${cut_files[@]}"; do echo "file '$PWD/$f'"; done) -c copy -avoid_negative_ts 1 "trimmed/$outfile"

        # Handle errors in ffmpeg commands
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create trimmed file for $file"
        else
            echo "Trimmed file saved: $outfile"
            # Clean up temporary cut files
            rm "${cut_files[@]}"
        fi
    fi
done

