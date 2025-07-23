#!/bin/bash
CONFIG_FILE="/home/xui/config/config.ini"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Please install XUI.one and run this again."
  exit 1
fi

is_valid_license() {
  [[ "$1" =~ ^[0-9a-fA-F]{16}$ ]]
}

# Geçerli lisans var mı kontrol et
current_license=$(sed -n 's/^license\s*=\s*"\([^"]*\)".*/\1/p' "$CONFIG_FILE")

if ! is_valid_license "$current_license"; then
  # Geçerli değilse otomatik lisans üret
  generated_license=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 16 | head -n 1)
  echo "[+] No valid license found. Generating license: $generated_license"

  if grep -q "^license" "$CONFIG_FILE"; then
    sed -i "s/^license\s*=.*/license     =   \"$generated_license\"/" "$CONFIG_FILE"
  else
    echo "license     =   \"$generated_license\"" >> "$CONFIG_FILE"
  fi

  echo "License updated in config.ini"
else
  echo "License: $current_license"
fi

echo ""
echo "Patching XUI extension...."

# Patch dosyalarını indir
wget -q -O /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20170718/xui.so \
  https://github.com/adilem/XUIPatch/raw/refs/heads/main/extension_7.2.so

wget -q -O /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/xui.so \
  https://github.com/adilem/XUIPatch/raw/refs/heads/main/extension_7.4.so

# Dosyalar indirildi mi?
if [ ! -f "/home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20170718/xui.so" ] || \
   [ ! -f "/home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/xui.so" ]; then
  echo "❌ One or more extension files failed to download."
  exit 1
fi

# Dosya sahipliğini ayarla
chown xui:xui /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-2017*/xui.so

# Lisans dosyası oluştur (gerekirse)
touch /home/xui/config/license
chmod 600 /home/xui/config/license

# XUI servisini yeniden başlat
echo "[+] Restarting XUI service..."
service xuione restart

# Sistem durumunu göster
/home/xui/status

echo ""
echo "✅ Patch and license applied automatically."
