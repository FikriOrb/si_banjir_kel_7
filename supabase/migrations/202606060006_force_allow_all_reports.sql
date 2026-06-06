-- Bersihkan semua policy SELECT di tabel flood_reports agar tidak bentrok
DROP POLICY IF EXISTS "users can read all their own reports" ON public.flood_reports;
DROP POLICY IF EXISTS "active flood reports are readable" ON public.flood_reports;
DROP POLICY IF EXISTS "all flood reports are readable" ON public.flood_reports;
DROP POLICY IF EXISTS "semua laporan bisa dibaca" ON public.flood_reports;

-- Buat 1 policy utama yang absolut mengizinkan SEMUA laporan dibaca oleh SEMUA user yang login
CREATE POLICY "all flood reports are readable"
ON public.flood_reports FOR SELECT
TO authenticated
USING (true);
