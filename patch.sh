#!/bin/bash

CONFIG_FILE="/home/xui/config/config.ini"

# Check if config.ini exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ XUI is not installed. Please install XUI.one first."
  exit 1
fi

# Validate license format (16-character hex)
is_valid_license() {
  [[ "$1" =~ ^[0-9a-fA-F]{16}$ ]]
}

# Read current license from config.ini
current_license=$(sed -n 's/^license\s*=\s*"\([^"]*\)".*/\1/p' "$CONFIG_FILE")

if ! is_valid_license "$current_license"; then
  while true; do
    read -rp "Enter license key (16 hex characters): " input_license
    if is_valid_license "$input_license"; then
      sed -i "s/^license\s*=.*/license     =   \"$input_license\"/" "$CONFIG_FILE"
      echo "✅ License updated in config.ini"
      break
    else
      echo "❌ Invalid license format. Please try again."
    fi
  done
else
  echo "✅ License found: $current_license"
fi

echo ""
echo "[+] Downloading XUI extension patch files..."

# Download .so extension files
wget -q -O /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20170718/xui.so \
  https://github.com/adilem/XUIPatch/raw/refs/heads/main/extension_7.2.so

wget -q -O /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/xui.so \
  https://github.com/adilem/XUIPatch/raw/refs/heads/main/extension_7.4.so

# Check if files were downloaded successfully
if [ ! -f "/home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20170718/xui.so" ] || \
   [ ! -f "/home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/xui.so" ]; then
  echo "❌ Failed to download patch files. Aborting."
  exit 1
fi

# Fix file ownership
chown xui:xui /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-2017*/xui.so

# Restart XUI service
echo "[+] Restarting XUI service..."
service xuione restart >/dev/null 2>&1
sleep 1

# Display XUI status
echo ""
/home/xui/status 2>/dev/null || echo "⚠️ Could not retrieve XUI status."

echo ""
echo "✅ Patch applied, license configured, and service restarted successfully."
exit 0
