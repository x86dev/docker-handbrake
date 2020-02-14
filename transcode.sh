#!/bin/sh

#
# A bit of configuration:
#

MY_FILENAME=${1}
MY_PROFILE_NAME=profile_default
MY_PROFILE_FILE=/usr/local/bin/${MY_PROFILE_NAME}.json
MY_DO_REPLACE=1
MY_PATH_TMP=/tmp
MY_FILENAME_SUFFIX_ORIGINAL=_original
MY_FILENAME_PREFIX_TRANSCODED=transcoded_
MY_FILENAME_SUFFIX_TRANSCODED=_transcoded

#
# The actual code begins here.
#

MY_FILENAME_PATH=$(dirname "$MY_FILENAME")
MY_FILENAME_NAME=$(basename "$MY_FILENAME")
MY_FILENAME_SRC=${MY_FILENAME_PATH}/${MY_FILENAME_NAME}
MY_FILENAME_EXT=$(echo ${MY_FILENAME_NAME} |awk -F . '{if (NF>1) {print $NF}}')
MY_FILENAME_NAME_NO_EXT=$(basename "$MY_FILENAME" .${MY_FILENAME_EXT})
MY_FILENAME_DST_NAME=${MY_FILENAME_NAME_NO_EXT}${MY_FILENAME_SUFFIX_TRANSCODED}.${MY_FILENAME_EXT}
MY_FILENAME_DST_TMP=${MY_PATH_TMP}/${MY_FILENAME_DST_NAME}
MY_FILENAME_DST=${MY_FILENAME_PATH}/${MY_FILENAME_DST_NAME}
MY_FILENAME_DST_OLD_SCHEME=${MY_FILENAME_PATH}/${MY_FILENAME_PREFIX_TRANSCODED}${MY_FILENAME_NAME}
MY_FILENAME_LOG=${MY_FILENAME_DST}.log

log()
{
    echo "[$(date)] $1" | tee -a "$MY_FILENAME_LOG" > /dev/null 2>&1
}

log "Handling '$MY_FILENAME'"

MY_ERROR=

mkdir -p "$MY_PATH_TMP"
if [ $? -ne 0 ]; then
    log "Unable to create temporary directory '$MY_PATH_TMP'"
    exit 1
fi

MY_SRC_CODEC_TYPE=$(ffprobe -v error -hide_banner -of default=noprint_wrappers=1:nokey=1 -select_streams v:0 -show_entries stream=codec_name "$MY_FILENAME_SRC")
if [ $? -ne 0 ]; then
    log "Unable to determine codec type, skipping: $MY_FILENAME_SRC"
    exit 1
fi
if [ "$MY_SRC_CODEC_TYPE" == "hevc" ]; then
    log "Already transcoded, skipping: $MY_FILENAME_SRC"
    exit 0
fi
if [ -f "$MY_FILENAME_DST" ]; then
    log "Destination file already exists, skipping: $MY_FILENAME_SRC"
    exit 1
fi
if [ -f "$MY_FILENAME_DST_OLD_SCHEME" ]; then
    log "Destination file (old scheme) already exists, skipping: $MY_FILENAME_SRC"
    exit 1
fi
log "Transcoding started: $MY_FILENAME_SRC ($MY_SRC_CODEC_TYPE) -> $MY_FILENAME_DST_TMP"
HandBrakeCLI --preset-import-file "$MY_PROFILE_FILE" -i "$MY_FILENAME_SRC" -o "$MY_FILENAME_DST_TMP" --preset="$MY_PROFILE_NAME" 2>&1 | tee -a "$MY_FILENAME_LOG" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log "Error: Could not transcode file: $MY_FILENAME_SRC"
    MY_ERROR=1
else
    log "Transcoding successful: $MY_FILENAME_SRC"
    log "Cloning file attributes ..."
    chown $(stat -c '%U.%G' "$MY_FILENAME_SRC") "$MY_FILENAME_DST"
    chmod $(stat -c '%a' "$MY_FILENAME_SRC") "$MY_FILENAME_DST"
    MY_DURATION_SRC=$(ffprobe -i "$MY_FILENAME_SRC" -show_format -v quiet | sed -n 's/duration=//p'| xargs printf %.0f)
    MY_DURATION_DST=$(ffprobe -i "$MY_FILENAME_DST" -show_format -v quiet | sed -n 's/duration=//p'| xargs printf %.0f)
    log "Duration source: $MY_DURATION_SRC seconds"
    log "Duration destination: $MY_DURATION_DST seconds"
    if [ "$MY_DURATION_SRC" = "$MY_DURATION_DST" ]; then
        rm "$MY_FILENAME_LOG" # Remove the log file on success.
        if [ -n "$MY_DO_REPLACE" ]; then
            log "Replacing $MY_FILENAME_SRC"
               mv "$MY_FILENAME_SRC" "$MY_FILENAME_PATH/$MY_FILENAME_NAME_NO_EXT$MY_FILENAME_SUFFIX_ORIGINAL.$MY_FILENAME_EXT" \
            && mv "$MY_FILENAME_DST" "$MY_FILENAME_SRC"
            if [ $? -ne 0 ]; then
                log "Error: Replacing file failed: $MY_FILENAME_SRC"
                MY_ERROR=1
            fi
        fi
    else
        log "Error: Durations do not match"
        MY_ERROR=1
    fi
fi

if [ -n "$MY_ERROR" ]; then
    log "An error ocurred -- see '$MY_FILENAME_LOG'"
    rm "$MY_FILENAME_DST_TMP" > /dev/null 2>&1 # Delete partially encoded file again.
    # Keep the log file, but apply the file's access rights to it,
    # so that the user can delete it with the same rights later.
    chown $(stat -c '%U.%G' "$MY_FILENAME_SRC") "$MY_FILENAME_LOG"
fi
