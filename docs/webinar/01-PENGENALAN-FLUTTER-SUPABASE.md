# Pengenalan Flutter & Supabase

## Daftar Isi
1. [Apa itu Flutter?](#apa-itu-flutter)
2. [Apa itu Supabase?](#apa-itu-supabase)
3. [Mengapa Flutter + Supabase?](#mengapa-flutter--supabase)
4. [Perbandingan dengan Alternatif Lain](#perbandingan-dengan-alternatif-lain)

---

## Apa itu Flutter?

### Definisi
**Flutter** adalah framework open-source dari Google untuk membangun aplikasi **cross-platform** dari satu codebase. Dengan Flutter, Anda bisa membuat aplikasi untuk:
- Android
- iOS
- Web
- Desktop (Windows, macOS, Linux)

### Bahasa Pemrograman: Dart
Flutter menggunakan bahasa **Dart** yang juga dikembangkan oleh Google. Dart adalah bahasa yang:
- **Strongly typed** - mengurangi bug saat runtime
- **Object-oriented** - familiar bagi developer Java/C#
- **Optimized for UI** - mendukung hot reload untuk development cepat

### Keunggulan Flutter

| Keunggulan | Penjelasan |
|------------|------------|
| **Single Codebase** | Tulis sekali, jalankan di mana saja (Android, iOS, Web, Desktop) |
| **Hot Reload** | Lihat perubahan UI secara instan tanpa restart aplikasi |
| **Widget-Based** | Semua adalah widget - mudah di-compose dan customize |
| **Native Performance** | Compile ke native ARM code, bukan bridge seperti React Native |
| **Rich Ecosystem** | 30,000+ packages di pub.dev |
| **Strong Community** | Didukung Google dengan komunitas aktif |

### Bagaimana Flutter Bekerja?

```
┌─────────────────────────────────────────────────────────┐
│                    YOUR FLUTTER APP                      │
│                    (Dart Code)                           │
├─────────────────────────────────────────────────────────┤
│                   FLUTTER FRAMEWORK                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐   │
│  │  Material   │ │  Cupertino  │ │    Widgets      │   │
│  │  Design     │ │  (iOS)      │ │    Library      │   │
│  └─────────────┘ └─────────────┘ └─────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                   FLUTTER ENGINE                         │
│           (C++ - Skia Graphics, Dart Runtime)           │
├─────────────────────────────────────────────────────────┤
│                   PLATFORM LAYER                         │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐   │
│  │   Android   │ │     iOS     │ │   Web/Desktop   │   │
│  └─────────────┘ └─────────────┘ └─────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## Apa itu Supabase?

### Definisi
**Supabase** adalah platform Backend-as-a-Service (BaaS) open-source yang sering disebut sebagai **"Firebase Alternative"**. Supabase menyediakan:

1. **PostgreSQL Database** - Database relasional yang powerful
2. **Authentication** - Login dengan email, OAuth, magic link
3. **Storage** - Penyimpanan file (gambar, dokumen)
4. **Realtime** - Subscribe ke perubahan data secara real-time
5. **Edge Functions** - Serverless functions (seperti Cloud Functions)

### Mengapa Supabase Populer?

| Fitur | Penjelasan |
|-------|------------|
| **Open Source** | Bisa self-host jika dibutuhkan |
| **PostgreSQL** | Database relasional yang mature dan powerful |
| **SQL Support** | Gunakan SQL langsung, tidak perlu belajar query language baru |
| **Row Level Security** | Keamanan di level database, bukan hanya API |
| **Free Tier Generous** | 500MB database, 1GB storage, unlimited API calls |
| **Auto-generated API** | REST & GraphQL API otomatis dari schema |

### Arsitektur Supabase

```
┌─────────────────────────────────────────────────────────┐
│                    YOUR FLUTTER APP                      │
├─────────────────────────────────────────────────────────┤
│                   SUPABASE CLIENT                        │
│            (supabase_flutter package)                    │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│  │   Auth   │ │ Database │ │ Storage  │ │ Realtime │   │
│  │ (GoTrue) │ │(PostgREST)│ │          │ │          │   │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘   │
│       │            │            │            │          │
│  ┌────┴────────────┴────────────┴────────────┴─────┐   │
│  │              POSTGRESQL DATABASE                 │   │
│  │         (with Row Level Security)               │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Supabase vs Firebase

| Aspek | Supabase | Firebase |
|-------|----------|----------|
| **Database** | PostgreSQL (SQL) | Firestore (NoSQL) |
| **Query** | SQL standard | Proprietary query |
| **Open Source** | Ya | Tidak |
| **Self-hosting** | Bisa | Tidak |
| **Realtime** | Ya | Ya |
| **Pricing** | Lebih murah | Lebih mahal di scale |
| **Learning Curve** | Familiar (SQL) | Perlu belajar NoSQL |

---

## Mengapa Flutter + Supabase?

### Kombinasi yang Powerful

```
┌────────────────────────────────────────────────────────┐
│                                                         │
│   FLUTTER                    SUPABASE                  │
│   ════════                   ═════════                 │
│   • Cross-platform UI        • Backend lengkap         │
│   • Single codebase          • PostgreSQL database     │
│   • Hot reload               • Authentication          │
│   • Native performance       • Realtime sync           │
│                                                         │
│              ┌─────────────────────┐                   │
│              │  PERFECT MATCH FOR  │                   │
│              │   OFFLINE-FIRST     │                   │
│              │   MOBILE APPS       │                   │
│              └─────────────────────┘                   │
│                                                         │
└────────────────────────────────────────────────────────┘
```

### Use Case: Aplikasi Laundry Offline

Aplikasi kasir laundry UMKM membutuhkan:

| Kebutuhan | Solusi Flutter | Solusi Supabase |
|-----------|----------------|-----------------|
| Jalan tanpa internet | SQLite lokal | - |
| Sync saat online | Connectivity check | Cloud database |
| Multi-device | Single codebase | Realtime sync |
| Cetak struk | Bluetooth printer plugin | - |
| Laporan | Export Excel | Backup cloud |
| Multi-user | Local auth | Supabase Auth |

### Keuntungan untuk UMKM

1. **Zero Server Cost** - Free tier Supabase cukup untuk bisnis kecil
2. **Offline-First** - Tetap jalan meski internet mati
3. **Data Aman** - Backup otomatis ke cloud
4. **Multi-Device** - Data sync antar HP/tablet
5. **Skalabel** - Bisa grow tanpa ganti teknologi

---

## Perbandingan dengan Alternatif Lain

### Mobile Framework

| Framework | Bahasa | Performance | Learning Curve |
|-----------|--------|-------------|----------------|
| **Flutter** | Dart | Excellent | Medium |
| React Native | JavaScript | Good | Medium |
| Native Android | Kotlin/Java | Excellent | High |
| Native iOS | Swift | Excellent | High |
| Ionic | JavaScript | Moderate | Low |

### Backend Service

| Service | Database | Pricing | Offline Support |
|---------|----------|---------|-----------------|
| **Supabase** | PostgreSQL | Generous free tier | Manual |
| Firebase | Firestore | Pay per read/write | Built-in |
| AWS Amplify | DynamoDB | Complex pricing | Manual |
| Appwrite | MariaDB | Self-host | Manual |

---

## Kesimpulan

**Flutter + Supabase** adalah kombinasi ideal untuk:
- Startup yang butuh MVP cepat
- UMKM yang butuh aplikasi affordable
- Developer solo yang ingin full-stack
- Aplikasi yang butuh offline-first capability

### Referensi
- [Flutter Documentation](https://docs.flutter.dev)
- [Supabase Documentation](https://supabase.com/docs)
- [Dart Language](https://dart.dev)
- [pub.dev - Flutter Packages](https://pub.dev)
