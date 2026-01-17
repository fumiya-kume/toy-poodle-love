.PHONY: generate build test clean

generate:
	xcodegen generate

build: generate
	xcodebuild -project handheld.xcodeproj -scheme handheld -sdk iphonesimulator build

test: generate
	xcodebuild test -project handheld.xcodeproj -scheme handheldTests -destination 'platform=iOS Simulator,name=iPhone 17'

clean:
	rm -rf handheld.xcodeproj
	rm -rf ~/Library/Developer/Xcode/DerivedData/handheld-*
