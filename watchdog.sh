#!/bin/sh

# If MY_PATH_WATCH is not set, use /var/www/html/data as default.
if [ -z "$MY_PATH_WATCH" ]; then
    MY_PATH_WATCH=/var/www/html/data
fi

MY_PATTERN_INCLUDE="*.mp4;*.avi"
MY_PATTERN_IGNORE="*_transcoded*;*_original*;*.part"

echo "Path is: $MY_PATH_WATCH"
echo "Include pattern: $MY_PATTERN_INCLUDE"
echo "Ignore pattern: $MY_PATTERN_IGNORE"

echo "Running once ..."
handbrake_transcode_dir.py "$MY_PATH_WATCH"

# Note! The inotify limit eventually needs to be tweaked on the host (not possible in a container)
#       for not running into inotify limits (as root), e.g. via
# 
#        echo fs.inotify.max_user_watches=524288 | tee -a /etc/sysctl.conf && sysctl -p

echo "Watchdog running ..."

watchmedo shell-command --patterns="$MY_PATTERN_INCLUDE" --ignore-pattern="$MY_PATTERN_IGNORE" --recursive --wait --command='transcode.sh "${watch_src_path}"' ${MY_PATH_WATCH}

echo "Watchdog terminated, waiting ..."

# Don't restart too fast in case that the watchdog crashed.
sleep 30
