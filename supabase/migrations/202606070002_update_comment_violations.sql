-- Perbarui fungsi pelanggaran komentar agar sinkron penuh dengan sistem laporan postingan yang baru
CREATE OR REPLACE FUNCTION public.check_comment_violations()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Jika report_count pada obrolan/komentar baru saja mencapai 5
    IF NEW.report_count >= 5 AND OLD.report_count < 5 THEN
        -- Nonaktifkan (sembunyikan/hapus otomatis) komentar saja (TIDAK berpengaruh ke postingan)
        NEW.is_active = false;
        
        -- Tambahkan violation_count ke pembuat komentar (sinkron dengan sistem peringatan postingan)
        UPDATE public.users
        SET violation_count = violation_count + 1,
            is_banned = CASE WHEN violation_count + 1 >= 3 THEN true ELSE is_banned END
        WHERE id = NEW.user_id;
    END IF;
    
    -- Instant ban jika obrolan direport oleh 50 orang (Sangat Parah)
    IF NEW.report_count >= 50 AND OLD.report_count < 50 THEN
        UPDATE public.users SET is_banned = true WHERE id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$;
