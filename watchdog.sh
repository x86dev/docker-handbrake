#!/bin/sh
echo "Watchdog running"
watchmedo shell-command --patterns="*.mp4;*.avi" --ignore-pattern="*_transcoded*;*.part" --recursive --wait --command='transcode.sh "${watch_src_path}"' /mnt/watch
