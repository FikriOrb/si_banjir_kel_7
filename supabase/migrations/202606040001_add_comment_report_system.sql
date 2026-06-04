-- 1. Tambahkan kolom report_count dan is_active pada tabel report_comments
ALTER TABLE public.report_comments ADD COLUMN IF NOT EXISTS report_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.report_comments ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- 2. Buat tabel comment_reports untuk mencatat siapa yang mereport komentar apa (mencegah double report)
CREATE TABLE IF NOT EXISTS public.comment_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comment_id UUID NOT NULL REFERENCES public.report_comments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL DEFAULT 'Lainnya',
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(comment_id, user_id)
);

-- Menambahkan kolom jika tabel sudah terlanjur dibuat
ALTER TABLE public.comment_reports ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'Lainnya';
ALTER TABLE public.comment_reports ADD COLUMN IF NOT EXISTS note TEXT;

-- Atur Row Level Security (RLS) untuk comment_reports
ALTER TABLE public.comment_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna bisa melihat laporannya sendiri" 
ON public.comment_reports FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Pengguna bisa menambahkan laporan" 
ON public.comment_reports FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 3. Buat fungsi RPC untuk melaporkan komentar
CREATE OR REPLACE FUNCTION public.report_comment(p_comment_id UUID, p_category TEXT, p_note TEXT DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Cek apakah user sudah pernah melaporkan komentar ini (Mencegah spam laporan)
    IF EXISTS (
        SELECT 1 FROM public.comment_reports
        WHERE comment_id = p_comment_id AND user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Anda sudah pernah melaporkan komentar ini.';
    END IF;

    -- Masukkan data laporan
    INSERT INTO public.comment_reports (comment_id, user_id, category, note)
    VALUES (p_comment_id, auth.uid(), p_category, p_note);

    -- Tambahkan report_count di tabel report_comments
    UPDATE public.report_comments
    SET report_count = report_count + 1
    WHERE id = p_comment_id;
END;
$$;

-- 4. Buat trigger untuk memberikan sanksi (violation/ban) jika report_count >= 5
CREATE OR REPLACE FUNCTION public.check_comment_violations()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Jika report_count baru saja mencapai 5
    IF NEW.report_count >= 5 AND OLD.report_count < 5 THEN
        -- Nonaktifkan (sembunyikan) komentar
        NEW.is_active = false;
        
        -- Cek apakah user INI sudah pernah mendapat peringatan di Postingan INI.
        -- Berlaku aturan: 1 User di 1 Postingan diskusi = Maksimal 1 Peringatan.
        IF NOT EXISTS (
            -- Cek apakah ada komentar lain dari user yang sama di post ini yang sudah di-banned
            SELECT 1 FROM public.report_comments 
            WHERE report_id = NEW.report_id 
              AND user_id = NEW.user_id 
              AND id != NEW.id 
              AND report_count >= 5
        ) AND NOT EXISTS (
            -- Cek apakah post ini sendiri adalah milik user yang sama dan sudah di-downvote/banned
            SELECT 1 FROM public.flood_reports
            WHERE id = NEW.report_id
              AND user_id = NEW.user_id
              AND downvote_count >= 5
        ) THEN
            -- Tambahkan violation_count ke pembuat komentar
            UPDATE public.users
            SET violation_count = violation_count + 1,
                is_banned = CASE WHEN violation_count + 1 >= 3 THEN true ELSE is_banned END
            WHERE id = NEW.user_id;
        END IF;
    END IF;
    
    -- Instant ban jika direport oleh 50 orang (Sangat Parah)
    IF NEW.report_count >= 50 AND OLD.report_count < 50 THEN
        UPDATE public.users SET is_banned = true WHERE id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_comment_violations ON public.report_comments;
CREATE TRIGGER enforce_comment_violations
BEFORE UPDATE OF report_count ON public.report_comments
FOR EACH ROW EXECUTE FUNCTION public.check_comment_violations();

-- 5. Perbarui fungsi laporan postingan (agar mendukung Instant Ban di 50 laporan)
CREATE OR REPLACE FUNCTION public.check_report_violations()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if downvote_count reached 5 for the first time
  if new.downvote_count >= 5 and old.downvote_count < 5 then
    -- Deactivate the report
    new.is_active = false;
    
    -- Increment violation count and check if banned
    update public.users
    set violation_count = violation_count + 1,
        is_banned = case when violation_count + 1 >= 3 then true else is_banned end
    where id = new.user_id;
  end if;

  -- Instant ban jika direport oleh 50 orang (Sangat Parah)
  if new.downvote_count >= 50 and old.downvote_count < 50 then
      update public.users set is_banned = true where id = new.user_id;
  end if;

  return new;
end;
$$;
