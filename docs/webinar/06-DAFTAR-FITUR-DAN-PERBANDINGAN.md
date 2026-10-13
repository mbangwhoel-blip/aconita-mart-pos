# Daftar Fitur & Perbandingan Versi

## Daftar Isi
1. [Daftar Lengkap Fitur](#daftar-lengkap-fitur)
2. [Perbandingan: Full Offline vs Online-Offline](#perbandingan-full-offline-vs-online-offline)
3. [Matriks Fitur](#matriks-fitur)
4. [Kapan Menggunakan Versi Mana?](#kapan-menggunakan-versi-mana)

---

## Daftar Lengkap Fitur

### 1. Dashboard & Overview

| Fitur | Deskripsi |
|-------|-----------|
| Welcome Screen | Tampilan greeting dengan nama user yang login |
| Statistik Hari Ini | Pendapatan hari ini dan jumlah order |
| Statistik Bulan Ini | Total order bulan berjalan |
| Status Order Overview | Ringkasan order: Pending, Proses, Siap Ambil, Selesai |
| Recent Orders | 5 order terbaru dengan quick access |
| Sync Status Indicator | Indikator status sinkronisasi cloud |
| Connectivity Indicator | Indikator online/offline |

### 2. Manajemen Order

| Fitur | Deskripsi |
|-------|-----------|
| Buat Order Baru | Form pembuatan order dengan multi-service |
| Daftar Order | List semua order dengan search |
| Filter by Status | Filter order berdasarkan status |
| Detail Order | Lihat detail lengkap order |
| Update Status | Ubah status order (Pending → Proses → Siap → Selesai) |
| Multi-Service per Order | Satu order bisa berisi beberapa layanan |
| Catatan Order | Tambah notes/catatan di order |
| Generate Invoice | Auto-generate nomor invoice (PREFIX-YYMMDD-NNNN) |
| Estimasi Selesai | Set tanggal perkiraan selesai |

### 3. Manajemen Pelanggan

| Fitur | Deskripsi |
|-------|-----------|
| Tambah Pelanggan | Buat profil pelanggan baru |
| Daftar Pelanggan | List pelanggan dengan search |
| Detail Pelanggan | Lihat detail dan history order |
| Auto-Save Pelanggan | Otomatis simpan pelanggan baru dari order |
| Statistik Pelanggan | Total order dan total spending |
| Catatan Pelanggan | Tambah notes untuk pelanggan |

### 4. Manajemen Layanan

| Fitur | Deskripsi |
|-------|-----------|
| Tambah Layanan | Buat layanan baru (Cuci Kering, Setrika, dll) |
| Edit Layanan | Ubah nama, harga, durasi |
| Nonaktifkan Layanan | Sembunyikan layanan tanpa hapus |
| Satuan Layanan | Pilih satuan (kg, pcs) |
| Durasi Default | Set estimasi hari pengerjaan |
| Harga Layanan | Set harga per satuan |

### 5. Pembayaran

| Fitur | Deskripsi |
|-------|-----------|
| Terima Pembayaran | Catat pembayaran dari pelanggan |
| DP (Down Payment) | Terima uang muka saat order |
| Pelunasan | Catat pembayaran sisa |
| Metode Pembayaran | Cash, Transfer, QRIS |
| Hitung Kembalian | Otomatis hitung kembalian |
| History Pembayaran | Lihat semua pembayaran per order |
| Sisa Pembayaran | Tampilkan sisa yang belum dibayar |

### 6. Laporan & Analitik

| Fitur | Deskripsi |
|-------|-----------|
| Laporan Pendapatan | Ringkasan omzet dan pembayaran |
| Filter Periode | Hari Ini, Minggu Ini, Bulan Ini, Bulan Lalu, Custom |
| Grafik Harian | Bar chart pendapatan per hari |
| Status Order Chart | Distribusi order berdasarkan status |
| Top Services | Ranking layanan terlaris |
| Export Excel | Download laporan format .xlsx |
| Share Laporan | Kirim file Excel via WhatsApp/Email |

### 7. Cetak Struk

| Fitur | Deskripsi |
|-------|-----------|
| Koneksi Bluetooth | Sambungkan ke printer thermal |
| Cetak Struk Order | Print receipt untuk pelanggan |
| Test Print | Cetak halaman test |
| Ukuran Kertas | Support 58mm dan 80mm |
| Auto-Reconnect | Otomatis sambung ke printer tersimpan |
| Format Struk | Header, detail item, total, footer |

### 8. Cloud Sync (Khusus Versi Online-Offline)

| Fitur | Deskripsi |
|-------|-----------|
| Auto-Sync | Sinkronisasi otomatis saat online |
| Periodic Sync | Sync setiap 30 detik |
| Sync Queue | Antrian data untuk disync |
| Pending Count | Tampilkan jumlah item pending |
| Last Sync Time | Waktu sync terakhir |
| Manual Sync | Trigger sync manual |
| Conflict Resolution | Handle duplikat data |

### 9. Backup & Restore (Khusus Versi Online-Offline)

| Fitur | Deskripsi |
|-------|-----------|
| Backup ke Cloud | Upload semua data lokal ke Supabase |
| Restore dari Cloud | Download data cloud ke device baru |
| Selective Backup | Pilih data yang di-backup |
| Backup Summary | Laporan hasil backup |
| Multi-Device | Akses data dari device berbeda |

### 10. Autentikasi

| Fitur | Deskripsi |
|-------|-----------|
| Login Lokal | Username + password tanpa internet |
| Login Cloud | Email + password via Supabase Auth |
| Register Cloud | Daftar akun Supabase baru |
| Role-Based Access | Owner vs Kasir |
| Password Reset | Reset password via email |
| Session Management | Kelola sesi login |

### 11. Manajemen User

| Fitur | Deskripsi |
|-------|-----------|
| Tambah Kasir | Buat akun kasir baru |
| Edit Kasir | Ubah nama, password kasir |
| Nonaktifkan Kasir | Disable akun tanpa hapus |
| List User | Daftar semua user |

### 12. Multi-Outlet Management

| Fitur | Deskripsi |
|-------|-----------|
| Tambah Outlet | Buat cabang/outlet baru |
| Edit Outlet | Ubah nama, alamat, telepon outlet |
| Switch Outlet | Pindah ke outlet lain |
| Delete Outlet | Hapus outlet (kecuali yang aktif) |
| Outlet di Header | Tampilkan nama outlet aktif di dashboard |
| Data Per-Outlet | Customer, layanan, order terpisah per outlet |
| Prefix Invoice Per-Outlet | Setiap outlet bisa punya prefix invoice berbeda |

### 13. Pengaturan

| Fitur | Deskripsi |
|-------|-----------|
| Nama Laundry | Set nama bisnis |
| Alamat | Set alamat laundry |
| Nomor Telepon | Set nomor untuk struk |
| Prefix Invoice | Customize prefix invoice |
| Printer Settings | Konfigurasi printer |
| Online Settings | Konfigurasi cloud (versi online) |
| Kelola Outlet | Manajemen multi-outlet |

### 14. Integrasi WhatsApp

| Fitur | Deskripsi |
|-------|-----------|
| Kirim Struk | Share struk via WhatsApp |
| Notifikasi Siap Ambil | Kirim notif ke pelanggan |
| Notifikasi Status | Update status via WA |
| Format Pesan | Template pesan otomatis |

### 15. Onboarding

| Fitur | Deskripsi |
|-------|-----------|
| Welcome Screen | Pengenalan aplikasi |
| Feature Slides | Penjelasan fitur-fitur |
| Offline-First Info | Penjelasan mode offline |

---

## Perbandingan: Full Offline vs Online-Offline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│   FULL OFFLINE VERSION              ONLINE-OFFLINE VERSION                  │
│   ════════════════════              ════════════════════════                │
│                                                                              │
│   ┌─────────────────┐               ┌─────────────────┐                     │
│   │   FLUTTER APP   │               │   FLUTTER APP   │                     │
│   │                 │               │                 │                     │
│   │  ┌───────────┐  │               │  ┌───────────┐  │                     │
│   │  │  SQLite   │  │               │  │  SQLite   │  │                     │
│   │  │  (Local)  │  │               │  │  (Local)  │◄─┼──┐                  │
│   │  └───────────┘  │               │  └───────────┘  │  │                  │
│   │                 │               │        │        │  │ Sync             │
│   │  Data stays     │               │        ▼        │  │                  │
│   │  on device only │               │  ┌───────────┐  │  │                  │
│   │                 │               │  │Sync Queue │  │  │                  │
│   └─────────────────┘               │  └─────┬─────┘  │  │                  │
│                                     │        │        │  │                  │
│                                     └────────┼────────┘  │                  │
│                                              │           │                  │
│                                              ▼           │                  │
│                                     ┌─────────────────┐  │                  │
│                                     │    SUPABASE     │──┘                  │
│                                     │   (Cloud DB)    │                     │
│                                     └─────────────────┘                     │
│                                                                              │
│   KARAKTERISTIK:                    KARAKTERISTIK:                          │
│   • Tidak butuh internet            • Bisa offline & online                 │
│   • Data hanya di 1 device          • Data sync ke cloud                    │
│   • Tidak ada backup cloud          • Multi-device support                  │
│   • Simple setup                    • Backup otomatis                       │
│   • Privacy maksimal                • Perlu akun Supabase                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Tabel Perbandingan Detail

| Aspek | Full Offline | Online-Offline |
|-------|--------------|----------------|
| **Koneksi Internet** | Tidak perlu sama sekali | Opsional (bisa tanpa internet) |
| **Penyimpanan Data** | SQLite lokal saja | SQLite lokal + Supabase cloud |
| **Multi-Device** | ❌ Tidak (1 device only) | ✅ Ya (data sync antar device) |
| **Backup Data** | ❌ Manual (export file) | ✅ Otomatis ke cloud |
| **Restore Data** | ❌ Manual (import file) | ✅ Dari cloud ke device baru |
| **Setup Complexity** | Simple | Medium (perlu setup Supabase) |
| **Biaya** | Gratis | Gratis (Supabase free tier) |
| **Privacy** | Maksimal (data lokal) | Data di cloud (encrypted) |
| **Kehilangan HP** | ❌ Data hilang | ✅ Data aman di cloud |
| **Ganti HP** | Manual transfer | Otomatis restore |
| **Real-time Sync** | ❌ Tidak ada | ✅ Ya (antar device) |

---

## Matriks Fitur

| Fitur | Full Offline | Online-Offline |
|-------|:------------:|:--------------:|
| **DASHBOARD** | | |
| Statistik Hari Ini | ✅ | ✅ |
| Statistik Bulan Ini | ✅ | ✅ |
| Recent Orders | ✅ | ✅ |
| Sync Status Indicator | ❌ | ✅ |
| Connectivity Indicator | ❌ | ✅ |
| **ORDER MANAGEMENT** | | |
| Buat Order | ✅ | ✅ |
| Multi-Service per Order | ✅ | ✅ |
| Update Status | ✅ | ✅ |
| Search Order | ✅ | ✅ |
| Filter by Status | ✅ | ✅ |
| Invoice Generation | ✅ | ✅ |
| **CUSTOMER MANAGEMENT** | | |
| Tambah Pelanggan | ✅ | ✅ |
| Edit Pelanggan | ✅ | ✅ |
| Customer Statistics | ✅ | ✅ |
| Sync Pelanggan ke Cloud | ❌ | ✅ |
| **SERVICE MANAGEMENT** | | |
| Tambah Layanan | ✅ | ✅ |
| Edit Layanan | ✅ | ✅ |
| Nonaktifkan Layanan | ✅ | ✅ |
| Sync Layanan ke Cloud | ❌ | ✅ |
| **PEMBAYARAN** | | |
| Terima Pembayaran | ✅ | ✅ |
| DP & Pelunasan | ✅ | ✅ |
| Multi Payment Method | ✅ | ✅ |
| Hitung Kembalian | ✅ | ✅ |
| Sync Pembayaran ke Cloud | ❌ | ✅ |
| **LAPORAN** | | |
| Laporan Pendapatan | ✅ | ✅ |
| Grafik Harian | ✅ | ✅ |
| Top Services | ✅ | ✅ |
| Export Excel | ✅ | ✅ |
| Laporan dari Cloud | ❌ | ✅ (potential) |
| **CETAK STRUK** | | |
| Bluetooth Printer | ✅ | ✅ |
| 58mm & 80mm Paper | ✅ | ✅ |
| Auto-Reconnect | ✅ | ✅ |
| **CLOUD FEATURES** | | |
| Auto-Sync | ❌ | ✅ |
| Periodic Sync | ❌ | ✅ |
| Sync Queue | ❌ | ✅ |
| Pending Count Display | ❌ | ✅ |
| **BACKUP & RESTORE** | | |
| Backup ke Cloud | ❌ | ✅ |
| Restore dari Cloud | ❌ | ✅ |
| Multi-Device Access | ❌ | ✅ |
| **AUTENTIKASI** | | |
| Login Lokal | ✅ | ✅ |
| Login Cloud (Email) | ❌ | ✅ |
| Register Cloud | ❌ | ✅ |
| Password Reset Email | ❌ | ✅ |
| **USER MANAGEMENT** | | |
| Tambah Kasir Lokal | ✅ | ✅ |
| Sync Kasir ke Cloud | ❌ | ✅ |
| **MULTI-OUTLET** | | |
| Tambah Outlet | ✅ | ✅ |
| Switch Outlet | ✅ | ✅ |
| Data Per-Outlet | ✅ | ✅ |
| Sync Outlet ke Cloud | ❌ | ✅ |
| **PENGATURAN** | | |
| Setting Laundry | ✅ | ✅ |
| Printer Settings | ✅ | ✅ |
| Online Settings | ❌ | ✅ |
| Kelola Outlet | ✅ | ✅ |
| **WHATSAPP** | | |
| Kirim Struk | ✅ | ✅ |
| Notifikasi Status | ✅ | ✅ |
| **ONBOARDING** | | |
| Welcome Slides | ✅ | ✅ |

### Legend
- ✅ = Tersedia
- ❌ = Tidak tersedia

---

## Kapan Menggunakan Versi Mana?

### Gunakan Full Offline Jika:

```
┌────────────────────────────────────────────────────────────┐
│                                                             │
│  ✓ Hanya punya 1 device (1 HP/tablet)                      │
│  ✓ Tidak ada koneksi internet sama sekali                  │
│  ✓ Ingin setup paling simple                               │
│  ✓ Sangat concern dengan privacy (data tidak ke cloud)     │
│  ✓ Tidak butuh backup otomatis                             │
│  ✓ Tidak perlu akses data dari device lain                 │
│                                                             │
│  COCOK UNTUK:                                              │
│  • Laundry kecil di daerah tanpa internet                  │
│  • Owner yang handle sendiri                               │
│  • Testing/demo aplikasi                                   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### Gunakan Online-Offline Jika:

```
┌────────────────────────────────────────────────────────────┐
│                                                             │
│  ✓ Punya lebih dari 1 device                               │
│  ✓ Ada koneksi internet (meski tidak stabil)               │
│  ✓ Butuh backup data otomatis                              │
│  ✓ Takut data hilang jika HP rusak/hilang                  │
│  ✓ Ingin bisa ganti HP tanpa kehilangan data               │
│  ✓ Punya karyawan yang perlu akses data yang sama          │
│                                                             │
│  COCOK UNTUK:                                              │
│  • Laundry dengan beberapa kasir                           │
│  • Owner yang tidak selalu di tempat                       │
│  • Bisnis yang butuh data aman                             │
│  • Laundry dengan multiple outlet ✅                       │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### Rekomendasi

| Skenario | Rekomendasi |
|----------|-------------|
| Laundry baru, 1 owner, 1 HP | Full Offline |
| Laundry dengan kasir | Online-Offline |
| Daerah tanpa internet | Full Offline |
| Internet tidak stabil | Online-Offline (tetap jalan offline) |
| Butuh backup | Online-Offline |
| Privacy concern tinggi | Full Offline |
| Multiple device | Online-Offline |
| Ganti HP sering | Online-Offline |
| Multiple outlet/cabang | Keduanya ✅ (Online-Offline untuk sync antar device) |

---

## Migrasi dari Full Offline ke Online-Offline

Jika nanti ingin upgrade dari Full Offline ke Online-Offline:

```
┌─────────────────────────────────────────────────────────────────┐
│                     MIGRATION PATH                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  STEP 1: Backup data Full Offline                               │
│          └─ Export ke Excel atau file backup                    │
│                                                                  │
│  STEP 2: Install versi Online-Offline                           │
│          └─ Atau update app jika same codebase                  │
│                                                                  │
│  STEP 3: Setup Supabase account                                 │
│          └─ Buat project, jalankan schema                       │
│                                                                  │
│  STEP 4: Register/Login cloud                                   │
│          └─ Buat akun owner di Supabase                         │
│                                                                  │
│  STEP 5: Upload data ke cloud                                   │
│          └─ Gunakan fitur Backup to Cloud                       │
│                                                                  │
│  STEP 6: Verify data                                            │
│          └─ Cek semua data sudah ada di cloud                   │
│                                                                  │
│  DONE! Data sekarang sync ke cloud                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Kesimpulan

| Versi | Kelebihan | Kekurangan |
|-------|-----------|------------|
| **Full Offline** | Simple, privacy, no internet needed | No backup, single device |
| **Online-Offline** | Backup, multi-device, sync | Perlu setup Supabase |

**Rekomendasi umum**: Jika ada akses internet (meski tidak stabil), gunakan **Online-Offline** karena benefit backup dan multi-device sangat berharga untuk bisnis.
