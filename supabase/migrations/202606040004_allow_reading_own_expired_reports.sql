-- Migrasi untuk mengizinkan pengguna membaca seluruh riwayat laporan mereka sendiri (termasuk yang sudah expired)

-- 1. Pastikan policy lama tetap ada (semua orang bisa membaca laporan aktif)
-- 2. Tambahkan policy baru agar pembuat laporan bisa membaca laporan mereka yang sudah expired

CREATE POLICY "users can read all their own reports"
ON public.flood_reports FOR SELECT
TO authenticated
USING (user_id = auth.uid());
