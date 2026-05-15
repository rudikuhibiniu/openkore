#!/bin/bash
# OpenKore - RevoclassicR (Priest)
# Ubuntu 24.04 — install / build / run

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_NAME="openkore-priest"
LOG_DIR="$SCRIPT_DIR/logs"
XSTOOLS_SO="$SCRIPT_DIR/src/auto/XSTools/XSTools.so"

# ─── Warna ───────────────────────────────────────────────────────────────────
OK="\e[1;32m[+]\e[0m"
WARN="\e[1;33m[!]\e[0m"
INFO="\e[1;34m[*]\e[0m"
ERR="\e[1;31m[x]\e[0m"

# ─── Install dependensi sistem + Perl ────────────────────────────────────────
install_deps() {
    echo -e "$INFO Menginstall paket sistem..."
    sudo apt-get update -qq
    sudo apt-get install -y \
        perl \
        python3 \
        build-essential \
        gcc \
        g++ \
        make \
        libreadline-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libz-dev \
        screen \
        cpanminus \
        libtime-hires-perl \
        libdigest-md5-perl \
        libnet-ssleay-perl \
        libio-socket-ssl-perl \
        liblist-moreutils-perl \
        libpath-tiny-perl \
        libwww-perl \
        liburi-perl \
        libhttp-message-perl \
        libio-socket-ip-perl \
        libyaml-perl \
        libjson-perl \
        libmodule-build-perl \
        libextutils-parsexs-perl

    echo -e "$INFO Menginstall Perl modules via cpanm..."
    sudo cpanm --notest \
        Compress::Raw::Zlib \
        IO::Compress::Gzip \
        IO::Uncompress::Gunzip \
        List::MoreUtils \
        Time::HiRes \
        Digest::MD5 \
        2>/dev/null || true

    echo -e "$OK Dependensi selesai diinstall."
}

# ─── Compile XSTools ─────────────────────────────────────────────────────────
build() {
    echo -e "$INFO Mengcompile XSTools..."
    cd "$SCRIPT_DIR"

    if ! command -v python3 &>/dev/null; then
        echo -e "$ERR python3 tidak ditemukan. Jalankan: $0 install"
        exit 1
    fi

    python3 src/scons-local-3.1.2/scons.py

    if [ -f "$XSTOOLS_SO" ]; then
        echo -e "$OK Compile berhasil: $XSTOOLS_SO"
    else
        echo -e "$WARN XSTools.so tidak ditemukan, tapi OpenKore mungkin tetap bisa jalan tanpa optimasi."
    fi
}

# ─── Setup lengkap (install + build) ─────────────────────────────────────────
setup() {
    install_deps
    build
    mkdir -p "$LOG_DIR"
    echo -e "$OK Setup selesai. Jalankan: $0 start"
}

# ─── Cek dependensi minimum ──────────────────────────────────────────────────
check_deps() {
    local fail=0
    for cmd in perl screen python3; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "$ERR '$cmd' tidak ditemukan."
            fail=1
        fi
    done
    if [ $fail -eq 1 ]; then
        echo -e "$WARN Jalankan: $0 install"
        exit 1
    fi
}

# ─── Manajemen bot ───────────────────────────────────────────────────────────
start_bot() {
    check_deps
    mkdir -p "$LOG_DIR"

    if screen -list 2>/dev/null | grep -q "$SESSION_NAME"; then
        echo -e "$WARN Bot sudah berjalan di session '$SESSION_NAME'."
        echo -e "    Gunakan: $0 attach"
        exit 1
    fi

    if [ ! -f "$XSTOOLS_SO" ]; then
        echo -e "$WARN XSTools.so belum dikompile. Jalankan: $0 build"
    fi

    echo -e "$INFO Menjalankan OpenKore Priest di screen session '$SESSION_NAME'..."
    cd "$SCRIPT_DIR"
    screen -dmS "$SESSION_NAME" \
        bash -c "perl openkore.pl --interface=Console 2>&1 | tee -a '$LOG_DIR/openkore-$(date +%Y%m%d).log'; echo 'Bot berhenti. Tekan Enter untuk keluar.'; read"
    echo -e "$OK Bot berjalan. Gunakan: $0 attach"
}

stop_bot() {
    if screen -list 2>/dev/null | grep -q "$SESSION_NAME"; then
        screen -S "$SESSION_NAME" -X quit
        echo -e "$OK Bot dihentikan."
    else
        echo -e "$WARN Bot tidak sedang berjalan."
    fi
}

restart_bot() {
    stop_bot
    sleep 2
    start_bot
}

attach_bot() {
    if screen -list 2>/dev/null | grep -q "$SESSION_NAME"; then
        echo -e "$INFO Masuk ke console bot. Keluar: Ctrl+A lalu D"
        screen -r "$SESSION_NAME"
    else
        echo -e "$WARN Bot tidak berjalan. Gunakan: $0 start"
        exit 1
    fi
}

status_bot() {
    if screen -list 2>/dev/null | grep -q "$SESSION_NAME"; then
        echo -e "$OK Bot BERJALAN"
        screen -list | grep "$SESSION_NAME"
        echo ""
        echo -e "$INFO Log terbaru:"
        ls -t "$LOG_DIR"/openkore-*.log 2>/dev/null | head -1 | xargs tail -5 2>/dev/null || true
    else
        echo -e "$WARN Bot TIDAK berjalan."
    fi
}

logs_bot() {
    local logfile
    logfile=$(ls -t "$LOG_DIR"/openkore-*.log 2>/dev/null | head -1)
    if [ -n "$logfile" ]; then
        tail -f "$logfile"
    else
        echo -e "$WARN Tidak ada log ditemukan di $LOG_DIR"
        exit 1
    fi
}

# ─── Main ────────────────────────────────────────────────────────────────────
case "${1:-help}" in
    install)  install_deps ;;
    build)    build ;;
    setup)    setup ;;
    start)    start_bot ;;
    stop)     stop_bot ;;
    restart)  restart_bot ;;
    attach)   attach_bot ;;
    status)   status_bot ;;
    logs)     logs_bot ;;
    *)
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "  Setup:"
        echo "    setup    — Install dependensi + compile XSTools (jalankan pertama kali)"
        echo "    install  — Install Perl, gcc, readline, curl, Perl modules"
        echo "    build    — Compile XSTools (C++ extension)"
        echo ""
        echo "  Bot:"
        echo "    start    — Jalankan bot di background (screen)"
        echo "    stop     — Hentikan bot"
        echo "    restart  — Restart bot"
        echo "    attach   — Masuk ke console bot (Ctrl+A+D untuk keluar)"
        echo "    status   — Cek status + 5 baris log terakhir"
        echo "    logs     — Tail log real-time"
        echo ""
        exit 1
        ;;
esac
