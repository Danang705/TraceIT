# PRD — FindIt: Platform Pelaporan Barang Hilang & Ditemukan
> Product Requirements Document · v1.0 · 2026  
> Mobile App · Flutter · Clean Architecture

---

## 1. Overview

**FindIt** adalah aplikasi mobile berbasis Flutter untuk melaporkan dan melacak barang hilang/ditemukan menggunakan lokasi real-time, peta interaktif, kamera, dan chat antar pengguna. Backend sudah tersedia di Render dengan REST API yang terdokumentasi.

**Target Pengguna:** Masyarakat umum yang kehilangan atau menemukan barang di area publik.

---

## 2. Design Direction

### Aesthetic: "Warm Urban Finder"
Bersih, cepat, dan manusiawi — tidak dingin seperti aplikasi utilitas. Terinspirasi dari desain aplikasi komunitas modern (Nextdoor, Be My Eyes) dengan sentuhan lokal yang hangat.

### Palet Warna
```dart
// Light Theme
primary        : Color(0xFF2563EB)  // Biru kepercayaan — CTA utama
primaryDark    : Color(0xFF1D4ED8)  // Pressed state
accent         : Color(0xFFF59E0B)  // Kuning amber — barang ditemukan
surface        : Color(0xFFF8FAFC)  // Background utama
surfaceCard    : Color(0xFFFFFFFF)  // Card
textPrimary    : Color(0xFF0F172A)  // Judul
textSecondary  : Color(0xFF64748B)  // Subtext
success        : Color(0xFF10B981)  // Closed/resolved
danger         : Color(0xFFEF4444)  // Hilang/urgent
borderColor    : Color(0xFFE2E8F0)

// Tag warna jenis laporan
tagLost        : Color(0xFFFFEDED)  // bg merah muda, text danger
tagFound       : Color(0xFFECFDF5)  // bg hijau muda, text success
```

### Tipografi
```dart
// Google Fonts
displayFont : 'Sora'       // Heading besar, judul card (FontWeight.w700, w600)
bodyFont    : 'Nunito'     // Body text, label, deskripsi (FontWeight.w400, w500)
monoFont    : 'Fira Code'  // Koordinat, timestamp, ID
```

### Prinsip UI/UX
- **Bottom Navigation Bar** — 4 tab utama (Beranda, Peta, Laporan Saya, Chat)
- **Card-first** — semua konten dalam rounded card dengan shadow lembut (`elevation: 2`)
- **Status chip berwarna** — "Hilang" merah, "Ditemukan" hijau, "Selesai" abu
- **Floating Action Button** — tombol lapor utama, selalu terlihat
- **Skeleton loading** — tidak ada spinner polos, semua pakai shimmer loading
- **Haptic feedback** — pada CTA penting (simpan laporan, terima klaim)
- **Empty state** — ilustrasi SVG kustom + teks deskriptif di setiap halaman kosong
- **Micro-animation** — Hero transition antar halaman, slide-up modal, fade-in card

---

## 3. Design System & Komponen

### 3.1 Komponen Global

| Komponen | Keterangan |
|---|---|
| `AppButton` | Primary, Secondary, Danger, Outlined — semua dengan loading state |
| `AppTextField` | Input dengan border animasi, error state, icon prefix/suffix |
| `PostCard` | Card laporan dengan foto, jarak, status chip, waktu relatif |
| `StatusChip` | Pill berwarna: Hilang / Ditemukan / Selesai |
| `UserAvatar` | Foto profil dengan fallback inisial nama |
| `AppBottomSheet` | Modal slide-up untuk form konfirmasi, filter, detail klaim |
| `MapMarker` | Custom marker merah (hilang) dan hijau (ditemukan) |
| `ChatBubble` | Bubble percakapan kiri/kanan dengan timestamp |
| `ImagePickerSheet` | Bottom sheet pilih: Kamera atau Galeri |
| `SkeletonCard` | Shimmer placeholder saat loading konten |
| `AppSnackbar` | Toast notifikasi sukses/error/info di bagian atas |

### 3.2 Layout & Navigation

```
AppShell
├── BottomNavigationBar
│   ├── Tab 0: Beranda (Home)
│   ├── Tab 1: Peta (Map)
│   ├── Tab 2: Laporan Saya (My Posts)
│   └── Tab 3: Pesan (Chat)
└── FloatingActionButton → Buat Laporan
```

---

## 4. Core Features

### 4.1 Autentikasi

| Fitur | Detail | Endpoint |
|---|---|---|
| Registrasi | Email, nama, password | `POST /auth/register` |
| Login | Email + password → simpan token di SecureStorage | `POST /auth/login` |
| Auto refresh token | Intercept 401, refresh otomatis, retry request | `POST /auth/refresh-token` |
| Logout | Hapus token lokal + invalidate server | `POST /auth/logout` |
| Lupa password | Flow: kirim email → input OTP → reset password | 3 endpoint terpisah |
| Persistent login | Token tersimpan di `flutter_secure_storage` | — |

### 4.2 Beranda (Feed Laporan)

| Fitur | Detail | Endpoint |
|---|---|---|
| Daftar laporan | Scroll infinite, tampil PostCard | `GET /posts` |
| Filter radius | Slider jarak (1–50 km dari lokasi user) | `GET /posts?radius=X` |
| Filter jenis | Toggle: Semua / Hilang / Ditemukan | `GET /posts?type=X` |
| Search | Cari berdasarkan deskripsi barang (client-side filter) | — |
| Pull to refresh | Tarik ke bawah untuk refresh feed | — |
| Detail laporan | Tap card → halaman detail lengkap + tombol klaim | `GET /posts/:id` |

### 4.3 Peta Interaktif

| Fitur | Detail | Endpoint |
|---|---|---|
| Tampil semua marker | Marker merah (hilang), hijau (ditemukan) | `GET /posts/maps` |
| Tap marker | Muncul bottom sheet mini: foto + deskripsi + tombol "Lihat Detail" | — |
| Lokasi user | Titik biru pulsating (current location) | GPS device |
| Filter on map | Toggle jenis laporan langsung di peta | — |
| Cluster marker | Marker otomatis cluster jika berdekatan | flutter_map |

### 4.4 Buat Laporan

| Fitur | Detail | Endpoint |
|---|---|---|
| Foto barang | Wajib min. 1 foto, max 3 foto; kamera atau galeri | `POST /upload` |
| Jenis laporan | Toggle: Barang Hilang / Barang Ditemukan | — |
| Deskripsi | Text area, min 20 karakter | — |
| Titik lokasi | Otomatis dari GPS; bisa geser pin di peta mini | — |
| Preview sebelum kirim | Tampil ringkasan sebelum submit | — |
| Submit | Kirim ke server, redirect ke detail laporan baru | `POST /posts` |

### 4.5 Manajemen Laporan Saya

| Fitur | Detail | Endpoint |
|---|---|---|
| Daftar laporan saya | Tab: Aktif / Selesai | `GET /posts` (filter user) |
| Edit laporan | Edit deskripsi & foto | `PUT /posts/:id` |
| Tutup kasus | Tandai selesai/barang sudah kembali | `PATCH /posts/:id/status` |
| Hapus laporan | Konfirmasi dialog sebelum hapus | `DELETE /posts/:id` |
| Lihat klaim masuk | List orang yang klaim laporan saya | `GET /posts/:id/responses` |
| Terima / tolak klaim | Action button di setiap klaim | `PATCH /responses/:id/status` |

### 4.6 Sistem Klaim

| Fitur | Detail | Endpoint |
|---|---|---|
| Kirim klaim | Dari halaman detail laporan orang lain | `POST /posts/:postId/responses` |
| Foto bukti | Upload foto bukti kepemilikan | `POST /upload` |
| Keterangan klaim | Deskripsi mengapa ini milik user | — |
| Status klaim | Menunggu / Diterima / Ditolak | — |
| Notifikasi lokal | Push notif saat klaim diterima/ditolak | — |
| Auto buat chat room | Jika klaim diterima → langsung buka chat | Triggered otomatis |

### 4.7 Chat Real-Time

| Fitur | Detail | Endpoint |
|---|---|---|
| Inbox | Daftar semua chat room aktif | `GET /chat` |
| Chat room | Percakapan antara pelapor & pengklaim | `GET /chat/:roomId/messages` |
| Kirim pesan | Text message | WebSocket / polling |
| Foto profil lawan | Tampil di header chat room | — |
| Timestamp pesan | Format: "barusan", "5 menit lalu", tanggal | — |
| Unread badge | Badge jumlah pesan belum dibaca di tab Chat | — |

### 4.8 Profil Pengguna

| Fitur | Detail | Endpoint |
|---|---|---|
| Lihat profil | Foto, nama, nomor HP, alamat | `GET /auth/me` |
| Edit profil | Ganti foto profil (kamera/galeri), nama, HP, alamat | `PUT /users/profile` |
| Lihat profil orang lain | Saat tap nama pelapor di detail laporan | `GET /users/:id` |

### 4.9 Admin Panel (Halaman Tersembunyi)

Hanya muncul jika user memiliki role admin (deteksi dari response `/auth/me`).

| Fitur | Detail | Endpoint |
|---|---|---|
| Statistik platform | Total user, laporan, klaim, selesai | `GET /admin/statistics` |
| Daftar semua user | List + opsi ban/unban | `GET /admin/users` |
| Ban user | Konfirmasi dialog | `PATCH /admin/users/:id/ban` |
| Semua laporan | Tanpa filter radius | `GET /admin/posts` |
| Hapus laporan | Moderasi konten melanggar aturan | `DELETE /admin/posts/:id` |

---

## 5. User Flow

### 5.1 Onboarding & Login
```
Splash Screen (2 detik, cek token)
  ├─ Token valid → Home (skip login)
  └─ Token tidak ada / expired
        └─> Onboarding (3 slide: fitur app) → hanya muncul pertama kali
              └─> Login Screen
                    ├─> [Masuk] → Home
                    ├─> [Daftar] → Register Screen → Verifikasi → Home
                    └─> [Lupa Password] → Email → OTP → Reset → Login
```

### 5.2 Lihat & Filter Laporan
```
Home Tab
  └─> Feed PostCard (foto, jarak, waktu, status chip)
        ├─> Filter Bar: [Semua] [Hilang] [Ditemukan] + Slider radius
        ├─> Pull to refresh
        ├─> Scroll infinite load more
        └─> Tap Card → Detail Laporan
              ├─> Foto carousel, deskripsi, lokasi, info pelapor
              ├─> Jika bukan laporan sendiri → Tombol [Ajukan Klaim]
              └─> Jika laporan sendiri → Tombol [Lihat Klaim Masuk]
```

### 5.3 Buat Laporan Baru
```
FAB (+) di Home / Peta
  └─> Bottom Sheet: [Barang Hilang] [Barang Ditemukan]
        └─> Form Laporan
              ├─> Upload Foto (tap → pilih kamera/galeri, min 1 max 3)
              ├─> Deskripsi barang (textarea)
              ├─> Peta mini — pin otomatis GPS, bisa geser
              └─> Tombol [Preview] → Tampil ringkasan
                    └─> Tombol [Publikasikan]
                          └─> Loading → Sukses → Detail laporan baru
```

### 5.4 Ajukan Klaim
```
Detail Laporan orang lain
  └─> Tombol [Ajukan Klaim]
        └─> Bottom Sheet Form Klaim
              ├─> Upload foto bukti kepemilikan
              ├─> Keterangan (mengapa barang ini milik saya)
              └─> Tombol [Kirim Klaim]
                    └─> Notif: "Klaim terkirim, tunggu konfirmasi pemilik"
```

### 5.5 Proses Klaim (Sisi Pelapor)
```
Notifikasi: "Ada yang mengklaim laporan Anda"
  └─> Laporan Saya → Tab [Klaim Masuk]
        └─> List klaim: foto profil, foto bukti, keterangan
              └─> Tap klaim → Detail klaim
                    ├─> [Terima Klaim] → Konfirmasi dialog
                    │     └─> Chat room otomatis terbuka dengan pengklaim
                    └─> [Tolak Klaim] → Konfirmasi dialog
                          └─> Pengklaim mendapat notif penolakan
```

### 5.6 Chat Setelah Klaim Diterima
```
Tab Pesan (atau redirect otomatis setelah terima klaim)
  └─> Inbox: list chat room aktif
        └─> Tap chat room → Chat Screen
              ├─> Header: foto profil, nama lawan bicara
              ├─> Riwayat pesan dengan timestamp
              └─> Input field + tombol kirim
```

### 5.7 Tutup Kasus
```
Laporan Saya → Detail laporan
  └─> Tombol [Tandai Selesai]
        └─> Konfirmasi: "Apakah barang sudah dikembalikan?"
              └─> Status laporan berubah → SELESAI
                    └─> Card ditandai hijau di feed + tidak muncul di filter aktif
```

### 5.8 Flow Admin
```
Deteksi role admin dari GET /auth/me
  └─> Menu tambahan muncul di profil: [Panel Admin]
        └─> Admin Dashboard
              ├─> Statistik (card: total user, laporan, klaim, selesai)
              ├─> Manajemen User (list + ban/unban)
              └─> Moderasi Laporan (semua laporan, tombol hapus)
```

---

## 6. Halaman & Screen List

| Screen | Route Name | Auth Required |
|---|---|---|
| Splash | `/splash` | No |
| Onboarding | `/onboarding` | No |
| Login | `/login` | No |
| Register | `/register` | No |
| Lupa Password | `/forgot-password` | No |
| OTP Verifikasi | `/verify-otp` | No |
| Reset Password | `/reset-password` | No |
| Home (Feed) | `/home` | Yes |
| Detail Laporan | `/posts/:id` | Partial |
| Buat Laporan | `/posts/create` | Yes |
| Edit Laporan | `/posts/:id/edit` | Yes |
| Peta | `/map` | Yes |
| Laporan Saya | `/my-posts` | Yes |
| Klaim Masuk | `/posts/:id/claims` | Yes |
| Detail Klaim | `/claims/:id` | Yes |
| Chat Inbox | `/chat` | Yes |
| Chat Room | `/chat/:roomId` | Yes |
| Profil Saya | `/profile` | Yes |
| Edit Profil | `/profile/edit` | Yes |
| Profil Orang Lain | `/users/:id` | Yes |
| Admin Dashboard | `/admin` | Admin only |
| Admin Users | `/admin/users` | Admin only |
| Admin Laporan | `/admin/posts` | Admin only |

---

## 7. Tech Stack & Clean Architecture

### Package Utama
```yaml
dependencies:
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # Navigation
  go_router: ^13.0.0

  # Network
  dio: ^5.4.0
  retrofit: ^4.1.0         # Type-safe HTTP client generator

  # Local Storage
  flutter_secure_storage: ^9.0.0  # Token JWT
  shared_preferences: ^2.2.2      # Preferensi app (onboarding shown, dll.)

  # Peta
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  geolocator: ^11.0.0
  geocoding: ^3.0.0

  # Kamera & Gambar
  image_picker: ^1.0.7
  cached_network_image: ^3.3.1
  photo_view: ^0.14.0

  # UI & Animasi
  shimmer: ^3.0.0
  lottie: ^3.1.0
  google_fonts: ^6.1.0

  # Utilitas
  intl: ^0.19.0
  timeago: ^3.6.0
  connectivity_plus: ^5.0.2
  permission_handler: ^11.3.0
```

### Struktur Folder (Clean Architecture)
```
lib/
├── core/
│   ├── constants/          # AppColors, AppStrings, AppRoutes
│   ├── errors/             # Failure, Exception classes
│   ├── network/            # DioClient, AuthInterceptor, TokenRefresher
│   ├── usecases/           # BaseUseCase abstract class
│   └── utils/              # DateFormatter, LocationHelper, ImageHelper
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/    # AuthRemoteDataSource
│   │   │   ├── models/         # UserModel, TokenModel
│   │   │   └── repositories/   # AuthRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/       # User, Token
│   │   │   ├── repositories/   # AuthRepository (abstract)
│   │   │   └── usecases/       # Login, Register, Logout, RefreshToken
│   │   └── presentation/
│   │       ├── bloc/           # AuthBloc, AuthEvent, AuthState
│   │       └── pages/          # LoginPage, RegisterPage, ForgotPasswordPage
│   │
│   ├── posts/              # Sama: data / domain / presentation
│   ├── map/
│   ├── claims/
│   ├── chat/
│   ├── profile/
│   └── admin/
│
├── shared/
│   ├── widgets/            # AppButton, AppTextField, PostCard, dll.
│   └── bloc/               # AppBloc (auth state global)
│
└── main.dart
    app.dart                # MaterialApp + GoRouter setup
    injection.dart          # GetIt dependency injection
```

### Pola State Management (BLoC)
```dart
// Setiap fitur memiliki:
// 1. Event  — aksi yang dipicu user
// 2. State  — kondisi UI (Initial, Loading, Success, Failure)
// 3. Bloc   — business logic, menghubungkan usecase ke state

// Contoh: PostsBloc
// Event: FetchPostsEvent(radius, type)
// State: PostsLoading | PostsLoaded(posts) | PostsError(message)
```

### Token Management
```
Login → simpan accessToken + refreshToken ke SecureStorage
Request → Dio Interceptor tambahkan Bearer Token di header
Response 401 → Interceptor otomatis: 
  1. Pause queue request
  2. Panggil POST /refresh-token
  3. Simpan token baru
  4. Retry semua request yang pending
Refresh gagal → Logout + redirect ke Login
```

---

## 8. Non-Functional Requirements

| Aspek | Target |
|---|---|
| Performance | Feed 60 FPS, image lazy load, pagination |
| Offline handling | Tampil pesan "Tidak ada koneksi" + retry button |
| Security | Token di SecureStorage (bukan SharedPreferences), HTTPS only |
| UX | Setiap aksi async punya loading state & error state |
| Aksesibilitas | Semua widget punya `Semantics` label |
| Android min SDK | API 21 (Android 5.0) |
| iOS min | iOS 13 |
| Localization | Bahasa Indonesia (default), siap multi-bahasa via `.arb` |

---

## 9. Error Handling Strategy

```
Network Error      → AppSnackbar merah: "Gagal memuat data. Coba lagi."
401 Unauthorized   → Auto refresh → jika gagal, redirect login
403 Forbidden      → Snackbar: "Anda tidak memiliki akses"
404 Not Found      → Halaman empty state khusus
500 Server Error   → Snackbar: "Server sedang bermasalah, coba beberapa saat lagi"
No Internet        → Full-screen offline widget dengan tombol retry
Form Validation    → Error message merah inline di bawah field
```

---

## 10. API Integration Map

| Feature | Method | Endpoint |
|---|---|---|
| Register | POST | `/auth/register` |
| Login | POST | `/auth/login` |
| Logout | POST | `/auth/logout` |
| Refresh Token | POST | `/auth/refresh-token` |
| Lupa Password | POST | `/auth/forgot-password` |
| Verifikasi OTP | POST | `/auth/verify-otp` |
| Reset Password | POST | `/auth/reset-password` |
| Profil saya | GET | `/auth/me` |
| Edit profil | PUT | `/users/profile` |
| Profil user lain | GET | `/users/:id` |
| Feed laporan | GET | `/posts?radius=&type=` |
| Marker peta | GET | `/posts/maps` |
| Detail laporan | GET | `/posts/:id` |
| Buat laporan | POST | `/posts` |
| Edit laporan | PUT | `/posts/:id` |
| Tutup kasus | PATCH | `/posts/:id/status` |
| Hapus laporan | DELETE | `/posts/:id` |
| Kirim klaim | POST | `/posts/:postId/responses` |
| Lihat klaim masuk | GET | `/posts/:postId/responses` |
| Terima/tolak klaim | PATCH | `/responses/:id/status` |
| Chat inbox | GET | `/chat` |
| Pesan chat room | GET | `/chat/:roomId/messages` |
| Upload foto | POST | `/upload` |
| Admin statistik | GET | `/admin/statistics` |
| Admin users | GET | `/admin/users` |
| Admin ban | PATCH | `/admin/users/:id/ban` |
| Admin posts | GET | `/admin/posts` |
| Admin hapus post | DELETE | `/admin/posts/:id` |

---

*FindIt PRD v1.0 — siap untuk tahap development Flutter*