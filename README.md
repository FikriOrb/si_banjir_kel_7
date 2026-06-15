# 🌊 Si Banjir (Sistem Peringatan Banjir Berbasis Komunitas)

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)

**Aplikasi *mobile* gotong royong digital (*crowdsourcing*) untuk warga Kota Medan guna saling membagikan informasi rute banjir secara *real-time* dan memberikan peringatan dini (*Geofencing Alarm*) saat mendekati zona bahaya.**

---

## 👥 Disusun Oleh: Kelompok 7
* Melati Simanungkalit (241712008)
* Maulia Revani Putri (241712009)
* Fathi Fadhil (241712019)
* Kabul Manik (241712023)
* M. Fikri Ramadhan Sembiring (241712027)
* Wiliam Tanu Wijaya (241712036)

---

## 📖 Ringkasan Eksekutif
Warga seringkali terjebak genangan banjir saat bepergian karena kurangnya informasi rute yang tergenang. Selain itu, banyaknya hoaks tentang banjir membuat masyarakat sulit mendapatkan data yang akurat. 

**Si Banjir** hadir memecahkan masalah ini dengan sistem pelaporan berbasis **komunitas** (dilengkapi verifikasi Anti-Hoaks *Upvote/Downvote*) dan **Geofencing Alarm** yang akan memicu sirine keras di HP jika pengguna berjarak <500 meter dari pusat banjir.

## 🌍 Target Sustainable Development Goals (SDGs)
Aplikasi ini secara langsung mendukung agenda Pembangunan Berkelanjutan (SDGs) PBB:
* **SDG 13: Climate Action** (Ketangguhan, adaptasi bencana iklim, dan edukasi peringatan dini).
* **SDG 11: Sustainable Cities** (Mengurangi secara signifikan jumlah orang yang terkena dampak bencana di perkotaan).

## ✨ Fitur Utama (Core MVP)
1. **Live Map:** Peta interaktif berisi pin titik lokasi banjir (merah) dan posko evakuasi (kuning).
2. **Lapor Cepat:** Formulir pintar berbekal koordinat GPS dan kamera untuk melaporkan genangan seketika.
3. **Feed Komunitas:** Linimasa sosial tempat warga berdiskusi kondisi terkini secara langsung.
4. **Emergency Geofencing:** Radar latar belakang yang terus memantau jarak pengguna dari titik banjir dan memberikan peringatan darurat.
5. **Autentikasi Mudah:** Masuk instan menggunakan *1-Click Google Sign-In*.
6. **Pusat Edukasi:** Nomor kontak darurat (Tim SAR/BPBD) dan panduan antisipasi banjir.

## 🛠️ Gambaran Teknis (Tech Stack)
* **Frontend:** Flutter & Dart (Cross-platform Android & iOS)
* **Backend:** Supabase (BaaS)
* **Database:** PostgreSQL (dengan ekstensi PostGIS untuk komputasi jarak spasial)
* **Realtime:** Supabase Realtime Websockets
* **Notifikasi:** Firebase Cloud Messaging (FCM) & Local Notifications
* **Peta:** Google Maps SDK

## 🚀 Panduan Menjalankan Proyek (Getting Started)

### Persyaratan Sistem
* Flutter SDK (Versi terbaru yang stabil)
* Akun Supabase (untuk menyiapkan *database* dan penyimpanan)
* Kunci API Google Maps

### 1. Kloning Repositori
```bash
git clone https://github.com/FikriOrb/si_banjir_kel_7.git
cd si_banjir_kel_7
```

### 2. Instalasi Dependensi
```bash
flutter pub get
```

### 3. Migrasi Database Supabase
Pastikan Anda sudah *login* ke CLI Supabase, lalu jalankan migrasi tabel ke *project* Supabase Anda:
```bash
supabase db push
```
*Catatan: Buat juga sebuah storage bucket bernama `report-photos` (publik) di Supabase.*

### 4. Menjalankan Aplikasi
Jalankan aplikasi dengan menyertakan *Environment Variables* untuk Supabase:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<PROJECT_REF>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<YOUR_SUPABASE_ANON_KEY>
```

*(Untuk Android, pastikan sudah menambahkan Kunci API Google Maps di `android/app/src/main/AndroidManifest.xml`)*

---
**Dibuat dengan ❤️ untuk Kota Medan oleh Kelompok 7.**
