-- Jalankan SETELAH migrasi awal dan setelah akun admin dibuat di Supabase Auth.
-- Ganti admin@example.com dengan email akun yang akan menjadi Super Admin pertama.
-- Jalankan hanya sekali pada database baru melalui Supabase SQL Editor.
do $$
declare
  v_admin_id uuid;
  v_org_id uuid;
  v_building_id uuid;
  v_room_id uuid;
  v_shelf_id uuid;
begin
  select id into v_admin_id from auth.users where lower(email) = lower('admin@example.com') limit 1;
  if v_admin_id is null then
    raise exception 'Buat akun admin di Supabase Auth dan ubah email pada bootstrap.sql sebelum menjalankan script ini.';
  end if;

  insert into public.organizations(name, timezone, currency)
  values ('Pustaka Bersama', 'Asia/Jakarta', 'IDR')
  returning id into v_org_id;

  insert into public.profiles(id, organization_id, full_name, role)
  select v_admin_id, v_org_id, coalesce(nullif(raw_user_meta_data->>'full_name',''), 'Admin Pustaka'), 'SUPER_ADMIN'
  from auth.users where id = v_admin_id;

  insert into public.member_categories(organization_id, name, max_total_items) values
    (v_org_id, 'Warga', 2),
    (v_org_id, 'Pengurus', 10),
    (v_org_id, 'Siswa', 3),
    (v_org_id, 'Guru', 10),
    (v_org_id, 'Tamu', 1);

  insert into public.item_categories(organization_id, name, description) values
    (v_org_id, 'Fiksi', 'Novel dan cerita'),
    (v_org_id, 'Pengembangan Diri', 'Pengembangan pribadi dan keterampilan'),
    (v_org_id, 'Sastra', 'Sastra Indonesia dan dunia'),
    (v_org_id, 'Elektronik', 'Perangkat elektronik komunitas'),
    (v_org_id, 'Perkakas', 'Peralatan dan perkakas'),
    (v_org_id, 'Lainnya', 'Koleksi lain');

  insert into public.locations(organization_id, name, level, description)
  values (v_org_id, 'Gedung Utama', 'GEDUNG', 'Lokasi utama Pustaka Bersama')
  returning id into v_building_id;
  insert into public.locations(organization_id, parent_id, name, level)
  values (v_org_id, v_building_id, 'Ruang Koleksi', 'RUANGAN')
  returning id into v_room_id;
  insert into public.locations(organization_id, parent_id, name, level)
  values (v_org_id, v_room_id, 'Rak A', 'RAK')
  returning id into v_shelf_id;

  with defaults(kind, category_name, allowed, loan_days, max_items, max_renewals, renewal_days, fine_rate) as (
    values
      ('BUKU','Warga',true,7,2,1,7,500),
      ('PERALATAN','Warga',true,3,2,1,2,5000),
      ('LAINNYA','Warga',true,2,1,0,0,10000),
      ('BUKU','Pengurus',true,14,10,2,14,500),
      ('PERALATAN','Pengurus',true,3,5,1,2,5000),
      ('LAINNYA','Pengurus',true,3,5,1,2,5000),
      ('BUKU','Siswa',true,7,3,1,7,500),
      ('PERALATAN','Siswa',false,2,0,0,0,5000),
      ('LAINNYA','Siswa',false,7,0,0,0,500),
      ('BUKU','Guru',true,14,10,2,14,500),
      ('PERALATAN','Guru',true,2,1,0,0,5000),
      ('LAINNYA','Guru',true,2,1,0,0,5000),
      ('BUKU','Tamu',true,7,1,0,0,500),
      ('PERALATAN','Tamu',false,2,0,0,0,5000),
      ('LAINNYA','Tamu',false,7,0,0,0,500)
  )
  insert into public.loan_policies(
    organization_id, member_category_id, item_kind, allowed, loan_days,
    max_items, max_renewals, renewal_days, grace_days, fine_rule
  )
  select v_org_id, mc.id, d.kind, d.allowed, d.loan_days, d.max_items,
         d.max_renewals, greatest(d.renewal_days,1), 0,
         jsonb_build_object('type','flat','rate',d.fine_rate,'grace_days',0,'cap',null)
  from defaults d
  join public.member_categories mc on mc.organization_id = v_org_id and mc.name = d.category_name;

  insert into public.notification_templates(organization_id, type, channel, subject, body)
  values
    (v_org_id, 'HOLD_READY', 'EMAIL', 'Koleksi siap diambil', 'Halo {nama}, {judul} sudah tersedia. Silakan ambil sebelum {batas_waktu}.'),
    (v_org_id, 'REMINDER_H2', 'EMAIL', 'Pengingat jatuh tempo', 'Halo {nama}, pinjaman {daftar_judul} jatuh tempo pada {tanggal_jatuh_tempo}.'),
    (v_org_id, 'FINE_OUTSTANDING', 'EMAIL', 'Pengingat tunggakan', 'Halo {nama}, Anda memiliki tunggakan Rp{denda_total}. Hubungi {kontak_admin}.');

  raise notice 'Pustaka Bersama siap. Organization ID: %; lokasi Rak A ID: %', v_org_id, v_shelf_id;
end $$;
