-- Supabase migration: Restrict Banned Users
-- Target: PostgreSQL

SET search_path = public, extensions;

CREATE OR REPLACE FUNCTION public.check_user_not_banned()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_banned boolean;
  v_user_id uuid;
BEGIN
  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    IF TG_TABLE_NAME = 'flood_prone_areas' THEN
      v_user_id := NEW.created_by;
    ELSE
      v_user_id := NEW.user_id;
    END IF;

  SELECT is_banned INTO v_is_banned
  FROM public.users
  WHERE id = v_user_id;

  IF v_is_banned THEN
    RAISE EXCEPTION 'Akun Anda telah diblokir. Anda tidak dapat melakukan tindakan ini.';
  END IF;

  END IF;

  RETURN NEW;
END;
$$;

-- Apply trigger to flood_reports
DROP TRIGGER IF EXISTS trg_check_banned_flood_reports ON public.flood_reports;
CREATE TRIGGER trg_check_banned_flood_reports
  BEFORE INSERT OR UPDATE ON public.flood_reports
  FOR EACH ROW
  EXECUTE FUNCTION public.check_user_not_banned();

-- Apply trigger to report_comments
DROP TRIGGER IF EXISTS trg_check_banned_report_comments ON public.report_comments;
CREATE TRIGGER trg_check_banned_report_comments
  BEFORE INSERT OR UPDATE ON public.report_comments
  FOR EACH ROW
  EXECUTE FUNCTION public.check_user_not_banned();

-- Apply trigger to post_reports
DROP TRIGGER IF EXISTS trg_check_banned_post_reports ON public.post_reports;
CREATE TRIGGER trg_check_banned_post_reports
  BEFORE INSERT OR UPDATE ON public.post_reports
  FOR EACH ROW
  EXECUTE FUNCTION public.check_user_not_banned();

-- Apply trigger to comment_reports
DROP TRIGGER IF EXISTS trg_check_banned_comment_reports ON public.comment_reports;
CREATE TRIGGER trg_check_banned_comment_reports
  BEFORE INSERT OR UPDATE ON public.comment_reports
  FOR EACH ROW
  EXECUTE FUNCTION public.check_user_not_banned();

-- Apply trigger to report_validations
DROP TRIGGER IF EXISTS trg_check_banned_report_validations ON public.report_validations;
CREATE TRIGGER trg_check_banned_report_validations
  BEFORE INSERT OR UPDATE ON public.report_validations
  FOR EACH ROW
  EXECUTE FUNCTION public.check_user_not_banned();

-- Apply trigger to flood_prone_areas
DROP TRIGGER IF EXISTS trg_check_banned_flood_prone_areas ON public.flood_prone_areas;
CREATE TRIGGER trg_check_banned_flood_prone_areas
  BEFORE INSERT OR UPDATE ON public.flood_prone_areas
  FOR EACH ROW
  EXECUTE FUNCTION public.check_user_not_banned();

-- Apply trigger to flood_prone_area_votes
DROP TRIGGER IF EXISTS trg_check_banned_flood_prone_area_votes ON public.flood_prone_area_votes;
CREATE TRIGGER trg_check_banned_flood_prone_area_votes
  BEFORE INSERT OR UPDATE ON public.flood_prone_area_votes
  FOR EACH ROW
  EXECUTE FUNCTION public.check_user_not_banned();
