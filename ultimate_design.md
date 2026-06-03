# UI/UX Design Guidelines & References
## Nama Projek: Sistem Peringatan Banjir Berbasis Komunitas
**Status Dokumen:** Draft v1.0  
**Fokus:** Mobile-First, Emergency-Friendly, Map-Centric

---

## 1. Filosofi Desain (Design Philosophy)
Karena aplikasi ini digunakan dalam kondisi potensial darurat (sedang hujan, di jalan, buru-buru), desain harus mematuhi prinsip:
* **One-Thumb Navigation:** Tombol aksi utama (seperti "Lapor Banjir") harus mudah dijangkau oleh ibu jari saat menggunakan ponsel dengan satu tangan.
* **High Contrast & Glare-Friendly:** Mengingat pengguna mungkin melihat layar di bawah rintik hujan atau cahaya luar ruangan, kontras antara teks dan *background* harus tinggi.
* **Map-Centric:** Peta adalah bintang utamanya. Elemen UI lain tidak boleh menutupi visibilitas peta terlalu banyak.

---

## 2. Referensi Aplikasi (UI/UX Inspirations)
Cari aplikasi berikut di internet/Pinterest/Mobbin untuk melihat struktur UI mereka:

### A. Waze (Referensi Utama untuk Crowdsourcing & Peta)
* **Yang ditiru:** 
  * Tombol *Floating Action Button* (FAB) bulat besar di sudut kanan bawah untuk melaporkan insiden.
  * Tampilan ikon peringatan di atas peta yang sangat jelas.
  * *Pop-up* konfirmasi (Upvote/Downvote) yang cepat (misal: "Masih ada genangan? Ya / Tidak").

### B. Grab / Gojek (Referensi untuk Bottom Sheet & Clean UI)
* **Yang ditiru:**
  * Penggunaan *Bottom Sheet* (panel yang muncul dari bawah layar). Alih-alih memindahkan pengguna ke halaman baru saat mau melapor banjir, gunakan *bottom sheet* agar mereka tetap bisa melihat peta di latar belakang.
  * Desain input lokasi yang intuitif.

### C. Qlue / JAKI (Referensi untuk Pelaporan Warga)
* **Yang ditiru:**
  * Alur (*flow*) pengambilan foto bukti dan pemilihan kategori laporan (ketinggian air) yang *straightforward*.
  * Tampilan *feed* atau daftar laporan terdekat berbasis jarak.

---

## 3. Komponen Layar Utama (Key Screens)

### 1. Splash Screen & Login/Register
* Tampilan bersih dengan logo aplikasi.
* Opsi *login* cepat (SSO Google) agar warga tidak repot mengisi form panjang.

### 2. Main Map View (Beranda)
* **Background:** Peta *fullscreen* (Google Maps/Mapbox style) dengan *Dark Mode* otomatis jika malam hari.
* **Header:** Kolom pencarian lokasi dan *chip* peringatan dini cuaca dari BMKG.
* **Content:** Titik-titik (Pin) banjir aktif dengan kode warna (Kuning, Oranye, Merah). Pin area rawan (hasil *voting*).
* **Action:** Tombol Lapor (FAB) besar dengan ikon "+ Lapor" di kanan bawah.

### 3. Report Bottom Sheet (Halaman Pelaporan)
Muncul dari bawah saat tombol Lapor ditekan.
* **Step 1:** Kamera langsung terbuka (di dalam kotak kecil) untuk ambil foto.
* **Step 2:** Pilihan *slider* atau *chip buttons* untuk Tinggi Air (Mata Kaki, Betis, Lutut, Pinggang).
* **Step 3:** Tombol "Kirim Laporan".

### 4. Voting & Area Rawan (List/Tab View)
* Halaman sekunder berupa daftar (List) jalan-jalan di Medan yang masuk nominasi rawan banjir.
* Dilengkapi *progress bar* jumlah *vote* dan tombol "Dukung Area Ini".

---

## 4. Sistem Warna (Color Palette)
* **Primary Color (Aksi Utama):** Biru Kelam (Navy Blue) atau Biru Terang (Electric Blue) melambangkan air dan teknologi.
* **Semantic Colors (Indikator Peta):**
  * 🟢 **Hijau (Aman):** #28A745
  * 🟡 **Kuning (Genangan Rendah):** #FFC107
  * 🟠 **Oranye (Banjir Sedang):** #FD7E14
  * 🔴 **Merah (Banjir Bahaya):** #DC3545
* **Background:** Terang (Putih/Abu sangat muda) untuk siang, Gelap (Deep Grey) untuk malam.
