#!/bin/sh

# ======================================
# Telegram Bot OpenWrt Installer
# ======================================

REPO="https://raw.githubusercontent.com/charudkelser/luci-controller-telegrambot/main/files"

TMP_BASE="/tmp/.telegrambot-installer"

FILES="
usr/bin/bot:/usr/bin/bot
etc/init.d/bot:/etc/init.d/bot
usr/lib/lua/luci/controller/bot.lua:/usr/lib/lua/luci/controller/bot.lua
usr/lib/lua/luci/model/cbi/bot.lua:/usr/lib/lua/luci/model/cbi/bot.lua
"

# ======================================
# CHECK ROOT
# ======================================

if [ "$(id -u)" != "0" ]; then
    echo ""
    echo "[!] Installer harus dijalankan sebagai root."
    echo ""
    exit 1
fi

# ======================================
# CLEAN TEMP
# ======================================

rm -f "$TMP_BASE"
rm -f "$TMP_BASE.update"
rm -f "$TMP_BASE.check"

# ======================================
# INPUT
# ======================================

read_input() {
    read "$@" </dev/tty
}

pause_menu() {
    echo ""
    printf "Tekan Enter untuk kembali ke menu..."
    read_input ENTER
}

# ======================================
# DOWNLOAD
# ======================================

download_file() {
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

    TMP="$TMP_BASE"

    echo "[+] Installing $DST"

    if ! download_file "$SRC" "$TMP"; then
        echo "[!] Gagal download: $SRC"
        return 1
    fi

    mkdir -p "$(dirname "$DST")"

    if ! mv "$TMP" "$DST"; then
        rm -f "$TMP"
        echo "[!] Gagal memasang: $DST"
        return 1
    fi

    return 0
}

# ======================================
# DETECT INSTALLATION
# ======================================

is_installed() {
    if [ -x /usr/bin/bot ] &&
       [ -x /etc/init.d/bot ] &&
       [ -f /usr/lib/lua/luci/controller/bot.lua ] &&
       [ -f /usr/lib/lua/luci/model/cbi/bot.lua ]; then
        return 0
    fi

    return 1
}

# ======================================
# SERVICE STATUS
# ======================================

service_running() {
    if [ -x /etc/init.d/bot ]; then
        if /etc/init.d/bot status >/dev/null 2>&1; then
            return 0
        fi
    fi

    if pgrep -f '/usr/bin/bot' >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

# ======================================
# ROUTER REBOOT PERMISSION
# ======================================

fix_router_reboot_permission() {

    mkdir -p /etc/router-reboot
    chmod 700 /etc/router-reboot 2>/dev/null

    if [ -f /usr/bin/router-reboot ]; then
        chmod 755 /usr/bin/router-reboot 2>/dev/null
    fi

    if [ -f /etc/router-reboot/router_reboot ]; then
        chmod 600 /etc/router-reboot/router_reboot 2>/dev/null
    fi
}

# ======================================
# CHECK UPDATE
# ======================================

check_updates() {

    UPDATE_COUNT=0
    MISSING_COUNT=0
    CHECK_FAILED=0

    rm -f "$TMP_BASE.check"

    echo ""
    echo "======================================"
    echo " Checking Telegram Bot"
    echo "======================================"
    echo ""

    for ITEM in $FILES; do

        SRC="${ITEM%%:*}"
        DST="${ITEM#*:}"

        TMP="$TMP_BASE.check"

        if ! download_file "$SRC" "$TMP"; then
            echo "[!] Gagal memeriksa: $DST"
            CHECK_FAILED=1
            rm -f "$TMP"
            continue
        fi

        if [ ! -f "$DST" ]; then

            echo "[+] MISSING : $DST"
            MISSING_COUNT=$((MISSING_COUNT + 1))

        else

            LOCAL_SUM="$(md5sum "$DST" 2>/dev/null | awk '{print $1}')"
            REMOTE_SUM="$(md5sum "$TMP" 2>/dev/null | awk '{print $1}')"

            if [ "$LOCAL_SUM" = "$REMOTE_SUM" ]; then
                echo "[=] TERBARU : $DST"
            else
                echo "[↑] UPDATE  : $DST"
                UPDATE_COUNT=$((UPDATE_COUNT + 1))
            fi

        fi

        rm -f "$TMP"

    done

    echo ""

    if [ "$CHECK_FAILED" = "1" ]; then
        echo "[!] Pemeriksaan selesai dengan error."
    fi

    if [ "$UPDATE_COUNT" = "0" ] &&
       [ "$MISSING_COUNT" = "0" ] &&
       [ "$CHECK_FAILED" = "0" ]; then

        echo "[✓] Semua file sudah terbaru."

    elif [ "$UPDATE_COUNT" -gt 0 ] ||
         [ "$MISSING_COUNT" -gt 0 ]; then

        echo "[i] Update tersedia."
        echo "[i] File berubah : $UPDATE_COUNT"
        echo "[i] File missing : $MISSING_COUNT"

    fi

    echo ""

    return 0
}

# ======================================
# INSTALL / REPAIR
# ======================================

do_install() {

    echo ""
    echo "======================================"
    echo " Telegram Bot OpenWrt"
    echo " Install / Repair"
    echo "======================================"
    echo ""

    FAILED=0

    for ITEM in $FILES; do

        SRC="${ITEM%%:*}"
        DST="${ITEM#*:}"

        if [ -f "$DST" ]; then
            echo "[=] Sudah ada : $DST"
        else
            if ! install_file "$SRC" "$DST"; then
                FAILED=1
            fi
        fi

    done

    # ==================================
    # CONFIG
    # ==================================

    if [ ! -f /etc/config/bot ]; then

        echo "[+] Membuat /etc/config/bot"

        if ! install_file "etc/config/bot" "/etc/config/bot"; then
            echo "[!] Gagal membuat /etc/config/bot"
            FAILED=1
        fi

    else

        echo "[=] Config tetap aman: /etc/config/bot"

    fi

    # ==================================
    # DATA
    # ==================================

    if [ ! -f /etc/known_macs.txt ]; then
        echo "[+] Membuat /etc/known_macs.txt"
        touch /etc/known_macs.txt
    fi

    if [ ! -f /etc/active_macs.txt ]; then
        echo "[+] Membuat /etc/active_macs.txt"
        touch /etc/active_macs.txt
    fi

    # ==================================
    # PERMISSION
    # ==================================

    chmod +x /usr/bin/bot 2>/dev/null
    chmod +x /etc/init.d/bot 2>/dev/null
    fix_router_reboot_permission

    # ==================================
    # SERVICE
    # ==================================

    if [ -x /etc/init.d/bot ]; then

        /etc/init.d/bot enable >/dev/null 2>&1

        echo ""
        echo "[+] Restarting Telegram Bot..."

        /etc/init.d/bot restart >/dev/null 2>&1

    fi

    sleep 1

    echo ""

    if [ "$FAILED" = "1" ]; then

        echo "======================================"
        echo " Install / Repair GAGAL"
        echo "======================================"

        return 1

    fi

    echo "======================================"
    echo " Install / Repair BERHASIL"
    echo "======================================"
    echo ""

    if service_running; then
        echo "Service : RUNNING"
    else
        echo "Service : STOPPED"
    fi

    echo ""

    return 0
}

# ======================================
# UPDATE
# ======================================

do_update() {

    echo ""
    echo "======================================"
    echo " Telegram Bot OpenWrt"
    echo " Update"
    echo "======================================"
    echo ""

    UPDATE_COUNT=0
    FAILED=0

    for ITEM in $FILES; do

        SRC="${ITEM%%:*}"
        DST="${ITEM#*:}"

        TMP="$TMP_BASE.update"

        if ! download_file "$SRC" "$TMP"; then
            echo "[!] Gagal memeriksa: $DST"
            FAILED=1
            rm -f "$TMP"
            continue
        fi

        if [ ! -f "$DST" ]; then

            echo "[+] Missing: $DST"
            echo "    Installing..."

            mkdir -p "$(dirname "$DST")"

            if mv "$TMP" "$DST"; then
                UPDATE_COUNT=$((UPDATE_COUNT + 1))
            else
                echo "[!] Gagal memasang: $DST"
                FAILED=1
            fi

            continue
        fi

        LOCAL_SUM="$(md5sum "$DST" 2>/dev/null | awk '{print $1}')"
        REMOTE_SUM="$(md5sum "$TMP" 2>/dev/null | awk '{print $1}')"

        if [ "$LOCAL_SUM" = "$REMOTE_SUM" ]; then

            echo "[=] Terbaru: $DST"
            rm -f "$TMP"

        else

            echo "[↑] Updating: $DST"

            if mv "$TMP" "$DST"; then
                UPDATE_COUNT=$((UPDATE_COUNT + 1))
            else
                echo "[!] Gagal update: $DST"
                FAILED=1
                rm -f "$TMP"
            fi

        fi

    done

    # ==================================
    # PERMISSION
    # ==================================

    chmod +x /usr/bin/bot 2>/dev/null
    chmod +x /etc/init.d/bot 2>/dev/null
    fix_router_reboot_permission
    
    # ==================================
    # RESTART
    # ==================================

    if [ "$UPDATE_COUNT" -gt 0 ] &&
       [ -x /etc/init.d/bot ]; then

        echo ""
        echo "[+] File berubah."
        echo "[+] Restarting Telegram Bot..."

        /etc/init.d/bot restart >/dev/null 2>&1

        sleep 1

    fi

    echo ""

    if [ "$FAILED" = "1" ]; then

        echo "======================================"
        echo " Update selesai dengan ERROR"
        echo "======================================"
        echo ""
        echo "File berubah: $UPDATE_COUNT"

        return 1

    fi

    echo "======================================"
    echo " Update selesai"
    echo "======================================"
    echo ""

    if [ "$UPDATE_COUNT" = "0" ]; then
        echo "Tidak ada file yang perlu diperbarui."
    else
        echo "File diperbarui: $UPDATE_COUNT"
    fi

    echo ""

    return 0
}

# ======================================
# RESTART
# ======================================

do_restart() {

    echo ""
    echo "======================================"
    echo " Restart Telegram Bot"
    echo "======================================"
    echo ""

    if [ ! -x /etc/init.d/bot ]; then
        echo "[!] Telegram Bot belum terinstall."
        return 1
    fi

    echo "[+] Restarting..."

    /etc/init.d/bot restart >/dev/null 2>&1

    sleep 1

    if service_running; then
        echo "[✓] Telegram Bot RUNNING."
    else
        echo "[!] Telegram Bot tidak berjalan."
    fi

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

    echo "[!] SEMUA file Telegram Bot akan dihapus:"
    echo ""
    echo "  /usr/bin/bot"
    echo "  /etc/init.d/bot"
    echo "  /usr/lib/lua/luci/controller/bot.lua"
    echo "  /usr/lib/lua/luci/model/cbi/bot.lua"
    echo "  /etc/config/bot"
    echo "  /etc/known_macs.txt"
    echo "  /etc/active_macs.txt"
    echo ""

    echo "[!] Token Telegram dan Chat ID juga akan terhapus."
    echo "[!] Install ulang akan kembali ke konfigurasi kosong."
    echo ""

    printf "Lanjutkan copot pemasangan? [y/N]: "
    read_input ANSWER

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

    # ==================================
    # STOP SERVICE
    # ==================================

    if [ -x /etc/init.d/bot ]; then

        echo "[+] Stopping Telegram Bot..."

        /etc/init.d/bot stop >/dev/null 2>&1
        /etc/init.d/bot disable >/dev/null 2>&1

    fi

    # ==================================
    # REMOVE APPLICATION
    # ==================================

    echo "[+] Menghapus file aplikasi..."

    rm -f /usr/bin/bot
    rm -f /etc/init.d/bot
    rm -f /usr/lib/lua/luci/controller/bot.lua
    rm -f /usr/lib/lua/luci/model/cbi/bot.lua

    # ==================================
    # REMOVE CONFIG
    # ==================================

    echo "[+] Menghapus konfigurasi..."

    rm -f /etc/config/bot

    # ==================================
    # REMOVE DATA
    # ==================================

    echo "[+] Menghapus data Telegram Bot..."

    rm -f /etc/known_macs.txt
    rm -f /etc/active_macs.txt

    echo ""
    echo "======================================"
    echo " Telegram Bot berhasil dicopot!"
    echo "======================================"
    echo ""
    echo "Semua konfigurasi dan data telah dihapus."
    echo ""
    echo "Install ulang akan dimulai dari kondisi fresh."
    echo ""

    return 0
}

# ======================================
# STATUS
# ======================================

show_status() {

    if is_installed; then
        STATUS="TERINSTALL"
    else
        STATUS="BELUM TERINSTALL"
    fi

    if service_running; then
        SERVICE="RUNNING"
    else
        SERVICE="STOPPED"
    fi

    MISSING=0

    for ITEM in $FILES; do

        SRC="${ITEM%%:*}"
        DST="${ITEM#*:}"

        if [ ! -f "$DST" ]; then
            MISSING=$((MISSING + 1))
        fi

    done

    if [ "$MISSING" = "0" ]; then
        FILE_STATUS="OK"
    else
        FILE_STATUS="$MISSING MISSING"
    fi

    echo "Status      : $STATUS"
    echo "Service     : $SERVICE"
    echo "Application : $FILE_STATUS"
}

# ======================================
# MAIN MENU
# ======================================

while true; do

    clear 2>/dev/null

    echo "======================================"
    echo "       TELEGRAM BOT OPENWRT"
    echo "======================================"
    echo ""

    show_status

    echo ""
    echo "======================================"
    echo ""

    if is_installed; then

        echo "1. Install / Repair"
        echo "2. Check Update"
        echo "3. Update"
        echo "4. Restart Service"
        echo "5. Copot Pemasangan"
        echo "0. Cancel"

        echo ""

        printf "Pilih [0-5]: "
        read_input MENU

        case "$MENU" in

            1)
                do_install
                pause_menu
                ;;

            2)
                check_updates
                pause_menu
                ;;

            3)
                do_update
                pause_menu
                ;;

            4)
                do_restart
                pause_menu
                ;;

            5)
                do_uninstall
                pause_menu
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
                sleep 1
                ;;

        esac

    else

        echo "1. Install"
        echo "0. Cancel"

        echo ""

        printf "Pilih [0-1]: "
        read_input MENU

        case "$MENU" in

            1)
                do_install
                pause_menu
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
                sleep 1
                ;;

        esac

    fi

done
