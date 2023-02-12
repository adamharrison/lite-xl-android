#!/bin/bash
# Build script for android. Assumes that you have the Android NDK installed,
# as well as gradle. Assumes you're building on Linux.

# Takes a list of plugins to install (including native ones), to bundle as part of your core plugins.
: ${ANDROID_ARCH=26}
: ${BIN=lite-xl.apk}
: ${APP=com.litexl.litexl}
SDL="lib/lite-xl-simplified/lib/SDL"

BUILD_TYPE=Debug && BUILD_FOLDER=debug
[[ "$@" == *"-O"* ]] && BUILD_TYPE=Release && BUILD_FOLDER=release
[[ ! -d $ANDROID_NDK_HOME ]] && echo "Please define \$ANDROID_NDK_HOME." && exit -1
[[ ! -d $SDL ]] && echo "Please run `git submodule update --init --recursive`." && exit -1

[[ "$@" == "clean" ]] && rm -rf $APP $BIN && exit -1

# Copy over the android sample project from SDL, and merge in our changes.
[[ ! -d $APP ]] && cp -r $SDL/android-project $APP && mkdir -p $APP/app/jni/SDL && cp $SDL/Android.mk $APP/app/jni/SDL && rm -rf $APP/app/jni/src && cp -r template/* $APP

# Install all desired plugins, if any.
ASSET_FOLDER="$APP/app/src/main/assets" && rm -rf $ASSET_FOLDER/user && mkdir $ASSET_FOLDER/user
if [[ "$LITEXL_PLUGINS" != "" ]]; then
  [[ ! -e "lpm" ]] && { curl -L https://github.com/lite-xl/lite-xl-plugin-manager/releases/download/latest/lpm.x86_64-linux > lpm && chmod +x lpm  || { echo "Unable to download lpm." && exit -1; }; }
  LPM_ARGUMENTS="--userdir $ASSET_FOLDER/user --arch x86-android --arch x86_64-android --arch aarch64-android --arch armv7a-android"
  ./lpm install $LITEXL_PLUGINS $LPM_ARGUMENTS && ./lpm purge $LPM_ARGUMENTS || { echo "Can't install $@." && exit -1; }
fi

(cd $APP && ./gradlew build$BUILD_TYPE) || { echo "Can't build gradle." && exit -1; }

# Go through, and build main.so for each target, linking against the SDL we just built, because Android's build process really sucks.
declare -a TARGETS=("armv7a-linux-androideabi" "i686-linux-android" "aarch64-linux-android" "x86_64-linux-android")
declare -a JNILIBS=("armeabi-v7a" "x86" "arm64-v8a" "x86_64")
declare -a LITELIBS=("arm-android" "x86-android" "aarch64-android" "x86_64-android")
WD=`pwd`
for TARGET_IDX in {0..3}; do
  export TARGET=${TARGETS[TARGET_IDX]}
  export JNILIB=${JNILIBS[TARGET_IDX]}
  export LITELIB=${LITELIBS[TARGET_IDX]}
  export VERSION=2.1.1-$LITELIB-`git rev-parse --short HEAD`
  if [[ $REBUILD_LITE != "" || ! -f $APP/app/src/main/jniLibs/$JNILIB/libmain.so ]]; then
    (cd lib/lite-xl-simplified && rm -f lite.so && ./build.sh clean && CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/$TARGET$ANDROID_ARCH-clang AR=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar BIN='lite.so' LLFLAGS="-g -fPIC" ./build.sh -DLITE_VERSION='"'$VERSION'"' -L$WD/$APP/app/build/intermediates/ndkBuild/$BUILD_FOLDER/obj/local/$JNILIB -lSDL2 -fPIC -Ilib/SDL/include -lSDL2 -shared $@ -DNO_SDL;) || exit -1
    mkdir -p $APP/app/src/main/jniLibs/$JNILIB && mv lib/lite-xl-simplified/lite.so $APP/app/src/main/jniLibs/$JNILIB/libmain.so
  fi
done

(cd $APP && ./gradlew assemble$BUILD_TYPE) || { echo "Can't build gradle." && exit -1; }

cp $APP/app/build/outputs/apk/$BUILD_FOLDER/*.apk $BIN

echo "Done."
