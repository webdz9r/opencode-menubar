APP_NAME = OpenCodeMenuBar
BUNDLE_ID = com.opencode.taskbar
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR = $(HOME)/Applications
SOURCES = $(wildcard Sources/*.swift)

# Code signing
SIGNING_IDENTITY = Developer ID Application: Chris Larson (9JCZHUAUEH)
TEAM_ID = 9JCZHUAUEH

# Notarization (override via env or CLI: make notarize NOTARY_KEY_ID=xxx)
NOTARY_KEY_ID ?= $(APP_STORE_KEY_ID)
NOTARY_ISSUER_ID ?= $(APP_STORE_ISSUER_ID)
NOTARY_KEY_PATH ?= $(wildcard AuthKey_*.p8)

.PHONY: all build clean sign notarize release install install-unsigned uninstall run

all: build

# --- Build ---

build: $(APP_BUNDLE)

$(APP_BUNDLE): $(SOURCES) Resources/Info.plist
	@echo "==> Compiling Swift sources..."
	@mkdir -p $(BUILD_DIR)
	swiftc \
		-o $(BUILD_DIR)/$(APP_NAME) \
		-framework Cocoa \
		-framework ServiceManagement \
		-target arm64-apple-macosx13.0 \
		-swift-version 5 \
		-O \
		$(SOURCES)
	@echo "==> Creating app bundle..."
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Resources/Info.plist $(APP_BUNDLE)/Contents/
	@echo "==> Ad-hoc signing app bundle..."
	codesign --force --deep --sign - $(APP_BUNDLE)
	@echo "==> Build complete: $(APP_BUNDLE)"

clean:
	@echo "==> Cleaning build directory..."
	rm -rf $(BUILD_DIR)
	@echo "==> Clean complete"

# --- Code Signing (Developer ID) ---

sign: build
	@echo "==> Signing with Developer ID..."
	codesign --force --deep \
		--sign "$(SIGNING_IDENTITY)" \
		--options runtime \
		--timestamp \
		$(APP_BUNDLE)
	@echo "==> Verifying signature..."
	codesign --verify --deep --strict --verbose=2 $(APP_BUNDLE)
	@echo "==> Signature valid"

# --- Notarization ---

notarize: sign
	@echo "==> Creating zip for notarization..."
	@rm -f $(BUILD_DIR)/$(APP_NAME).zip
	ditto -c -k --keepParent $(APP_BUNDLE) $(BUILD_DIR)/$(APP_NAME).zip
	@echo "==> Submitting to Apple for notarization..."
	xcrun notarytool submit $(BUILD_DIR)/$(APP_NAME).zip \
		--key "$(NOTARY_KEY_PATH)" \
		--key-id "$(NOTARY_KEY_ID)" \
		--issuer "$(NOTARY_ISSUER_ID)" \
		--wait
	@echo "==> Stapling notarization ticket..."
	xcrun stapler staple $(APP_BUNDLE)
	@echo "==> Verifying notarization..."
	spctl --assess --type execute --verbose=2 $(APP_BUNDLE)
	@echo "==> Notarization complete"
	@rm -f $(BUILD_DIR)/$(APP_NAME).zip

# --- Release (full pipeline) ---

release: notarize
	@echo "==> Release build ready: $(APP_BUNDLE)"
	@echo "    Signed with: $(SIGNING_IDENTITY)"
	@echo "    Notarized and stapled"

# --- Install ---

install: release
	@echo "==> Installing to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@-pkill -f "$(APP_NAME).app/Contents/MacOS/$(APP_NAME)" 2>/dev/null || true
	@sleep 0.5
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@cp -R $(APP_BUNDLE) "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "==> Installed: $(INSTALL_DIR)/$(APP_NAME).app"
	@echo "==> Launching $(APP_NAME)..."
	@open "$(INSTALL_DIR)/$(APP_NAME).app"

install-unsigned: build
	@echo "==> Installing (unsigned) to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@-pkill -f "$(APP_NAME).app/Contents/MacOS/$(APP_NAME)" 2>/dev/null || true
	@sleep 0.5
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@cp -R $(APP_BUNDLE) "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "==> Installed: $(INSTALL_DIR)/$(APP_NAME).app"
	@echo "==> Launching $(APP_NAME)..."
	@open "$(INSTALL_DIR)/$(APP_NAME).app"

uninstall:
	@echo "==> Stopping $(APP_NAME) if running..."
	@-pkill -f "$(APP_NAME).app/Contents/MacOS/$(APP_NAME)" 2>/dev/null || true
	@echo "==> Removing from $(INSTALL_DIR)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "==> Uninstall complete"

run: build
	@echo "==> Running $(APP_NAME)..."
	@open $(APP_BUNDLE)
