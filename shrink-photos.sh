#!/bin/bash

# Set the directory path
directory="./photo_downloads"

# Set the reduction factor
reduction_factor=20

# Navigate to the directory
cd "$directory" || exit

# Reduce all JPEG images in the directory
for file in *; do
    if [ -f "$file" ]; then
        echo "Reducing $file..."
        mogrify -resize "$((100 / reduction_factor))%" "$file"
    fi
done

echo "Reduction complete."
