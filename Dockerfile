FROM alpine:latest

RUN apk update && \
    apk upgrade && \
    apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing handbrake && \
    apk add --no-cache ffmpeg

RUN apk add --no-cache python3 py3-pip && \
    pip3 install --no-cache --upgrade pip watchdog

RUN mkdir -p /mnt/watch

ADD transcode.sh watchdog.sh *.json *.py /usr/local/bin/

VOLUME /mnt/watch

ENTRYPOINT [ "/usr/local/bin/watchdog.sh" ]
