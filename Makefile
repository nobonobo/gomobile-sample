PKG=noboapp1
NAME=$(basename $(PKG))
LABEL=Noboapp1

WORK=$(PWD)
GOMOBILEPATH:=$(GOPATH)
GOMOBILE=$(GOMOBILEPATH)/pkg/gomobile
GOMOBILEBIN=$(GOMOBILEPATH)/bin/gomobile
BUILD=$(WORK)/build
export GOPATH:=$(GOMOBILEPATH):$(PWD)

CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
CXX=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
SDK=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.0.sdk
ADB=/opt/homebrew-cask/Caskroom/genymotion/2.5.2/Genymotion.app/Contents/MacOS/tools/adb
SUBJ=CN=$(NAME),O=$(NAME).gomobile.apps,C=JP
KEYSTOREPASS=password

SRC=$(shell find ./src -name *.go)

.PHONY: all icons apk app install-apk install-app clean

all: apk app

app: $(BUILD)/$(NAME).app
apk: $(BUILD)/$(NAME).apk

icons: $(BUILD)/main/Images.xcassets/AppIcon.appiconset $(BUILD)/icons

$(BUILD)/main/Images.xcassets/AppIcon.appiconset: $(WORK)/ios.png
	@-rm -rf $(BUILD)/main/Images.xcassets/AppIcon.appiconset $(BUILD)/main/Images.xcassets/iTunesArtwork*.png
	icons --device ios -o $(BUILD)/main/Images.xcassets $(WORK)/ios.png

$(BUILD)/icons: $(WORK)/android.png
	@-rm -rf $(BUILD)/icons
	icons --device android -o $(BUILD)/icons $(WORK)/android.png

$(GOMOBILE):
	GOPATH=$(GOMOBILEPATH) go get -u golang.org/x/mobile/cmd/...
	$(GOMOBILEPATH)/bin/gomobile init

$(BUILD)/main.xcodeproj: $(GOMOBILE)
	mkdir -p $(BUILD)
	eval $$($(GOMOBILEBIN) build -target ios -work -o $(BUILD)/$(NAME).app $(PKG) || true); \
	cp -Rf $$WORK/main.xcodeproj $(BUILD)/; \
	cp -Rf $$WORK/main $(BUILD)/
	touch $(WORK)/ios.png

$(BUILD)/$(NAME).app: $(BUILD)/main.xcodeproj $(BUILD)/main/Images.xcassets/AppIcon.appiconset $(SDK) $(SRC)
	GOOS=darwin GOARCH=arm GOARM=7 CC=$(CC) CXX=$(CXX) CGO_CFLAGS="-isysroot $(SDK) -arch armv7" CGO_LDFLAGS="-isysroot $(SDK) -arch armv7" CGO_ENABLED=1 go build -p=4 -pkgdir=$(GOMOBILE)/pkg_darwin_arm -tags="" -x -work -tags=ios -o=$(BUILD)/arm $(PKG)
	GOOS=darwin GOARCH=arm64 CC=$(CC) CXX=$(CXX) CGO_CFLAGS="-isysroot $(SDK) -arch arm64" CGO_LDFLAGS="-isysroot $(SDK) -arch arm64" CGO_ENABLED=1 go build -p=4 -pkgdir=$(GOMOBILE)/pkg_darwin_arm64 -tags="" -x -work -tags=ios -o=$(BUILD)/arm64 $(PKG)
	xcrun lipo -create $(BUILD)/arm $(BUILD)/arm64 -o $(BUILD)/main/main
	mkdir -p $(BUILD)/main/assets
	xcrun xcodebuild -configuration Release -project $(BUILD)/main.xcodeproj
	-rm -rf $(BUILD)/$(NAME).app
	mv $(BUILD)/build/Release-iphoneos/main.app $(BUILD)/$(NAME).app

$(BUILD)/$(NAME).apk: $(BUILD)/icons $(SRC) $(WORK)/AndroidManifest.xml
	$(GOMOBILEBIN) build -target android -o $(BUILD)/$(NAME).apk $(NAME)
	keytool -genkey -keystore $(BUILD)/app.keystore -storepass $(KEYSTOREPASS) \
	-dname "$(SUBJ)" -keypass $(KEYSTOREPASS) -keyalg RSA -validity 18250 \
	-alias $(NAME) || true
	rm -rf $(BUILD)/apk
	apktool decode -o $(BUILD)/apk $(BUILD)/$(NAME).apk
	mv -f $(BUILD)/$(NAME).apk $(BUILD)/$(NAME).bak
	mkdir $(BUILD)/apk/res
	cp -Rf $(BUILD)/icons/drawable* $(BUILD)/apk/res/
	cat $(WORK)/AndroidManifest.xml | \
		sed "s|{{NAME}}|$(NAME)|g" | \
		sed "s|{{LABEL}}|$(LABEL)|g" > $(BUILD)/apk/AndroidManifest.xml
	apktool build -o $(BUILD)/$(NAME).apk -f $(BUILD)/apk
	jarsigner \
    -verbose \
    -storepass $(KEYSTOREPASS) \
    -sigalg MD5withRSA \
    -digestalg SHA1 \
    -tsa http://timestamp.digicert.com \
    -keystore $(BUILD)/app.keystore \
    $(BUILD)/$(NAME).apk \
    $(NAME)

install-app: $(BUILD)/$(NAME).app
	ios-deploy -b $(BUILD)/$(NAME).app

install-apk: $(BUILD)/$(NAME).apk
	$(ADB) install -r $(BUILD)/$(NAME).apk

clean:
	@-rm -rf $(BUILD) $(WORK)/res/icons $(BUILD)/main/Images.xcassets/AppIcon.appiconset
