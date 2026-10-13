# Checklist konfigurasi layanan

## GitHub

- Repository target: `Nawfal30/Perpustakaan` (branch `main` saat diperiksa kosong).
- Konektor GitHub yang tersedia dapat membaca repository, tetapi penulisan file ditolak API dengan `403 Resource not accessible by integration`.
- Setelah integrasi GitHub diotorisasi untuk menulis, unggah isi arsip proyek ini ke root repo, commit ke branch, lalu verifikasi workflow CI.

## Supabase

- Organisasi yang terlihat pada akun terhubung: `Faiz` (`gjcznnwvklnyulqmuxcy`).
- Estimasi biaya proyek baru yang dikembalikan Supabase: `$0/month` (estimasi saat dicek; konfirmasi billing di dashboard sebelum operasional).
- Proyek Supabase belum dibuat. Pembuatan memerlukan konfirmasi eksplisit organisasi dan biaya.
- Urutan: buat proyek → tunggu status siap → jalankan `supabase/migrations/202610130001_initial_schema.sql` → buat user admin melalui Auth → edit email di `supabase/bootstrap.sql` → jalankan bootstrap → ambil project URL dan publishable key → set env lokal/Vercel → jalankan Security Advisor dan uji integritas.

## Vercel

- Akun terhubung berada pada paket Hobby, tetapi pembuatan proyek lewat konektor gagal dengan `403 forbidden` pada scope personal yang meminta autentikasi ulang.
- Setelah otorisasi Vercel dipulihkan, impor `Nawfal30/Perpustakaan` sebagai proyek Next.js dan set region function `sin1` (Singapore) bila diinginkan.
- Environment variables: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, `NEXT_PUBLIC_APP_URL`.
- Setelah variabel dan migrasi tersedia, deploy preview, tes, lalu promosikan ke production.

## Validasi sebelum produksi

- [ ] `npm install`
- [ ] `npm run typecheck`
- [ ] `npm run lint`
- [ ] `npm run test:schema`
- [ ] `npm run build`
- [ ] Test integration PostgreSQL untuk checkout, return, denda, FIFO hold, RLS isolation, dan concurrency.
- [ ] Auth/RBAC end-to-end dan data adapter Supabase menggantikan seluruh interaksi demo.
- [ ] Backup/restore drill, provider email, dan UAT lokasi pilot.
