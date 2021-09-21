BUNDLE := dev.manticore.manticore

.PHONY: all clean

all: clean	
	xcodebuild clean build ONLY_ACTIVE_ARCH=NO PRODUCT_BUNDLE_IDENTIFIER='dev.manticore.manticore' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED="NO" -sdk iphoneos -scheme manticore -configuration Debug -derivedDataPath build
	ln -sf build/Build/Products/Debug-iphoneos Payload
	rm -rf Payload/Manticore.app/Frameworks
	zip -r9 Manticore.ipa Payload/Manticore.app

clean:
	rm -rf build Payload Manticore.ipa
