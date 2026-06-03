# Product Requirement Document (PRD)
## Nama Projek: Sistem Peringatan Banjir Berbasis Komunitas (Community-Based Flood Warning System)
### Fokus Utama: SDG 13 (Climate Action) & Keselamatan Publik (Proyek Akhir Akademik)
**Status Dokumen:** Final v3.0 (Comprehensive Version)  
**Tanggal:** 2026-06-02  
**Bahasa:** Bahasa Indonesia (High-Level / Profesional)

---

## 1. Ringkasan Eksekutif (Executive Summary)
Perubahan iklim global (SDG 13) memicu peningkatan frekuensi cuaca ekstrem dan genangan air di kawasan urban. Dokumen ini merinci kebutuhan produk untuk proyek akhir akademik berupa aplikasi mobile berbasis *crowdsourcing* yang berfungsi sebagai sistem peringatan dini banjir (*early warning system*). 

Aplikasi ini didesain sebagai utilitas publik yang sepenuhnya gratis, tanpa skema monetisasi, yang bertujuan untuk memetakan titik banjir secara mikro (hiper-lokal). Fokus uji coba (Pilot Project) dibatasi secara geografis di wilayah Kota Medan.

---

## 2. Latar Belakang & Pernyataan Masalah (Problem Statement)
Sistem ini dibangun untuk menjawab empat masalah utama di lapangan:
1. **Data Laporan Terlalu Makro:** Informasi resmi biasanya hanya mencakup area luas (misal: "Kecamatan X banjir"), padahal di lapangan, banjir sangat spesifik hanya di satu titik jalan.
2. **Kecepatan Informasi (Time Lag):** Petugas butuh waktu untuk meninjau lokasi, sementara air naik dalam hitungan menit yang membahayakan warga.
3. **Informasi Tidak Terpusat:** Warga berbagi info di grup WhatsApp atau media sosial secara acak, sehingga tidak terpetakan, sulit dikonfirmasi, dan cepat hilang tertimbun *chat* lain.
4. **Kebutaan Navigasi (Navigation Blindness):** Pengendara nekat menerobos genangan karena tidak tahu kedalaman air di rute depan, berujung pada kendaraan mogok.

---

## 3. Visi & Tujuan Produk (Product Vision & Objectives)

### 3.1 Visi Produk
Menjadi platform navigasi dan manajemen risiko banjir hiper-lokal yang digerakkan oleh komunitas untuk membangun resiliensi warga terhadap cuaca ekstrem.

### 3.2 Tujuan Strategis:
* **Meningkatkan Keselamatan Publik:** Memastikan warga dan pengendara tidak terjebak di area banjir yang membahayakan nyawa atau aset.
* **Efisiensi Mobilitas:** Membantu pengguna jalan menemukan rute alternatif secara *real-time*.
* **Demokratisasi Data:** Memberikan akses informasi banjir yang sama cepatnya untuk jalan protokol maupun gang sempit.
* **Lingkup Proyek Akhir:** Mengimplementasikan Sistem Informasi Geografis (GIS) dan pemrosesan kueri spasial *real-time* ke dalam sebuah produk fungsional.

---

## 4. Profil Pengguna (User Personas)
1. **Warga Pelapor (The Contributor):** Penduduk lokal di Medan yang ingin menginformasikan kondisi genangan di sekitar rumah/jalan mereka.
2. **Pengendara / Pekerja Jalanan (The Mobile User):** Pengemudi ojek online, kurir, atau mahasiswa yang butuh navigasi rute aman saat hujan deras turun.

---

## 5. Fitur Utama & Solusi (Core Features)

### A. Pra-Pemetaan Daerah Rawan (Public Voting System)
* **Tujuan:** Mengatasi masalah aplikasi kosong (*cold start*) sebelum musim hujan.
* **Mekanisme:** Warga dapat menominasikan dan memberikan *vote* pada ruas jalan/kawasan di Medan yang secara historis sering banjir. Area dengan *vote* tinggi akan mendapat markah "Zona Rawan" permanen di peta.

### B. Integrasi Peringatan Dini Cuaca (BMKG API)
* **Tujuan:** Tindakan preventif sebelum banjir terjadi.
* **Mekanisme:** Menarik data terbuka dari BMKG dan memberikan notifikasi prakiraan cuaca ekstrem (hujan lebat) ke pengguna di wilayah yang terdampak.

### C. Crowdsourcing Sebagai Sensor Utama
* **Tujuan:** Mengubah warga menjadi "sensor berjalan" untuk mendapatkan data hiper-lokal yang instan.
* **Mekanisme:** Pengguna melaporkan genangan dengan menyertakan: Titik GPS (otomatis), Kedalaman Air (Kode Warna: Hijau, Kuning, Oranye, Merah), dan Bukti Foto langsung dari kamera gawai (menghindari foto hoaks/lama).

### D. Sistem Verifikasi Bertingkat & Penyusutan Data (TTL)
* **Tujuan:** Menjaga kebersihan dan validitas data peta.
* **Mekanisme:** Laporan bisa di-*upvote* ("Masih Banjir") atau di-*downvote* ("Sudah Surut"). Laporan memiliki umur (*Time-to-Live*); jika melewati batas waktu tertentu (misal 4 jam) dan tidak ada konfirmasi "Masih Banjir", laporan otomatis terhapus dari peta aktif.

### E. Notifikasi Berbasis Lokasi (Geofencing Alert)
* **Tujuan:** Peringatan keselamatan proaktif tanpa pengguna harus selalu melihat layar.
* **Mekanisme:** Sistem melacak pergerakan pengguna di latar belakang (*background*). Jika pengguna memasuki radius 500 meter dari titik banjir, akan muncul *Push Notification*: *"Awas, Anda mendekati area banjir. Cari rute alternatif!"*

---

## 6. Persyaratan Teknis & Tech Stack
Sistem dirancang efisien dan relevan untuk lingkup akademis:
* **Backend & Database:** **Supabase**
  * Memanfaatkan **PostgreSQL**.
  * Memanfaatkan ekstensi **PostGIS** untuk menangani seluruh komputasi spasial (*geofencing*, radius jarak, klasterisasi peta) secara efisien di sisi basis data.
* **Layanan Pihak Ketiga (API):**
  * **Peta Digital:** Google Maps API atau Mapbox.
  * **Data Cuaca:** BMKG Open Data API.
* **Geofencing Scope:** Operasional sistem dan batasan peta dikunci menggunakan poligon wilayah Kota Medan.

---

## 7. Indikator Keberhasilan (Success Metrics)
1. **Keberhasilan Komputasi Spasial:** *Trigger geofencing* Supabase berfungsi akurat memberi notifikasi saat *device* masuk radius banjir.
2. **Kelancaran Siklus Data:** Alur *Create-Read-Update-Delete* (CRUD) laporan dan sistem *Voting* berjalan tanpa latensi berarti.
3. **Akurasi Integrasi Eksternal:** Data API BMKG berhasil di-*parsing* dan ditampilkan dengan format yang mudah dibaca oleh pengguna akhir.

---
*Dokumen PRD ini ditunjang oleh dokumen spesifikasi teknis lanjutan: ultimate_erd.md (Struktur Database) dan ultimate_dfd.md (Alur Data).*
