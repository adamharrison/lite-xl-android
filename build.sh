#!/bin/bash
# Build script for android. Assumes that you have the Android NDK installed,
# as well as gradle. Assumes you're building on Linux.

# Takes a list of plugins to install (including native ones), to bundle as part of your core plugins.
: ${ANDROID_ARCH=26}
: ${BIN=lite-xl.apk}

BUILD_TYPE=Release && BUILD_FOLDER=release
[[ "$@" == *"-g"* ]] && BUILD_TYPE=Debug && BUILD_FOLDER=debug
[[ ! -d $ANDROID_NDK_HOME ]] && echo "Please define \$ANDROID_NDK_HOME." && exit -1
[[ ! -d "lib/lite-xl-simplified" || ! -d "lib/lite-xl-simplified/lib/SDL" ]] && echo "Please run `git submodule update --init --recursive`." && exit -1


[[ "$@" == "clean" ]] && rm -rf com.litexl.litexl/build com.litexl.litexl/app/jni/src/lib $BIN && exit -1

# Install all desired plugins, if any.
ASSET_FOLDER="com.litexl.litexl/app/src/main/assets" && rm -rf $ASSET_FOLDER/user && mkdir $ASSET_FOLDER/user
if [[ "$LITEXL_PLUGINS" != "" ]]; then
  [[ ! -e "lpm" ]] && { curl -L https://github.com/lite-xl/lite-xl-plugin-manager/releases/download/latest/lpm.x86_64-linux > lpm && chmod +x lpm  || { echo "Unable to download lpm." && exit -1; }; }
  LPM_ARGUMENTS="--userdir $ASSET_FOLDER/user --arch x86-android --arch x86_64-android --arch aarch64-android --arch armv7a-android"
  ./lpm install $LITEXL_PLUGINS $LPM_ARGUMENTS && ./lpm purge $LPM_ARGUMENTS || { echo "Can't install $@." && exit -1; }
fi

# Go through, and build liblite.a for each target.
declare -a TARGETS=("armv7a-linux-androideabi" "i686-linux-android" "aarch64-linux-android" "x86_64-linux-android")
declare -a JNILIBS=("armeabi-v7a" "x86" "arm64-v8a" "x86_64")
for TARGET_IDX in {0..3}; do
  export TARGET=${TARGETS[TARGET_IDX]}
  export JNILIB=${JNILIBS[TARGET_IDX]}
  export CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/$TARGET$ANDROID_ARCH-clang
  export AR=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar
  if [[ ! -f com.litexl.litexl/app/jni/src/lib/$JNILIB/libmain.so ]]; then
    (cd lib/lite-xl-simplified && rm -f lite.so && ./build.sh clean && CFLAGS="-Ilib/SDL/include -fPIC" LLFLAGS='-fPIC' BIN='lite.so' ./build.sh -shared $@ -DNO_SDL;) || exit -1
    mkdir -p com.litexl.litexl/app/jni/src/lib/$JNILIB && mv lib/lite-xl-simplified/lite.so com.litexl.litexl/app/jni/src/lib/$JNILIB/libmain.so
  fi
done

(cd com.litexl.litexl && ./gradlew assemble$BUILD_TYPE) || { echo "Can't build gradle." && exit -1; }

cp com.litexl.litexl/app/build/outputs/apk/$BUILD_FOLDER/*.apk $BIN

echo "Done."
