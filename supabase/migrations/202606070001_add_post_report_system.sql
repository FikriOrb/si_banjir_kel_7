-- 1. Tambahkan kolom report_count dan is_blocked pada tabel flood_reports
ALTER TABLE public.flood_reports ADD COLUMN IF NOT EXISTS report_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.flood_reports ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN NOT NULL DEFAULT false;

-- 2. Buat tabel post_reports untuk mencatat siapa yang mereport postingan apa (mencegah double report)
CREATE TABLE IF NOT EXISTS public.post_reports (
    id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.flood_reports(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL DEFAULT 'Lainnya',
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(report_id, user_id)
);

-- Atur Row Level Security (RLS) untuk post_reports
ALTER TABLE public.post_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna bisa melihat laporan postnya sendiri" 
ON public.post_reports FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Pengguna bisa menambahkan laporan post" 
ON public.post_reports FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 3. Buat fungsi RPC untuk melaporkan postingan
CREATE OR REPLACE FUNCTION public.report_post(p_report_id UUID, p_category TEXT, p_note TEXT DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Cek apakah user sudah pernah melaporkan postingan ini (Mencegah spam laporan)
    IF EXISTS (
        SELECT 1 FROM public.post_reports
        WHERE report_id = p_report_id AND user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Anda sudah pernah melaporkan postingan ini.';
    END IF;

    -- Masukkan data laporan
    INSERT INTO public.post_reports (report_id, user_id, category, note)
    VALUES (p_report_id, auth.uid(), p_category, p_note);

    -- Tambahkan report_count di tabel flood_reports
    UPDATE public.flood_reports
    SET report_count = report_count + 1
    WHERE id = p_report_id;
END;
$$;

-- 4. Perbarui fungsi laporan postingan agar bergantung pada report_count, bukan downvote_count
CREATE OR REPLACE FUNCTION public.check_report_violations()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if report_count reached 5 for the first time
  if new.report_count >= 5 and old.report_count < 5 then
    -- Deactivate and block the report
    new.is_active = false;
    new.is_blocked = true;
    
    -- Increment violation count and check if banned
    update public.users
    set violation_count = violation_count + 1,
        is_banned = case when violation_count + 1 >= 3 then true else is_banned end
    where id = new.user_id;
  end if;

  -- Instant ban jika direport oleh 50 orang (Sangat Parah)
  if new.report_count >= 50 and old.report_count < 50 then
      update public.users set is_banned = true where id = new.user_id;
  end if;

  return new;
end;
$$;

-- Pastikan trigger sudah terpasang pada report_count (jika belum, buat ulang pada flood_reports)
DROP TRIGGER IF EXISTS enforce_report_violations ON public.flood_reports;
CREATE TRIGGER enforce_report_violations
BEFORE UPDATE OF report_count ON public.flood_reports
FOR EACH ROW EXECUTE FUNCTION public.check_report_violations();
