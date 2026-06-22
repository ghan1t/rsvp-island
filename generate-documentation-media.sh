#!/bin/zsh

set -euo pipefail

root_dir="${0:A:h}"
update_marker="$root_dir/.build/update-documentation-media"

mkdir -p "$root_dir/.build"
touch "$update_marker"
trap 'rm -f "$update_marker"' EXIT

xcodebuild \
  -project "$root_dir/RSVPIsland.xcodeproj" \
  -scheme RSVPIsland \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$root_dir/.build/documentation-media" \
  -only-testing:RSVPIslandTests/DocumentationMediaTests/testDocumentationMediaIsCurrent \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY=- \
  DEVELOPMENT_TEAM= \
  test

echo "Updated documentation media in $root_dir/docs/media"
