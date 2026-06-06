-- Migrasi untuk mengizinkan pengguna membaca seluruh laporan (aktif dan tidak aktif) untuk statistik
DROP POLICY IF EXISTS "users can read all their own reports" ON public.flood_reports;
DROP POLICY IF EXISTS "active flood reports are readable" ON public.flood_reports;

CREATE POLICY "all flood reports are readable"
ON public.flood_reports FOR SELECT
TO authenticated
USING (true);
