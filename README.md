# lite-xl-android

A simple project which enables an easy build of generic lite to android.

**Currently expeimental; so expect crashes, lack of features, version misconfigurations, etc..**

## Building

Currently, building is only supported on linux.

In order to build, simply ensure:

1. You have all submodules by doing `git submodule update --init --recursive`.
2. You've installed the [android-ndk](https://developer.android.com/ndk) set `$ANDROID_NDK_HOME`, to the path of your NDK, `$ANDROID_SDK_ROOT`, to the root of your SDK.
3. Set `$LITEXL_PLUGINS` to a space separated list of all the plugins you'd like to bundle into this android build.

Then do `./build.sh` to produce `lite-xl.apk` in the main directory.

## Releases

Release APKs are available for `armv7a`, `arm64-v8a`, `x86`, `x86_64` android. This is a debug APK, because it's not signed.

I may eventually get an android developer account to sign things, if I can get a reasonable android implementation going.

