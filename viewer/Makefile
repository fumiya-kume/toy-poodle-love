.PHONY: generate build test clean run

XCODE_TOOLCHAINS ?= com.apple.dt.toolchain.XcodeDefault

generate:
	xcodegen generate

build: generate
	xcodebuild -project viewer.xcodeproj -scheme viewer -destination 'platform=macOS' COMPILER_INDEX_STORE_ENABLE=NO TOOLCHAINS=$(XCODE_TOOLCHAINS) build

test: generate
	xcodebuild test -project viewer.xcodeproj -scheme viewer -destination 'platform=macOS' COMPILER_INDEX_STORE_ENABLE=NO TOOLCHAINS=$(XCODE_TOOLCHAINS)

clean:
	rm -rf viewer.xcodeproj
	rm -rf ~/Library/Developer/Xcode/DerivedData/viewer-*

run: build
	open ~/Library/Developer/Xcode/DerivedData/viewer-*/Build/Products/Debug/VideoOverlayViewer.app
