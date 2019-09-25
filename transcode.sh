#!/bin/sh

#
# A bit of configuration:
#

MY_FILENAME=${1}
MY_PROFILE_NAME=profile_default
MY_PROFILE_FILE=/usr/local/bin/${MY_PROFILE_NAME}.json
MY_FILENAME_SUFFIX_ORIGINAL=_original
MY_FILENAME_PREFIX_TRANSCODED=transcoded_
MY_FILENAME_SUFFIX_TRANSCODED=_transcoded

#
# The actual code begins here.
#

echo "[$(date)] Handling '$MY_FILENAME'"

MY_FILENAME_PATH=$(dirname "$MY_FILENAME")
MY_FILENAME_NAME=$(basename "$MY_FILENAME")
MY_FILENAME_SRC=${MY_FILENAME_PATH}/${MY_FILENAME_NAME}
MY_FILENAME_EXT=$(echo ${MY_FILENAME_NAME} |awk -F . '{if (NF>1) {print $NF}}')
MY_FILENAME_NAME_NO_EXT=$(basename "$MY_FILENAME" .${MY_FILENAME_EXT})
MY_FILENAME_DST=${MY_FILENAME_PATH}/${MY_FILENAME_NAME_NO_EXT}${MY_FILENAME_SUFFIX_TRANSCODED}.${MY_FILENAME_EXT}
MY_FILENAME_DST_OLD_SCHEME=${MY_FILENAME_PATH}/${MY_FILENAME_PREFIX_TRANSCODED}${MY_FILENAME_NAME}
MY_FILENAME_LOG=${MY_FILENAME_DST}.log

MY_SRC_CODEC_TYPE=$(ffprobe -v error -hide_banner -of default=noprint_wrappers=1:nokey=1 -select_streams v:0 -show_entries stream=codec_name "$MY_FILENAME_SRC")

MY_ERROR=

if [ $? -ne 0 ]; then
    echo "[$(date)] Unable to determine codec type, skipping: $MY_FILENAME_SRC"
    exit 1
fi
if [ "$MY_SRC_CODEC_TYPE" == "hevc" ]; then
    echo "[$(date)] Already transcoded, skipping: $MY_FILENAME_SRC"
    exit 0
fi
if [ -f "$MY_FILENAME_DST" ]; then
    echo "[$(date)] Destination file already exists, skipping: $MY_FILENAME_SRC"
    exit 1
fi
if [ -f "$MY_FILENAME_DST_OLD_SCHEME" ]; then
    echo "[$(date)] Destination file (old scheme) already exists, skipping: $MY_FILENAME_SRC"
    exit 1
fi
echo "[$(date)] Transcoding started: $MY_FILENAME_SRC ($MY_SRC_CODEC_TYPE) -> $MY_FILENAME_DST"
HandBrakeCLI --preset-import-file "$MY_PROFILE_FILE" -i "$MY_FILENAME_SRC" -o "$MY_FILENAME_DST" --preset="$MY_PROFILE_NAME" 2>&1 | tee "$MY_FILENAME_LOG" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[$(date)] Error: Could not transcode file: $MY_FILENAME_SRC"
    MY_ERROR=1
else
    echo "[$(date)] Transcoding successful: $MY_FILENAME_SRC"
    echo "[$(date)] Cloning file attributes ..."
    chown $(stat -c '%U.%G' ${MY_FILENAME_SRC}) ${MY_FILENAME_DST}
    chmod $(stat -c '%a' ${MY_FILENAME_SRC}) ${MY_FILENAME_DST}
    MY_DURATION_SRC=$(ffprobe -i "$MY_FILENAME_SRC" -show_format -v quiet | sed -n 's/duration=//p'| xargs printf %.0f)
    MY_DURATION_DST=$(ffprobe -i "$MY_FILENAME_DST" -show_format -v quiet | sed -n 's/duration=//p'| xargs printf %.0f)
    echo "[$(date)] Duration source: $MY_DURATION_SRC seconds"
    echo "[$(date)] Duration destination: $MY_DURATION_DST seconds"
    if [ "$MY_DURATION_SRC" = "$MY_DURATION_DST" ]; then
        rm "$MY_FILENAME_LOG" # Remove the log file on success.
        if [ -n "$MY_DO_REPLACE" ]; then
            echo "[$(date)] Replacing $MY_FILENAME_SRC"
               mv "$MY_FILENAME_SRC" "${MY_FILENAME_PATH}/${MY_FILENAME_NAME_NO_EXT}${MY_FILENAME_SUFFIX_ORIGINAL}.${MY_FILENAME_EXT}" \
            && mv "$MY_FILENAME_DST" "$MY_FILENAME_SRC"
        fi
    else
        echo "[$(date)] Error: Durations do not match"
        MY_ERROR=1
    fi
fi

if [ -n "$MY_ERROR" ]; then
    echo "[$(date)] An error ocurred -- see '$MY_FILENAME_LOG')"
    rm "$MY_FILENAME_DST" > /dev/null 2>&1 # Delete partially encoded file again.
    # Keep the log file.
fi
