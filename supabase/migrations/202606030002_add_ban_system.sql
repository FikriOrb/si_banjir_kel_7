-- Supabase migration: Add ban system
-- Target: PostgreSQL

set search_path = public, extensions;

-- 1. Add violation_count and is_banned to users table
alter table public.users add column if not exists violation_count integer not null default 0;
alter table public.users add column if not exists is_banned boolean not null default false;

-- 2. Modify check_report_violations trigger
create or replace function public.check_report_violations()
returns trigger language plpgsql security definer as $$
begin
  -- Check if downvote_count reached 5 for the first time
  if new.downvote_count >= 5 and old.downvote_count < 5 then
    -- Deactivate the report
    new.is_active = false;
    
    -- Increment violation count and check if banned
    update public.users
    set violation_count = violation_count + 1,
        is_banned = case when violation_count + 1 >= 3 then true else is_banned end
    where id = new.user_id;
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_report_violations on public.flood_reports;
create trigger enforce_report_violations
before update of downvote_count on public.flood_reports
for each row execute function public.check_report_violations();
