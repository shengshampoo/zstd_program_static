FROM alpine:latest

# https://mirrors.alpinelinux.org/
RUN sed -i 's@dl-cdn.alpinelinux.org@ftp.halifax.rwth-aachen.de@g' /etc/apk/repositories

RUN apk update
RUN apk upgrade

# required xz, lz4, and zstd
RUN apk add --no-cache \
  gcc make linux-headers musl-dev \
  zlib-dev zlib-static python3-dev \
  curl git xz grep jq meson ninja g++ bash tar

ENV XZ_OPT=-e9
COPY build-static-zstd.sh build-static-zstd.sh
RUN chmod +x ./build-static-zstd.sh
RUN bash ./build-static-zstd.sh
