-- Phone OTP users may not have an email. Prefer display name, then email, then phone.

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, terms_accepted_at)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data->>'full_name', ''),
      new.email,
      new.phone
    ),
    nullif(new.raw_user_meta_data->>'terms_accepted_at', '')::timestamptz
  );
  return new;
end;
$$ language plpgsql security definer;
