LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := main
LOCAL_SHARED_LIBRARIES := SDL2 main
LOCAL_SRC_FILES := lib/$(TARGET_ARCH_ABI)/libmain.so
LOCAL_LDLIBS := -lOpenSLES -llog -landroid -lm

include $(PREBUILT_SHARED_LIBRARY)
