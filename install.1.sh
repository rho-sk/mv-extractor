#!/bin/bash

INSTALL_BASE_DIR="$PWD/.."
INSTALL_DIR="$PWD"

echo "Installing module into: $INSTALL_DIR"

###############################################################################
#
#							FFMPEG
#
###############################################################################

# Install FFMPEG dependencies
apt-get update -qq --fix-missing && \
apt-get upgrade -y && \
apt-get -y install \
    libass-dev \
    libfreetype6-dev \
    libsdl2-dev \
    libtool \
    libva-dev \
    libvdpau-dev \
    libvorbis-dev \
    libxcb1-dev \
    libxcb-shm0-dev \
    libxcb-xfixes0-dev \
    texinfo \
    zlib1g-dev \
    nasm \
    yasm \
    libnuma-dev \
    libvpx-dev \
    libfdk-aac-dev \
    libmp3lame-dev \
    libopus-dev



# Download FFMPEG source
FFMPEG_VERSION="4.1.3"
mkdir -p "$INSTALL_BASE_DIR"/ffmpeg_sources/ffmpeg "$INSTALL_BASE_DIR"/bin
cd "$INSTALL_BASE_DIR"/ffmpeg_sources
wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-"$FFMPEG_VERSION".tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2 -C "$INSTALL_BASE_DIR"/ffmpeg_sources/ffmpeg --strip-components=1
rm -rf "$INSTALL_BASE_DIR"/ffmpeg_sources/ffmpeg-snapshot.tar.bz2
cd "$INSTALL_BASE_DIR"/ffmpeg_sources/ffmpeg


# Install patch for FFMPEG which exposes timestamp in AVPacket
export FFMPEG_INSTALL_DIR="$INSTALL_BASE_DIR/ffmpeg_sources/ffmpeg"
export FFMPEG_PATCH_DIR="$INSTALL_DIR/ffmpeg_patch"

chmod +x "$FFMPEG_PATCH_DIR"/patch.sh
"$FFMPEG_PATCH_DIR"/patch.sh


cd "$INSTALL_BASE_DIR"/ffmpeg_sources && \
git -C x264 pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
cd x264 && \
PATH="$INSTALL_BASE_DIR/bin:$PATH" PKG_CONFIG_PATH="$INSTALL_BASE_DIR/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$INSTALL_BASE_DIR/ffmpeg_build" --bindir="$INSTALL_BASE_DIR/bin" --enable-static --enable-pic && \
PATH="$INSTALL_BASE_DIR/bin:$PATH" make && \
make install

#cd "$INSTALL_BASE_DIR"/ffmpeg_sources && \
#wget -O x265.tar.bz2 https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2 && \
#tar xjvf x265.tar.bz2 && \
#cd multicoreware*/build/linux && \
#PATH="$INSTALL_BASE_DIR/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$INSTALL_BASE_DIR/ffmpeg_build" -DENABLE_SHARED=off ../../source && \
#PATH="$INSTALL_BASE_DIR/bin:$PATH" make && \
#make install


# Compile FFMPEG
cd "$INSTALL_BASE_DIR"/ffmpeg_sources/ffmpeg && \
./configure \
--prefix="$INSTALL_BASE_DIR/ffmpeg_build" \
--pkg-config-flags="--static" \
--extra-cflags="-I$INSTALL_BASE_DIR/ffmpeg_build/include -static" \
--extra-ldflags="-L$INSTALL_BASE_DIR/ffmpeg_build/lib -static" \
--extra-libs="-lpthread -lm" \
--bindir="$INSTALL_BASE_DIR/bin" \
--enable-gpl \
--enable-libfreetype \
--enable-libmp3lame \
--enable-libopus \
--enable-libvpx \
--enable-libx264 \
--enable-nonfree \
--enable-pic && \
make -j $(nproc) && \
make install && \
hash -r
