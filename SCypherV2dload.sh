#!/bin/bash

# API URLs
urls=(
    "https://api.sigmaspace.io/api/v1/tokens/2441e82d669db1ec65af092db175d91872ebfdd9a7865893254de863f30e62d8"
    "https://api.sigmaspace.io/api/v1/tokens/2d0d020b4f2669938c436fb4f30de703774faae20e0af7d77bf452ab330eaf9b"
    "https://api.sigmaspace.io/api/v1/tokens/55a364c8ab60444430d8a9bd88fcadf6231a72c8c8b92c3cb091c6497e0da85a"
    "https://api.sigmaspace.io/api/v1/tokens/3bc76d50309ad65cfb10be3bd288069c1eefc93465d65afcd8e5af7a99c5d9ce"
    "https://api.sigmaspace.io/api/v1/tokens/7ff624b7747e1dbd2dae1967d81c77eb5bd39671a581faf8ea923b27a6ce7776"
    "https://api.sigmaspace.io/api/v1/tokens/de7cca77a29aa84efdf873df47a74e4a667d419be735c7bfc0208619ce73c3e2"
    "https://api.sigmaspace.io/api/v1/tokens/7edcf227b14484a85b3e6bc33a56de4bab845590a8bdd474c1c9d3a83a4ce2bb"
    "https://api.sigmaspace.io/api/v1/tokens/494e97b1b2d54729b35174533edc04336efb314d6d05a2985225524a3468c1fd"
)

# Temporary file to store base64 content
temp_base64="SCypherV2BASE64.txt"
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
