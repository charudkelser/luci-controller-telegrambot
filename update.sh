#!/bin/sh

REPO="https://raw.githubusercontent.com/charudkelser/luci-controller-telegrambot/main/files"

echo "======================================"
echo " Telegram Bot OpenWrt Updater"
echo "======================================"
echo ""

download_file() {
    SRC="$1"
    DST="$2"

    echo "[+] Updating $DST"

    TMP="/tmp/.telegrambot-update"

    if ! wget -qO "$TMP" "$REPO/$SRC"; then
        echo "[!] Failed: $SRC"
        rm -f "$TMP"
        return 1
    fi

    if [ ! -s "$TMP" ]; then
        echo "[!] Empty file: $SRC"
        rm -f "$TMP"
        return 1
    fi

    mkdir -p "$(dirname "$DST")"
    mv "$TMP" "$DST"

    return 0
}

# ======================================
# PROGRAM FILES
# ======================================

download_file \
    "usr/bin/bot" \
    "/usr/bin/bot"

download_file \
    "etc/init.d/bot" \
    "/etc/init.d/bot"

download_file \
    "usr/lib/lua/luci/controller/bot.lua" \
    "/usr/lib/lua/luci/controller/bot.lua"

download_file \
    "usr/lib/lua/luci/model/cbi/bot.lua" \
    "/usr/lib/lua/luci/model/cbi/bot.lua"

# ======================================
# PERMISSION
# ======================================

chmod +x /usr/bin/bot
chmod +x /etc/init.d/bot

# ======================================
# RESTART SERVICE
# ======================================

echo ""
echo "[+] Restarting Telegram Bot..."

if /etc/init.d/bot status >/dev/null 2>&1; then
    /etc/init.d/bot restart
else
    /etc/init.d/bot start
fi

echo ""
echo "======================================"
echo " Telegram Bot berhasil diperbarui!"
echo "======================================"
echo ""
