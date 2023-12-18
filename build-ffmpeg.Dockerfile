# use this if you want to setup ffmpeg in a multi-staged docker build, and you want to configure it yourself

# step 1: build ffmpeg
FROM ubuntu:22.04 as build-ffmpeg

ENV TZ=Europe/Brussels
ENV DEBIAN_FRONTEND=noninteractive
ENV FFMPEG_VERSION=6.1
ENV XDG_CACHE_HOME=/cache

WORKDIR /ffmpeg

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,target=/cache,sharing=locked \
    apt-get update && \
	apt-get install -y --no-install-recommends \
	autoconf \
	automake \
	build-essential \
	cmake \
	git-core \
	libass-dev \
	libfreetype6-dev \
	libgnutls28-dev \
	libmp3lame-dev \
	libsdl2-dev \
	libtool \
	libva-dev \
	libvdpau-dev \
	libvorbis-dev \
	libxcb1-dev \
	libxcb-shm0-dev \
	libxcb-xfixes0-dev \
	meson \
	ninja-build \
	pkg-config \
	texinfo \
	wget \
	yasm \
    libx264-dev \
    ca-certificates \
	zlib1g-dev


WORKDIR /app

RUN mkdir -p /app/ffmpeg_sources /app/ffmpeg_build /app/bin /app/lib

WORKDIR /app/ffmpeg_sources

RUN wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2

RUN tar xjvf ffmpeg-snapshot.tar.bz2

WORKDIR /app/ffmpeg_sources/ffmpeg

ENV PATH="/app/bin:${PATH}"
ENV PKG_CONFIG_PATH="/app/ffmpeg_build/lib/pkgconfig"

# view https://gist.github.com/omegdadi/6904512c0a948225c81114b1c5acb875 for a list of all configure options
RUN ./configure \
    --prefix="/app/ffmpeg_build" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I/app/ffmpeg_build/include" \
    --extra-ldflags="-L/app/ffmpeg_build/lib" \
    --extra-libs="-lpthread -lm" \
    --bindir="/app/bin" \
    --arch=$TARGETARCH \
    \
    --disable-debug \
    --disable-doc \
    --disable-autodetect \
    \
    --enable-gpl \
    --enable-libx264 \
    --enable-zlib \
    \
    --disable-ffplay

RUN make clean
RUN make -j$(nproc)
RUN make install
RUN hash -r


# step 2: copy the ffmpeg binary into a minimal image
FROM ubuntu:22.04 as runtime

ENV TZ=Europe/Brussels
ENV DEBIAN_FRONTEND=noninteractive

COPY --from=build-ffmpeg /app/bin/ffmpeg /usr/local/bin/ffmpeg

# make sure to add dependencies here if you add more ffmpeg configure options
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,target=/cache,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    libx264-dev \
    ca-certificates \
    zlib1g-dev

CMD ["ffmpeg", "-version"]