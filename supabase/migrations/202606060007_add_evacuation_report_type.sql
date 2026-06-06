-- Add report_type to flood_reports to support Evacuation Centers
ALTER TABLE public.flood_reports 
ADD COLUMN report_type text NOT NULL DEFAULT 'flood';

-- Add index on report_type for faster filtering if needed in the future
CREATE INDEX flood_reports_report_type_idx ON public.flood_reports (report_type);

-- Drop old RPC and recreate with p_report_type
DROP FUNCTION IF EXISTS public.create_flood_report(double precision, double precision, public.water_depth_level, text, text, text);

CREATE OR REPLACE FUNCTION public.create_flood_report(
  p_latitude double precision,
  p_longitude double precision,
  p_depth_level public.water_depth_level,
  p_photo_url text,
  p_address text default null,
  p_note text default null,
  p_report_type text default 'flood'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  inserted_id uuid;
BEGIN
  INSERT INTO public.flood_reports (
    user_id,
    location,
    depth_level,
    photo_url,
    address,
    note,
    report_type
  )
  VALUES (
    auth.uid(),
    st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography,
    p_depth_level,
    p_photo_url,
    p_address,
    p_note,
    p_report_type
  )
  RETURNING id INTO inserted_id;

  RETURN inserted_id;
END;
$$;
