# gomobile android/iOS sample

## Setup

### for iOS

- Xcode7 install
- npm install -g ios-deploy

**Create Certificate for iOS Code signing**

- Open Preferences of Xcode7.
- Select Accounts and append own account.
- Click 'View Details' button for own account.
- Show 'Sigining Identities'
- Click 'Create' button for 'iOS Development'

### for Android

- android-platform-tools install
- android-apktool install
- java runtime environment(> 1.8) install

### gomobile

```sh
go get -u golang.org/x/mobile/cmd/...
gomobile init
```

### icon generator

```sh
curl -kL https://raw.github.com/pypa/pip/master/contrib/get-pip.py | sudo python2
sudo pip2 install icons
```

## build & install iOS app

### first time

```sh
make app
open ./build/main.xcodeproj
# build -> Fix issues -> select AppleID
```

### 2 times onward

```sh
make app
make install-app
```

## build & install Android apk

```sh
make apk
make install-apk
```
