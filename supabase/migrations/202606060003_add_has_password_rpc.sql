CREATE OR REPLACE FUNCTION public.has_password()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE id = auth.uid() 
    AND encrypted_password IS NOT NULL
  );
END;
$$;
