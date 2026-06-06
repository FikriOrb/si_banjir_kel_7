-- 1. Pastikan kolom username ada di tabel users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username text;

-- 2. Pastikan kolom username bersifat unik (tidak boleh ada yang sama)
-- Pertama hapus constraint jika sudah pernah ada, untuk mencegah error
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_username_key;
ALTER TABLE public.users ADD CONSTRAINT users_username_key UNIQUE (username);

-- 3. Perbarui fungsi trigger untuk memastikan saat user baru mendaftar (register), username-nya ikut disalin
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, full_name, avatar_url, username)
  VALUES (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url',
    new.raw_user_meta_data ->> 'username'
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN new;
END;
$$;
