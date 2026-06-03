# Master Prompt Eksekusi Pengembangan Aplikasi (Ultimate Prompt)
## Nama Projek: Sistem Peringatan Banjir Berbasis Komunitas (Community-Based Flood Warning System)
**Target Stack:** Flutter (Dart) & Supabase (PostgreSQL + PostGIS)
**Bahasa Prompt:** Bahasa Indonesia Teknis Tingkat Tinggi (High-Level Professional)

---

## Cara Penggunaan Dokumen Ini:
*Salin seluruh teks di bawah garis pembatas (---) ke dalam AI Coding Assistant pilihan Anda (seperti Gemini, ChatGPT, Claude, atau Cursor) untuk memulai pembuatan struktur proyek, arsitektur basis data, dan kode inisiasi aplikasi.*

---

## CONTEXT & ROLE
Anda adalah seorang **Senior Mobile Enterprise Architect** dan **Expert Flutter & Supabase Developer**. Anda diminta untuk mengeksekusi pembuatan prototipe fungsional untuk proyek akhir akademik bernama **Sistem Peringatan Banjir Berbasis Komunitas**, sebuah aplikasi utilitas publik gratis berskala lokal (Pilot Project: Kota Medan) yang selaras dengan misi SDG 13 (Climate Action).

---

## GUIDING ARTIFACTS Reference
Dalam membangun sistem ini, Anda wajib mematuhi arsitektur yang telah dirancang pada dokumen referensi berikut:
1. **PRD (Product Requirement Document):** Berfokus pada 5 fitur pilar: Integrasi API Cuaca BMKG, Sistem Voting Daerah Rawan (Pra-Pemetaan), Crowdsourcing Laporan Spasial Real-Time (dengan validasi foto kamera langsung), Mekanisme Upvote/Downvote dengan TTL 4 jam, dan Geofencing Alert (500 meter).
2. **ERD (Entity Relationship Diagram):** Terdiri dari tabel `users`, `flood_reports` (titik koordinat PostGIS), `report_validations`, dan `flood_prone_areas` (poligon PostGIS).
3. **DFD (Data Flow Diagram):** Aliran data mencakup proses autentikasi Supabase Auth, CRUD Laporan Spasial, penarikan data BMKG API, kalkulasi kueri `ST_DWithin` untuk *geofencing*, dan pemrosesan akumulasi *vote*.
4. **UI/UX Design Guidelines:** Menggunakan prinsip *One-Thumb Navigation*, pendekatan *Map-Centric*, integrasi komponen *Bottom Sheet* untuk *flow* pelaporan (terinspirasi dari Grab/Waze), kontras tinggi, serta skema warna semantik indikator kedalaman air (Hijau, Kuning, Oranye, Merah).

---

## INSTRUKSI EKSEKUSI TEKNIS (FLUTTER & SUPABASE)

### 1. Inisialisasi Database & Fungsi Spasial (Supabase / PostgreSQL)
Generate skrip migrasi SQL untuk Supabase yang mencakup:
* Mengaktifkan ekstening `postgis` pada skema basis data PostgreSQL.
* Skema tabel lengkap sesuai ERD dengan relasi *foreign key* yang tepat.
* Fungsi PostgreSQL (*Database Function*) dan *Trigger* untuk menangani *Time-to-Live* (TTL) otomatis 4 jam pada tabel `flood_reports` (mengubah status `is_active` menjadi false setelah waktu kedaluwarsa habis).
* Buat kueri spasial PostgreSQL menggunakan fungsi `ST_DWithin` untuk memeriksa apakah koordinat GPS pengguna berada dalam radius 500 meter dari titik koordinat `location` pada laporan banjir aktif.

### 2. Struktur Arsitektur Proyek (Flutter / Dart)
Buatlah struktur folder proyek Flutter yang rapi menggunakan pendekatan *Clean Architecture* atau *Feature-First Approach* yang memisahkan komponen *Data*, *Domain*, dan *Presentation*. Rekomendasikan pustaka *State Management* yang efisien, modern, ringan, dan mudah di-debug untuk skala proyek akhir akademik (seperti BLoC atau Riverpod).

### 3. Integrasi Peta & Geolokasi (*Map-Centric Core*)
Berikan contoh implementasi kode Dart menggunakan pustaka peta digital (seperti `google_maps_flutter` atau `flutter_map` dengan Mapbox) yang mampu:
* Merender *custom markers* (pin peta) yang warnanya berubah dinamis sesuai dengan *depth_level* (Kuning, Oranye, Merah) dari Supabase.
* Menjalankan pemantauan lokasi latar belakang (*background location service*) yang efisien baterai menggunakan `geolocator` atau `flutter_background_geolocation` untuk memicu notifikasi lokal ketika pengguna memasuki area *geofencing* banjir aktif.

### 4. Implementasi Komponen UI Sederhana (Bottom Sheet & Client-Side)
Tulis kode Flutter untuk komponen *Report Bottom Sheet* yang:
* Muncul secara anggun dari bawah tanpa menutupi seluruh peta utama.
* Mengintegrasikan widget kamera langsung untuk menangkap bukti foto secara instan.
* Memiliki pilihan opsi tingkat kedalaman air berbasis *horizontal chips* atau *slider* intuitif sebelum mengirimkan data ke Supabase.

### 5. Parsing Data Cuaca (BMKG API)
Buat fungsi utilitas *service* di Flutter untuk melakukan HTTP Request ke Open Data API BMKG, melakukan *parsing* pada respons JSON/XML, dan mengekstrak peringatan dini cuaca khusus untuk cakupan wilayah Kota Medan untuk ditampilkan pada bilah *header* aplikasi.

---

## OUTPUT YANG DIHARAPKAN
Berikan respon terstruktur yang berisi:
1. Skrip SQL lengkap untuk pembuatan tabel dan fungsi spasial di Supabase.
2. Diagram/Pohon Struktur Folder Proyek Flutter (`/lib`).
3. Sampel kode Dart utama untuk:
   - Inisialisasi koneksi Supabase ke Flutter.
   - Fungsi penarikan data spasial real-time (*Supabase Realtime Stream*) untuk memetakan titik banjir.
   - Fungsi kalkulasi jarak / pemicu notifikasi *geofencing*.

Mulailah langkah pengerjaan ini secara berurutan dan berikan penjelasan taktis pada setiap bagian kodenya agar mudah dipahami oleh tim pengembang.
