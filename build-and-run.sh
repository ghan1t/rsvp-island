#!/bin/zsh

set -euo pipefail

root_dir="${0:A:h}"
derived_data_dir="$root_dir/.build/signed"
app_path="$derived_data_dir/Build/Products/Debug/RSVPIsland.app"

xcodebuild \
  -project "$root_dir/RSVPIsland.xcodeproj" \
  -scheme RSVPIsland \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$derived_data_dir" \
  build

# Ensure `open` launches this build if another development copy is running.
pkill -x RSVPIsland 2>/dev/null || true
open "$app_path"
