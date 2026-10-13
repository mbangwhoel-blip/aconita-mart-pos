# Dokumentasi Webinar: Flutter + Supabase Offline-First

## Laundry JagoFlutter - Aplikasi Kasir Laundry UMKM

Dokumentasi lengkap untuk webinar tentang membangun aplikasi Flutter dengan Supabase yang mendukung mode offline.

---

## Daftar Dokumen

| No | Dokumen | Deskripsi |
|----|---------|-----------|
| 1 | [Pengenalan Flutter & Supabase](01-PENGENALAN-FLUTTER-SUPABASE.md) | Apa itu Flutter, apa itu Supabase, mengapa kombinasi ini powerful |
| 2 | [Architecture Project](02-ARCHITECTURE-PROJECT.md) | Clean Architecture, folder structure, state management dengan BLoC/Cubit |
| 3 | [Packages & Dependencies](03-PACKAGES-DEPENDENCIES.md) | Daftar lengkap packages dan fungsinya |
| 4 | [Step-by-Step Integrasi Supabase](04-STEP-BY-STEP-INTEGRASI-SUPABASE.md) | Dari buat akun sampai CRUD operations |
| 5 | [Sync Online-Offline](05-SYNC-ONLINE-OFFLINE.md) | Implementasi offline-first dengan sync queue |
| 6 | [Daftar Fitur & Perbandingan](06-DAFTAR-FITUR-DAN-PERBANDINGAN.md) | Semua fitur aplikasi dan perbandingan Full Offline vs Online-Offline |
| 7 | [Multi-Outlet Backup & Restore](07-MULTI-OUTLET-BACKUP-RESTORE.md) | **NEW!** Multi-outlet support, backup/restore, RLS policies, ID mapping |

---

## Quick Start

### Prerequisites
- Flutter SDK ^3.10.1
- Dart SDK ^3.0.0
- Supabase Account (free tier cukup)
- IDE: VS Code / Android Studio

### Setup Project

```bash
# Clone repository
git clone https://github.com/jagoflutter/laundry-offline-app.git
cd laundry-offline-app

# Install dependencies
flutter pub get

# Copy environment file
cp .env.example .env

# Edit .env dengan credentials Supabase Anda
# SUPABASE_URL=https://xxx.supabase.co
# SUPABASE_ANON_KEY=eyJhbGciOiJI...

# Run
flutter run
```

### Setup Supabase

1. Buat project di [supabase.com](https://supabase.com)
2. Jalankan SQL schema di `supabase/schema.sql`
3. Enable Email auth di Authentication > Providers
4. Copy URL dan anon key ke file `.env`

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER APP                           │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │ Presentation│  │    Logic    │  │      Data       │  │
│  │   (Screens) │◀─│   (Cubits)  │◀─│  (Repositories) │  │
│  └─────────────┘  └─────────────┘  └────────┬────────┘  │
│                                              │           │
│                          ┌───────────────────┼───────────┤
│                          │                   │           │
│                          ▼                   ▼           │
│                   ┌─────────────┐     ┌─────────────┐   │
│                   │   SQLite    │     │  sync_queue │   │
│                   │   (Local)   │     │   (Queue)   │   │
│                   └─────────────┘     └──────┬──────┘   │
│                                              │           │
│                                        When Online       │
│                                              │           │
│                                              ▼           │
│                                       ┌─────────────┐   │
│                                       │  SUPABASE   │   │
│                                       │   (Cloud)   │   │
│                                       └─────────────┘   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Key Features

### 1. Offline-First
- Semua operasi CRUD disimpan ke SQLite lokal
- App bisa digunakan 100% tanpa internet
- Data auto-sync saat online

### 2. Multi-Platform
- Android (primary)
- iOS
- (potential) Web, Desktop

### 3. Fitur Bisnis
- Manajemen order laundry
- Cetak struk thermal printer
- Laporan penjualan
- Multi-user (Owner, Kasir)
- Export Excel
- **Multi-Outlet** - Kelola beberapa cabang dalam satu app

### 4. Cloud Sync (Multi-Outlet Support)
- Backup otomatis ke Supabase (semua outlet sekaligus)
- Restore dari cloud dengan ID mapping
- Multi-device sync
- Row Level Security (Owner akses semua outlet, Kasir satu outlet)
- Auto-sync order baru dengan service_id mapping
- Debug tools untuk troubleshooting

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI Framework | Flutter 3.10+ |
| State Management | flutter_bloc (Cubit) |
| Local Database | SQLite (sqflite) |
| Cloud Backend | Supabase |
| Authentication | Supabase Auth + Local Auth |
| Connectivity | connectivity_plus |

---

## Agenda Webinar

### Sesi 1: Pengenalan (15 menit)
- Apa itu Flutter?
- Apa itu Supabase?
- Demo aplikasi

### Sesi 2: Architecture (20 menit)
- Clean Architecture
- Folder structure
- State management

### Sesi 3: Integrasi Supabase (30 menit)
- Setup project Supabase
- Setup Flutter project
- Authentication
- CRUD operations

### Sesi 4: Offline-First (30 menit)
- Connectivity monitoring
- Sync queue mechanism
- Conflict handling

### Sesi 5: Demo & Q&A (25 menit)
- Live demo
- Tanya jawab

---

## Kontak & Resources

### JagoFlutter
- Website: [jagoflutter.com](https://jagoflutter.com)
- WhatsApp: [Contact](https://wa.me/6285640899224)
- GitHub: [github.com/jagoflutter](https://github.com/jagoflutter)

### Referensi
- [Flutter Documentation](https://docs.flutter.dev)
- [Supabase Documentation](https://supabase.com/docs)
- [flutter_bloc Package](https://bloclibrary.dev)

---

## License

MIT License - Feel free to use for learning and commercial projects.
