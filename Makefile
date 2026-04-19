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

# ── Clean ─────────────────────────────────────────────────────────────────────
.PHONY: clean
clean:
	@echo "→ Cleaning build artifacts..."
	rm -rf build/ DerivedData/
	xcodebuild clean -scheme $(SCHEME) -destination '$(DESTINATION)' 2>/dev/null || true
