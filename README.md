# docker-handbrake
A simple container to automatically convert video files.

# Intro

This is a simple container you can run on your server to convert all video files in an incoming directory
(by default /var/www/html/data) to x265 (HEVC). For this Handbrake and some Python code (watchdog) is being used. 

Feel free to clone & tweak this to your likings.

# Settings

The default profile (profile_default.json) uses settings which work for me, but not necessarily for you. So adjust this profile as needed and/or just create and use your own profile. Various other parameters can be tweaked -- for this have a look into the file **transcode.sh**.

# Building & Running

Build with:
`
docker build --tag docker-handbrake:devel .
`

To use a local directory, start with:
`
docker run -it --name handbrake -v /server/incoming:/var/www/html/data x86dev/docker-handbrake
`

The above example starts a container which will watch the directory `/server/incoming` for new .avi / .mpg files and starts to convert those as soon as they appear. The converted files will have the suffix **_transcoded** on success. 

To use volume from another container called 'my-container':
`
docker run -it --name handbrake --volumes-from my-container x86dev/docker-handbrake
`

# Customizing

Set the environment variable MY_PATH_WATCH when running the container to use a different watch path, e.g.
`
docker run -it --name handbrake -e MY_PATH_WATCH=/path/in/my-container --volumes-from my-container x86dev/docker-handbrake
`
