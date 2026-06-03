# Rencana & Progres Pengembangan (Project Plan)
**Sistem Peringatan Banjir Berbasis Komunitas (Kota Medan)**

Dokumen ini melacak seluruh fitur yang telah berhasil diimplementasikan, fitur yang sedang berjalan, dan rencana pengembangan di masa depan.

---

## ✅ FASE 1: Fitur Inti yang Telah Selesai (Completed)

### 1. Sistem Autentikasi & Profil
- [x] Login dan Register menggunakan email/password (Supabase Auth).
- [x] Menyimpan dan menampilkan `full_name` (Nama Lengkap) pengguna di halaman Profil dan Beranda.
- [x] Proteksi rute aplikasi (wajib login sebelum bisa mengakses fitur utama).

### 2. Modul Pelaporan Banjir (*Flood Reporting*)
- [x] Integrasi kamera asli bawaan HP (*full-screen*) menggunakan `image_picker`.
- [x] Otomatis mengubah gambar menjadi rasio persegi (1:1) dan kualitas HD (720p/80%) agar server tidak terbebani.
- [x] Menangkap titik lokasi akurat pelapor (*Latitude/Longitude*) via GPS.
- [x] Pilihan indikator visual kedalaman air (Mata kaki, Betis, Lutut, Pinggang).
- [x] Pengiriman laporan ke *Supabase Database* dan penyimpanan gambar ke *Supabase Storage*.
- [x] Dialog konfirmasi keamanan sebelum mengirim laporan untuk mencegah salah klik.

### 3. Beranda Komunitas (*Social Feed*)
- [x] Tampilan berbasis kartu (*Card-based UI*) ala Instagram untuk kemudahan visual.
- [x] Penampilan gambar banjir dengan proporsi elegan (1:1).
- [x] Menampilkan alamat lokasi (jika tersedia) beserta tombol jalan pintas menuju Peta.
- [x] Menampilkan identitas (Nama) asli dari si pelapor.

### 4. Sistem Validasi Laporan (*Voting System*)
- [x] Tombol "Masih Banjir" (Upvote) dan "Sudah Surut" (Downvote).
- [x] Logika Anti-Spam: Pengecekan otomatis di *repository* agar satu akun tidak bisa menyumbang *vote* ganda atau menumpuk suara.
- [x] Eksekusi Suara Senyap (*Silent Operation*): Suara dikirim secara instan di latar belakang tanpa terhalang *pop-up* notifikasi/SnackBar.
- [x] *Progress Bar* interaktif dengan animasi mulus (*TweenAnimation*) untuk melihat rasio validasi masyarakat.
- [x] Fitur **Tarik Suara (Undo Vote)**: Pengguna dapat membatalkan vote mereka jika salah.

### 5. Peta Interaktif & Jarak *Real-time* (*Google Maps*)
- [x] Halaman Peta Utama menampilkan pin semua titik banjir di seluruh kota.
- [x] Warna Pin Peta (Marker Hue) otomatis menyesuaikan level bahaya (cth: Lutut = Kuning, Pinggang = Oranye).
- [x] Tombol *My Location* Kustom: Posisi tombol target dipindah ke kiri bawah agar tidak tertutup oleh *System Bar* HP atau navigasi aplikasi.
- [x] **Halaman Detil Peta:** Tombol "Lihat Peta" di Beranda akan langsung membawa (*zoom*) ke lokasi spesifik.
- [x] **Live Distance Tracking:** Mengukur jarak fisik antara pengguna dan titik genangan air secara langsung (*real-time*) tanpa henti saat berjalan.

### 6. Peringatan Cuaca Ekstrem (API BMKG)
- [x] Integrasi *Nowcast RSS/XML API* dari BMKG secara langsung.
- [x] Deteksi pintar kata kunci wilayah (Medan / Sumatera Utara).
- [x] Pemunculan *Banner* Merah darurat secara otomatis di atas tab Peta jika hujan lebat/badai akan datang.

### 7. Manajemen Riwayat (*History*)
- [x] Daftar riwayat laporan yang dibuat sendiri oleh pengguna.
- [x] Tombol "Hapus Laporan" dengan integrasi *Delete Policy* (RLS) SQL di Supabase.

### 8. Sinkronisasi Live (*Realtime Feed*)
- [x] Mendengarkan perubahan data *live* langsung dari `flood_reports` dan `report_validations`.
- [x] *Vote* Beranda bertambah/berkurang secara *real-time* bagaikan Live Chat.

### 9. Pencarian Nama Jalan (*Reverse Geocoding*)
- [x] Otomatis menerjemahkan angka koordinat GPS menjadi teks alamat jalan (cth: "Jl. Sudirman...") saat pelaporan.
- [x] Integrasi OpenStreetMap Nominatim API tanpa kunci (*No API Key required*).

### 10. Pengaturan Profil Lanjutan
- [x] Fitur "Ubah Nama Profil" untuk memperbarui `full_name` di metadata Supabase.
- [x] Fitur "Ubah Foto Profil (Avatar)" yang terhubung ke Galeri HP dan Supabase Storage.
- [x] Fitur "Ubah Kata Sandi" terintegrasi langsung dengan keamanan Supabase Auth.

### 11. Fitur Diskusi & Komentar Laporan
- [x] Dukungan *Threaded Chat* ala media sosial untuk saling membalas komentar (fitur balasan bertingkat).
- [x] Fitur *Like* dan Hapus Komentar.
- [x] Pembaruan UI Instan (*Instant Invalidation*) yang memunculkan atau menghapus pesan tanpa perlu menunggu jeda server.
- [x] Fitur *Pull-to-Refresh* manual pada menu diskusi.
- [x] Indikator Total Komentar dinamis di bagian atas menu.

### 12. Micro-Animations & Polesan UI Premium
- [x] *Skeleton Loading* (kerangka bayangan abu-abu berdenyut) saat menunggu data laporan masuk.
- [x] Mode Gambar Layar Penuh (*Full-Screen Image View*) dengan transisi lompatan mulus (*Hero Animation*) dan fitur *Pinch-to-Zoom*.
- [x] *Cross-fade Transition* mulus saat berpindah antar tab navigasi bawah (*FadeIndexedStack*).
- [x] Efek Riak Air (*Ripple / InkWell*) pada kartu beranda sebagai umpan balik interaksi sentuhan.

---

## ⏳ FASE 2: Optimalisasi yang Sedang/Akan Dikerjakan

*(Kosong untuk saat ini, siap dieksekusi)*

---

## 🚀 FASE 3: Fitur Impian Jangka Panjang (*Future Backlog*)

1. **Geofencing Push Notifications:**
   Mengirimkan notifikasi HP berbunyi sirine apabila pengguna berjalan/mengemudi memasuki radius 500 meter dari titik banjir aktif yang dilaporkan orang lain.
2. **Filter Peta:**
   Opsi untuk menyaring peta (Tampilkan *Hanya Banjir Selutut*, atau *Hanya Laporan Hari Ini*).

---
*Dokumen ini diperbarui terakhir pada: 2 Juni 2026*
