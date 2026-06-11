-- Local development seed: create the public `photos` storage bucket and
-- access policies the app needs for uploading outfit/favourite/profile images.
-- Runs automatically on `supabase start` / `supabase db reset`.

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
