# docker-handbrake
A simple container to automatically convert video files.

# Intro

This is a simple container you can run on your server to convert all video files in an incoming directory
to x265 (HEVC). For this Handbrake and some Python code (watchdog) is being used. 

Feel free to clone & tweak this to your likings.

# Building & Running

Build with:
`
docker build --tag docker-handbrake:devel .
`

Start with:

`
docker run -it --name handbrake -v /server/incoming:/mnt/watch docker-handbrake:devel
`

The above example starts a container which will watch the directory `/server/incoming` for new .avi / .mpg files and starts to convert those as soon as they appear. The converted files will have the suffix **_transcoded** on success. Various parameters can be tweaked -- for this have a look into the file **transcode.sh**.
