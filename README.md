# Sistem Peringatan Banjir Berbasis Komunitas

Prototipe Flutter + Supabase untuk pilot project Kota Medan. Implementasi ini mengeksekusi instruksi pada `ultimate_prompt.md`: skema Supabase/PostGIS, struktur Flutter feature-first, peta real-time, report bottom sheet, geofencing 500 meter, dan parsing peringatan BMKG.

## Artefak Utama

- `supabase/migrations/202606020001_initial_schema.sql`: tabel `users`, `flood_reports`, `report_validations`, `flood_prone_areas`, indeks PostGIS, trigger validasi vote, fungsi TTL, RPC `get_active_flood_reports`, RPC `get_flood_reports_within_radius`, dan RPC `create_flood_report`.
- `lib/main.dart`: inisialisasi Flutter, Supabase, dan local notification.
- `lib/features/map/data/repositories/flood_report_repository.dart`: stream realtime Supabase dengan refetch RPC agar koordinat PostGIS tersedia sebagai latitude/longitude.
- `lib/features/map/domain/services/geofencing_service.dart`: pemantauan lokasi dan pemicu notifikasi saat masuk radius 500 meter dari laporan aktif.
- `lib/features/report/presentation/widgets/report_bottom_sheet.dart`: bottom sheet pelaporan dengan kamera langsung dan pilihan kedalaman air.
- `lib/features/weather/data/services/bmkg_weather_service.dart`: client RSS/CAP XML BMKG untuk peringatan dini nowcast cakupan Kota Medan.

## Struktur `lib/`

```text
lib/
  app.dart
  main.dart
  core/
    config/env.dart
    notifications/local_notification_service.dart
    theme/app_theme.dart
  features/
    map/
      data/models/flood_report.dart
      data/repositories/flood_report_repository.dart
      domain/services/geofencing_service.dart
      presentation/pages/main_map_page.dart
    report/
      data/repositories/report_submission_repository.dart
      presentation/widgets/report_bottom_sheet.dart
    weather/
      data/models/bmkg_weather_warning.dart
      data/services/bmkg_weather_service.dart
```

## Menjalankan Flutter

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Untuk Android, tambahkan Google Maps API key di `android/app/src/main/AndroidManifest.xml`. Untuk iOS, tambahkan konfigurasi Google Maps di `AppDelegate` sesuai dokumentasi `google_maps_flutter`.

## Menjalankan Migrasi Supabase

```bash
supabase db push
```

TTL empat jam membutuhkan scheduler karena database trigger tidak dapat mengeksekusi dirinya sendiri tepat saat waktu kedaluwarsa lewat. Di Supabase, jadwalkan fungsi berikut setiap beberapa menit melalui Supabase Cron atau Edge Function terjadwal:

```sql
select public.expire_stale_flood_reports();
```

Storage bucket yang dibutuhkan:

```text
report-photos
```

Gunakan public bucket untuk prototipe akademik, atau private bucket dengan signed URL jika ingin kontrol akses lebih ketat.

## Catatan Implementasi

- State management memakai Riverpod karena ringan, mudah diuji, dan cukup jelas untuk proyek akhir akademik.
- Koordinat disimpan sebagai `geography(Point, 4326)` agar `ST_DWithin` dan `ST_Distance` memakai meter.
- Realtime Supabase dipakai sebagai sinyal perubahan tabel, lalu aplikasi memanggil RPC `get_active_flood_reports()` supaya field PostGIS dikembalikan sebagai `latitude` dan `longitude`.
- Background location penuh di Android/iOS produksi biasanya membutuhkan konfigurasi permission tambahan dan penjelasan penggunaan lokasi di manifest/plist.
- Service BMKG memakai feed nowcast `https://www.bmkg.go.id/alerts/nowcast/id` dan detail CAP XML karena dokumen resmi BMKG menempatkan peringatan dini cuaca pada format XML CAP hingga level kecamatan.
