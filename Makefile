# Makefile for AwemeBypass Tweak (Non-Jailbreak compatible)
# Uses substitute instead of CydiaSubstrate

ARCHS = arm64 arm64e
TARGET = iphone:latest:11.0

THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222
INSTALL_TARGET_PROCESSES = AwemeHM

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AwemeBypass
AwemeBypass_FILES = Tweak.xm
AwemeBypass_CFLAGS = -fobjc-arc
# Use substitute for non‑jailbreak injection
AwemeBypass_LDFLAGS = -lsubstitute

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 AwemeHM || true"