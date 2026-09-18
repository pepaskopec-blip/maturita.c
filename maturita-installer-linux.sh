#!/bin/sh
# maturita.c installer for Linux.
#
# Carries no application of its own. Fastly caches branch-named URLs on
# raw.githubusercontent.com, so this script looks up the tip of `builds`
# and downloads that commit — not a stale AppImage from the last five minutes.
#
# Double-click the file (or run: sh maturita-installer-linux.sh).
# The app updates itself from then on.

set -eu

REPO="pepaskopec-blip/maturita.c"
BRANCH="builds"
ASSET="maturita-linux-x86_64.AppImage"

DEST_DIR="$HOME/Applications"
DEST="$DEST_DIR/maturita.AppImage"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"

say() { printf '%s\n' "$*"; }
die() {
    printf '\nError: %s\n' "$*" >&2
    printf 'Press Enter to close. '
    read -r _ || true
    exit 1
}

builds_sha() {
    curl -fsSL --max-time 20 \
        "https://github.com/$REPO/commits/$BRANCH.atom" |
        sed -n 's/.*Commit\/\([0-9a-f]\{40\}\).*/\1/p' |
        head -n 1
}

say "Installing maturita.C"
say "---------------------"

arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
    die "only x86_64 builds are published, but this machine reports '$arch'.
Build from source instead: https://github.com/$REPO"
fi

command -v curl >/dev/null 2>&1 || die "curl was not found. Install it first."

mkdir -p "$DEST_DIR"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

say "Looking up the latest build..."
sha=$(builds_sha)
[ ${#sha} -eq 40 ] || die "could not find the latest build on GitHub."
URL="https://raw.githubusercontent.com/$REPO/$sha/$ASSET"

say "Downloading build $(printf '%.7s' "$sha")..."
curl -fL --progress-bar --max-time 1800 -o "$tmp/$ASSET" "$URL" ||
    die "the download failed. Check your internet connection."

say "Installing to $DEST"
chmod +x "$tmp/$ASSET"
mv -f "$tmp/$ASSET" "$DEST" || die "could not write to $DEST_DIR."

if (cd "$tmp" && "$DEST" --appimage-extract \
        'usr/share/icons/hicolor/512x512/apps/maturita.png' >/dev/null 2>&1); then
    icon="$tmp/squashfs-root/usr/share/icons/hicolor/512x512/apps/maturita.png"
    if [ -f "$icon" ]; then
        mkdir -p "$ICON_DIR"
        cp -f "$icon" "$ICON_DIR/maturita.png"
    fi
fi

mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/maturita.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=maturita.C
Comment=Practice app for the Czech maturita exam
Exec=$DEST
Icon=maturita
Terminal=false
Categories=Education;
EOF

command -v update-desktop-database >/dev/null 2>&1 &&
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true

say ""
say "Done. Starting the app..."
"$DEST" >/dev/null 2>&1 &
