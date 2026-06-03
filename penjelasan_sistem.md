# Penjelasan Sistem (Penting!)

## 1. Kenapa Vote-nya Berganti dan Tidak Bisa Pilih Keduanya?
Ini **bukan error / bug**, melainkan sistem validasi asli yang sengaja saya rancang seperti sistem *Upvote / Downvote* di Reddit atau YouTube. 
Satu akun (satu orang) **hanya boleh memiliki 1 suara** per laporan. Kamu tidak mungkin menyatakan *"Air masih banjir"* sekaligus *"Air sudah surut"* di waktu yang bersamaan, kan? 

Itulah mengapa sistem *database* kita menggunakan perintah `Upsert`. Jika sebelumnya kamu menekan "Masih Banjir", lalu kamu menekan "Sudah Surut", sistem akan otomatis mencabut suara lamamu dan menggantinya dengan yang terbaru. Ini untuk mencegah manipulasi data (agar satu orang tidak bisa spam banyak vote).

---

## 2. Kenapa Laporan Gagal Dihapus di Riwayat?
Tebakanmu tepat sekali! Secara bawaan (*default*), skema keamanan (*Row Level Security / RLS*) yang ada di database kita saat ini **belum mengizinkan** fitur penghapusan (DELETE). Karena izinnya belum ada di Supabase, maka database menolak perintah penghapusan dari aplikasinya (meskipun kamu sudah memencet tombol "Hapus").

Untuk memperbaikinya, kamu harus membuka **SQL Editor** di *dashboard* Supabase-mu, lalu jalankan satu kode singkat ini untuk membuka gembok izinnya:

```sql
create policy "Izinkan user menghapus laporan sendiri"
on public.flood_reports for delete
to authenticated
using (user_id = auth.uid());
```

Setelah kamu klik **RUN** pada kode tersebut di Supabase, tombol "Hapus" di aplikasimu akan langsung berfungsi dengan sempurna dan laporanmu benar-benar musnah dari Riwayat!

---

## 3. Kenapa Batal Vote (Tarik Suara) Gagal/Masih Ada?
Sama persis seperti masalah penghapusan riwayat di atas. Database Supabase secara bawaan (*default*) melindungi semua tabel dari penghapusan demi keamanan. 

Tabel penyimpanan dukungan (*vote*), yaitu `report_validations`, belum memiliki izin Hapus (DELETE). Sehingga saat aplikasi mencoba menghapus dukunganmu, database menolaknya diam-diam.

Silakan jalankan kembali kode SQL ini di **SQL Editor Supabase**-mu untuk mengaktifkan izin Tarik Suara:

```sql
create policy "Izinkan user menarik vote sendiri"
on public.report_validations for delete
to authenticated
using (user_id = auth.uid());
```

Setelah ini dijalankan, tombol *Undo* (Tarik Suara) di Beranda akan 100% berfungsi dan angka votenya akan turun kembali!

---

## 4. Cara Menghidupkan Sinkronisasi Live (Realtime Feed)
Agar Beranda (*Feed*) di aplikasi bisa diperbarui secara *live* tanpa pengguna harus menarik layar ke bawah (*pull-to-refresh*), database Supabase perlu diperintahkan untuk "menyiarkan" (*broadcast*) setiap perubahan data yang terjadi.

Secara bawaan (*default*), Supabase mematikan fitur siaran langsung ini demi menghemat kinerja *server*. Oleh karena itu, kita wajib menyalakannya secara manual untuk tabel `flood_reports` (agar postingan baru langsung muncul) dan `report_validations` (agar hasil *vote* dari orang lain bisa bergerak-gerak secara *live* di layar).

Silakan salin dan jalankan kode SQL ini di **SQL Editor Supabase**-mu untuk menghidupkan fitur *Realtime*:

```sql
-- Karena flood_reports sudah ada, kita cukup tambahkan report_validations saja:
alter publication supabase_realtime add table report_validations;
```

Setelah kamu sukses menjalankan kode SQL di atas, *Feed* aplikasi-mu sekarang menjadi sehidup dan semulus *Live Chat*. Jika kamu membuka aplikasinya di 2 HP yang berbeda, HP A memberikan *vote*, angka di HP B akan bertambah sendiri tanpa perlu disentuh!

---

## 5. Cara Menambahkan Dukungan "@Username" Ala Sosmed
Agar fitur pendaftaran dan profil bisa menggunakan *@username* yang keren layaknya media sosial, kita butuh sebuah kolom baru bernama `username` di dalam database Supabase.

Silakan salin dan jalankan kode SQL berikut ini di **SQL Editor Supabase**:

```sql
-- 1. Tambahkan kolom username ke tabel users
alter table public.users add column if not exists username text;

-- 2. Perbarui trigger agar otomatis menyalin username dari pendaftaran
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, full_name, avatar_url, username)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url',
    new.raw_user_meta_data ->> 'username'
  )
  on conflict (id) do update set 
    full_name = excluded.full_name,
    username = excluded.username;

  return new;
end;
$$;
```

Jika sukses, setiap orang yang membuat akun atau memperbarui profil, username-nya (contoh: `@budi`) akan langsung muncul di *Feed* laporan tepat di bawah nama aslinya!

---

## 6. Cara Menambahkan Tabel Komentar & Balasan (Threaded Chat)
Untuk mewujudkan fitur diskusi ala sosmed (lengkap dengan fitur balas-balasan komentar), kita perlu membuat tabel baru di Supabase.

Silakan salin dan jalankan kode SQL berikut ini di **SQL Editor Supabase**:

```sql
-- 1. Buat tabel komentar
create table public.report_comments (
  id uuid primary key default extensions.gen_random_uuid(),
  report_id uuid not null references public.flood_reports(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  parent_id uuid references public.report_comments(id) on delete cascade, -- Untuk fitur balasan
  content text not null,
  likes_user_ids uuid[] default '{}', -- Untuk menyimpan daftar ID user yang me-like
  created_at timestamptz not null default now()
);

-- 2. Buat indeks untuk mempercepat pencarian komentar berdasarkan laporan
create index report_comments_report_id_idx on public.report_comments(report_id);
create index report_comments_parent_id_idx on public.report_comments(parent_id);

-- 3. Aktifkan keamanan baris (RLS)
alter table public.report_comments enable row level security;

-- 4. Kebijakan (Policies)
-- Siapapun yang sudah login bisa melihat komentar
create policy "Comments are readable by everyone"
on public.report_comments for select
to authenticated
using (true);

-- Hanya pengguna yang login yang bisa menambahkan komentar
create policy "Users can insert comments"
on public.report_comments for insert
to authenticated
with check (user_id = auth.uid());

-- Izinkan pengguna memperbarui komentar mereka (untuk keperluan menambah likes atau menghapus)
create policy "Users can update comments"
on public.report_comments for update
to authenticated
using (true);

create policy "Users can delete own comments"
on public.report_comments for delete
to authenticated
using (user_id = auth.uid());

-- 5. Fungsi Pintar untuk Mengurus Like (Bisa ditambah/dihapus secara otomatis)
create or replace function public.toggle_comment_like(p_comment_id uuid)
returns void as $$
declare
  v_uid uuid;
  v_likes uuid[];
begin
  v_uid := auth.uid();
  select likes_user_ids into v_likes from public.report_comments where id = p_comment_id;
  
  if v_uid = ANY(v_likes) then
    -- Jika sudah like, maka hapus like-nya
    update public.report_comments set likes_user_ids = array_remove(likes_user_ids, v_uid) where id = p_comment_id;
  else
    -- Jika belum, tambahkan like-nya
    update public.report_comments set likes_user_ids = array_append(likes_user_ids, v_uid) where id = p_comment_id;
  end if;
end;
$$ language plpgsql security definer;

-- 6. Aktifkan Realtime untuk tabel komentar agar terasa seperti Live Chat!
alter publication supabase_realtime add table public.report_comments;
```
