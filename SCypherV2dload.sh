#!/bin/bash

# API URLs
urls=(
    "https://api.sigmaspace.io/api/v1/tokens/01594be725214d0282e154991b1797fdf306a99ccc624b4642d40f387afe4a4f"
    "https://api.sigmaspace.io/api/v1/tokens/6a6c1307a1e4a7c5e72126aa19846c8f8c81d59f3d75f4e42b60e1efd3d49265"
    "https://api.sigmaspace.io/api/v1/tokens/3a2a80cb9ca428a90b9dbe9b2ef61a41f8b868a233b702d2090dcea466de28bc"
    "https://api.sigmaspace.io/api/v1/tokens/154327dc6767265842e996e9cdf4f232b62733b21c337b1e041c5255fb73d967"
    "https://api.sigmaspace.io/api/v1/tokens/a3cccedd94e11579ccb299acc758aab945a6ce9447ad168d3325280ae1795e29"
    "https://api.sigmaspace.io/api/v1/tokens/63b056564a399cfcad7437d36023a72bc8d81b64e97a0615bf2950f98cd2952f"
    "https://api.sigmaspace.io/api/v1/tokens/1efa48085300bfbd94f30ad6ed0dfcc51448f2dbec544fd391ef7c6f0f64a949"
    "https://api.sigmaspace.io/api/v1/tokens/3962e719f65b9c5d540727fe59ebc9dd62b93ae43c059e20a95a2d377f91b674"
)

# Temporary file to store base64 content
temp_base64="scypherBASE64.txt"
# Clear the temporary file if it exists
> "$temp_base64"

# Process each URL
for url in "${urls[@]}"; do
    echo "Processing $url..."

    # Make curl request and extract description field using jq
    description=$(curl -s -X GET "$url" | jq -r '.description')

    # Add content to base64 file
    echo "$description" >> "$temp_base64"
done

echo "Decoding base64 to compressed file..."
base64 -d "$temp_base64" > SCypherV2.sh.xz

echo "Decompressing xz file..."
xz -d SCypherV2.sh.xz

echo "Cleaning temporary files..."
rm "$temp_base64"

echo "Process completed. The resulting script is SCypherV2.sh"
