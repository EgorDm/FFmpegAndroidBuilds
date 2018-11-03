#!/bin/bash

NDK="/opt/android-sdk/ndk-bundle"
TARGET_API="android-21"
TOOLCHAIN_PATH="/ext_stor/Development/CPP/libs/toolchains"
ARCHES=("arm" "arm64" "x86" "x84_64")

PREV_PATH=$PATH

MODULES="\
	--disable-debug \
        --disable-avdevice \
        --disable-avfilter \
        --disable-swscale \
        --enable-ffmpeg \
        --disable-ffplay \
        --disable-network \
        --disable-muxers \
        --disable-demuxers \
        --enable-rdft \
        --enable-demuxer=aac \
        --enable-demuxer=ac3 \
        --enable-demuxer=ape \
        --enable-demuxer=asf \
        --enable-demuxer=flac \
        --enable-demuxer=matroska_audio \
        --enable-demuxer=mp3 \
        --enable-demuxer=mpc \
        --enable-demuxer=mov \
        --enable-demuxer=mpc8 \
        --enable-demuxer=ogg \
        --enable-demuxer=tta \
        --enable-demuxer=wav \
        --enable-demuxer=wv \
        --disable-bsfs \
        --disable-filters \
        --disable-parsers \
        --enable-parser=aac \
        --enable-parser=ac3 \
        --enable-parser=mpegaudio \
        --disable-protocols \
        --enable-protocol=file \
        --disable-indevs \
        --disable-outdevs \
        --disable-encoders \
        --disable-decoders \
        --enable-decoder=aac \
        --enable-decoder=ac3 \
        --enable-decoder=alac \
        --enable-decoder=ape \
        --enable-decoder=flac \
        --enable-decoder=mp1 \
        --enable-decoder=mp2 \
        --enable-decoder=mp3 \
        --enable-decoder=mpc7 \
        --enable-decoder=mpc8 \
        --enable-decoder=tta \
        --enable-decoder=vorbis \
        --enable-decoder=wavpack \
        --enable-decoder=wmav1 \
        --enable-decoder=wmav2 \
        --enable-decoder=pcm_alaw \
        --enable-decoder=pcm_dvd \
        --enable-decoder=pcm_f32be \
        --enable-decoder=pcm_f32le \
        --enable-decoder=pcm_f64be \
        --enable-decoder=pcm_f64le \
        --enable-decoder=pcm_s16be \
        --enable-decoder=pcm_s16le \
        --enable-decoder=pcm_s16le_planar \
        --enable-decoder=pcm_s24be \
        --enable-decoder=pcm_daud \
        --enable-decoder=pcm_s24le \
        --enable-decoder=pcm_s32be \
        --enable-decoder=pcm_s32le \
        --enable-decoder=pcm_s8 \
        --enable-decoder=pcm_u16be \
        --enable-decoder=pcm_u16le \
        --enable-decoder=pcm_u24be \
        --enable-decoder=pcm_u24le \
        --enable-decoder=rawvideo
	"

function build_android() {
  ARCH=$1
  TOOLCHAIN="$TOOLCHAIN_PATH/$ARCH"

  echo "================= STARTING BUILD AND CONFIG FOR $ARCH"

  if [ $ARCH == "arm" ]; then
	CONFIG_FLAGS="--arch=arm --enable-neon"
	ARCH_NAME="arm-linux-androideabi-"
  elif [ $ARCH == "arm64" ]; then
	CONFIG_FLAGS="--arch=aarch64 --enable-yasm"
	ARCH_NAME="aarch64-linux-android-"
  elif [ $ARCH == "x86" ]; then
	CONFIG_FLAGS="--arch=x86 --cpu=i686 --enable-yasm"
	ARCH_NAME="i686-linux-android-"
  elif [ $ARCH == "x86_64" ]; then
	CONFIG_FLAGS="--arch=x86_64 --enable-yasm"
	ARCH_NAME="x86_64-linux-android-"
  fi

  if [ ! -d "$TOOLCHAIN" ]; then
	  echo "======== Creating TOOLCHAIN"
	  bash $NDK/build/tools/make-standalone-toolchain.sh \
	    	--arch=$ARCH \
	    	--platform=$TARGET_API \
	    	--install-dir=$TOOLCHAIN
  else
	  echo "======== Using existing toolchain $TOOLCHAIN"
  fi

  export PATH=$PREV_PATH:$TOOLCHAIN/bin
  CROSS_PREFIX=$TOOLCHAIN/bin/$ARCH_NAME

  export AR=${CROSS_PREFIX}ar
  export AS=${CROSS_PREFIX}clang
  export CC=${CROSS_PREFIX}clang
  export CXX=${CROSS_PREFIX}clang++
  export LD=${CROSS_PREFIX}ld
  export STRIP=${CROSS_PREFIX}strip

  export CFLAGS="-fPIE -fPIC"
  export LDFLAGS="-pie"

  echo "======== Configuring"
  ./configure \
	  --prefix=./android/$ARCH \
	  --logfile=conflog-$ARCH.txt \
	  --target-os=linux \
	  --cross-prefix=$CROSS_PREFIX \
	  --sysroot=$TOOLCHAIN/sysroot \
	  $CONFIG_FLAGS \
	  --enable-shared \
	  --enable-static \
	  --enable-small \
	  --enable-optimizations \
	  $MODULES

  echo "======== Building"
  make clean
  make -j4
  make install
}

for a in "${ARCHES[@]}"
do
build_android $a
done
