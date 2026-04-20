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
	if [ -d "/Applications/Dicto.app" ]; then \
		echo "→ Alte Version wird ersetzt..."; \
		rm -rf "/Applications/Dicto.app"; \
	fi; \
	cp -R "$$BUILD_DIR/Dicto.app" /Applications/; \
	echo "✓ Dicto.app ist jetzt unter /Applications verfügbar."

# ── Clean ─────────────────────────────────────────────────────────────────────
.PHONY: clean
clean:
	@echo "→ Cleaning build artifacts..."
	rm -rf build/ DerivedData/
	xcodebuild clean -scheme $(SCHEME) -destination '$(DESTINATION)' 2>/dev/null || true
