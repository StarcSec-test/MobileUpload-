#!/bin/bash
# --- CHECK FOR REQUIRED ARGUMENTS ---
if [ "$#" -lt 2 ]; then
    echo "Error: Missing arguments!"
    echo "Usage:   $0  <FILE_PATH> <UPLOAD_NAME> "
    echo "Example: $0  "Upload file path" "App name" "
    exit 1
fi

# --- DYNAMIC ARGUMENTS ---
FILE_PATH="$1"
BASE_UPLOAD_NAME="$2"

CHUNK_SIZE="95m"

# Verify target file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found at $FILE_PATH"
    exit 1
fi

# Extract original filename
ORIGINAL_FILE_NAME=$(basename "$FILE_PATH")

# Generate a unique name
UNIQUE_SUFFIX=$(date +%s)
UNIQUE_UPLOAD_NAME="${BASE_UPLOAD_NAME}_${UNIQUE_SUFFIX}"

# Create a unique temporary directory
TMP_WORKSPACE="starcsec_workspace_$$"
mkdir -p "$TMP_WORKSPACE"

echo "Splitting file into pieces"
split -b "$CHUNK_SIZE" "$FILE_PATH" "$TMP_WORKSPACE/chunk_"

# Load chunk elements into array context
chunks=("$TMP_WORKSPACE"/chunk_*)
total_chunks=${#chunks[@]}
echo "File divided into $total_chunks chunks. Starting sequential upload..."

for i in "${!chunks[@]}"; do
    chunk_file="${chunks[$i]}"
    echo "Processing chunk $((i+1)) of $total_chunks ($chunk_file)..."

    # dynamic curl execution using the completely unique upload session id
    RESPONSE_CODE=$(curl --write-out '%{http_code}' --silent --output /dev/null --location "https://api-dev.starcsec.com/v1/integration/mobileAsset/upload" \
      --header "domain: app.starcsec.com" \
      --header "Organisationid: 6acf6d20d048a733bccafafb" \
      --header "Authorization: Basic ******" \
      --header "App: StarcSec ASPM" \
      --header 'Accept: application/json, text/plain, */*' \
      --form "request={
        \"name\":\"$UNIQUE_UPLOAD_NAME\",
        \"originalFileName\":\"$ORIGINAL_FILE_NAME\",
        \"chunkIndex\":$i,
        \"totalChunks\":$total_chunks
      };type=application/json" \
      --form "files=@\"$chunk_file\"")

    if [ "$RESPONSE_CODE" -ne 200 ] && [ "$RESPONSE_CODE" -ne 201 ]; then
        echo "Error: Chunk upload failed at step $i with HTTP status $RESPONSE_CODE"
        # Wipe local unique folder before failing out
        rm -rf "$TMP_WORKSPACE"
        exit 1
    fi
done

# Clean up our specific unique workspace
rm -rf "$TMP_WORKSPACE"
echo "Stream upload complete for '$UNIQUE_UPLOAD_NAME' across all chunks!"
