#!/bin/sh

MY_PATH_WATCH=/mnt/watch

MY_PATTERN_INCLUDE="*.mp4;*.avi"
MY_PATTERN_IGNORE="*_transcoded*;*_original*;*.part"

echo "Path is: $MY_PATH_WATCH"
echo "Include pattern: $MY_PATTERN_INCLUDE"
echo "Ignore pattern: $MY_PATTERN_IGNORE"

echo "Running once ..."
handbrake_transcode_dir.py "$MY_PATH_WATCH"

# Raise ulimit to not run (too fast) into errors.
ulimit -n 8096

echo "Watchdog running ..."

watchmedo shell-command --patterns="$MY_PATTERN_INCLUDE" --ignore-pattern="$MY_PATTERN_IGNORE" --recursive --wait --command='transcode.sh "${watch_src_path}"' ${MY_PATH_WATCH}

echo "Watchdog terminated"

# Don't restart too fast in case that the watchdog crashed.
sleep 30
