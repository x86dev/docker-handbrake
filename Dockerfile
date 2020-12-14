FROM ubuntu:focal

RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg handbrake-cli python3 python3-pip

RUN pip3 install --no-cache --upgrade pip watchdog watchdog[watchmedo]

# Clean up.
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /mnt/watch

ADD transcode.sh watchdog.sh *.json *.py /usr/local/bin/

VOLUME /mnt/watch

ENTRYPOINT [ "/usr/local/bin/watchdog.sh" ]
