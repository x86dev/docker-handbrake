#!/bin/sh

MY_PATH_WATCH=/mnt/watch

echo "Path is: $MY_PATH_WATCH"

echo "Running once ..."
handbrake_transcode_dir.py ${MY_PATH_WATCH}

MY_PATTERN_INCLUDE="*.mp4;*.avi"
MY_PATTERN_IGNORE="*_transcoded*;*_original*;*.part"

echo "Watchdog running ..."
echo "Include pattern: $MY_PATTERN_INCLUDE"
echo "Ignore pattern: $MY_PATTERN_IGNORE"

watchmedo shell-command --patterns="$MY_PATTERN_INCLUDE" --ignore-pattern="$MY_PATTERN_IGNORE" --recursive --wait --command='transcode.sh "${watch_src_path}"' ${MY_PATH_WATCH}
