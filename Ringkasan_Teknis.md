# Ringkasan Teknis Developer: Arsitektur & Direktori Aplikasi SiBanjir

Dokumen ini disusun khusus untuk kebutuhan *Developer, Code Reviewer*, atau Akademisi yang ingin memahami anatomi kode sumber (Source Code) dari aplikasi secara spesifik, hingga ke tingkat hierarki setiap file di dalam folder `lib/`.

---

## 🏗 Konsep Dasar Struktur (Clean Architecture)
Aplikasi ini mematuhi standar *Feature-Driven Layered Architecture*. Artinya, sistem tidak dipisah berdasarkan tipe file (seperti folder *Controllers* dicampur semua, *Views* dicampur semua), melainkan dikelompokkan berdasarkan **Nama Fitur**. Setiap fitur kemudian dibagi lagi menjadi `data/` (Logika Backend), `domain/` (Logika Bisnis komputasi), dan `presentation/` (Tampilan UI).

---

## 📁 Pembedahan Struktur Folder `lib/`

### 1. File Entry Point (Akar Aplikasi)
- `main.dart` : Jantung dari aplikasi. Di sini kita memanggil fungsi `WidgetsFlutterBinding.ensureInitialized()`, memulai koneksi Supabase, menginisialisasi environment (`.env`), Firebase, dan membungkus aplikasi dengan `ProviderScope` (Riverpod).
- `app.dart` : Berisi kelas `MaterialApp`. Menyimpan pengaturan tema utama (`AppTheme`), penanganan transisi layar Splash *deep linking* ke Login, penyegaran state autentikasi (*listen onAuthStateChange*), dan pembungkus *Tap-to-Dismiss Global Keyboard* menggunakan `GestureDetector`.
- `firebase_options.dart` : File *auto-generated* berisi kunci konfigurasi rahasia untuk Firebase Cloud Messaging (FCM).

### 2. Folder `lib/core/` (Logika Global)
Berisi pondasi yang dipakai secara bersama-sama oleh berbagai fitur.
- **`config/`**
  - `env.dart` : Pembaca variabel rahasia dari `.env` (seperti *Supabase URL* & *Anon Key*).
- **`theme/`**
  - `app_theme.dart` : Konstanta UI. Berisi definisi warna utama (`AppColors`), tipografi dinamis, serta *override* gaya dasar *ElevatedButton*, *InputDecoration*, dan *Card* (Material 3).
- **`utils/`**
  - `error_handler.dart` : Penerjemah kode *Error* Supabase. Misal, jika database melempar *Custom Exception* `P0001` karena pelanggaran blokir, file ini menerjemahkannya ke kalimat bahasa Indonesia yang manusiawi.
- **`providers/`**
  - `navigation_providers.dart` : Menyimpan state `homeTabIndexProvider` yang berstatus `autoDispose`. Digunakan agar Tab UI Home bisa direset ke-0 setiap *Logout*.
  - `network_connectivity_provider.dart` : Mendeteksi ketersediaan kuota/wifi (*auto-refresh* otomatis saat internet tersambung kembali).
- **`notifications/`**
  - `fcm_service.dart` : Mesin pendengar pesan notifikasi *Push/Background* Firebase.
  - `local_notification_service.dart` : Pemanggil pesan Pop-up ke layar Android menggunakan `flutter_local_notifications`.
- **`widgets/`**
  - `app_notification.dart` : Komponen *Pop-up/Snackbar Toast* kustom bergaya *Glassmorphism* melayang untuk menampilkan notifikasi *Success/Error* elegan.
  - `report_detail_bottom_sheet.dart` : Logika *Bottom Sheet* yang dapat dipakai ulang di peta atau feed untuk menampilkan detail banjir.

### 3. Folder `lib/features/auth/` (Autentikasi)
- **`presentation/pages/`**
  - `login_page.dart` : Antarmuka masuk. Menangani API Supabase Auth standar dan `signInWithIdToken` melalui *Google Sign In Provider*.
  - `register_page.dart` : Antarmuka daftar dengan perlindungan deteksi *Username* duplikat.
  - `splash_page.dart` : Tampilan *Loading* pembuka bergaya logo air berdetak.
  - `forgot_password_page.dart` & `update_password_page.dart` : Alur pemulihan sandi via *Deep Linking Magic Link*.
  - `onboarding_page.dart` : Karosel pengenalan fitur awal untuk pendaftar baru.

### 4. Folder `lib/features/home/` (Container Utama)
- **`presentation/pages/`**
  - `home_shell_page.dart` : "Cangkang" navigasi utama. Memegang komponen *BottomNavigationBar* dan *IndexedStack*. File ini menjaga agar *Map* dan *Feed* tidak memuat ulang (*re-render*) secara membabi-buta setiap kali pengguna berpindah Tab. Terdapat *Listener* untuk `activeGeofenceAlertProvider` yang mengeksekusi Pop-up Darurat.

### 5. Folder `lib/features/map/` (Pemetaan & Pelacakan)
- **`data/models/`**
  - `flood_report.dart` : Blueprint (DTO) parsing data JSON dari tabel *flood_reports* Supabase menjadi Dart Object.
- **`data/repositories/`**
  - `flood_report_repository.dart` : Pusat pengambilan data. Menggunakan perintah `.stream()` dari Supabase untuk *Realtime Websocket Connection*.
- **`domain/services/`**
  - `geofencing_service.dart` : *Engine* Pelacak. Berisi logika matematis `Geolocator.distanceBetween` untuk mencari selisih meter dari GPS terkini terhadap koordinat banjir. Memicu Alarm `flutter_ringtone_player`.
- **`presentation/pages/`**
  - `main_map_page.dart` : Layar Peta. Menangani manipulasi *Camera Position* dari *Google Maps Flutter*, render setelan pin marker (Merah/Kuning), dan memanggil *Custom Bottom Sheet*.
  - `emergency_alarm_page.dart` : Halaman intervensi khusus jika pengguna berjarak ekstrem dari lokasi berbahaya.

### 6. Folder `lib/features/feed/` (Sosial Komunitas)
- **`presentation/pages/`**
  - `feed_page.dart` : Linimasa utama beranda. Mengurutkan array `FloodReport` berdasarkan waktu terbaru.
- **`presentation/widgets/`**
  - `report_card.dart` : Kartu UI pelaporan yang memuat gambar, sistem *Upvote / Downvote*, status verifikasi, dan badge pelanggaran.
  - `report_comments_sheet.dart` : Layar *Bottom Sheet* untuk memuat daftar diskusi `report_comments` di setiap pelaporan.

### 7. Folder `lib/features/report/` (Pengajuan Data)
- **`data/repositories/`**
  - `report_submission_repository.dart` : Logika *Upload*. Menggunakan `image` (package) untuk memperkecil resolusi foto secara drastis, lalu melempar file tersebut ke *Supabase Storage Buckets*, mengambil URL publik, lalu menjalankan fungsi SQL `INSERT`.
- **`presentation/widgets/`**
  - `report_bottom_sheet.dart` : Form *Input* raksasa berlapis. Mempunyai logika *Smart Toggle Chips* interaktif (contoh: membatalkan teks "Jalan Terputus" jika diklik ulang), pembaca GPS lokal, dan manajemen *Keyboard Insets Geometry*.

### 8. Folder `lib/features/profile/` (Sistem Akun & Ekstra)
- **`presentation/pages/`**
  - `profile_page.dart` : Tempat kontrol akun. Mengeksekusi API `signOut()`, modifikasi *Username*, deteksi status *"Banned Account"* dari database, dan memanggil menu-menu edukasi lainnya.
  - `report_statistics_page.dart` : Menampilkan UI diagram analisis dari *Fl Chart* (misal Tren Genangan 3 Bulan Terakhir).
  - `emergency_contacts_page.dart`, `flood_guide_page.dart`, `evacuation_centers_page.dart` : Halaman utilitas edukasi dan komunikasi darurat.

---

## 🛠 Tabel *Database Triggers* (Bagian Latar Belakang / Backend)
Aplikasi sangat mengandalkan skrip SQL di server Supabase (Folder Lokal `supabase/migrations/`):
- `202606020001_initial_schema.sql` : Cetak biru utama struktur tabel RLS (Users, Flood Reports, Comments).
- `202606070002_update_comment_violations.sql` : Skrip penambah *logic Trigger*. Jika downvote laporan mencapai ambang batas negatif, tambahkan `violation_count` si pembuat laporan.
- `202606080001_restrict_banned_users.sql` : Skrip sekuritas mutlak. Mencegat operasi INSERT apapun dari *Client* jika ID mereka berafiliasi dengan akun yang telah memiliki nilai *strike* `is_banned = true`. Melempar *code* `P0001` untuk ditangkap oleh `error_handler.dart` Flutter.
