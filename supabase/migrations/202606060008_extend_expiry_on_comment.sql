-- Trigger untuk menambah waktu aktif 4 jam ketika ada komentar baru
CREATE OR REPLACE FUNCTION public.extend_report_expiry_on_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update waktu kedaluwarsa laporan ke 4 jam dari sekarang
  -- greatest() memastikan kita hanya menambah waktu jika waktunya lebih lama
  UPDATE public.flood_reports
  SET 
    expires_at = greatest(expires_at, now() + interval '4 hours'),
    is_active = true,
    updated_at = now()
  WHERE id = NEW.report_id;

  RETURN NEW;
END;
$$;

-- Hapus trigger jika sudah ada sebelumnya, lalu buat baru
DROP TRIGGER IF EXISTS on_comment_extend_expiry ON public.report_comments;

CREATE TRIGGER on_comment_extend_expiry
AFTER INSERT ON public.report_comments
FOR EACH ROW EXECUTE FUNCTION public.extend_report_expiry_on_comment();
