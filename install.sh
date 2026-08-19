#!/bin/sh

REPO="https://raw.githubusercontent.com/charudkelser/luci-controller-telegrambot/main/files"

echo "======================================"
echo " Telegram Bot OpenWrt Installer"
echo "======================================"
echo ""

download_file() {
    SRC="$1"
    DST="$2"

    echo "[+] Installing $DST"

    mkdir -p "$(dirname "$DST")"

    if ! wget -qO "$DST" "$REPO/$SRC"; then
        echo "[!] Failed: $SRC"
        rm -f "$DST"
        return 1
    fi
}

# PROGRAM FILES
download_file "usr/bin/bot" "/usr/bin/bot"
download_file "etc/init.d/bot" "/etc/init.d/bot"
download_file "usr/lib/lua/luci/controller/bot.lua" "/usr/lib/lua/luci/controller/bot.lua"
download_file "usr/lib/lua/luci/model/cbi/bot.lua" "/usr/lib/lua/luci/model/cbi/bot.lua"

# CONFIG
# Jangan menimpa konfigurasi yang sudah ada
if [ ! -f /etc/config/bot ]; then
    echo "[+] Creating /etc/config/bot"
    download_file "etc/config/bot" "/etc/config/bot"
else
    echo "[i] /etc/config/bot already exists - keeping existing config"
fi

# DATA FILES
if [ ! -f /etc/known_macs.txt ]; then
    touch /etc/known_macs.txt
fi

if [ ! -f /etc/active_macs.txt ]; then
    touch /etc/active_macs.txt
fi

# PERMISSION
chmod +x /usr/bin/bot
chmod +x /etc/init.d/bot

# SERVICE
/etc/init.d/bot enable
/etc/init.d/bot restart

echo ""
echo "======================================"
echo " Telegram Bot berhasil diinstall!"
echo "======================================"
echo ""
echo "LuCI: Services -> Telegram Bot"
echo ""
