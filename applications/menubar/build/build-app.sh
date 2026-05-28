#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
VENDOR_DIR="$SCRIPT_DIR/vendor/bundle"

cd "$SCRIPT_DIR"

PLATYPUS_CLI=""

if [ -f "/opt/homebrew/Caskroom/platypus/5.5.0/Platypus.app/Contents/Resources/platypus_clt" ]; then
    PLATYPUS_CLI="/opt/homebrew/Caskroom/platypus/5.5.0/Platypus.app/Contents/Resources/platypus_clt"
elif [ -f "/usr/local/Caskroom/platypus/5.5.0/Platypus.app/Contents/Resources/platypus_clt" ]; then
    PLATYPUS_CLI="/usr/local/Caskroom/platypus/5.5.0/Platypus.app/Contents/Resources/platypus_clt"
elif command -v platypus &> /dev/null; then
    PLATYPUS_CLI="platypus"
else
    echo "❌ Platypus is not installed or CLI tool not found"
    echo "Install with: brew install platypus"
    echo ""
    echo "After installation, install the CLI tool:"
    echo "  Open Platypus.app → Preferences → Install CLI Tool"
    exit 1
fi

echo "Using Platypus CLI: $PLATYPUS_CLI"

if [ -n "$PLATYPUS_CLI_OVERRIDE" ]; then
    PLATYPUS_CLI="$PLATYPUS_CLI_OVERRIDE"
fi

PLATYPUS_RESOURCES_CHECK="${PLATYPUS_RESOURCES_CHECK:-/usr/local/share/platypus/ScriptExec}"

if [ ! -f "$PLATYPUS_RESOURCES_CHECK" ] && [[ "$PLATYPUS_CLI" == *"Caskroom"* ]]; then
    RESOURCES_DIR="$(dirname "$PLATYPUS_CLI")"
    INSTALL_SCRIPT="$RESOURCES_DIR/InstallCommandLineTool.sh"
    echo ""
    echo "❌ Platypus CLI resources not installed system-wide."
    echo "Run the following command to install them, then re-run this script:"
    echo ""
    echo "  sudo \"$INSTALL_SCRIPT\" \"$RESOURCES_DIR\""
    echo ""
    exit 1
fi

RUBY_INTERPRETER="$(which ruby)"
echo "Using Ruby interpreter: $RUBY_INTERPRETER"

rm -rf "$VENDOR_DIR"
(cd "$REPO_ROOT" && BUNDLE_PATH=applications/menubar/build/vendor/bundle bundle install --standalone)

"$PLATYPUS_CLI" \
  -y \
  --name "Ambx Lights" \
  --interface-type "Status Menu" \
  --interpreter "$RUBY_INTERPRETER" \
  --bundled-file "../../../libambx" \
  --bundled-file "./vendor/bundle" \
  --bundled-file "../config/colors.yml" \
  --bundled-file "../app.rb" \
  --bundled-file "../boot.rb" \
  --bundled-file "../brightness_actions.rb" \
  --bundled-file "../macos_volume.rb" \
  --status-item-icon "icon.png" \
  --quit-after-execution false \
  "../menubar.rb" \
  "./Ambx Lights.app"

echo "✓ Built: build/Ambx Lights.app"
