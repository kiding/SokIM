#!/bin/bash
set -Eeuxo pipefail

APP='/Users/kiding/Desktop/SokIM 2023-04-17 17-31-46/SokIM.app'

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
    SokIM_component.pkg

  productbuild \
    --synthesize \
    --package SokIM_component.pkg \
    Distribution.xml

  productbuild \
    --distribution Distribution.xml \
    --package-path . \
    SokIM_unsigned.pkg

  productsign \
    --sign "Developer ID Installer: Dong Sung Kim (MHKL47BD47)" \
    SokIM_unsigned.pkg \
    SokIM.pkg
  open .
popd
