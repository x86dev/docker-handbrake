#!/bin/sh

MY_PATH_WATCH=/mnt/watch

echo "Path is: $MY_PATH_WATCH"

echo "Running once ..."
handbrake_transcode_dir.py ${MY_PATH_WATCH}

echo "Watchdog running"
watchmedo shell-command --patterns="*.mp4;*.avi" --ignore-pattern="*_transcoded*;*_original*;*.part" --recursive --wait --command='transcode.sh "${watch_src_path}"' ${MY_PATH_WATCH}
