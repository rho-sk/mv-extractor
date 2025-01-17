FROM ubuntu:20.04 AS builder42

WORKDIR /home/video_cap

COPY install.sh /home/video_cap
COPY ffmpeg_patch /home/video_cap/ffmpeg_patch/

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Bratislava

# Install dependencies
RUN mkdir -p /home/video_cap && \
  cd /home/video_cap && \
  chmod +x install.sh && \
  ./install.sh

COPY install.1.sh /home/video_cap

RUN mkdir -p /home/video_cap && \
  cd /home/video_cap && \
  chmod +x install.1.sh && \
  ./install.1.sh

# Install debugging tools
RUN apt-get update && \
  apt-get -y install \
  gdb \
  python3-dbg

FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Bratislava

# install Python
RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
    pkg-config \
    python3-dev \
    python3-pip \
    python3-numpy \
    python3-pkgconfig && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
  apt-get -y install \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libmp3lame-dev \
    zlib1g-dev \
    libx264-dev \
    libx265-dev \
    libsdl2-dev \
    libvpx-dev \
    libvdpau-dev \
    libvorbis-dev \
    libopus-dev \
    libdc1394-22-dev \
    liblzma-dev && \
    rm -rf /var/lib/apt/lists/*

# copy libraries
WORKDIR /usr/local/lib
COPY --from=builder42 /usr/local/lib .
WORKDIR /usr/local/include
COPY --from=builder42 /home/ffmpeg_build/include .
WORKDIR /home/ffmpeg_build/lib
COPY --from=builder42 /home/ffmpeg_build/lib .
WORKDIR /usr/local/include/opencv4/
COPY --from=builder42 /usr/local/include/opencv4/ .
WORKDIR /home/opencv/build/lib
COPY --from=builder42 /home/opencv/build/lib .

# Set environment variables
ENV PATH="$PATH:/home/bin"
ENV PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/home/ffmpeg_build/lib/pkgconfig"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/home/opencv/build/lib"

WORKDIR /home/video_cap

COPY setup.py /home/video_cap
COPY src /home/video_cap/src/

# Install Python package
COPY vid.mp4 /home/video_cap
RUN cd /home/video_cap && \
  python3 setup.py install

CMD ["sh", "-c", "tail -f /dev/null"]
