#!/bin/bash
# Build script for android. Assumes that you have the Android NDK installed,
# as well as gradle. Assumes you're building on Linux.

# Takes a list of plugins to install (including native ones), to bundle as part of your core plugins.

[[ "$@" == "clean" ]] && rm -rf com.litexl.litexl/build com.litexl.litexl/app/jni/src/lib && exit -1

ANDROID_ARCH=26
[[ ! -d $ANDROID_NDK_HOME ]] && echo "Please define \$ANDROID_NDK_HOME." && exit -1
[[ ! -d "lib/lite-xl-simplified" ]] && echo "Please run `git submodule update --init`." && exit -1

[[ ! -e "lpm" ]] && curl -L https://github.com/lite-xl/lite-xl-plugin-manager/releases/download/latest/lpm.x86_64-linux > lpm && chmod +x lpm

ASSET_FOLDER="com.litexl.litexl/app/src/main/assets" && rm -rf $ASSET_FOLDER/user && mkdir $ASSET_FOLDER/user

# Install all desired plugins.
LPM_ARGUMENTS="--userdir $ASSET_FOLDER/user --arch x86-android --arch x86_64-android --arch aarch64-android --arch armv7a-android"
[[ "$@" != "" ]] && { ./lpm install $@ $LPM_ARGUMENTS && ./lpm purge $LPM_ARGUMENTS || { echo "Can't install $@." && exit -1; }; }

# Go through, and build liblite.a for each target.
declare -a TARGETS=("armv7a-linux-androideabi" "i686-linux-android" "aarch64-linux-android" "x86_64-linux-android")
declare -a JNILIBS=("armeabi-v7a" "x86" "arm64-v8a" "x86_64")
for TARGET_IDX in {0..3}; do
  export TARGET=${TARGETS[TARGET_IDX]}
  export JNILIB=${JNILIBS[TARGET_IDX]}
  export CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/$TARGET$ANDROID_ARCH-clang
  export AR=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar
  (cd lib/lite-xl-simplified && ./build.sh clean && CFLAGS="-Ilib/SDL/include" ./build.sh  -DNO_SDL -DNO_LINK && $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar -r liblite.a src/*.o src/api/*.o;) || exit -1
  mkdir -p com.litexl.litexl/app/jni/src/lib/$JNILIB && mv lib/lite-xl-simplified/liblite.a com.litexl.litexl/app/jni/src/lib/$JNILIB/liblite.a
done

(cd com.litexl.litexl && ./gradlew buildDebug) || { echo "Can't build gradle." && exit -1; }

echo "Done."
