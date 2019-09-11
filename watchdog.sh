#!/bin/sh

MY_PATH_WATCH=/mnt/watch

echo "Path is: $MY_PATH_WATCH"

echo "Running once ..."
run-once.py ${MY_PATH_WATCH}

echo "Watchdog running"
watchmedo shell-command --patterns="*.mp4;*.avi" --ignore-pattern="*_transcoded*;*.part" --recursive --wait --command='transcode.sh "${watch_src_path}"' ${MY_PATH_WATCH}
