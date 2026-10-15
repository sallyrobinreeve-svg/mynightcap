-- Ordered photo and video galleries on an entry.
-- Photos: type 'photo' (up to 10). Videos: type 'video' (up to 5).
-- Existing outfit/favourite rows and entries.video_url stay valid.

alter table public.photos add column if not exists sort_order integer not null default 0;

alter table public.photos drop constraint if exists photos_type_check;

alter table public.photos
  add constraint photos_type_check
  check (type in ('outfit', 'favourite', 'step', 'photo', 'video'));
