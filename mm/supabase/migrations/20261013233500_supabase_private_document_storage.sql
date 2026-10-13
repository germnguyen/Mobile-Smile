-- Private Supabase Storage for document files.
-- This migration assumes Firebase Third-Party Auth is enabled and verified
-- so auth.jwt()->>'sub' contains the signed-in Firebase UID.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'documents',
  'documents',
  false,
  20971520,
  array[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'image/png',
    'image/jpeg'
  ]
)
on conflict (id) do update
set name = excluded.name,
    public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists documents_storage_select_authorized on storage.objects;
create policy documents_storage_select_authorized
on storage.objects for select to authenticated
using (
  bucket_id = 'documents'
  and (
    split_part(name, '/', 1) = (select app_private.current_firebase_uid())
    or exists (
      select 1
      from public.documents d
      where d.storage_path = storage.objects.name
        and (select app_private.can_read_document(d.id))
    )
  )
);

drop policy if exists documents_storage_insert_owner on storage.objects;
create policy documents_storage_insert_owner
on storage.objects for insert to authenticated
with check (
  bucket_id = 'documents'
  and split_part(name, '/', 1) = (select app_private.current_firebase_uid())
  and exists (
    select 1
    from public.documents d
    where d.id::text = split_part(storage.objects.name, '/', 2)
      and d.owner_id = (select app_private.current_firebase_uid())
  )
);

drop policy if exists documents_storage_update_owner on storage.objects;
create policy documents_storage_update_owner
on storage.objects for update to authenticated
using (
  bucket_id = 'documents'
  and split_part(name, '/', 1) = (select app_private.current_firebase_uid())
)
with check (
  bucket_id = 'documents'
  and split_part(name, '/', 1) = (select app_private.current_firebase_uid())
);

drop policy if exists documents_storage_delete_owner on storage.objects;
create policy documents_storage_delete_owner
on storage.objects for delete to authenticated
using (
  bucket_id = 'documents'
  and split_part(name, '/', 1) = (select app_private.current_firebase_uid())
);
