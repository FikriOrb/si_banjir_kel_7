-- Supabase migration: Secure report editing and deleting
-- Target: PostgreSQL

set search_path = public, extensions;

-- Drop the old update policy
drop policy if exists "users can update own flood reports" on public.flood_reports;

-- Create secure update policy (only if active and not expired)
create policy "users can update own active flood reports"
on public.flood_reports for update
to authenticated
using (
    user_id = auth.uid() 
    and is_active = true 
    and expires_at > now()
)
with check (
    user_id = auth.uid()
);

-- Create secure delete policy (only if active and not expired)
-- (Previously missing in initial schema, so we add it here)
create policy "users can delete own active flood reports"
on public.flood_reports for delete
to authenticated
using (
    user_id = auth.uid() 
    and is_active = true 
    and expires_at > now()
);
