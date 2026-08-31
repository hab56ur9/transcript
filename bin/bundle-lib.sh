#!/bin/bash

app_version() {
  local root="$1"
  python3 -c "import json; print(json.load(open('$root/plugin/.claude-plugin/plugin.json'))['version'])"
}

assemble_app() {
  local app="$1" bundle_id="$2" display="$3" root="$4"
  local version
  version="$(app_version "$root")"
  rm -rf "$app"
  mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
  cp "$root/.build/release/Transcript" "$app/Contents/MacOS/Transcript"
  for bundle in "$root/.build/release/"*.bundle
  do
    if [ -e "$bundle" ]
    then
      cp -R "$bundle" "$app/Contents/Resources/"
    fi
  done
  if [ -f "$root/assets/AppIcon.icns" ]
  then
    cp "$root/assets/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
  fi
  cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>Transcript</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIdentifier</key><string>$bundle_id</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$display</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$version</string>
  <key>CFBundleVersion</key><string>$version</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSMicrophoneUsageDescription</key><string>Transcript records the microphone to transcribe meetings in real time.</string>
  <key>NSAudioCaptureUsageDescription</key><string>Transcript captures system audio to transcribe remote meeting participants.</string>
</dict>
</plist>
PLIST
  codesign --force --sign - --identifier "$bundle_id" "$app"
}
