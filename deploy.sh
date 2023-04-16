#!/bin/bash
set -Eeuxo pipefail

APP='/Users/kiding/Library/Developer/Xcode/Archives/2023-04-16/SokIM 2023-04-16 7.09 PM.xcarchive/Products/Applications/SokIM.app'

rm -rfv /tmp/SokIM
mkdir /tmp/SokIM
pushd /tmp/SokIM
  mkdir scripts
  pushd scripts
    cat > preinstall <<< '#!/bin/sh
killall KeyboardSettings keyboardservicesd TextInputMenuAgent TextInputSwitcher imklaunchagent SokIM || true
sleep 3
killall KeyboardSettings keyboardservicesd TextInputMenuAgent TextInputSwitcher imklaunchagent SokIM || true'
    chmod +x preinstall
  popd

  mkdir -p 'ROOT/Library/Input Methods/'
  pushd 'ROOT/Library/Input Methods/'
    cp -rfv "$APP" .
  popd

  pkgbuild \
    --root ROOT \
    --scripts scripts \
    --identifier com.kiding.inputmethod.sok \
    --sign "Developer ID Installer: Dongsung Kim" \
    SokIM.pkg
  open .
popd
