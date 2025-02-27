export ARCHS := arm64
PACKAGE_FORMAT = ipa
#TARGET := iphone:clang:latest:13.0:7.0
TARGET := iphone:clang:latest:14.0:13.5
#TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES = Geode

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Geode

Geode_FILES = $(wildcard src/*.m) $(wildcard src/components/*.m) $(wildcard src/LCUtils/*.m) $(wildcard src/LCUtils/AltStoreCore*.m) fishhook/fishhook.c $(wildcard MSColorPicker/MSColorPicker/*.m)
Geode_FRAMEWORKS = UIKit CoreGraphics
Geode_CFLAGS = -fobjc-arc
Geode_CODESIGN_FLAGS = -Sentitlements.xml
Geode_LIBRARIES = archive # thats dumb
#Geode_LDFLAGS = -lxml2 -framework CoreGraphics
$(APPLICATION_NAME)_LDFLAGS = -e _GeodeMain -rpath @loader_path/Frameworks

include $(THEOS_MAKE_PATH)/application.mk
SUBPROJECTS += ZSign TweakLoader
include $(THEOS_MAKE_PATH)/aggregate.mk

#@cp Geode.ios.dylib $(THEOS_STAGING_DIR)/Applications/Geode.app/Frameworks
before-package::
	@mv $(THEOS_STAGING_DIR)/Applications/Geode.app/Geode $(THEOS_STAGING_DIR)/Applications/Geode.app/GeodeLauncher_PleaseDoNotShortenTheExecutableNameBecauseItIsUsedToReserveSpaceForOverwritingThankYou
	
before-all::
	@sh ./download_openssl.sh
