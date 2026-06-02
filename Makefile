.DEFAULT_GOAL := build

SCHEME := Dicto
DESTINATION := platform=macOS,arch=arm64

# ── Dependencies ────────────────────────────────────────────────────────────
.PHONY: install
install:
	@echo "→ Installing dependencies..."
	@which xcodegen > /dev/null || brew install xcodegen
	@which swiftformat > /dev/null || brew install swiftformat

# ── Code generation ─────────────────────────────────────────────────────────
.PHONY: generate
generate:
	@echo "→ Generating Xcode project..."
	xcodegen generate

# ── Formatting ───────────────────────────────────────────────────────────────
.PHONY: format
format:
	@echo "→ Formatting Swift sources..."
	swiftformat Sources/ tests/

# ── Build ────────────────────────────────────────────────────────────────────
.PHONY: build
build: generate
	@echo "→ Building $(SCHEME)..."
	xcodebuild build \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		| xcpretty || xcodebuild build -scheme $(SCHEME) -destination '$(DESTINATION)'

# ── Test ─────────────────────────────────────────────────────────────────────
.PHONY: test
test: generate
	@echo "→ Running tests..."
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		| xcpretty || xcodebuild test -scheme $(SCHEME) -destination '$(DESTINATION)'

# ── Install to /Applications ─────────────────────────────────────────────────
.PHONY: install-app
install-app: build
	@echo "→ Installing Dicto.app to /Applications..."
	@BUILD_DIR=$$(xcodebuild -scheme $(SCHEME) -destination '$(DESTINATION)' \
		-showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | head -1 | awk '{print $$3}'); \
	if [ -z "$$BUILD_DIR" ]; then echo "✗ Build-Verzeichnis nicht gefunden."; exit 1; fi; \
	pkill -f "/Applications/Dicto.app" 2>/dev/null; sleep 1; \
	if [ -d "/Applications/Dicto.app" ]; then \
		echo "→ Inhalte werden in-place aktualisiert (Accessibility-Berechtigung bleibt erhalten)..."; \
		rsync -a --delete "$$BUILD_DIR/Dicto.app/" "/Applications/Dicto.app/"; \
	else \
		cp -R "$$BUILD_DIR/Dicto.app" /Applications/; \
	fi; \
	echo "✓ Dicto.app aktualisiert – Accessibility-Berechtigung bleibt erhalten."; \
	open /Applications/Dicto.app

# ── Release Archive ───────────────────────────────────────────────────────────
# Baut ein signiertes Release-Archiv für die GitHub-Veröffentlichung.
# Voraussetzung: Apple Developer ID Application Zertifikat im Keychain.
# Aufruf: make archive TEAM_ID=XXXXXXXXXX
TEAM_ID ?= UNSET
VERSION := $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
	"Sources/App/Info.plist" 2>/dev/null || grep CFBundleShortVersionString project.yml \
	| awk -F'"' '{print $$2}')

.PHONY: archive
archive: generate
	@echo "→ Building Release Archive v$(VERSION)..."
	@mkdir -p release
	xcodebuild archive \
		-scheme $(SCHEME) \
		-archivePath release/Dicto.xcarchive \
		-destination 'generic/platform=macOS' \
		CODE_SIGN_IDENTITY="Developer ID Application" \
		DEVELOPMENT_TEAM=$(TEAM_ID) \
		| xcpretty || xcodebuild archive \
			-scheme $(SCHEME) \
			-archivePath release/Dicto.xcarchive \
			-destination 'generic/platform=macOS'
	@echo "→ Exporting .app from archive..."
	@xcodebuild -exportArchive \
		-archivePath release/Dicto.xcarchive \
		-exportOptionsPlist scripts/ExportOptions.plist \
		-exportPath release/export
	@echo "→ Creating zip for notarization..."
	@ditto -c -k --keepParent release/export/Dicto.app release/Dicto-v$(VERSION).zip
	@echo "✓ release/Dicto-v$(VERSION).zip bereit für Notarisierung."
	@echo ""
	@echo "Nächster Schritt: make notarize TEAM_ID=$(TEAM_ID) APPLE_ID=deine@email.com"

.PHONY: notarize
notarize:
	@echo "→ Notarisierung bei Apple einreichen..."
	xcrun notarytool submit release/Dicto-v$(VERSION).zip \
		--apple-id $(APPLE_ID) \
		--team-id $(TEAM_ID) \
		--password $(APP_PASSWORD) \
		--wait
	@echo "→ Notarization-Ticket stempeln..."
	xcrun stapler staple release/export/Dicto.app
	@echo "→ Finales DMG erstellen..."
	@which create-dmg > /dev/null || brew install create-dmg
	create-dmg \
		--volname "Dicto $(VERSION)" \
		--window-size 660 400 \
		--icon-size 128 \
		--icon "Dicto.app" 180 170 \
		--app-drop-link 480 170 \
		"release/Dicto-$(VERSION).dmg" \
		"release/export/Dicto.app"
	@echo "✓ release/Dicto-$(VERSION).dmg ist fertig für den GitHub Release."

# ── DMG ohne Notarisierung (für Releases ohne Apple Developer Account) ────────
# Voraussetzung: make archive wurde bereits ausgeführt (release/export/Dicto.app existiert)
.PHONY: dmg
dmg:
	@echo "→ Erstelle DMG (ohne Notarisierung) v$(VERSION)..."
	@which create-dmg > /dev/null || brew install create-dmg
	@rm -f "release/Dicto-$(VERSION).dmg"
	create-dmg \
		--volname "Dicto $(VERSION)" \
		--window-size 660 400 \
		--icon-size 128 \
		--icon "Dicto.app" 180 170 \
		--app-drop-link 480 170 \
		"release/Dicto-$(VERSION).dmg" \
		"release/export/Dicto.app"
	@echo "✓ release/Dicto-$(VERSION).dmg fertig."
	@echo "  Hinweis: Nicht notarisiert – Nutzer müssen beim ersten Start Rechtsklick → Öffnen verwenden."

# ── Clean ─────────────────────────────────────────────────────────────────────
.PHONY: clean
clean:
	@echo "→ Cleaning build artifacts..."
	rm -rf build/ DerivedData/
	xcodebuild clean -scheme $(SCHEME) -destination '$(DESTINATION)' 2>/dev/null || true
