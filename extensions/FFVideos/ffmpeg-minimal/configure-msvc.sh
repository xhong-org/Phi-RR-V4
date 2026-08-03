#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <ffmpeg-source> <install-prefix>" >&2
  exit 2
fi

source_dir="$(cd "$1" && pwd)"
prefix="$(mkdir -p "$2" && cd "$2" && pwd)"
build_dir="${prefix}/build"
mkdir -p "$build_dir"
cd "$build_dir"

"${source_dir}/configure" \
  --toolchain=msvc \
  --arch=x86_64 \
  --target-os=win32 \
  --prefix="$prefix" \
  --disable-shared \
  --enable-static \
  --disable-programs \
  --disable-avdevice \
  --disable-avfilter \
  --disable-swresample \
  --disable-doc \
  --disable-debug \
  --disable-network \
  --disable-autodetect \
  --disable-everything \
  --enable-small \
  --enable-avcodec \
  --enable-avformat \
  --enable-avutil \
  --enable-swscale \
  --enable-protocol=file \
  --enable-demuxer=mov,matroska,avi,flv,mpegts,mpegps,ogg \
  --enable-decoder=h264,hevc,mpeg4,vp8,vp9,av1,mjpeg,png,rawvideo,theora,wmv1,wmv2,wmv3,vc1 \
  --enable-parser=h264,hevc,mpeg4video,vp8,vp9,av1,mjpeg,vc1 \
  --enable-bsf=h264_mp4toannexb,hevc_mp4toannexb \
  --extra-cflags="-MD"

make clean
make -j2
make install
cp "${source_dir}/COPYING.LGPLv2.1" "${prefix}/COPYING.LGPLv2.1"
cp "${source_dir}/LICENSE.md" "${prefix}/FFmpeg-LICENSE.md"
