### builder
FROM alpine:edge AS alpine-c-base-builder

RUN apk add --no-cache \
        build-base \
        curl \
        ffmpeg-dev \
        gcc \
        git \
        libusb \
        libusb-dev \
        make \
        meson \
        musl-dev \
        openjdk8 \
        pkgconf \
        sdl2-dev

FROM alpine-c-base-builder AS builder

ARG SCRCPY_VER=v2.7
ARG SERVER_HASH="0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"

RUN PATH=$PATH:/usr/lib/jvm/java-1.8-openjdk/bin
RUN curl -L -o scrcpy-server https://github.com/Genymobile/scrcpy/releases/download/v${SCRCPY_VER}/scrcpy-server-v${SCRCPY_VER}
RUN echo "$SERVER_HASH  /scrcpy-server" | sha256sum -c -
RUN git clone https://github.com/Genymobile/scrcpy.git
RUN cd scrcpy && meson x --buildtype release --strip -Db_lto=true -Dprebuilt_server=/scrcpy-server
RUN cd scrcpy/x && ninja

### runner
FROM alpine:edge AS runner

LABEL maintainer="Pierre Gordon <pierregordon@protonmail.com>"

# needed for android-tools
RUN echo https://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories


RUN apk add -U --no-cache \
        android-tools \
        ffmpeg \
        libusb \
        libusb-dev \
        virtualgl

COPY --from=builder /scrcpy-server /usr/local/share/scrcpy/
COPY --from=builder /scrcpy/x/app/scrcpy /usr/local/bin/

FROM runner AS gallium

RUN apk add --no-cache mesa-dri-gallium

#### runner (amd)
#FROM runner AS amd

##RUN apk add --no-cache mesa-dri-swrast

#### runner (intel)
#FROM runner AS intel

#RUN apk add --no-cache mesa-dri-intel

#### runner (nvidia)
#FROM runner AS nvidia

#RUN apk add --no-cache mesa-dri-nouveau
