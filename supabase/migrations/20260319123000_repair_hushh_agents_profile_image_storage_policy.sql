drop policy if exists "Hushh Agents users can upload own profile images" on storage.objects;
create policy "Hushh Agents users can upload own profile images"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'hushh-agent-profile-images'
  and lower((storage.foldername(name))[1]) = auth.uid()::text
);

drop policy if exists "Hushh Agents users can update own profile images" on storage.objects;
create policy "Hushh Agents users can update own profile images"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'hushh-agent-profile-images'
  and lower((storage.foldername(name))[1]) = auth.uid()::text
)
with check (
  bucket_id = 'hushh-agent-profile-images'
  and lower((storage.foldername(name))[1]) = auth.uid()::text
);

drop policy if exists "Hushh Agents users can delete own profile images" on storage.objects;
create policy "Hushh Agents users can delete own profile images"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'hushh-agent-profile-images'
  and lower((storage.foldername(name))[1]) = auth.uid()::text
);
