#!/bin/bash

CONFIG_FILE="/home/xui/config/config.ini"

# Check if config.ini exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ XUI is not installed. Please install XUI.one first."
  exit 1
fi

# Check current license
is_valid_license() {
  [[ "$1" =~ ^[0-9a-fA-F]{16}$ ]]
}

current_license=$(sed -n 's/^license\s*=\s*"\([^"]*\)".*/\1/p' "$CONFIG_FILE")

if ! is_valid_license "$current_license"; then
  generated_license=$(tr -dc 'a-f0-9' < /dev/urandom | head -c 16)
  echo "[+] No valid license found. Generated: $generated_license"
  
  if grep -q "^license" "$CONFIG_FILE"; then
    sed -i "s/^license\s*=.*/license     =   \"$generated_license\"/" "$CONFIG_FILE"
  else
    echo "license     =   \"$generated_license\"" >> "$CONFIG_FILE"
  fi
  echo "✅ License updated in config.ini"
else
  echo "✅ Existing license: $current_license"
fi

echo ""
echo "[+] Downloading XUI extension patch files..."

# Download patch files
wget -q -O /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20170718/xui.so \
  https://github.com/adilem/XUIPatch/raw/refs/heads/main/extension_7.2.so

wget -q -O /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/xui.so \
  https://github.com/adilem/XUIPatch/raw/refs/heads/main/extension_7.4.so

# Validate download
if [ ! -f "/home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20170718/xui.so" ] || \
   [ ! -f "/home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/xui.so" ]; then
  echo "❌ Failed to download patch files."
  exit 1
fi

# Set file ownership
chown xui:xui /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-2017*/xui.so

# Ensure license file exists
touch /home/xui/config/license
chmod 600 /home/xui/config/license

# Restart service
echo "[+] Restarting XUI service..."
service xuione restart >/dev/null 2>&1
sleep 1

# Show status
echo ""
/home/xui/status 2>/dev/null || echo "⚠️ Could not retrieve XUI status."

# Done
echo ""
echo "✅ Patch applied and XUI restarted."
exit 0
