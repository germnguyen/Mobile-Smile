-- Initial schema for the Study Cashew document-management app.
-- Requires Supabase Third-Party Auth to validate Firebase ID tokens.
-- Policies use the verified Firebase UID from JWT claim "sub".

create schema if not exists app_private;
revoke all on schema app_private from public;
grant usage on schema app_private to authenticated;

create table if not exists public.users (
  id text primary key,
  email text,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists users_email_lower_unique
  on public.users (lower(email))
  where email is not null;

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  owner_id text not null references public.users(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 250),
  description text,
  subject text,
  document_type text not null default 'other'
    check (document_type in ('lecture', 'assignment', 'reference', 'other')),
  storage_path text,
  mime_type text,
  file_size_bytes bigint check (file_size_bytes is null or file_size_bytes >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint documents_storage_metadata_consistent check (
    (storage_path is null and mime_type is null and file_size_bytes is null)
    or storage_path is not null
  )
);

create index if not exists documents_owner_created_idx
  on public.documents (owner_id, created_at desc);

create index if not exists documents_subject_idx
  on public.documents (subject);

create table if not exists public.document_permissions (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.documents(id) on delete cascade,
  user_id text not null references public.users(id) on delete cascade,
  shared_by text not null references public.users(id) on delete restrict,
  permission text not null check (permission in ('viewer', 'editor')),
  created_at timestamptz not null default now(),
  constraint document_permissions_unique_recipient unique (document_id, user_id),
  constraint document_permissions_no_self_share check (user_id <> shared_by)
);

create index if not exists document_permissions_user_document_idx
  on public.document_permissions (user_id, document_id);

create or replace function app_private.current_firebase_uid()
returns text
language sql
stable
set search_path = ''
as $$
  select nullif(auth.jwt() ->> 'sub', '');
$$;

create or replace function app_private.is_document_owner(p_document_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.documents d
    where d.id = p_document_id
      and d.owner_id = (select app_private.current_firebase_uid())
  );
$$;

create or replace function app_private.can_read_document(p_document_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    (select app_private.is_document_owner(p_document_id))
    or exists (
      select 1
      from public.document_permissions dp
      where dp.document_id = p_document_id
        and dp.user_id = (select app_private.current_firebase_uid())
    );
$$;

create or replace function app_private.can_edit_document(p_document_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    (select app_private.is_document_owner(p_document_id))
    or exists (
      select 1
      from public.document_permissions dp
      where dp.document_id = p_document_id
        and dp.user_id = (select app_private.current_firebase_uid())
        and dp.permission = 'editor'
    );
$$;

revoke all on function app_private.current_firebase_uid() from public;
revoke all on function app_private.is_document_owner(uuid) from public;
revoke all on function app_private.can_read_document(uuid) from public;
revoke all on function app_private.can_edit_document(uuid) from public;
grant execute on function app_private.current_firebase_uid() to authenticated;
grant execute on function app_private.is_document_owner(uuid) to authenticated;
grant execute on function app_private.can_read_document(uuid) to authenticated;
grant execute on function app_private.can_edit_document(uuid) to authenticated;

create or replace function app_private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
before update on public.users
for each row execute function app_private.set_updated_at();

drop trigger if exists documents_set_updated_at on public.documents;
create trigger documents_set_updated_at
before update on public.documents
for each row execute function app_private.set_updated_at();

create or replace function app_private.guard_document_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.id is distinct from old.id
     or new.owner_id is distinct from old.owner_id
     or new.created_at is distinct from old.created_at then
    raise exception 'Document identity and ownership are immutable';
  end if;

  if (
    new.storage_path is distinct from old.storage_path
    or new.mime_type is distinct from old.mime_type
    or new.file_size_bytes is distinct from old.file_size_bytes
  ) and not (select app_private.is_document_owner(old.id)) then
    raise exception 'Only the document owner can change file metadata';
  end if;

  return new;
end;
$$;

drop trigger if exists documents_guard_update on public.documents;
create trigger documents_guard_update
before update on public.documents
for each row execute function app_private.guard_document_update();

create or replace function app_private.guard_permission_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.id is distinct from old.id
     or new.document_id is distinct from old.document_id
     or new.user_id is distinct from old.user_id
     or new.shared_by is distinct from old.shared_by
     or new.created_at is distinct from old.created_at then
    raise exception 'Permission identity fields are immutable';
  end if;

  return new;
end;
$$;

drop trigger if exists document_permissions_guard_update
  on public.document_permissions;
create trigger document_permissions_guard_update
before update on public.document_permissions
for each row execute function app_private.guard_permission_update();

create or replace function public.share_document_with_email(
  p_document_id uuid,
  p_email text,
  p_permission text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner_id text;
  v_recipient_id text;
  v_permission_id uuid;
  v_email text := lower(btrim(p_email));
begin
  v_owner_id := app_private.current_firebase_uid();

  if v_owner_id is null then
    raise exception 'Authentication is required';
  end if;

  if not app_private.is_document_owner(p_document_id) then
    raise exception 'Only the document owner can manage sharing';
  end if;

  if p_permission not in ('viewer', 'editor') then
    raise exception 'Permission must be viewer or editor';
  end if;

  select u.id
    into v_recipient_id
  from public.users u
  where lower(u.email) = v_email;

  if v_recipient_id is null then
    raise exception 'No registered user matches this email';
  end if;

  if v_recipient_id = v_owner_id then
    raise exception 'A document cannot be shared with its owner';
  end if;

  insert into public.document_permissions (
    document_id,
    user_id,
    shared_by,
    permission
  )
  values (
    p_document_id,
    v_recipient_id,
    v_owner_id,
    p_permission
  )
  on conflict (document_id, user_id)
  do update set permission = excluded.permission
  returning id into v_permission_id;

  return v_permission_id;
end;
$$;

create or replace function public.revoke_document_share(
  p_document_id uuid,
  p_user_id text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not app_private.is_document_owner(p_document_id) then
    raise exception 'Only the document owner can manage sharing';
  end if;

  delete from public.document_permissions
  where document_id = p_document_id
    and user_id = p_user_id;
end;
$$;

create or replace function public.list_document_shares(p_document_id uuid)
returns table(user_id text, email text, permission text)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not app_private.is_document_owner(p_document_id) then
    raise exception 'Only the document owner can manage sharing';
  end if;

  return query
  select dp.user_id, u.email, dp.permission
  from public.document_permissions dp
  join public.users u on u.id = dp.user_id
  where dp.document_id = p_document_id
  order by lower(u.email);
end;
$$;

create or replace function public.search_documents(
  p_query text default null,
  p_document_type text default null
)
returns setof public.documents
language sql
stable
set search_path = ''
as $$
  select d.*
  from public.documents d
  where (
    nullif(btrim(p_query), '') is null
    or d.title ilike '%' || btrim(p_query) || '%'
    or coalesce(d.description, '') ilike '%' || btrim(p_query) || '%'
    or coalesce(d.subject, '') ilike '%' || btrim(p_query) || '%'
  )
  and (p_document_type is null or d.document_type = p_document_type)
  order by d.created_at desc;
$$;

revoke all on function public.share_document_with_email(uuid, text, text)
  from public;
grant execute on function public.share_document_with_email(uuid, text, text)
  to authenticated;
revoke all on function public.revoke_document_share(uuid, text)
  from public;
grant execute on function public.revoke_document_share(uuid, text)
  to authenticated;
revoke all on function public.list_document_shares(uuid)
  from public;
grant execute on function public.list_document_shares(uuid)
  to authenticated;
revoke all on function public.search_documents(text, text)
  from public;
grant execute on function public.search_documents(text, text)
  to authenticated;

alter table public.users enable row level security;
alter table public.documents enable row level security;
alter table public.document_permissions enable row level security;

drop policy if exists users_select_self on public.users;
create policy users_select_self
on public.users for select to authenticated
using (id = (select app_private.current_firebase_uid()));

drop policy if exists users_insert_self on public.users;
create policy users_insert_self
on public.users for insert to authenticated
with check (
  id = (select app_private.current_firebase_uid())
  and email is not distinct from (select auth.jwt() ->> 'email')
);

drop policy if exists users_update_self on public.users;
create policy users_update_self
on public.users for update to authenticated
using (id = (select app_private.current_firebase_uid()))
with check (
  id = (select app_private.current_firebase_uid())
  and email is not distinct from (select auth.jwt() ->> 'email')
);

drop policy if exists documents_select_authorized on public.documents;
create policy documents_select_authorized
on public.documents for select to authenticated
using ((select app_private.can_read_document(id)));

drop policy if exists documents_insert_owner on public.documents;
create policy documents_insert_owner
on public.documents for insert to authenticated
with check (
  owner_id = (select app_private.current_firebase_uid())
  and exists (
    select 1
    from public.users u
    where u.id = (select app_private.current_firebase_uid())
  )
);

drop policy if exists documents_update_owner_or_editor on public.documents;
create policy documents_update_owner_or_editor
on public.documents for update to authenticated
using ((select app_private.can_edit_document(id)))
with check ((select app_private.can_edit_document(id)));

drop policy if exists documents_delete_owner on public.documents;
create policy documents_delete_owner
on public.documents for delete to authenticated
using ((select app_private.is_document_owner(id)));

drop policy if exists permissions_select_authorized on public.document_permissions;
create policy permissions_select_authorized
on public.document_permissions for select to authenticated
using (
  user_id = (select app_private.current_firebase_uid())
  or (select app_private.is_document_owner(document_id))
);

drop policy if exists permissions_insert_owner on public.document_permissions;
create policy permissions_insert_owner
on public.document_permissions for insert to authenticated
with check (
  shared_by = (select app_private.current_firebase_uid())
  and (select app_private.is_document_owner(document_id))
  and user_id <> (select app_private.current_firebase_uid())
);

drop policy if exists permissions_update_owner on public.document_permissions;
create policy permissions_update_owner
on public.document_permissions for update to authenticated
using ((select app_private.is_document_owner(document_id)))
with check (
  shared_by = (select app_private.current_firebase_uid())
  and (select app_private.is_document_owner(document_id))
);

drop policy if exists permissions_delete_owner on public.document_permissions;
create policy permissions_delete_owner
on public.document_permissions for delete to authenticated
using ((select app_private.is_document_owner(document_id)));

grant select, insert, update on public.users to authenticated;
grant select, insert, update, delete on public.documents to authenticated;
grant select, insert, update, delete
  on public.document_permissions to authenticated;
