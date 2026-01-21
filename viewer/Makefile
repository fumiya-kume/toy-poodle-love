.PHONY: generate build test clean run

XCODE_TOOLCHAINS ?= com.apple.dt.toolchain.XcodeDefault
CLONED_SOURCE_PACKAGES_DIR_PATH ?= .sourcepackages

generate:
	xcodegen generate

build: generate
	mkdir -p $(CLONED_SOURCE_PACKAGES_DIR_PATH)
	xcodebuild -project viewer.xcodeproj -scheme viewer -destination 'platform=macOS' -clonedSourcePackagesDirPath $(CLONED_SOURCE_PACKAGES_DIR_PATH) COMPILER_INDEX_STORE_ENABLE=NO TOOLCHAINS=$(XCODE_TOOLCHAINS) build

test: generate
	mkdir -p $(CLONED_SOURCE_PACKAGES_DIR_PATH)
	xcodebuild -project viewer.xcodeproj -scheme viewer -destination 'platform=macOS' -clonedSourcePackagesDirPath $(CLONED_SOURCE_PACKAGES_DIR_PATH) COMPILER_INDEX_STORE_ENABLE=NO TOOLCHAINS=$(XCODE_TOOLCHAINS) test

clean:
	rm -rf viewer.xcodeproj
	rm -rf ~/Library/Developer/Xcode/DerivedData/viewer-*

run: build
	open ~/Library/Developer/Xcode/DerivedData/viewer-*/Build/Products/Debug/VideoOverlayViewer.app
