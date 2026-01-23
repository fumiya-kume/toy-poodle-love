.PHONY: generate build test clean build-mac test-mac

XCODE_TOOLCHAINS ?= com.apple.dt.toolchain.XcodeDefault

generate:
	xcodegen generate

build: generate
	xcodebuild -project handheld.xcodeproj -scheme handheld -sdk iphonesimulator COMPILER_INDEX_STORE_ENABLE=NO TOOLCHAINS=$(XCODE_TOOLCHAINS) build

test: generate
	xcodebuild test -project handheld.xcodeproj -scheme handheld -destination 'platform=iOS Simulator,name=iPhone 16' COMPILER_INDEX_STORE_ENABLE=NO TOOLCHAINS=$(XCODE_TOOLCHAINS)

build-mac: generate
	xcodebuild -project handheld.xcodeproj -scheme handheld -destination 'platform=macOS,variant=Mac Catalyst' COMPILER_INDEX_STORE_ENABLE=NO TOOLCHAINS=$(XCODE_TOOLCHAINS) CODE_SIGNING_ALLOWED=NO build

test-mac: generate
	xcodebuild test -project handheld.xcodeproj -scheme handheld -destination 'platform=macOS,variant=Mac Catalyst' COMPILER_INDEX_STORE_ENABLE=NO TOOLCHAINS=$(XCODE_TOOLCHAINS) CODE_SIGNING_ALLOWED=NO

clean:
	rm -rf handheld.xcodeproj
	rm -rf ~/Library/Developer/Xcode/DerivedData/handheld-*
