#!/bin/bash
set -Eeuxo pipefail

APP_PATH="${1:?}"
PASSWORD="${2:?}"

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
    cp -rfv "$APP_PATH" .
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
    --sign 'Developer ID Installer: Dong Sung Kim (MHKL47BD47)' \
    SokIM_unsigned.pkg \
    SokIM.pkg

  SUBMISSION_ID="$(xcrun notarytool submit \
    SokIM.pkg \
    --apple-id 'kiding@me.com' \
    --password "$PASSWORD" \
    --team-id 'MHKL47BD47' \
    | awk '/id: / {print $2; exit 0;}' || true)"

  xcrun notarytool wait \
    "$SUBMISSION_ID" \
    --apple-id 'kiding@me.com' \
    --password "$PASSWORD" \
    --team-id 'MHKL47BD47'

  stapler staple SokIM.pkg
  stapler validate SokIM.pkg
    
  open .
popd
