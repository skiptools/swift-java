#!/bin/bash

set -x
set -e

# WORKAROUND: prebuilts broken on Swift 6.2.1 and Linux and tests using macros https://github.com/swiftlang/swift-java/issues/418
if [ "$(uname)" = "Darwin" ]; then
  DISABLE_EXPERIMENTAL_PREBUILTS=''
else
  DISABLE_EXPERIMENTAL_PREBUILTS='--disable-experimental-prebuilts'
fi

# FIXME: disable prebuilts until prebuilt swift-syntax isn't broken on 6.2 anymore: https://github.com/swiftlang/swift-java/issues/418
swift build $DISABLE_EXPERIMENTAL_PREBUILTS --disable-sandbox

./gradlew test
