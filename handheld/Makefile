.PHONY: generate build test clean build-mac test-mac

generate:
	xcodegen generate

build: generate
	xcodebuild -project handheld.xcodeproj -scheme handheld -sdk iphonesimulator build

test: generate
	xcodebuild test -project handheld.xcodeproj -scheme handheld -destination 'platform=iOS Simulator,name=iPhone 16'

build-mac: generate
	xcodebuild -project handheld.xcodeproj -scheme handheld -destination 'platform=macOS,variant=Mac Catalyst' CODE_SIGNING_ALLOWED=NO build

test-mac: generate
	xcodebuild test -project handheld.xcodeproj -scheme handheld -destination 'platform=macOS,variant=Mac Catalyst' CODE_SIGNING_ALLOWED=NO

clean:
	rm -rf handheld.xcodeproj
	rm -rf ~/Library/Developer/Xcode/DerivedData/handheld-*
