-- Perbarui fungsi get_active_flood_reports agar mengembalikan report_type
DROP FUNCTION IF EXISTS public.get_active_flood_reports();

CREATE OR REPLACE FUNCTION public.get_active_flood_reports()
RETURNS TABLE (
  id uuid,
  user_id uuid,
  latitude double precision,
  longitude double precision,
  address text,
  depth_level public.water_depth_level,
  photo_url text,
  note text,
  upvote_count integer,
  downvote_count integer,
  expires_at timestamptz,
  created_at timestamptz,
  report_type text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  SELECT
    fr.id,
    fr.user_id,
    st_y(fr.location::geometry) AS latitude,
    st_x(fr.location::geometry) AS longitude,
    fr.address,
    fr.depth_level,
    fr.photo_url,
    fr.note,
    fr.upvote_count,
    fr.downvote_count,
    fr.expires_at,
    fr.created_at,
    fr.report_type
  FROM public.flood_reports fr
  WHERE fr.is_active = true
    AND fr.expires_at > now()
  ORDER BY fr.created_at DESC;
$$;

-- Perbarui fungsi get_flood_reports_within_radius agar mengembalikan report_type
DROP FUNCTION IF EXISTS public.get_flood_reports_within_radius(double precision, double precision, integer);

CREATE OR REPLACE FUNCTION public.get_flood_reports_within_radius(
  user_latitude double precision,
  user_longitude double precision,
  radius_meters integer DEFAULT 500
)
RETURNS TABLE (
  id uuid,
  latitude double precision,
  longitude double precision,
  depth_level public.water_depth_level,
  distance_meters double precision,
  expires_at timestamptz,
  report_type text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  SELECT
    fr.id,
    st_y(fr.location::geometry) AS latitude,
    st_x(fr.location::geometry) AS longitude,
    fr.depth_level,
    st_distance(
      fr.location,
      st_setsrid(st_makepoint(user_longitude, user_latitude), 4326)::geography
    ) AS distance_meters,
    fr.expires_at,
    fr.report_type
  FROM public.flood_reports fr
  WHERE fr.is_active = true
    AND fr.expires_at > now()
    AND st_dwithin(
      fr.location,
      st_setsrid(st_makepoint(user_longitude, user_latitude), 4326)::geography,
      radius_meters
    )
  ORDER BY distance_meters ASC;
$$;
