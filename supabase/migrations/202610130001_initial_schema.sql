-- Pustaka Bersama — foundational schema
-- Apply through Supabase migrations after reviewing organization and access policies.
create extension if not exists pgcrypto;
create extension if not exists pg_trgm;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  timezone text not null default 'Asia/Jakarta',
  currency char(3) not null default 'IDR',
  settings jsonb not null default '{"hold_hours":48,"fine_block_threshold":0,"max_reservations_per_member":3}'::jsonb,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  organization_id uuid not null references public.organizations(id),
  full_name text not null,
  role text not null check (role in ('SUPER_ADMIN','ADMIN','PENGURUS','ANGGOTA')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists profiles_org_role_idx on public.profiles(organization_id,role);

create table if not exists public.member_categories (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  name text not null, max_total_items integer not null default 2 check (max_total_items >= 0),
  active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (organization_id,name), unique (organization_id,id)
);
create table if not exists public.members (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  user_id uuid references auth.users(id) on delete set null, member_category_id uuid not null,
  member_code text not null, full_name text not null, email text, whatsapp text, photo_url text,
  status text not null default 'AKTIF' check (status in ('AKTIF','DISUSPEND','DIBLOKIR','NONAKTIF')),
  valid_until date, internal_notes text, suspended_reason text, suspended_until timestamptz, archived_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (organization_id,member_code), unique (organization_id,id),
  foreign key (organization_id,member_category_id) references public.member_categories(organization_id,id)
);
create index if not exists members_org_name_idx on public.members(organization_id,full_name);
create index if not exists members_name_trgm_idx on public.members using gin(full_name gin_trgm_ops);

create table if not exists public.item_categories (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  parent_id uuid, name text not null, description text, archived_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (organization_id,id), unique (organization_id,name),
  foreign key (organization_id,parent_id) references public.item_categories(organization_id,id)
);
create table if not exists public.locations (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  parent_id uuid, name text not null, level text not null default 'RAK' check(level in ('GEDUNG','RUANGAN','RAK','LAINNYA')),
  description text, archived_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (organization_id,id), foreign key (organization_id,parent_id) references public.locations(organization_id,id)
);
create table if not exists public.item_types (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  category_id uuid, kind text not null check(kind in ('BUKU','PERALATAN','LAINNYA')),
  title text not null, description text, isbn text, cover_url text, attributes jsonb not null default '{}'::jsonb,
  archived_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (organization_id,id), foreign key (organization_id,category_id) references public.item_categories(organization_id,id)
);
create index if not exists item_types_org_title_idx on public.item_types(organization_id,title);
create index if not exists item_types_title_trgm_idx on public.item_types using gin(title gin_trgm_ops);
create index if not exists item_types_attributes_idx on public.item_types using gin(attributes);
create table if not exists public.book_metadata (
  organization_id uuid not null references public.organizations(id),
  item_type_id uuid primary key references public.item_types(id) on delete cascade,
  authors text[], publisher text, publication_year integer, language text, page_count integer,
  source text, fetched_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  foreign key (organization_id,item_type_id) references public.item_types(organization_id,id) on delete cascade
);
create table if not exists public.isbn_cache (
  isbn text primary key, source text not null, response jsonb not null, fetched_at timestamptz not null default now()
);
create table if not exists public.item_copies (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  item_type_id uuid not null, barcode text not null, status text not null default 'TERSEDIA'
    check(status in ('TERSEDIA','DIPINJAM','DITAHAN','RUSAK','DALAM_PERBAIKAN','HILANG','DITARIK')),
  location_id uuid, condition text not null default 'BAIK' check(condition in ('BAIK','RUSAK','HILANG','TIDAK_DIKETAHUI')),
  acquired_at date, acquisition_price bigint check(acquisition_price is null or acquisition_price >= 0), source text, notes text,
  archived_at timestamptz, version integer not null default 1,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (organization_id,barcode), unique (organization_id,id),
  foreign key (organization_id,item_type_id) references public.item_types(organization_id,id),
  foreign key (organization_id,location_id) references public.locations(organization_id,id)
);
create index if not exists item_copies_org_status_idx on public.item_copies(organization_id,status);
create index if not exists item_copies_item_idx on public.item_copies(item_type_id,status);

create table if not exists public.loan_policies (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  member_category_id uuid not null, item_category_id uuid, item_kind text check(item_kind is null or item_kind in ('BUKU','PERALATAN','LAINNYA')),
  allowed boolean not null default true, loan_days integer not null default 7 check(loan_days > 0),
  max_items integer not null default 2 check(max_items >= 0), max_renewals integer not null default 1 check(max_renewals >= 0),
  renewal_days integer not null default 7 check(renewal_days > 0), grace_days integer not null default 0 check(grace_days >= 0),
  fine_rule jsonb not null default '{"type":"flat","rate":500,"cap":null}'::jsonb,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  foreign key (organization_id,member_category_id) references public.member_categories(organization_id,id),
  foreign key (organization_id,item_category_id) references public.item_categories(organization_id,id)
);

create table if not exists public.loans (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  copy_id uuid not null, member_id uuid not null, checked_out_at timestamptz not null default now(),
  due_date date not null, due_at timestamptz not null, returned_at timestamptz,
  status text not null default 'AKTIF' check(status in ('AKTIF','DIKEMBALIKAN','HILANG','DIBATALKAN')),
  renewal_count integer not null default 0 check(renewal_count >= 0), policy_snapshot jsonb not null,
  condition_out text not null default 'BAIK', condition_in text, processed_by uuid references auth.users(id),
  returned_processed_by uuid references auth.users(id), void_reason text, idempotency_key text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  foreign key (organization_id,copy_id) references public.item_copies(organization_id,id),
  unique (organization_id,id),
  foreign key (organization_id,member_id) references public.members(organization_id,id)
);
create unique index if not exists uq_loans_open_per_copy on public.loans(copy_id) where returned_at is null and status='AKTIF';
create unique index if not exists uq_loans_idempotency on public.loans(organization_id,idempotency_key) where idempotency_key is not null;
create index if not exists loans_due_open_idx on public.loans(organization_id,due_date) where returned_at is null and status='AKTIF';
create index if not exists loans_member_open_idx on public.loans(member_id) where returned_at is null and status='AKTIF';
create table if not exists public.loan_events (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  loan_id uuid not null, event_type text not null, actor_user_id uuid references auth.users(id),
  payload jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(),
  foreign key (organization_id,loan_id) references public.loans(organization_id,id)
);

create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  item_type_id uuid not null, member_id uuid not null,
  status text not null default 'MENUNGGU' check(status in ('MENUNGGU','SIAP_DIAMBIL','TERPENUHI','KEDALUWARSA','DIBATALKAN')),
  queued_at timestamptz not null default now(), ready_at timestamptz, hold_expires_at timestamptz, held_copy_id uuid,
  fulfilled_loan_id uuid, cancel_reason text, created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  foreign key (organization_id,fulfilled_loan_id) references public.loans(organization_id,id),
  foreign key (organization_id,item_type_id) references public.item_types(organization_id,id),
  foreign key (organization_id,member_id) references public.members(organization_id,id),
  foreign key (organization_id,held_copy_id) references public.item_copies(organization_id,id)
);
create unique index if not exists uq_res_active_per_member on public.reservations(item_type_id,member_id) where status in ('MENUNGGU','SIAP_DIAMBIL');
create unique index if not exists uq_res_held_copy on public.reservations(held_copy_id) where status='SIAP_DIAMBIL';
create index if not exists reservations_fifo_idx on public.reservations(item_type_id,queued_at,id) where status='MENUNGGU';

create table if not exists public.fines (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  loan_id uuid, member_id uuid not null, type text not null check(type in ('TERLAMBAT','HILANG','RUSAK','LAINNYA')),
  amount bigint not null check(amount >= 0), amount_paid bigint not null default 0 check(amount_paid >= 0 and amount_paid <= amount),
  status text not null default 'BELUM_BAYAR' check(status in ('BELUM_BAYAR','SEBAGIAN','LUNAS','DIHAPUSKAN')),
  computed_from jsonb not null default '{}'::jsonb, waived_by uuid references auth.users(id), waive_reason text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (organization_id,id),
  foreign key (organization_id,loan_id) references public.loans(organization_id,id),
  foreign key (organization_id,member_id) references public.members(organization_id,id)
);
create index if not exists fines_org_status_idx on public.fines(organization_id,status) where status in ('BELUM_BAYAR','SEBAGIAN');
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  member_id uuid not null, amount bigint not null check(amount > 0), method text not null check(method in ('TUNAI','TRANSFER','QRIS_MANUAL','LAINNYA')),
  received_by uuid references auth.users(id), paid_at timestamptz not null default now(), reference text, notes text,
  idempotency_key text, voided_at timestamptz, created_at timestamptz not null default now(),
  foreign key (organization_id,member_id) references public.members(organization_id,id),
  unique (organization_id,id), unique (organization_id,idempotency_key)
);
create table if not exists public.payment_allocations (
  organization_id uuid not null references public.organizations(id),
  payment_id uuid not null, fine_id uuid not null,
  amount bigint not null check(amount > 0), created_at timestamptz not null default now(), primary key(payment_id,fine_id),
  foreign key (organization_id,payment_id) references public.payments(organization_id,id),
  foreign key (organization_id,fine_id) references public.fines(organization_id,id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  type text not null, channel text not null check(channel in ('EMAIL','WHATSAPP','MANUAL')),
  member_id uuid, recipient text, payload jsonb not null default '{}'::jsonb,
  dedupe_key text not null unique, status text not null default 'PENDING' check(status in ('PENDING','SENDING','SENT','FAILED','SKIPPED')),
  attempts integer not null default 0, next_attempt_at timestamptz not null default now(), sent_at timestamptz,
  provider_message_id text, error text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  foreign key (organization_id,member_id) references public.members(organization_id,id)
);
create index if not exists notifications_outbox_idx on public.notifications(status,next_attempt_at) where status in ('PENDING','FAILED');
create table if not exists public.notification_templates (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  type text not null, channel text not null default 'EMAIL', subject text, body text not null, enabled boolean not null default true,
  updated_at timestamptz not null default now(), unique(organization_id,type,channel)
);
create table if not exists public.audit_logs (
  id bigint generated always as identity primary key, organization_id uuid not null references public.organizations(id),
  actor_user_id uuid references auth.users(id), action text not null, entity_type text not null, entity_id text,
  before jsonb, after jsonb, reason text, ip inet, created_at timestamptz not null default now()
);
create index if not exists audit_logs_org_created_idx on public.audit_logs(organization_id,created_at desc);
create table if not exists public.job_runs (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  job_name text not null, started_at timestamptz not null default now(), finished_at timestamptz,
  status text not null default 'RUNNING' check(status in ('RUNNING','SUCCEEDED','FAILED')),
  processed_count integer not null default 0, error text, meta jsonb not null default '{}'::jsonb
);
create table if not exists public.holidays (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  holiday_date date not null, name text not null, created_at timestamptz not null default now(), unique(organization_id,holiday_date)
);
create table if not exists public.settings (
  organization_id uuid not null references public.organizations(id), key text not null, value jsonb not null,
  updated_at timestamptz not null default now(), updated_by uuid references auth.users(id), primary key(organization_id,key)
);

create or replace function public.set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;
do $$ declare t text; begin
  foreach t in array array['organizations','profiles','member_categories','members','item_categories','locations','item_types','book_metadata','item_copies','loan_policies','loans','reservations','fines','notifications','payments','notification_templates'] loop
    execute format('drop trigger if exists set_updated_at on public.%I',t);
    execute format('create trigger set_updated_at before update on public.%I for each row execute function public.set_updated_at()',t);
  end loop;
end $$;

-- Deterministic day-based fine calculation. Supports flat or tiered JSON rules, grace days, and a numeric cap.
create or replace function public.calculate_fine(p_rule jsonb, p_due date, p_return date)
returns bigint language plpgsql immutable as $$
declare late_days integer; grace integer; charge bigint := 0; tier jsonb; lo integer; hi integer; rate bigint;
begin
  grace := greatest(0, coalesce((p_rule->>'grace_days')::integer,0));
  late_days := greatest(0,(p_return-p_due)-grace);
  if late_days = 0 then return 0; end if;
  if coalesce(p_rule->>'type','flat') = 'tiered' and jsonb_typeof(p_rule->'tiers')='array' then
    for tier in select value from jsonb_array_elements(p_rule->'tiers') loop
      lo := greatest(1,coalesce((tier->>'from_day')::integer,1));
      hi := coalesce((tier->>'to_day')::integer,late_days);
      rate := greatest(0,coalesce((tier->>'rate')::bigint,0));
      if late_days >= lo then charge := charge + greatest(0,least(late_days,hi)-lo+1)*rate; end if;
    end loop;
  else
    charge := late_days * greatest(0,coalesce((p_rule->>'rate')::bigint,500));
  end if;
  if nullif(p_rule->>'cap','') is not null then charge := least(charge,greatest(0,(p_rule->>'cap')::bigint)); end if;
  return greatest(0,charge);
end; $$;

-- Checkout a single copy atomically. Unique partial index remains the final concurrency guard.
create or replace function public.checkout_copy(p_member_id uuid,p_copy_id uuid,p_idempotency_key text default null)
returns jsonb language plpgsql security invoker as $$
declare m public.members%rowtype; c public.item_copies%rowtype; it public.item_types%rowtype; cat public.member_categories%rowtype;
  pol public.loan_policies%rowtype; org_tz text; local_today date; open_count integer; policy_open_count integer; fine_total bigint; held public.reservations%rowtype; new_loan public.loans%rowtype; actor_id uuid := auth.uid();
begin
  if actor_id is null then raise exception 'AUTHENTICATION_REQUIRED' using errcode='28000'; end if;
  if p_idempotency_key is not null then
    select * into new_loan from public.loans where idempotency_key=p_idempotency_key and organization_id=(select organization_id from public.members where id=p_member_id) limit 1;
    if found then return jsonb_build_object('loan_id',new_loan.id,'due_date',new_loan.due_date,'idempotent_replay',true); end if;
  end if;
  select * into m from public.members where id=p_member_id and archived_at is null for update;
  if not found then raise exception 'MEMBER_NOT_FOUND' using errcode='P0002'; end if;
  select timezone into org_tz from public.organizations where id=m.organization_id;
  if m.status <> 'AKTIF' then raise exception 'MEMBER_SUSPENDED' using errcode='P0001'; end if;
  if m.valid_until is not null and m.valid_until < (now() at time zone coalesce(org_tz,'Asia/Jakarta'))::date then raise exception 'MEMBERSHIP_EXPIRED' using errcode='P0001'; end if;
  select * into cat from public.member_categories where id=m.member_category_id;
  select coalesce(sum(amount-amount_paid),0) into fine_total from public.fines where member_id=m.id and status in ('BELUM_BAYAR','SEBAGIAN');
  if fine_total > 0 then raise exception 'FINES_OUTSTANDING' using errcode='P0001'; end if;
  select * into c from public.item_copies where id=p_copy_id and organization_id=m.organization_id and archived_at is null for update;
  if not found then raise exception 'COPY_NOT_FOUND' using errcode='P0002'; end if;
  if c.status not in ('TERSEDIA','DITAHAN') then raise exception 'COPY_NOT_AVAILABLE' using errcode='P0001'; end if;
  if c.status='DITAHAN' then
    select * into held from public.reservations where held_copy_id=c.id and status='SIAP_DIAMBIL' for update;
    if not found or held.member_id <> m.id then raise exception 'HOLD_RESERVED_FOR_OTHER' using errcode='P0001'; end if;
  end if;
  select * into it from public.item_types where id=c.item_type_id;
  select * into pol from public.loan_policies lp where lp.organization_id=m.organization_id and lp.member_category_id=m.member_category_id
    and (lp.item_category_id=it.category_id or lp.item_category_id is null)
    and (lp.item_kind=it.kind or lp.item_kind is null)
    order by (lp.item_category_id is not null)::int desc,(lp.item_kind is not null)::int desc limit 1;
  if not found or not pol.allowed then raise exception 'NOT_ELIGIBLE' using errcode='P0001'; end if;
  select count(*) into open_count from public.loans where member_id=m.id and status='AKTIF' and returned_at is null;
  select count(*) into policy_open_count from public.loans l join public.item_copies cp on cp.id=l.copy_id join public.item_types old_it on old_it.id=cp.item_type_id
    where l.member_id=m.id and l.status='AKTIF' and l.returned_at is null
      and (pol.item_category_id is null or old_it.category_id=pol.item_category_id)
      and (pol.item_kind is null or old_it.kind=pol.item_kind);
  if open_count >= cat.max_total_items or policy_open_count >= pol.max_items then raise exception 'QUOTA_EXCEEDED' using errcode='P0001'; end if;
  local_today := (now() at time zone coalesce(org_tz,'Asia/Jakarta'))::date;
  insert into public.loans(organization_id,copy_id,member_id,due_date,due_at,status,policy_snapshot,processed_by,idempotency_key)
  values(m.organization_id,c.id,m.id,local_today+pol.loan_days,((local_today+pol.loan_days)+time '23:59') at time zone coalesce(org_tz,'Asia/Jakarta'),'AKTIF',to_jsonb(pol),actor_id,p_idempotency_key)
  returning * into new_loan;
  update public.item_copies set status='DIPINJAM',version=version+1 where id=c.id;
  if c.status='DITAHAN' then update public.reservations set status='TERPENUHI',fulfilled_loan_id=new_loan.id,updated_at=now() where id=held.id; end if;
  insert into public.loan_events(organization_id,loan_id,event_type,actor_user_id,payload) values(m.organization_id,new_loan.id,'CHECKOUT',actor_id,jsonb_build_object('copy_id',c.id,'member_id',m.id));
  insert into public.audit_logs(organization_id,actor_user_id,action,entity_type,entity_id,after) values(m.organization_id,actor_id,'CHECKOUT','loans',new_loan.id::text,jsonb_build_object('copy_id',c.id,'member_id',m.id,'due_date',new_loan.due_date));
  return jsonb_build_object('loan_id',new_loan.id,'due_date',new_loan.due_date,'status','AKTIF');
end; $$;

-- Return one copy atomically and assign a 48-hour hold to the FIFO reservation queue when needed.
create or replace function public.return_copy(p_barcode text,p_condition text default 'BAIK',p_replacement_amount bigint default null)
returns jsonb language plpgsql security invoker as $$
declare c public.item_copies%rowtype; l public.loans%rowtype; f public.fines%rowtype; r public.reservations%rowtype;
  actual_condition text := upper(coalesce(p_condition,'BAIK')); charge bigint := 0; fine_rule jsonb; exp timestamptz; org_tz text; actor_id uuid := auth.uid();
begin
  if actor_id is null then raise exception 'AUTHENTICATION_REQUIRED' using errcode='28000'; end if;
  if p_replacement_amount is not null and p_replacement_amount < 0 then raise exception 'INVALID_REPLACEMENT_AMOUNT' using errcode='22023'; end if;
  if actual_condition not in ('BAIK','RUSAK','HILANG') then raise exception 'INVALID_CONDITION' using errcode='22023'; end if;
  select * into c from public.item_copies where barcode=p_barcode and archived_at is null for update;
  if not found then raise exception 'COPY_NOT_FOUND' using errcode='P0002'; end if;
  select * into l from public.loans where copy_id=c.id and status='AKTIF' and returned_at is null for update;
  if not found then raise exception 'NO_OPEN_LOAN' using errcode='P0001'; end if;
  fine_rule := coalesce(l.policy_snapshot->'fine_rule','{"type":"flat","rate":500,"grace_days":0}'::jsonb);
  if actual_condition='HILANG' then
    charge := coalesce(p_replacement_amount,c.acquisition_price);
    if charge is null then raise exception 'REPLACEMENT_AMOUNT_REQUIRED' using errcode='22023'; end if;
    update public.loans set status='HILANG',returned_at=now(),condition_in='HILANG',returned_processed_by=actor_id where id=l.id;
    update public.item_copies set status='HILANG',condition='HILANG',version=version+1 where id=c.id;
    insert into public.fines(organization_id,loan_id,member_id,type,amount,computed_from)
      values(l.organization_id,l.id,l.member_id,'HILANG',charge,jsonb_build_object('copy_id',c.id,'acquisition_price',c.acquisition_price,'replacement_amount',charge)) returning * into f;
  else
    charge := public.calculate_fine(fine_rule,l.due_date,(now() at time zone coalesce((select timezone from public.organizations where id=c.organization_id),'Asia/Jakarta'))::date);
    update public.loans set status='DIKEMBALIKAN',returned_at=now(),condition_in=actual_condition,returned_processed_by=actor_id where id=l.id;
    if charge > 0 then
      insert into public.fines(organization_id,loan_id,member_id,type,amount,computed_from)
      values(l.organization_id,l.id,l.member_id,'TERLAMBAT',charge,jsonb_build_object('due_date',l.due_date,'return_date',(now() at time zone coalesce((select timezone from public.organizations where id=c.organization_id),'Asia/Jakarta'))::date,'rule',fine_rule)) returning * into f;
    end if;
    if actual_condition='RUSAK' then
      update public.item_copies set status='RUSAK',condition='RUSAK',version=version+1 where id=c.id;
    else
      select * into r from public.reservations where organization_id=c.organization_id and item_type_id=c.item_type_id and status='MENUNGGU' order by queued_at,id limit 1 for update skip locked;
      if found then
        select timezone into org_tz from public.organizations where id=c.organization_id;
        exp := now()+make_interval(hours=>coalesce(((select settings from public.organizations where id=c.organization_id)->>'hold_hours')::int,48));
        update public.reservations set status='SIAP_DIAMBIL',ready_at=now(),hold_expires_at=exp,held_copy_id=c.id where id=r.id;
        update public.item_copies set status='DITAHAN',version=version+1 where id=c.id;
        insert into public.notifications(organization_id,type,channel,member_id,payload,dedupe_key)
        values(c.organization_id,'HOLD_READY','EMAIL',r.member_id,jsonb_build_object('reservation_id',r.id,'copy_id',c.id,'hold_expires_at',exp),'HOLD_READY:'||r.id::text)
        on conflict(dedupe_key) do nothing;
      else update public.item_copies set status='TERSEDIA',condition='BAIK',version=version+1 where id=c.id; end if;
    end if;
  end if;
  insert into public.loan_events(organization_id,loan_id,event_type,actor_user_id,payload) values(l.organization_id,l.id,'RETURN',actor_id,jsonb_build_object('copy_id',c.id,'condition',actual_condition,'fine_amount',coalesce(charge,0)));
  insert into public.audit_logs(organization_id,actor_user_id,action,entity_type,entity_id,after) values(l.organization_id,actor_id,'RETURN','loans',l.id::text,jsonb_build_object('copy_id',c.id,'condition',actual_condition,'fine_amount',coalesce(charge,0),'status',case when actual_condition='HILANG' then 'HILANG' else 'DIKEMBALIKAN' end));
  return jsonb_build_object('loan_id',l.id,'copy_status',case when actual_condition='HILANG' then 'HILANG' when actual_condition='RUSAK' then 'RUSAK' when r.id is not null then 'DITAHAN' else 'TERSEDIA' end,'fine_amount',coalesce(charge,0),'reservation_id',r.id,'hold_expires_at',exp);
end; $$;

-- RLS on every exposed business table. Reads are scoped to the organization attached to the authenticated profile.
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['organizations','profiles','member_categories','members','item_categories','locations','item_types','book_metadata','isbn_cache','item_copies','loan_policies','loans','loan_events','reservations','fines','payments','payment_allocations','notifications','notification_templates','audit_logs','job_runs','holidays','settings'] LOOP
    EXECUTE format('alter table public.%I enable row level security',t);
  END LOOP;
END $$;

-- Organizations are visible only to authenticated users with a profile in that organization.
create policy organizations_select_member on public.organizations for select to authenticated using (id=(select p.organization_id from public.profiles p where p.id=(select auth.uid())));
-- Profile is only directly readable/updatable by its owner. Role assignment is not exposed to client updates.
create policy profiles_select_self on public.profiles for select to authenticated using (id=(select auth.uid()));
create policy profiles_update_self on public.profiles for update to authenticated using (id=(select auth.uid())) with check (id=(select auth.uid()));

DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['member_categories','members','item_categories','locations','item_types','book_metadata','item_copies','loan_policies','loans','loan_events','reservations','fines','payments','payment_allocations','notifications','notification_templates','audit_logs','job_runs','holidays','settings'] LOOP
    EXECUTE format('create policy %I on public.%I for select to authenticated using (organization_id = (select p.organization_id from public.profiles p where p.id=(select auth.uid())))', t||'_select_org',t);
  END LOOP;
END $$;
-- Staff writes are allowed only inside their own organization. Pengurus is intentionally read-only.
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['member_categories','members','item_categories','locations','item_types','book_metadata','item_copies','loan_policies','loans','loan_events','reservations','fines','payments','payment_allocations','notifications','notification_templates','holidays','settings'] LOOP
    EXECUTE format('create policy %I on public.%I for insert to authenticated with check (organization_id = (select p.organization_id from public.profiles p where p.id=(select auth.uid()) and p.role in (''SUPER_ADMIN'',''ADMIN'')))', t||'_insert_staff',t);
    EXECUTE format('create policy %I on public.%I for update to authenticated using (organization_id = (select p.organization_id from public.profiles p where p.id=(select auth.uid()) and p.role in (''SUPER_ADMIN'',''ADMIN''))) with check (organization_id = (select p.organization_id from public.profiles p where p.id=(select auth.uid()) and p.role in (''SUPER_ADMIN'',''ADMIN'')))', t||'_update_staff',t);
  END LOOP;
END $$;
-- Audit is append-only to clients; only SELECT and INSERT policies are defined.
create policy audit_insert_staff on public.audit_logs for insert to authenticated with check (organization_id=(select p.organization_id from public.profiles p where p.id=(select auth.uid()) and p.role in ('SUPER_ADMIN','ADMIN')));
grant usage on schema public to authenticated;
grant select, insert, update on all tables in schema public to authenticated;
-- Table-level grants are narrowed AFTER broad baseline grants.
revoke update, delete, truncate on public.audit_logs from public, anon, authenticated;
revoke all on public.isbn_cache from public, anon, authenticated;
revoke update on public.profiles from public, anon, authenticated;
grant update (full_name) on public.profiles to authenticated;
revoke insert, update, delete, truncate on public.organizations from public, anon, authenticated;
revoke insert, update, delete, truncate on public.isbn_cache from public, anon, authenticated;

-- Keep business RPCs under the caller's database grants. They enforce organization scope using the member/copy lock pair.
revoke all on function public.checkout_copy(uuid,uuid,text) from public, anon;
revoke all on function public.return_copy(text,text,bigint) from public, anon;
grant execute on function public.checkout_copy(uuid,uuid,text) to authenticated;
grant execute on function public.return_copy(text,text,bigint) to authenticated;
