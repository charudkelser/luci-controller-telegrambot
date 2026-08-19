#!/bin/sh

REPO="https://raw.githubusercontent.com/charudkelser/luci-controller-telegrambot/main/files"

FILES="
usr/bin/bot:/usr/bin/bot
etc/init.d/bot:/etc/init.d/bot
usr/lib/lua/luci/controller/bot.lua:/usr/lib/lua/luci/controller/bot.lua
usr/lib/lua/luci/model/cbi/bot.lua:/usr/lib/lua/luci/model/cbi/bot.lua
"

echo "======================================"
echo " Telegram Bot OpenWrt Installer"
echo "======================================"
echo ""

# ======================================
# CHECK ROOT
# ======================================

if [ "$(id -u)" != "0" ]; then
    echo "[!] Installer harus dijalankan sebagai root."
    exit 1
fi

# ======================================
# DOWNLOAD TEMP FILE
# ======================================

download_temp() {
    SRC="$1"
    TMP="$2"

    rm -f "$TMP"

    if ! wget -qO "$TMP" "$REPO/$SRC"; then
        rm -f "$TMP"
        return 1
    fi

    if [ ! -s "$TMP" ]; then
        rm -f "$TMP"
        return 1
    fi

    return 0
}

# ======================================
# INSTALL FILE
# ======================================

install_file() {
    SRC="$1"
    DST="$2"

    TMP="/tmp/.telegrambot-install"

    echo "[+] Installing $DST"

    if ! download_temp "$SRC" "$TMP"; then
        echo "[!] Failed: $SRC"
        return 1
    fi

    mkdir -p "$(dirname "$DST")"

    mv "$TMP" "$DST"

    return 0
}

# ======================================
# UPDATE FILE
# ======================================

update_file() {
    SRC="$1"
    DST="$2"

    TMP="/tmp/.telegrambot-update"

    if [ ! -f "$DST" ]; then
        echo "[+] Missing: $DST"
        echo "    Installing..."
        install_file "$SRC" "$DST"
        return $?
    fi

    if ! download_temp "$SRC" "$TMP"; then
        echo "[!] Failed checking: $SRC"
        return 1
    fi

    LOCAL_SUM="$(md5sum "$DST" 2>/dev/null | awk '{print $1}')"
    REMOTE_SUM="$(md5sum "$TMP" 2>/dev/null | awk '{print $1}')"

    if [ "$LOCAL_SUM" = "$REMOTE_SUM" ]; then
        echo "[=] Up to date: $DST"
        rm -f "$TMP"
        return 0
    fi

    echo "[↑] Updating: $DST"

    mv "$TMP" "$DST"

    return 0
}

# ======================================
# INSTALL
# ======================================

do_install() {

    echo ""
    echo "======================================"
    echo " Installing Telegram Bot"
    echo "======================================"
    echo ""

    FAILED=0

    OLD_IFS="$IFS"
    IFS='
'

    for ITEM in $FILES; do

        SRC="${ITEM%%:*}"
        DST="${ITEM#*:}"

        if [ -f "$DST" ]; then
            echo "[i] Already installed: $DST"
        else
            if ! install_file "$SRC" "$DST"; then
                FAILED=1
            fi
        fi

    done

    IFS="$OLD_IFS"

    # ==================================
    # CONFIG
    # ==================================

    if [ ! -f /etc/config/bot ]; then

        echo "[+] Creating /etc/config/bot"

        if ! install_file "etc/config/bot" "/etc/config/bot"; then
            FAILED=1
        fi

    else

        echo "[i] /etc/config/bot already exists"
        echo "    Keeping existing configuration"

    fi

    # ==================================
    # DATA FILES
    # ==================================

    if [ ! -f /etc/known_macs.txt ]; then
        echo "[+] Creating /etc/known_macs.txt"
        touch /etc/known_macs.txt
    fi

    if [ ! -f /etc/active_macs.txt ]; then
        echo "[+] Creating /etc/active_macs.txt"
        touch /etc/active_macs.txt
    fi

    # ==================================
    # PERMISSION
    # ==================================

    chmod +x /usr/bin/bot 2>/dev/null
    chmod +x /etc/init.d/bot 2>/dev/null

    # ==================================
    # SERVICE
    # ==================================

    if [ -x /etc/init.d/bot ]; then

        /etc/init.d/bot enable

        echo ""
        echo "[+] Starting Telegram Bot..."

        /etc/init.d/bot restart

    fi

    echo ""

    if [ "$FAILED" = "1" ]; then

        echo "======================================"
        echo " Instalasi selesai dengan error!"
        echo "======================================"

        return 1

    fi

    echo "======================================"
    echo " Telegram Bot berhasil diinstall!"
    echo "======================================"
    echo ""
    echo "LuCI: Services -> Telegram Bot"
    echo ""

    return 0
}

# ======================================
# UPDATE
# ======================================

do_update() {

    echo ""
    echo "======================================"
    echo " Updating Telegram Bot"
    echo "======================================"
    echo ""

    FAILED=0

    OLD_IFS="$IFS"
    IFS='
'

    for ITEM in $FILES; do

        SRC="${ITEM%%:*}"
        DST="${ITEM#*:}"

        if ! update_file "$SRC" "$DST"; then
            FAILED=1
        fi

    done

    IFS="$OLD_IFS"

    # ==================================
    # PERMISSION
    # ==================================

    chmod +x /usr/bin/bot 2>/dev/null
    chmod +x /etc/init.d/bot 2>/dev/null

    # ==================================
    # SERVICE
    # ==================================

    if [ -x /etc/init.d/bot ]; then

        echo ""
        echo "[+] Restarting Telegram Bot..."

        /etc/init.d/bot restart

    fi

    echo ""

    if [ "$FAILED" = "1" ]; then

        echo "======================================"
        echo " Update selesai dengan error!"
        echo "======================================"

        return 1

    fi

    echo "======================================"
    echo " Telegram Bot berhasil diperbarui!"
    echo "======================================"
    echo ""

    return 0
}

# ======================================
# UNINSTALL
# ======================================

do_uninstall() {

    echo ""
    echo "======================================"
    echo " Copot Telegram Bot"
    echo "======================================"
    echo ""

    echo "[!] File berikut akan dihapus:"
    echo ""
    echo "/usr/bin/bot"
    echo "/etc/init.d/bot"
    echo "/usr/lib/lua/luci/controller/bot.lua"
    echo "/usr/lib/lua/luci/model/cbi/bot.lua"
    echo ""

    echo "[i] File konfigurasi dan data TIDAK akan dihapus:"
    echo ""
    echo "/etc/config/bot"
    echo "/etc/known_macs.txt"
    echo "/etc/active_macs.txt"
    echo ""

    printf "Lanjutkan copot pemasangan? [y/N]: "
    read ANSWER

    case "$ANSWER" in
        y|Y|yes|YES)
            ;;
        *)
            echo ""
            echo "[i] Copot pemasangan dibatalkan."
            return 0
            ;;
    esac

    echo ""

    if [ -x /etc/init.d/bot ]; then
        echo "[+] Stopping Telegram Bot..."
        /etc/init.d/bot stop 2>/dev/null
        /etc/init.d/bot disable 2>/dev/null
    fi

    echo "[+] Removing application files..."

    rm -f /usr/bin/bot
    rm -f /etc/init.d/bot
    rm -f /usr/lib/lua/luci/controller/bot.lua
    rm -f /usr/lib/lua/luci/model/cbi/bot.lua

    echo ""
    echo "======================================"
    echo " Telegram Bot berhasil dicopot!"
    echo "======================================"
    echo ""
    echo "Konfigurasi tetap disimpan:"
    echo "/etc/config/bot"
    echo ""
    echo "Data MAC tetap disimpan:"
    echo "/etc/known_macs.txt"
    echo "/etc/active_macs.txt"
    echo ""

    return 0
}

# ======================================
# MENU
# ======================================

while true; do

    INSTALLED=0

    if [ -x /usr/bin/bot ] && \
       [ -x /etc/init.d/bot ] && \
       [ -f /usr/lib/lua/luci/controller/bot.lua ] && \
       [ -f /usr/lib/lua/luci/model/cbi/bot.lua ]; then

        INSTALLED=1

    fi

    echo ""
    echo "======================================"
    echo " Telegram Bot OpenWrt"
    echo "======================================"

    if [ "$INSTALLED" = "1" ]; then
        echo " Status : TERINSTALL"
    else
        echo " Status : BELUM TERINSTALL"
    fi

    echo "======================================"
    echo ""
    echo "1. Install / Terinstall"
    echo "2. Update"
    echo "3. Copot Pemasangan"
    echo "0. Cancel"
    echo ""

    printf "Pilih [0-3]: "
    read MENU

    case "$MENU" in

        1)
            do_install
            ;;

        2)
            if [ "$INSTALLED" = "1" ]; then
                do_update
           
              else
                  echo ""
                  echo "[!] Telegram Bot belum terinstall."
                  echo "[i] Gunakan menu 1 terlebih dahulu."
              fi
              ;;

          3)
              if [ "$INSTALLED" = "1" ]; then
                  do_uninstall
              else
                  echo ""
                  echo "[i] Telegram Bot belum terinstall."
              fi
              ;;

          0)
              echo ""
              echo "Batal. Tidak ada perubahan."
              echo ""
              exit 0
              ;;

          *)
              echo ""
              echo "[!] Pilihan tidak valid."
              ;;

      esac

      echo ""
      printf "Tekan Enter untuk kembali ke menu..."
      read ENTER

done
