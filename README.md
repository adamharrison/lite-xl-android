# lite-xl-android

A simple project which enables an easy build of generic lite to android.

## Building

Currently, building is only supported on linux.

In order to build, simply ensure:

1. You have all submodules by doing `git submodule update --init --recursive`.
2. You've installed the [android-ndk](https://developer.android.com/ndk) set `$ANDROID_NDK_HOME`, to the path of your NDK.
3. Set `$LITEXL_PLUGINS` to a space separated list of all the plugins you'd like to bundle into this android build.

Then do `./build.sh -g` to produce a debug build. Or `./build.sh` to produce a `lite-xl.apk` in the main directory.
