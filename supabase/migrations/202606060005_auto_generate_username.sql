-- 1. Perbarui trigger agar otomatis mencari username unik untuk akun Google
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_username text;
  final_username text;
  counter integer := 1;
BEGIN
  -- Ambil username dari metadata
  base_username := new.raw_user_meta_data ->> 'username';
  
  -- Jika kosong (misal login via Google), buat default base username
  IF base_username IS NULL OR base_username = '' THEN
    base_username := '@warga';
  END IF;

  final_username := base_username;

  -- Looping untuk mencari username yang belum dipakai
  WHILE EXISTS (SELECT 1 FROM public.users WHERE username = final_username) LOOP
    final_username := base_username || '_' || floor(random() * 90000 + 10000)::text;
    counter := counter + 1;
    IF counter > 100 THEN
      final_username := base_username || '_' || md5(random()::text);
      EXIT;
    END IF;
  END LOOP;

  -- Update metadata user agar tersimpan di sesi aplikasi
  IF new.raw_user_meta_data ->> 'username' IS NULL THEN
    UPDATE auth.users 
    SET raw_user_meta_data = jsonb_set(
      coalesce(raw_user_meta_data, '{}'::jsonb), 
      '{username}', 
      to_jsonb(final_username)
    )
    WHERE id = new.id;
  END IF;

  INSERT INTO public.users (id, full_name, avatar_url, username)
  VALUES (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url',
    final_username
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN new;
END;
$$;

-- 2. Perbaiki pengguna lama yang username-nya masih KOSONG (NULL) akibat login Google terdahulu
DO $$
DECLARE
  r RECORD;
  final_username text;
  counter integer;
BEGIN
  FOR r IN SELECT id FROM public.users WHERE username IS NULL LOOP
    final_username := '@warga';
    counter := 1;
    
    WHILE EXISTS (SELECT 1 FROM public.users WHERE username = final_username) LOOP
      final_username := '@warga_' || floor(random() * 90000 + 10000)::text;
      counter := counter + 1;
      IF counter > 100 THEN
        final_username := '@warga_' || md5(random()::text);
        EXIT;
      END IF;
    END LOOP;
    
    -- Update di tabel public.users
    UPDATE public.users SET username = final_username WHERE id = r.id;
    
    -- Update di auth.users agar sinkron
    UPDATE auth.users 
    SET raw_user_meta_data = jsonb_set(
      coalesce(raw_user_meta_data, '{}'::jsonb), 
      '{username}', 
      to_jsonb(final_username)
    )
    WHERE id = r.id;
  END LOOP;
END $$;
