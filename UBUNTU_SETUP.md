# OpenKore — Tutorial Ubuntu 24.04

## Prasyarat

- VPS / Server Ubuntu 24.04 (minimal 512MB RAM)
- Akses SSH ke server
- Project OpenKore sudah ada di komputer lokal (Windows)

---

## Langkah 1 — Upload Project ke Server

### Option A: Menggunakan `scp` dari Windows

Buka PowerShell / Command Prompt di komputer Windows:

```bash
scp -r "E:\Games\openkore\openkore_rogue" user@IP_SERVER:/home/user/openkore
```

Ganti `user` dengan username server dan `IP_SERVER` dengan IP VPS kamu.

### Option B: Menggunakan Git (jika project ada di GitHub)

SSH ke server terlebih dahulu, lalu:

```bash
git clone https://github.com/USERNAME/REPO_NAME.git openkore
```

---

## Langkah 2 — SSH ke Server

```bash
ssh user@IP_SERVER
```

Masuk ke direktori project:

```bash
cd /home/user/openkore
```

---

## Langkah 3 — Install Dependensi & Compile

Jalankan satu perintah berikut untuk install semua dependensi sekaligus compile XSTools:

```bash
make -f Makefile.ubuntu install
make -f Makefile.ubuntu build
```

Proses ini membutuhkan waktu beberapa menit. Output yang benar di akhir:

```
[+] XSTools berhasil di-compile: src/auto/XSTools/XSTools.so
[+] Setup lengkap.
```

> **Catatan:** Jika `make` menampilkan error `python3 not found`, jalankan dulu:
> ```bash
> sudo apt install python3
> ```

---

## Langkah 4 — Jalankan Bot

### Jalankan di background (direkomendasikan untuk server)

```bash
make -f Makefile.ubuntu start
```

Bot berjalan di dalam `screen` session — tetap hidup meski SSH terputus.

### Lihat log bot

```bash
make -f Makefile.ubuntu attach
```

Untuk keluar dari log **tanpa menghentikan bot**: tekan `Ctrl+A` lalu `D`.

---

## Perintah Sehari-hari

| Perintah | Fungsi |
|---|---|
| `make -f Makefile.ubuntu start` | Jalankan bot di background |
| `make -f Makefile.ubuntu attach` | Lihat log bot |
| `make -f Makefile.ubuntu stop` | Hentikan bot |
| `make -f Makefile.ubuntu status` | Cek apakah bot sedang jalan |
| `make -f Makefile.ubuntu run` | Jalankan foreground (untuk debug) |

---

## Troubleshooting

### Error: `XSTools.so` tidak terbuat

```bash
# Install build tools yang mungkin kurang
sudo apt install build-essential libssl-dev zlib1g-dev

# Compile ulang
make -f Makefile.ubuntu clean
make -f Makefile.ubuntu build
```

### Error: `Can't locate MODULE.pm`

Ada modul Perl yang belum terinstall:

```bash
sudo cpanm NAMA::MODUL
# Contoh:
sudo cpanm List::MoreUtils
```

### Bot konek tapi langsung disconnect

Cek `control/config.txt` — pastikan `username`, `password`, dan server sudah benar.

### Bot berjalan tapi tidak bisa lihat log

Mungkin session sudah mati. Cek dengan:

```bash
screen -list
```

Jika kosong, jalankan ulang:

```bash
make -f Makefile.ubuntu start
```

### Error `TERM` saat menjalankan screen

```bash
export TERM=xterm
make -f Makefile.ubuntu start
```

---

## Struktur File Penting

```
openkore/
├── openkore.pl              # File utama
├── Makefile.ubuntu          # Makefile untuk Ubuntu
├── start-ubuntu.sh          # Script alternatif
├── control/
│   ├── config.txt           # Konfigurasi utama bot
│   ├── mon_control.txt      # Kontrol monster
│   ├── pickupitems.txt      # Item yang diambil
│   └── eventMacros.txt      # Macro otomatis
└── src/auto/XSTools/
    └── XSTools.so           # Library yang perlu di-compile
```

---

## Auto-start saat Server Reboot (opsional)

Buat systemd service agar bot otomatis jalan saat server restart:

```bash
sudo nano /etc/systemd/system/openkore.service
```

Isi file:

```ini
[Unit]
Description=OpenKore Bot
After=network.target

[Service]
Type=simple
User=user
WorkingDirectory=/home/user/openkore
ExecStart=/usr/bin/perl openkore.pl --interface=Console
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Ganti `user` dengan username kamu dan path sesuai lokasi project.

Aktifkan service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable openkore
sudo systemctl start openkore

# Cek status
sudo systemctl status openkore

# Lihat log
sudo journalctl -u openkore -f
```
