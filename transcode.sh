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

MY_ERROR=

cleanup() 
{
    echo "Cleaning up ..."

    if [ -n "$MY_ERROR" ]; then
        echo "An error ocurred -- see '$MY_FILENAME_LOG'"
        # Apply the source file's access rights to the log file,
        # so that the user can delete it with the same rights later.
        chown $(stat -c '%U.%G' "$MY_FILENAME_SRC") "$MY_FILENAME_LOG"
        # Delete partially encoded files again.
        rm "$MY_FILENAME_DST" > /dev/null 2>&1
        rm "$MY_FILENAME_DST_TMP" > /dev/null 2>&1
    else
        # Remove the log file on success.
        rm "$MY_FILENAME_LOG" > /dev/null 2>&1
    fi
}

# Install signal handling.
trap cleanup INT TERM

log()
{
    echo "[$(date)] $1" | tee -a "$MY_FILENAME_LOG" > /dev/null 2>&1
}

error()
{
    echo "[$(date)] ERROR: $1" | tee -a "$MY_FILENAME_LOG" > /dev/null 2>&1
    MY_ERROR=1
}

log "Handling '$MY_FILENAME'"

mkdir -p "$MY_PATH_TMP"
if [ $? -ne 0 ]; then
    log "Unable to create temporary directory '$MY_PATH_TMP'"
    exit 1
fi

MY_SRC_CODEC_TYPE=$(ffprobe -v error -hide_banner -of default=noprint_wrappers=1:nokey=1 -select_streams v:0 -show_entries stream=codec_name "$MY_FILENAME_SRC")
if [ $? -ne 0 ]; then
    error "Unable to determine codec type, skipping: $MY_FILENAME_SRC"
    exit 1
fi
if [ "$MY_SRC_CODEC_TYPE" == "hevc" ]; then
    log "Already transcoded, skipping: $MY_FILENAME_SRC"
    exit 0
fi
if [ -f "$MY_FILENAME_DST" ]; then
    log "Destination file already exists, skipping: $MY_FILENAME_SRC"
    exit 0
fi
if [ -f "$MY_FILENAME_DST_OLD_SCHEME" ]; then
    log "Destination file (old scheme) already exists, skipping: $MY_FILENAME_SRC"
    exit 0
fi
log "Transcoding started: $MY_FILENAME_SRC ($MY_SRC_CODEC_TYPE) -> $MY_FILENAME_DST_TMP"
HandBrakeCLI --preset-import-file "$MY_PROFILE_FILE" -i "$MY_FILENAME_SRC" -o "$MY_FILENAME_DST_TMP" --preset="$MY_PROFILE_NAME" 2>&1 | tee -a "$MY_FILENAME_LOG" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    error "Could not transcode file: $MY_FILENAME_SRC"
else
    log "Transcoding successful: $MY_FILENAME_SRC"
    log "Moving temp file '$MY_FILENAME_DST_TMP' to '$MY_FILENAME_DST' ..."
    mv "$MY_FILENAME_DST_TMP" "$MY_FILENAME_DST" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        error "Moving temp file '$MY_FILENAME_DST_TMP' to '$MY_FILENAME_DST' failed"
    else
        log "Cloning file attributes ..."
        chown $(stat -c '%U.%G' "$MY_FILENAME_SRC") "$MY_FILENAME_DST" | tee -a "$MY_FILENAME_LOG" > /dev/null 2>&1
        chmod $(stat -c '%a' "$MY_FILENAME_SRC") "$MY_FILENAME_DST" | tee -a "$MY_FILENAME_LOG" > /dev/null 2>&1
        MY_DURATION_SRC=$(ffprobe -i "$MY_FILENAME_SRC" -show_format -v quiet | sed -n 's/duration=//p'| xargs printf %.0f)
        MY_DURATION_DST=$(ffprobe -i "$MY_FILENAME_DST" -show_format -v quiet | sed -n 's/duration=//p'| xargs printf %.0f)
        log "Duration source: $MY_DURATION_SRC seconds"
        log "Duration destination: $MY_DURATION_DST seconds"
        # Do a rough approximation here by comparing the destination duration to the source duration
        # and see if the durations are more or less equal (>= 90%); good enough for now.
        if [[ $(($MY_DURATION_DST * 9/10)) -lt $MY_DURATION_SRC ]]; then
            if [ -n "$MY_DO_REPLACE" ]; then
                log "Replacing $MY_FILENAME_SRC"
                mv "$MY_FILENAME_SRC" "$MY_FILENAME_PATH/$MY_FILENAME_NAME_NO_EXT$MY_FILENAME_SUFFIX_ORIGINAL.$MY_FILENAME_EXT" \
                && mv "$MY_FILENAME_DST" "$MY_FILENAME_SRC"
                if [ $? -ne 0 ]; then
                    error "Replacing file failed: $MY_FILENAME_SRC"                    
                fi
            fi
        else
            error "Destination duration is less than 90% of the source duration"
        fi
    fi
fi

cleanup
