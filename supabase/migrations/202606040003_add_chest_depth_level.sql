-- Supabase migration: Add 'chest' level to water_depth_level enum
-- Target: PostgreSQL

set search_path = public, extensions;

-- Alter the enum type to add the new value
ALTER TYPE public.water_depth_level ADD VALUE IF NOT EXISTS 'chest';
