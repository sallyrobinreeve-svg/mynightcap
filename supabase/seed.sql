-- Local development seed. Runs automatically on `supabase start` / `supabase db reset`.
--
-- 1) Table privileges for the API roles.
--    The repo migrations enable RLS and define policies but never GRANT table
--    privileges. Recent local Supabase default privileges only grant
--    TRUNCATE/REFERENCES/TRIGGER to anon/authenticated, so DML hits
--    "permission denied for table ...". Restore the standard Supabase grants
--    (RLS policies still enforce row-level access on top of these).
grant usage on schema public to anon, authenticated, service_role;
grant select, insert, update, delete on all tables in schema public
  to anon, authenticated, service_role;
grant usage, select on all sequences in schema public
  to anon, authenticated, service_role;
grant execute on all functions in schema public
  to anon, authenticated, service_role;

alter default privileges in schema public
  grant select, insert, update, delete on tables to anon, authenticated, service_role;
alter default privileges in schema public
  grant usage, select on sequences to anon, authenticated, service_role;
alter default privileges in schema public
  grant execute on functions to anon, authenticated, service_role;

-- 2) Create the public `photos` storage bucket and access policies the app
--    needs for uploading outfit/favourite/profile images.

insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do update set public = excluded.public;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'photos_public_select'
  ) then
    create policy "photos_public_select" on storage.objects
      for select using (bucket_id = 'photos');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'photos_auth_insert'
  ) then
    create policy "photos_auth_insert" on storage.objects
      for insert to authenticated with check (bucket_id = 'photos');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'photos_auth_update'
  ) then
    create policy "photos_auth_update" on storage.objects
      for update to authenticated using (bucket_id = 'photos');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'photos_auth_delete'
  ) then
    create policy "photos_auth_delete" on storage.objects
      for delete to authenticated using (bucket_id = 'photos');
  end if;
end $$;
