LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := lite
LOCAL_SRC_FILES := lib/$(TARGET_ARCH_ABI)/liblite.a
include $(PREBUILT_STATIC_LIBRARY)


include $(CLEAR_VARS)

LOCAL_MODULE := main
SDL_PATH := ../SDL

LOCAL_SHARED_LIBRARIES := SDL2
LOCAL_STATIC_LIBRARIES := lite
LOCAL_LDLIBS := -lOpenSLES -llog -landroid -lm

include $(BUILD_SHARED_LIBRARY)
