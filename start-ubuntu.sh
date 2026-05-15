#!/bin/bash
# OpenKore starter untuk Ubuntu 24.04
# Jalankan sekali: chmod +x start-ubuntu.sh && ./start-ubuntu.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── 1. Install dependensi sistem ────────────────────────────────────────────
install_deps() {
    echo "[*] Menginstall dependensi sistem..."
    sudo apt-get update -qq
    sudo apt-get install -y \
        perl \
        libperlio-gzip-perl \
        libio-socket-ssl-perl \
        libnet-ssleay-perl \
        libcrypt-des-perl \
        libdigest-md5-perl \
        libdigest-sha-perl \
        liblist-moreutils-perl \
        libtime-hires-perl \
        scons \
        build-essential \
        libssl-dev \
        screen
    echo "[+] Dependensi sistem selesai."
}

# ── 2. Compile XSTools ───────────────────────────────────────────────────────
build_xstools() {
    echo "[*] Mengcompile XSTools untuk Linux..."
    cd "$SCRIPT_DIR/src/auto/XSTools"
    scons
    if [ ! -f "*.so" ] && ! ls ./*.so 1>/dev/null 2>&1; then
        echo "[!] Peringatan: XSTools.so tidak ditemukan setelah compile."
        echo "    OpenKore akan berjalan tanpa XSTools (performa lebih lambat)."
    else
        echo "[+] XSTools berhasil di-compile."
    fi
    cd "$SCRIPT_DIR"
}

# ── 3. Cek apakah XSTools sudah ada ─────────────────────────────────────────
check_xstools() {
    if ls "$SCRIPT_DIR/src/auto/XSTools/"*.so 1>/dev/null 2>&1; then
        echo "[+] XSTools.so ditemukan, skip compile."
        return 0
    fi
    build_xstools
}

# ── 4. Jalankan OpenKore ─────────────────────────────────────────────────────
run_openkore() {
    local session_name="openkore"

    if screen -list | grep -q "$session_name"; then
        echo "[!] Session '$session_name' sudah berjalan."
        echo "    Attach dengan: screen -r $session_name"
        echo "    Stop dengan:   screen -S $session_name -X quit"
        exit 0
    fi

    echo "[*] Menjalankan OpenKore di screen session '$session_name'..."
    screen -dmS "$session_name" perl "$SCRIPT_DIR/openkore.pl" --interface=Console
    sleep 1

    if screen -list | grep -q "$session_name"; then
        echo "[+] OpenKore berjalan di background."
        echo ""
        echo "  Attach (lihat log)  : screen -r $session_name"
        echo "  Detach (biarkan jalan): Ctrl+A lalu D"
        echo "  Stop bot            : screen -S $session_name -X quit"
    else
        echo "[-] Gagal menjalankan OpenKore. Coba jalankan manual:"
        echo "    perl openkore.pl --interface=Console"
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
case "${1:-start}" in
    install)
        install_deps
        check_xstools
        echo "[+] Setup selesai. Jalankan: ./start-ubuntu.sh"
        ;;
    build)
        build_xstools
        ;;
    stop)
        screen -S openkore -X quit && echo "[+] OpenKore dihentikan." || echo "[!] Session tidak ditemukan."
        ;;
    attach)
        screen -r openkore
        ;;
    start|*)
        # Pertama kali: install deps + build jika belum ada
        if ! command -v scons &>/dev/null || ! dpkg -l | grep -q libio-socket-ssl-perl; then
            install_deps
        fi
        check_xstools
        run_openkore
        ;;
esac
