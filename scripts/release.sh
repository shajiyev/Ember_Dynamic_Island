#!/bin/bash
# Makes a release of Ember (docs/specs/auto-updates.md, "Releasing a version"):
#   1. sets the version (and the build number one higher) in the project,
#   2. builds Release, signed with "Ember Code Signing",
#   3. makes Ember-<version>.zip (for Sparkle) and Ember-<version>.dmg in build/release/,
#   4. signs the zip with Sparkle's key from the login keychain,
#   5. adds the version to site/appcast.xml.
# Then, by hand: create the GitHub Release v<version> with the zip, the DMG and its notes,
# and commit the project and the appcast.
#
# Run from anywhere, on the Mac that holds the keys:
#     scripts/release.sh 1.1
# A trial that changes nothing in the repository (same version, prints the appcast entry):
#     DRY_RUN=1 scripts/release.sh 1.1

set -euo pipefail

VERSION="${1:?Usage: scripts/release.sh <version>, such as 1.1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/release"
DERIVED="$OUT/DerivedData"
PROJECT="$ROOT/Ember.xcodeproj/project.xcproj"
APPCAST="$ROOT/site/appcast.xml"
REPO="https://github.com/shajiyev/Ember_Dynamic_Island"
DRY_RUN="${DRY_RUN:-0}"

# 1. The version.
BUILD=$(sed -n 's/.*"CURRENT_PROJECT_VERSION": "\([0-9]*\)".*/\1/p' "$PROJECT" | head -n 1)
if [ "$DRY_RUN" = 1 ]; then
    echo "Dry run: the project keeps its version (build $BUILD)."
else
    BUILD=$((BUILD + 1))
    sed -i '' -e "s/\"MARKETING_VERSION\": \"[^\"]*\"/\"MARKETING_VERSION\": \"$VERSION\"/" \
              -e "s/\"CURRENT_PROJECT_VERSION\": \"[0-9]*\"/\"CURRENT_PROJECT_VERSION\": \"$BUILD\"/" "$PROJECT"
    echo "Version $VERSION, build $BUILD."
fi

# 2. The build, signed with the project's own certificate.
rm -rf "$OUT"
mkdir -p "$OUT"
# Any Mac: Apple silicon and Intel in one app.
xcodebuild -project "$ROOT/Ember.xcodeproj" -scheme Ember -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath "$DERIVED" clean build -quiet
APP="$DERIVED/Build/Products/Release/Ember.app"
codesign --verify --deep --strict "$APP"
SIGNED_BY=$(codesign -dvv "$APP" 2>&1)
case "$SIGNED_BY" in
    *"Authority=Ember Code Signing"*) ;;
    *) echo "Ember.app is not signed with Ember Code Signing." >&2; exit 1 ;;
esac

# 3. The zip for Sparkle and the DMG for first downloads (with a link to Applications).
ZIP="$OUT/Ember-$VERSION.zip"
DMG="$OUT/Ember-$VERSION.dmg"
ditto -c -k --keepParent "$APP" "$ZIP"
STAGE="$OUT/dmg"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Ember" -srcfolder "$STAGE" -ov -format UDZO "$DMG" -quiet
rm -rf "$STAGE"

# 4. Sparkle's signature: sparkle:edSignature="…" length="…".
SIGN_UPDATE=$(find "$DERIVED/SourcePackages/artifacts" -path '*Sparkle/bin/sign_update' | head -n 1)
SIGNATURE=$("$SIGN_UPDATE" "$ZIP")

# 5. The appcast entry.
ITEM="    <item>
      <title>Version $VERSION</title>
      <pubDate>$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>$REPO/releases/tag/v$VERSION</sparkle:releaseNotesLink>
      <enclosure url=\"$REPO/releases/download/v$VERSION/Ember-$VERSION.zip\" type=\"application/octet-stream\" $SIGNATURE />
    </item>"
if [ "$DRY_RUN" = 1 ]; then
    echo "Dry run: the appcast would get:"
    echo "$ITEM"
else
    ITEM="$ITEM" perl -0pi -e 's{  </channel>}{$ENV{ITEM}\n  </channel>}' "$APPCAST"
    echo "Added version $VERSION to site/appcast.xml."
fi

echo "Made $ZIP and $DMG."
echo "Next: create the GitHub Release v$VERSION with both files and its notes, then commit the project and the appcast."
