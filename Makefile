export ARCHS := arm64
PACKAGE_FORMAT = ipa
TARGET := iphone:clang:latest:13.0:7.0
INSTALL_TARGET_PROCESSES = Geode

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Geode

Geode_FILES = $(wildcard src/*.m)
Geode_FRAMEWORKS = UIKit CoreGraphics
Geode_CFLAGS = -fobjc-arc
Geode_CODESIGN_FLAGS = -Sentitlements.xml
Geode_LDFLAGS = -lxml2 -framework CoreGraphics

include $(THEOS_MAKE_PATH)/application.mk
