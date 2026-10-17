# luci-controller-telegrambot

[![OpenWrt](https://img.shields.io/badge/OpenWrt-Supported-blue.svg)](https://openwrt.org/) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Telegram Bot Controller untuk OpenWrt dengan integrasi LuCI Web UI. Project ini dibuat untuk memberikan kontrol dan monitoring router OpenWrt secara jarak jauh (*remote*) melalui Telegram Bot, serta menyediakan halaman konfigurasi yang terintegrasi langsung di LuCI.

---

## ✨ Fitur

- 🤖 **Telegram Bot untuk OpenWrt**
- 🖥️ **Integrasi dengan LuCI**
- 📊 **Monitoring status router** secara *real-time*
- 🌐 **Informasi IP publik / WAN**
- 📱 **Monitoring perangkat LAN** yang terhubung
- 🔔 **Notifikasi perangkat terhubung & terputus**
- 🌡️ **Informasi suhu CPU**
- 🚀 **Speed Test** jaringan
- 🧹 **Clear Cache RAM**
- 💾 **Backup konfigurasi OpenWrt**
- 🔄 **Reboot router jarak jauh** (Menggunakan OpenSSH Client & PEM Key)
- 🚫 **Ban / Unban MAC Address** (Blokir / Buka blokir perangkat)
- 📋 **Daftar MAC Address yang diblokir**
- ⚙️ **Service menggunakan `procd`**
- 🔄 **Installer & Updater dari GitHub**
- 🛡️ **Konfigurasi Telegram Bot tetap dipertahankan saat update**

---

## 📁 Struktur Repository

```text
luci-controller-telegrambot/
├── README.md
├── install.sh
├── update.sh
└── files/
    ├── etc/
    │   ├── active_macs.txt
    │   ├── known_macs.txt
    │   ├── config/
    │   │   └── bot
    │   └── init.d/
    │       └── bot
    │
    └── usr/
        ├── bin/
        │   └── bot
        │
        └── lib/
            └── lua/
                └── luci/
                    ├── controller/
                    │   └── bot.lua
                    └── model/
                        └── cbi/
                            └── bot.lua
```

---

## 🚀 Instalasi

### 1. Install Paket Dependensi
Jalankan perintah berikut pada Terminal / SSH router OpenWrt untuk memasang paket prasyarat (termasuk `openssh-client` untuk fitur remote reboot):

```bash
opkg update && opkg install curl ca-certificates jq conntrack openssh-client
```

### 2. Install Telegram Bot Controller
Jalankan perintah berikut untuk menginstal langsung dari GitHub menggunakan installer otomatis:

```bash
wget -qO- https://raw.githubusercontent.com/charudkelser/luci-controller-telegrambot/main/install.sh | sh
```

---

## 🔑 Catatan Penting: SSH Key untuk Reboot Router

Jika kamu menggunakan fitur **Reboot Router Target**:
1. Gunakan Private Key berformat **PEM (OpenSSH)** (`-----BEGIN OPENSSH PRIVATE KEY-----`).
2. Pastikan izin file *key* di-set ke **`600`** agar tidak diblokir oleh OpenSSH (mencegah error *UNPROTECTED PRIVATE KEY FILE / Exit 255*):
   ```bash
   chmod 600 /etc/router-reboot/router_reboot
   ```

---

## ⚙️ Cara Penggunaan

1. Buka Web UI LuCI di browser kamu (misal: `192.168.1.1`).
2. Masuk ke menu **Telegram Bot Controller**.
3. Centang opsi **Aktifkan**.
4. Masukkan **Token Bot** dan **Chat ID** Telegram kamu.
5. Klik **Save & Apply**.
6. Buka bot di Telegram lalu ketik `/start`.

---

## 👤 Author & Repository

* **Author:** KANG ASAH  
* **Repository:** [luci-controller-telegrambot](https://github.com/charudkelser/luci-controller-telegrambot)
