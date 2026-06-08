# Ringkasan Umum: Aplikasi SiBanjir

**SiBanjir (Sistem Peringatan Banjir Berbasis Komunitas)** adalah aplikasi gotong royong digital (*crowdsourcing*) yang dirancang untuk warga Kota Medan. Aplikasi ini bertujuan membantu masyarakat saling menginformasikan lokasi banjir, mencari tempat evakuasi terdekat, serta memberikan sinyal bahaya jika ada warga yang terjebak di sekitar lokasi rawan.

---

## 🌟 Fungsi & Tujuan Utama
1. **Berbagi Informasi Real-time**: Siapa pun yang melihat banjir dapat memfoto dan membagikannya ke aplikasi. Info tersebut langsung muncul di peta seluruh warga.
2. **Menghindari Hoaks**: Laporan yang tidak benar bisa diberi jempol ke bawah (*Downvote*) oleh warga lain. Jika downvote banyak, sistem otomatis memblokir pembuat laporan tersebut.
3. **Penyelamat Nyawa Darurat**: Menjauhkan warga dari lokasi berbahaya dengan mengirimkan notifikasi bunyi sirine jika mereka tanpa sengaja berjalan mendekati zona genangan banjir.

---

## 📱 Fitur-Fitur Unggulan

1. **Masuk Pakai Google (1-Klik)**
   Memudahkan warga mendaftar tanpa perlu repot mengetik email dan kata sandi panjang.

2. **Peta Interaktif (Live Map)**
   Layar utama yang langsung menampilkan Peta Google berisi dua jenis ikon:
   - 🔴 Peringatan titik banjir (dilengkapi info kedalaman air).
   - 🟡 Posko evakuasi darurat.

3. **Lapor Banjir Semudah Chatting**
   Untuk melaporkan banjir, pengguna hanya perlu menekan tombol Lapor. Aplikasi otomatis melacak koordinat GPS mereka, meminta foto bukti, dan menyediakan pilihan *template* teks instan (seperti "Akses jalan terputus").

4. **Feed (Linimasa Laporan)**
   Halaman beranda bergaya seperti media sosial yang berisi urutan laporan terbaru dari seluruh Medan. Warga bisa saling mengomentari kondisi air secara langsung (misal: "Air sudah mulai surut, aman dilewati").

5. **Geofencing & Radar Alarm**
   Jika pengguna berada terlalu dekat (radius 500 meter) dari titik banjir baru, HP pengguna akan memunculkan peringatan pop-up merah dan membunyikan alarm keras.

6. **Statistik & Edukasi**
   Menyediakan grafik sejarah curah hujan, nomor penting (Tim SAR, BPBD), dan panduan hal apa yang harus dilakukan saat evakuasi.

---

## 🎨 Tampilan (Desain Aplikasi)
Aplikasi didesain bukan bergaya "formal dan kaku" layaknya aplikasi pemerintah pada umumnya, melainkan bergaya modern dan *elegant*:
- Menggunakan warna dominan **Biru Kelam** yang nyaman di mata, dengan elemen bayangan lembut bergaya *Glassmorphism* (kaca transparan).
- Pengalaman berpindah menu yang mulus: Saat membuka laporan atau menulis komentar, layar tidak berpindah kaku, melainkan menggunakan lembar pop-up dari bawah layar (*Bottom Sheet*).

---

## ⚙️ Teknologi yang Menghidupkan Aplikasi
- **Flutter**: Basis utama pembuat aplikasi (untuk Android & iOS).
- **Supabase**: Server data canggih di awan (Database & Real-time Server).
- **Google Maps**: Penyedia peta digital utama.
- **Firebase / FCM**: Pengirim pesan *Push Notifikasi* secara instan ke HP pengguna walau aplikasi sedang tertutup.
