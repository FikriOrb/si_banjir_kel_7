-- Supabase migration: Community-Based Flood Warning System
-- Target: PostgreSQL + PostGIS

create extension if not exists postgis with schema extensions;
create extension if not exists pgcrypto with schema extensions;

set search_path = public, extensions;

create type public.water_depth_level as enum (
  'ankle',
  'calf',
  'knee',
  'waist'
);

create type public.report_vote_type as enum (
  'upvote',
  'downvote'
);

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  avatar_url text,
  phone_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.flood_reports (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  location geography(Point, 4326) not null,
  address text,
  depth_level public.water_depth_level not null,
  photo_url text not null,
  note text,
  upvote_count integer not null default 0 check (upvote_count >= 0),
  downvote_count integer not null default 0 check (downvote_count >= 0),
  is_active boolean not null default true,
  expires_at timestamptz not null default now() + interval '4 hours',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.report_validations (
  id uuid primary key default extensions.gen_random_uuid(),
  report_id uuid not null references public.flood_reports(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  vote_type public.report_vote_type not null,
  created_at timestamptz not null default now(),
  unique (report_id, user_id)
);

create table public.flood_prone_areas (
  id uuid primary key default extensions.gen_random_uuid(),
  created_by uuid references public.users(id) on delete set null,
  name text not null,
  description text,
  area geography(Polygon, 4326) not null,
  vote_count integer not null default 0 check (vote_count >= 0),
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.flood_prone_area_votes (
  id uuid primary key default extensions.gen_random_uuid(),
  area_id uuid not null references public.flood_prone_areas(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (area_id, user_id)
);

create index flood_reports_location_gix
  on public.flood_reports using gist (location);

create index flood_reports_active_location_gix
  on public.flood_reports using gist (location)
  where is_active = true;

create index flood_reports_active_expires_idx
  on public.flood_reports (is_active, expires_at);

create index flood_prone_areas_area_gix
  on public.flood_prone_areas using gist (area);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger users_touch_updated_at
before update on public.users
for each row execute function public.touch_updated_at();

create trigger flood_reports_touch_updated_at
before update on public.flood_reports
for each row execute function public.touch_updated_at();

create trigger flood_prone_areas_touch_updated_at
before update on public.flood_prone_areas
for each row execute function public.touch_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, full_name, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger auth_users_create_public_profile
after insert on auth.users
for each row execute function public.handle_new_auth_user();

create or replace function public.set_flood_report_expiry()
returns trigger
language plpgsql
as $$
begin
  if new.expires_at is null then
    new.expires_at = now() + interval '4 hours';
  end if;

  if new.expires_at <= now() then
    new.is_active = false;
  end if;

  return new;
end;
$$;

create trigger flood_reports_set_expiry
before insert or update on public.flood_reports
for each row execute function public.set_flood_report_expiry();

create or replace function public.expire_stale_flood_reports()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  affected_rows integer;
begin
  update public.flood_reports
  set is_active = false,
      updated_at = now()
  where is_active = true
    and expires_at <= now();

  get diagnostics affected_rows = row_count;
  return affected_rows;
end;
$$;

create or replace function public.refresh_report_validation_counts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_report_id uuid;
begin
  target_report_id = coalesce(new.report_id, old.report_id);

  update public.flood_reports fr
  set upvote_count = (
        select count(*)::integer
        from public.report_validations rv
        where rv.report_id = target_report_id
          and rv.vote_type = 'upvote'
      ),
      downvote_count = (
        select count(*)::integer
        from public.report_validations rv
        where rv.report_id = target_report_id
          and rv.vote_type = 'downvote'
      ),
      expires_at = case
        when exists (
          select 1
          from public.report_validations rv
          where rv.report_id = target_report_id
            and rv.vote_type = 'upvote'
            and rv.created_at >= now() - interval '4 hours'
        )
        then greatest(fr.expires_at, now() + interval '4 hours')
        else fr.expires_at
      end,
      is_active = case
        when fr.expires_at <= now() then false
        else fr.is_active
      end,
      updated_at = now()
  where fr.id = target_report_id;

  return coalesce(new, old);
end;
$$;

create trigger report_validations_refresh_counts
after insert or update or delete on public.report_validations
for each row execute function public.refresh_report_validation_counts();

create or replace function public.refresh_flood_prone_area_votes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_area_id uuid;
begin
  target_area_id = coalesce(new.area_id, old.area_id);

  update public.flood_prone_areas fpa
  set vote_count = (
        select count(*)::integer
        from public.flood_prone_area_votes fpav
        where fpav.area_id = target_area_id
      ),
      updated_at = now()
  where fpa.id = target_area_id;

  return coalesce(new, old);
end;
$$;

create trigger flood_prone_area_votes_refresh_counts
after insert or delete on public.flood_prone_area_votes
for each row execute function public.refresh_flood_prone_area_votes();

create or replace function public.get_active_flood_reports()
returns table (
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
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select
    fr.id,
    fr.user_id,
    st_y(fr.location::geometry) as latitude,
    st_x(fr.location::geometry) as longitude,
    fr.address,
    fr.depth_level,
    fr.photo_url,
    fr.note,
    fr.upvote_count,
    fr.downvote_count,
    fr.expires_at,
    fr.created_at
  from public.flood_reports fr
  where fr.is_active = true
    and fr.expires_at > now()
  order by fr.created_at desc;
$$;

create or replace function public.get_flood_reports_within_radius(
  user_latitude double precision,
  user_longitude double precision,
  radius_meters integer default 500
)
returns table (
  id uuid,
  latitude double precision,
  longitude double precision,
  depth_level public.water_depth_level,
  distance_meters double precision,
  expires_at timestamptz
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select
    fr.id,
    st_y(fr.location::geometry) as latitude,
    st_x(fr.location::geometry) as longitude,
    fr.depth_level,
    st_distance(
      fr.location,
      st_setsrid(st_makepoint(user_longitude, user_latitude), 4326)::geography
    ) as distance_meters,
    fr.expires_at
  from public.flood_reports fr
  where fr.is_active = true
    and fr.expires_at > now()
    and st_dwithin(
      fr.location,
      st_setsrid(st_makepoint(user_longitude, user_latitude), 4326)::geography,
      radius_meters
    )
  order by distance_meters asc;
$$;

create or replace function public.create_flood_report(
  p_latitude double precision,
  p_longitude double precision,
  p_depth_level public.water_depth_level,
  p_photo_url text,
  p_address text default null,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  inserted_id uuid;
begin
  insert into public.flood_reports (
    user_id,
    location,
    depth_level,
    photo_url,
    address,
    note
  )
  values (
    auth.uid(),
    st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography,
    p_depth_level,
    p_photo_url,
    p_address,
    p_note
  )
  returning id into inserted_id;

  return inserted_id;
end;
$$;

alter table public.users enable row level security;
alter table public.flood_reports enable row level security;
alter table public.report_validations enable row level security;
alter table public.flood_prone_areas enable row level security;
alter table public.flood_prone_area_votes enable row level security;

create policy "users can read profiles"
on public.users for select
to authenticated
using (true);

create policy "users can update own profile"
on public.users for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "users can insert own profile"
on public.users for insert
to authenticated
with check (id = auth.uid());

create policy "active flood reports are readable"
on public.flood_reports for select
to authenticated
using (is_active = true and expires_at > now());

create policy "users can create own flood reports"
on public.flood_reports for insert
to authenticated
with check (user_id = auth.uid());

create policy "users can update own flood reports"
on public.flood_reports for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "validations are readable"
on public.report_validations for select
to authenticated
using (true);

create policy "users can validate reports once"
on public.report_validations for insert
to authenticated
with check (user_id = auth.uid());

create policy "users can change own validation"
on public.report_validations for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "flood prone areas are readable"
on public.flood_prone_areas for select
to authenticated
using (true);

create policy "users can nominate flood prone areas"
on public.flood_prone_areas for insert
to authenticated
with check (created_by = auth.uid());

create policy "area votes are readable"
on public.flood_prone_area_votes for select
to authenticated
using (true);

create policy "users can vote areas once"
on public.flood_prone_area_votes for insert
to authenticated
with check (user_id = auth.uid());

insert into storage.buckets (id, name, public)
values ('report-photos', 'report-photos', true)
on conflict (id) do update set public = excluded.public;

create policy "report photos are publicly readable"
on storage.objects for select
to public
using (bucket_id = 'report-photos');

create policy "authenticated users can upload report photos"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'report-photos'
  and owner = auth.uid()
);
