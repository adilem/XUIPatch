#!/bin/bash

CONFIG_FILE="/home/xui/config/config.ini"

# Config dosyası kontrolü
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ XUI not installed. Please install XUI.one first."
  exit 1
fi

# Lisans format kontrolü
is_valid_license() {
  [[ "$1" =~ ^[0-9a-fA-F]{16}$ ]]
}

# Geçerli lisansı kontrol et
current_license=$(sed -n 's/^license\s*=\s*"\([^"]*\)".*/\1/p' "$CONFIG_FILE")

if ! is_valid_license "$current_license"; then
  generated_license=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 16 | head -n 1)
  echo "[+] No valid license found. Generating license: $generated_license"

  if grep -q "^license" "$CONFIG_FILE"; then
    sed -i "s/^license\s*=.*/license     =   \"$generated_license\"/" "$CONFIG_FILE"
  else
    echo "license     =   \"$generated_license\"" >> "$CONFIG_FILE"
  fi

  echo "✅ License updated in config.ini"
else
  echo "✅ License: $current_license"
fi

echo ""
echo "[+] Downloading XUI extension patches..."

# Patch dosyalarını indir
wget -q -O /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20170718/xui.so \
  https://github.com/adilem/XUIPatch/raw/refs/heads/main/extension_7.2.so

wget -q -O /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/xui.so \
  https://github.com/adilem/XUIPatch/raw/refs/heads/main/extension_7.4.so

# Dosya kontrolü
if [ ! -f "/home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20170718/xui.so" ] || \
   [ ! -f "/home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/xui.so" ]; then
  echo "❌ Patch download failed. Aborting."
  exit 1
fi

# Sahiplik ayarla
chown xui:xui /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-2017*/xui.so

# Lisans dosyası oluştur
touch /home/xui/config/license
chmod 600 /home/xui/config/license

# Servisi yeniden başlat (arka planda)
echo "[+] Restarting XUI service..."
/home/xui/service stop >/dev/null 2>&1 || true
sleep 1
nohup /home/xui/service start >/dev/null 2>&1 &
sleep 2

# Durumu sadece kısa özetle göster
STATUS_OUTPUT=$(/home/xui/status 2>/dev/null)

if echo "$STATUS_OUTPUT" | grep -q "XUI is running"; then
  echo ""
  echo "✅ XUI is running and patch was successful."
else
  echo ""
  echo "⚠️  XUI status check failed. Please verify manually."
fi

echo ""
echo "✅ Patch and license applied successfully. Script finished."
exit 0
