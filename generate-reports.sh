#!/bin/bash

# Counter to keep track of file number
file_number=0

# Directory paths
generate_docs_dir="generate-docs"
photo_downloads_dir="photo_downloads"

# Maximum number of download attempts
max_attempts=3

# Create directories if they don't exist
mkdir -p "$generate_docs_dir"
mkdir -p "$photo_downloads_dir"

# Backup original files
for file in "$generate_docs_dir"/*; do
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak"
    fi
done

# Copy the contents of factual-inaccuracies-in-armours-report.md to generate-docs
cp -r factual-inaccuracies-in-armours-report.md/* "$generate_docs_dir"

# Function to download with retry
download_with_retry() {
    local src_value="$1"
    local downloaded_file="$2"
    local attempts=0

    # Check if the file already exists, if yes, return without re-downloading
    if [ -e "$downloaded_file" ]; then
        echo "File already exists: $downloaded_file"
        return 0
    fi

    while [ $attempts -lt $max_attempts ]; do
        # Download the image using wget
        wget -P "$photo_downloads_dir" -O "$downloaded_file" "$src_value"
        
        # Check if wget was successful
        if [ $? -eq 0 ]; then
            break  # Break the loop if successful
        else
            echo "Error: Failed to download image from $src_value (Attempt $((attempts+1)))"
            ((attempts++))
        fi
    done

    # Return 0 on success, 1 on failure
    return $?
}

# Iterate over all files in the generate-docs directory
for file in "$generate_docs_dir"/*; do
    # Check if the current item is a file
    if [ -f "$file" ]; then

        ((file_number++))

        echo "Processing file: $file"

        # Counter to keep track of line number
        line_number=0

        # Temporary file to store modified content
        temp_file="${file}.temp"

        # Process each line in the file
        while IFS= read -r line; do

            ((line_number++))
    
            # Use grep to find occurrences of the pattern 'src="[^"]*"'
            # and extract the value between the double quotes
            src_value=$(echo "$line" | grep -o 'src="[^"]*"' | cut -d'"' -f2)
    
            # Check if "src" attribute was found in the line
            if [ -n "$src_value" ]; then
                # Download the image with retry
                downloaded_file="${photo_downloads_dir}/image_${file_number}_${line_number}"
                download_with_retry "$src_value" "$downloaded_file"
                
                # Check if download was successful
                if [ $? -eq 0 ]; then
                    # Replace the src attribute in the line with the downloaded file path
                    line=$(echo "$line" | sed "s@$src_value@../$downloaded_file@g")
                else
                    echo "Error: All attempts failed for $src_value"
                fi
            fi

            # Append the modified line to the temporary file
            echo "$line" >> "$temp_file"

        done < "$file"

        # Replace the original file with the temporary file
        mv "$temp_file" "$file"
    fi
done
