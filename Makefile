# SaveSpace Makefile

.PHONY: build release dmg clean run help

# Default target
help:
	@echo "SaveSpace Build Commands:"
	@echo "  make build   - Build debug version"
	@echo "  make release - Build release version"
	@echo "  make dmg     - Build release and create DMG"
	@echo "  make run     - Build and run debug version"
	@echo "  make clean   - Clean build artifacts"

# Build debug version
build:
	xcodebuild -project SaveSpace.xcodeproj -scheme SaveSpace -configuration Debug build

# Build release version
release:
	xcodebuild -project SaveSpace.xcodeproj -scheme SaveSpace -configuration Release build

# Create DMG
dmg:
	./scripts/build-dmg.sh

# Build and run
run: build
	@APP_PATH=$$(xcodebuild -project SaveSpace.xcodeproj -scheme SaveSpace -configuration Debug -showBuildSettings | grep -m 1 "BUILT_PRODUCTS_DIR" | awk '{print $$3}'); \
	open "$$APP_PATH/SaveSpace.app"

# Clean build artifacts
clean:
	xcodebuild -project SaveSpace.xcodeproj -scheme SaveSpace clean
	rm -rf build/
	rm -rf DerivedData/
