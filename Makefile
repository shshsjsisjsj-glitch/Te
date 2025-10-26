ARCHS := arm64  # arm64e
TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES := TrollSpeed

# المسارات الأساسية
ENT_PLIST := $(CURDIR)/supports/entitlements.plist
LAUNCHD_PLIST := $(THEOS_PROJECT_DIR)/layout/Library/LaunchDaemons/ch.xxtou.hudapp.plist

include $(THEOS)/makefiles/common.mk

# بيانات الإصدار والاسم
GIT_TAG_SHORT := $(shell git describe --tags --always --abbrev=0)
APPLICATION_NAME := TrollSpeed

# إعدادات المشروع
TrollSpeed_USE_MODULES := 0

# ملفات السورس
TrollSpeed_FILES += $(wildcard sources/*.mm sources/*.m)
TrollSpeed_FILES += $(wildcard sources/KIF/*.mm sources/KIF/*.m)
TrollSpeed_FILES += $(wildcard sources/*.swift)
TrollSpeed_FILES += $(wildcard sources/SPLarkController/*.swift)
TrollSpeed_FILES += $(wildcard sources/SnapshotSafeView/*.swift)

# دعم Swift bridging header
TrollSpeed_SWIFT_BRIDGING_HEADER += supports/hudapp-bridging-header.h

# إعدادات الترجمة (CFLAGS و CCFLAGS)
TrollSpeed_CFLAGS += -fobjc-arc
TrollSpeed_CFLAGS += -Iheaders
TrollSpeed_CFLAGS += -Isources
TrollSpeed_CFLAGS += -Isources/KIF
TrollSpeed_CFLAGS += -include supports/hudapp-prefix.pch
MainApplication.mm_CCFLAGS += -std=c++14

# إعدادات الربط (Linking)
TrollSpeed_LDFLAGS += -Flibraries

# الإطارات (Frameworks)
TrollSpeed_FRAMEWORKS += CoreGraphics CoreServices QuartzCore IOKit UIKit
TrollSpeed_PRIVATE_FRAMEWORKS += BackBoardServices GraphicsServices SpringBoardServices

# الربط مع entitlements
TrollSpeed_CODESIGN_FLAGS += -Sentitlements.plist

# تضمين قواعد بناء تطبيق iOS
include $(THEOS_MAKE_PATH)/application.mk

# بناء المشاريع الفرعية إن لم يكن البناء النهائي
ifneq ($(FINALPACKAGE),1)
SUBPROJECTS += memory_pressure
include $(THEOS_MAKE_PATH)/aggregate.mk
endif

# قبل عملية البناء
before-all::
	$(ECHO_NOTHING)defaults write $(LAUNCHD_PLIST) ProgramArguments -array "$(THEOS_PACKAGE_INSTALL_PREFIX)/Applications/TrollSpeed.app/TrollSpeed" "-hud" || true$(ECHO_END)
	$(ECHO_NOTHING)plutil -convert xml1 $(LAUNCHD_PLIST)$(ECHO_END)

# قبل التغليف النهائي
before-package::
	$(ECHO_NOTHING)mv -f $(THEOS_STAGING_DIR)/usr/local/bin/memory_pressure $(THEOS_STAGING_DIR)/Applications/TrollSpeed.app || true$(ECHO_END)
	$(ECHO_NOTHING)rmdir $(THEOS_STAGING_DIR)/usr/local/bin $(THEOS_STAGING_DIR)/usr/local $(THEOS_STAGING_DIR)/usr || true$(ECHO_END)

# بعد التغليف النهائي (إنشاء ملف .tipa)
after-package::
	$(ECHO_NOTHING)mkdir -p packages $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cp -rp $(THEOS_STAGING_DIR)$(THEOS_PACKAGE_INSTALL_PREFIX)/Applications/TrollSpeed.app $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)defaults delete $(THEOS_STAGING_DIR)/Payload/TrollSpeed.app/Info.plist CFBundleIconName || true$(ECHO_END)
	$(ECHO_NOTHING)plutil -convert xml1 $(THEOS_STAGING_DIR)/Payload/TrollSpeed.app/Info.plist$(ECHO_END)
	$(ECHO_NOTHING)cd $(THEOS_STAGING_DIR); zip -qr TrollSpeed_${GIT_TAG_SHORT}.tipa Payload; cd -;$(ECHO_END)
	$(ECHO_NOTHING)mv $(THEOS_STAGING_DIR)/TrollSpeed_${GIT_TAG_SHORT}.tipa packages/TrollSpeed_${GIT_TAG_SHORT}.tipa$(ECHO_END)
