#!/bin/bash
set -euo pipefail

REPO="hab56ur9/transcript"
APP="$HOME/Applications/Transcript.app"

echo "Transcript 설치 중..."
url="$(curl -fsSL "https://api.github.com/repos/$REPO/releases" 2>/dev/null | grep -o 'https://[^"]*/Transcript\.app\.zip' | head -1 || true)"
if [ -z "$url" ]
then
  echo "다운로드할 릴리즈를 찾지 못했습니다: https://github.com/$REPO/releases"
  exit 1
fi

tmp="$(mktemp -d)"
curl -fsSL -o "$tmp/Transcript.app.zip" "$url"
mkdir -p "$HOME/Applications"
rm -rf "$APP"
ditto -xk "$tmp/Transcript.app.zip" "$HOME/Applications"
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

curl -fsSL -o "$tmp/transcript" "https://raw.githubusercontent.com/$REPO/main/bin/transcript"
chmod +x "$tmp/transcript"

install_cli() {
  cp "$tmp/transcript" "$1/transcript"
  echo "CLI 설치됨: $1/transcript"
}

installed=""
for dir in /opt/homebrew/bin /usr/local/bin "$HOME/bin"
do
  if [ ! -d "$dir" ]
  then
    continue
  fi
  if [ ! -w "$dir" ]
  then
    continue
  fi
  install_cli "$dir"
  installed="yes"
  break
done

if [ -z "$installed" ]
then
  mkdir -p "$HOME/bin"
  install_cli "$HOME/bin"
  echo "참고: \$HOME/bin이 PATH에 없다면 추가해주세요"
fi

rm -rf "$tmp"
echo "설치 완료: $APP — 'transcript' 명령으로 실행하세요"
