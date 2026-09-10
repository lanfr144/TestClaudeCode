
-- Un document par emplacement de stockage : permet l'upsert lors d'une régénération.
create unique index if not exists documents_storage_path_key on documents(storage_path);

-- Bucket privé : aucun accès public, uniquement des URL signées à durée courte.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('documents', 'documents', false, 26214400,
        array['application/pdf','image/png','image/jpeg'])
on conflict (id) do nothing;

-- Le premier segment du chemin est l'identifiant de société : l'isolation
-- multi-sociétés vaut aussi pour les fichiers.
create policy documents_bucket_read on storage.objects for select to authenticated
  using (
    bucket_id = 'documents'
    and (
      has_company_access(((storage.foldername(name))[1])::uuid)
      or exists (
        select 1 from employees e
        where e.user_id = auth.uid()
          and e.id::text = (storage.foldername(name))[2]
      )
    )
  );

create policy documents_bucket_write on storage.objects for insert to authenticated
  with check (
    bucket_id = 'documents'
    and can_manage_company(((storage.foldername(name))[1])::uuid)
  );

create policy documents_bucket_update on storage.objects for update to authenticated
  using (bucket_id = 'documents' and can_manage_company(((storage.foldername(name))[1])::uuid))
  with check (bucket_id = 'documents' and can_manage_company(((storage.foldername(name))[1])::uuid));

create policy documents_bucket_delete on storage.objects for delete to authenticated
  using (bucket_id = 'documents' and can_manage_company(((storage.foldername(name))[1])::uuid));
