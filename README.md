# Pustaka Bersama

Sistem web manajemen perpustakaan dan peminjaman barang bersama untuk komunitas, sekolah, kantor, atau RT/RW. Bahasa UI: Indonesia; zona waktu bawaan: `Asia/Jakarta`; nilai uang disimpan sebagai bilangan bulat Rupiah.

## Status implementasi

- Dashboard admin, katalog, anggota, meja sirkulasi, reservasi, denda, laporan, pengaturan, dan portal anggota responsif.
- Interaksi UI saat ini menggunakan data demo lokal supaya alur bisa diperiksa tanpa memutasi data nyata.
- Migrasi PostgreSQL awal mencakup tabel domain, constraint anti-peminjaman ganda, perhitungan denda, fungsi checkout/return transaksional, RLS berbasis organisasi, dan audit log append-only.
- Data demo UI **belum sinkron dengan Supabase**. Jangan gunakan untuk transaksi operasional sampai proyek Supabase dibuat, migrasi/bootstrap diterapkan, autentikasi dan adapter data diintegrasikan, dan pengujian penerimaan dijalankan.

## Stack

- Next.js App Router + TypeScript
- Tailwind tidak diperlukan untuk styling saat ini; stylesheet berada di `app/globals.css`
- Supabase PostgreSQL / Auth (`@supabase/ssr`, `@supabase/supabase-js`)
- Vercel (konfigurasi dasar ada di `vercel.json`)

## Menjalankan secara lokal

1. Gunakan Node.js 20 atau yang lebih baru.
2. Pasang dependensi dengan `npm install`.
3. Salin `.env.example` menjadi `.env.local`. UI demo dapat berjalan tanpa kredensial; koneksi database tidak aktif sampai variabel Supabase diisi.
4. Jalankan `npm run dev`, lalu buka `http://localhost:3000`.
5. Sebelum rilis, jalankan `npm run typecheck`, `npm run lint`, dan `npm run build`.

## Supabase

1. Buat proyek Supabase di organisasi yang disepakati.
2. Terapkan `supabase/migrations/202610130001_initial_schema.sql` **satu kali** melalui SQL Editor atau Supabase CLI.
3. Buat akun admin awal melalui Supabase Auth, lalu sesuaikan email di `supabase/bootstrap.sql` dan jalankan script bootstrap melalui SQL Editor. Script ini membuat organisasi, profil Super Admin, kategori anggota, kategori koleksi, lokasi awal, dan kebijakan pinjam contoh.
4. Isi variabel di `.env.local`:

   ```dotenv
   NEXT_PUBLIC_SUPABASE_URL=https://PROJECT_REF.supabase.co
   NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
   ```

   `NEXT_PUBLIC_SUPABASE_ANON_KEY` tetap didukung untuk key lama. Jangan pernah menaruh `service_role` atau `sb_secret` di variabel `NEXT_PUBLIC_*` atau di kode browser.
5. Jalankan pemeriksaan keamanan/performa Supabase setelah migrasi. Verifikasi bahwa `profiles.role` dan `profiles.organization_id` hanya dapat dikelola lewat jalur administrasi tepercaya.

> Migrasi SQL telah disiapkan untuk ditinjau. Uji di proyek non-produksi terlebih dahulu sebelum memasukkan data nyata.

## Vercel

- Impor repository `Nawfal30/Perpustakaan` sebagai proyek Next.js.
- Atur `NEXT_PUBLIC_SUPABASE_URL` dan `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` di Project Settings → Environment Variables untuk Production/Preview/Development yang sesuai.
- Deploy preview terlebih dahulu. Setelah tes berhasil, promosikan ke produksi.
- Jika repository terhubung ke Git, push ke branch production akan memicu deployment otomatis. Secret tetap disimpan di pengaturan Vercel, tidak di commit.

## Cakupan yang masih perlu diselesaikan sebelum MVP produksi

- Halaman login/lupa password dan RBAC end-to-end.
- Mengganti mutasi lokal demo dengan query/RPC Supabase pada seluruh layar.
- Worker terjadwal untuk kedaluwarsa hold, outbox email, reminder H-2/H-1/hari-H, dan pemeriksaan integritas.
- Provider email transaksional, impor CSV, cetak label barcode/QR, ekspor PDF/Excel.
- Integration tests untuk concurrency checkout/kuota/antrian, E2E Playwright, uji backup/restore, serta UAT lokasi pilot.

Rincian kebutuhan produk tetap merujuk ke PRD **Sistem Manajemen Perpustakaan & Peminjaman Barang Komunitas**.
