- [ ]

  # PRD — Sistem Manajemen Perpustakaan & Peminjaman Barang Komunitas

Versi 0.1 (draft) · 13 Oktober 2026 · Nama kerja: "Pustaka Bersama"

## 1. Ringkasan

Pustaka Bersama adalah web app untuk mengelola barang pinjam-pakai bersama (buku perpustakaan dan barang komunal seperti perkakas, proyektor, tenda) di komunitas, sekolah, kantor, atau RT/RW. Sistem menggantikan buku catatan/spreadsheet dengan pencatatan per eksemplar yang terlacak, deteksi keterlambatan otomatis, denda terhitung otomatis, dan antrian reservasi yang adil.

**Prinsip desain:**

- **Rule-based, tanpa AI/LLM.** Semua keputusan (denda, antrian, batas pinjam, reminder) berasal dari aturan terkonfigurasi dan scheduled job yang deterministik dan bisa diaudit.
- **Integritas data di level database.** Aturan kritis (satu eksemplar tidak boleh dipinjam dua orang) dijaga oleh constraint database, bukan hanya oleh kode aplikasi.
- **Admin-first.** Alur kasir/meja sirkulasi harus cepat (target < 30 detik per transaksi dengan scanner). Self-service datang belakangan.
- **Sederhana untuk dioperasikan.** Satu database, satu aplikasi, satu worker; bisa dijalankan di satu VPS kecil.

## 2. Tujuan, Non-Tujuan, dan Metrik Sukses

**Tujuan**

1. Setiap eksemplar punya identitas unik (barcode/QR), status, dan lokasi yang selalu diketahui.
2. Semua peminjaman/pengembalian tercatat dengan siapa, kapan, dan kondisi.
3. Keterlambatan terdeteksi otomatis dan peminjam diingatkan sebelum dan sesudah jatuh tempo.
4. Barang populer dibagikan lewat antrian FIFO yang transparan.
5. Pengurus bisa melihat laporan sirkulasi, tunggakan, dan barang yang "hilang jejak" tanpa rekap manual.

**Non-tujuan (di luar lingkup)**

- Fitur AI/LLM, rekomendasi buku berbasis ML, atau chatbot.
- Pengadaan/pembelian, akuntansi penuh, atau manajemen aset tetap (penyusutan).
- Peminjaman uang, sewa komersial, atau barang habis pakai (consumable).
- Aplikasi native iOS/Android (cukup web responsif).

**Metrik sukses (target awal, dikalibrasi setelah baseline 1–2 bulan)**

- ≥ 95% transaksi sirkulasi tercatat di sistem (bukan di buku/spreadsheet lama).
- Waktu rata-rata checkout/return oleh admin < 30 detik.
- Rasio keterlambatan turun ≥ 30% dalam 3 bulan setelah reminder aktif.
- Barang berstatus "tidak diketahui keberadaannya" turun mendekati 0 setelah stock opname pertama.
- 0 kasus satu eksemplar tercatat dipinjam dua orang (diverifikasi lewat concurrency test dan query integritas).

## 3. Pengguna dan Peran

- **Super Admin** — konfigurasi organisasi, kebijakan, manajemen staf, akses penuh.
- **Admin/Petugas Sirkulasi** — katalog, anggota, peminjaman, pengembalian, denda, reservasi.
- **Pengurus (read-only)** — hanya melihat dashboard dan laporan.
- **Anggota** — login ke portal anggota: cari katalog, reservasi, lihat pinjaman/denda/riwayat sendiri. Anggota boleh **tanpa akun** (mis. warga tanpa email); mereka dilayani sepenuhnya lewat admin.
- **Kategori anggota** (konfigurabel): siswa, guru, warga, tamu, dan lainnya. Ini bukan peran sistem, melainkan penentu aturan pinjam.

## 4. Asumsi dan Target Skala

Karena target belum ditentukan, rekomendasi saya:

- **Satu organisasi per instalasi** pada MVP (satu sekolah/kantor/RW), namun skema database memuat `organization_id` sejak awal agar bisa multi-organisasi nanti tanpa migrasi besar.
- **Skala desain (dengan ruang tumbuh):** hingga 5.000 anggota, 50.000 eksemplar, \~500 transaksi sirkulasi/hari, \~20 pengguna aktif bersamaan.
- **Skala tipikal awal:** 100–1.000 anggota, 500–5.000 eksemplar, < 100 transaksi/hari.
- Dengan skala ini, satu server dan satu PostgreSQL sudah sangat memadai; tidak perlu microservices, Elasticsearch, atau cache terdistribusi.
- **Zona waktu:** disimpan UTC, ditampilkan sesuai zona organisasi (WIB/WITA/WIT, default Asia/Jakarta). Jatuh tempo berbasis tanggal dan berakhir pukul 23:59 waktu lokal.
- **Mata uang:** Rupiah, disimpan sebagai bilangan bulat (tanpa float).
- **Bahasa UI:** Indonesia, dengan struktur i18n agar mudah ditambah.
- **Konektivitas:** meja sirkulasi diasumsikan punya internet stabil. Mode offline di luar lingkup (lihat Risiko).

## 5. Pembagian MVP dan Fase Lanjutan

**Fase 1 — MVP (perkiraan 8–12 minggu untuk 1–2 developer; estimasi kasar)**

- Autentikasi, RBAC, audit log.
- Master data: kategori barang, lokasi bertingkat (gedung → ruangan → rak), kategori anggota, kebijakan pinjam.
- Katalog: judul/jenis barang, banyak eksemplar, status per eksemplar, kode unik, cetak label barcode/QR (PDF), auto-fill ISBN.
- Anggota: CRUD, kategori, suspend/blokir, riwayat.
- Sirkulasi oleh admin: pinjam, kembali, perpanjang; mendukung scanner USB/Bluetooth (berperilaku seperti keyboard).
- Reservasi, antrian FIFO, hold dengan window klaim.
- Denda otomatis, pencatatan pembayaran manual, blokir pinjam saat ada tunggakan.
- Notifikasi **email**: reminder H-2/H-1, barang reservasi siap, tunggakan.
- Dashboard dasar: pinjaman aktif, daftar terlambat, barang paling populer.
- **Impor CSV** data lama (katalog, anggota, pinjaman aktif) agar migrasi dari spreadsheet realistis.
- Portal anggota dasar (login, cari, reservasi, lihat pinjaman/denda).

**Fase 2 — Operasional matang**

- Notifikasi WhatsApp.
- Scan barcode lewat kamera HP (web).
- Laporan lengkap dan tren (grafik mingguan/bulanan), ekspor Excel/PDF.
- Stock opname (pencocokan fisik dengan sistem lewat scan).
- Kalender hari libur untuk perhitungan denda, cetak label massal, impor anggota massal.
- Checklist kelengkapan dan kondisi barang saat pinjam/kembali (mis. proyektor + kabel + remote), foto kondisi.
- Aturan auto-suspend (mis. terlambat > N hari).

**Fase 3 — Ekspansi**

- Mode kiosk self-service dan peminjaman mandiri oleh anggota.
- Integrasi payment gateway (QRIS via penyedia lokal).
- Booking berbasis tanggal/kalender untuk barang komunal (mis. tenda untuk acara tertentu).
- Multi-cabang/multi-organisasi, OPAC publik, SSO (mis. Google Workspace sekolah), PWA offline.

## 6. Kebutuhan Fungsional

### 6.1 Katalog dan Inventaris

- **FR-CAT-01** Entitas **Item Type** (judul/jenis barang) dan **Copy** (eksemplar fisik). Banyak copy per item type.
- **FR-CAT-02** Setiap copy punya kode unik (barcode Code 128 dan/atau QR) yang dibuat sistem; bisa juga memakai kode yang sudah ditempel. Kode unik per organisasi.
- **FR-CAT-03** Item type punya jenis (`BUKU`, `PERALATAN`, `LAINNYA`), kategori (hierarki), deskripsi, foto sampul/produk, dan atribut tambahan fleksibel (JSONB) sesuai jenis.
- **FR-CAT-04** Auto-fill metadata dari ISBN: Open Library lebih dulu, Google Books sebagai cadangan. Hasil disimpan di cache lokal dan selalu bisa diedit manual. Kegagalan API tidak boleh menghalangi input manual.
- **FR-CAT-05** Status copy: `TERSEDIA`, `DIPINJAM`, `DITAHAN` (hold untuk antrian), `RUSAK`, `DALAM_PERBAIKAN`, `HILANG`, `DITARIK` (dikeluarkan dari koleksi). Setiap perubahan status tercatat (siapa, kapan, alasan).
- **FR-CAT-06** Lokasi bertingkat (gedung → ruangan → rak); copy punya lokasi "rumah" dan admin bisa memindahkannya.
- **FR-CAT-07** Pencarian katalog (judul, penulis, ISBN, kode, kategori) memakai full-text search PostgreSQL + trigram agar toleran salah ketik.
- **FR-CAT-08** Kebijakan akses: item type/kategori dapat dibatasi untuk kategori anggota tertentu (mis. perkakas hanya untuk warga dan pengurus).

### 6.2 Peminjaman dan Pengembalian

- **FR-LOAN-01** Admin memindai kode anggota lalu kode copy untuk mencatat pinjaman; satu transaksi bisa berisi beberapa copy.
- **FR-LOAN-02** Sistem memvalidasi sebelum pinjam: anggota aktif dan tidak disuspend, keanggotaan belum kedaluwarsa, tidak ada denda di atas batas, kuota belum penuh, kategori anggota berhak, copy berstatus `TERSEDIA` (atau `DITAHAN` untuk anggota yang berhak). Alasan penolakan ditampilkan jelas; admin dengan izin khusus dapat **override** dengan alasan wajib (tercatat di audit).
- **FR-LOAN-03** Durasi pinjam, kuota, dan batas perpanjangan ditentukan oleh **kebijakan pinjam** per kombinasi kategori anggota × kategori/jenis barang.
- **FR-LOAN-04** Perpanjangan: ditolak bila batas perpanjangan tercapai, ada antrian reservasi untuk judul tersebut, anggota punya denda/disuspend, atau (konfigurabel) pinjaman sudah terlambat. Perpanjangan dihitung dari tanggal jatuh tempo lama atau hari ini (konfigurabel).
- **FR-LOAN-05** Pengembalian: pindai copy saja (anggota ditemukan dari pinjaman aktif). Sistem menghitung denda, menanyakan kondisi barang (baik/rusak), lalu mengubah status copy sesuai aturan reservasi (lihat 6.3).
- **FR-LOAN-06** Pelaporan hilang: admin menandai pinjaman `HILANG`; copy menjadi `HILANG`; denda penggantian dapat dibuat (nilai default dari harga copy, dapat diedit).
- **FR-LOAN-07** Jika copy yang "hilang" kemudian ditemukan, admin dapat memulihkannya, dengan pembalikan denda yang tercatat sebagai penyesuaian (bukan penghapusan).

### 6.3 Reservasi dan Antrian

- **FR-RES-01** Reservasi dilakukan pada level **item type** (judul/jenis), bukan copy spesifik. Anggota hanya bisa reservasi jika tidak ada copy yang `TERSEDIA`.
- **FR-RES-02** Antrian FIFO per item type, diurutkan berdasarkan waktu antri; satu anggota maksimal satu reservasi aktif per item type, dan ada batas jumlah reservasi aktif per anggota (konfigurabel).
- **FR-RES-03** Saat sebuah copy dikembalikan dan antrian tidak kosong, copy otomatis menjadi `DITAHAN` untuk antrian pertama dan reservasi berubah menjadi `SIAP_DIAMBIL` dengan `hold_expires_at` (default 48 jam, konfigurabel) — semuanya dalam satu transaksi database yang sama dengan pengembalian.
- **FR-RES-04** Notifikasi dikirim saat hold dibuat. Bila anggota tidak mengambil sampai `hold_expires_at`, scheduled job menandai reservasi `KEDALUWARSA`, lalu hold berpindah ke antrian berikutnya (atau copy kembali `TERSEDIA` jika antrian kosong).
- **FR-RES-05** Anggota dapat membatalkan reservasi; pembatalan pada status `SIAP_DIAMBIL` juga meneruskan hold ke antrian berikutnya.
- **FR-RES-06** Selama copy `DITAHAN`, hanya pemegang hold yang bisa meminjamnya (admin dapat override dengan alasan). Pinjaman oleh pemegang hold mengubah reservasi menjadi `TERPENUHI`.
- **FR-RES-07** Admin dapat membuat reservasi atas nama anggota yang tidak punya akun.

### 6.4 Denda dan Kebijakan

- **FR-FINE-01** Aturan denda per kebijakan: **flat per hari** atau **bertingkat** (mis. hari 1–7 Rp500/hari, hari 8+ Rp1.000/hari), masa tenggang (grace period) dalam hari, dan batas maksimum denda per pinjaman (mis. tidak melebihi harga barang).
- **FR-FINE-02** Denda dihitung dari selisih hari keterlambatan secara deterministik. Saat pinjaman masih terlambat, sistem menampilkan **estimasi berjalan**; denda resmi dicatat saat pengembalian atau penandaan hilang.
- **FR-FINE-03** Denda adalah entri tersendiri (buku besar sederhana): `fines` dengan status `BELUM_BAYAR`, `SEBAGIAN`, `LUNAS`, `DIHAPUSKAN`. Penghapusan denda (waive) memerlukan izin dan alasan.
- **FR-FINE-04** Pembayaran dicatat manual oleh admin (jumlah, metode, tanggal, catatan, bukti opsional). Satu pembayaran boleh mencakup beberapa denda; pembayaran sebagian didukung. Payment gateway adalah opsi Fase 3 lewat antarmuka `PaymentProvider`.
- **FR-FINE-05** Pembatasan: total tunggakan melebihi ambang (default Rp0, konfigurabel) memblokir pinjaman baru dan perpanjangan. Pengembalian tetap selalu boleh.
- **FR-FINE-06** Struk/bukti pembayaran dapat dicetak atau disimpan sebagai PDF.

### 6.5 Manajemen Anggota

- **FR-MEM-01** Profil: nama, nomor anggota, kategori, kontak (email, WhatsApp), foto opsional, masa berlaku, status (`AKTIF`, `DISUSPEND`, `DIBLOKIR`, `NONAKTIF`), catatan internal.
- **FR-MEM-02** Riwayat lengkap: pinjaman, perpanjangan, keterlambatan, denda, pembayaran, dan perubahan status.
- **FR-MEM-03** Suspend/blokir oleh admin dengan alasan, masa berlaku opsional, dan tercatat di audit. Anggota disuspend tidak bisa pinjam/reservasi/perpanjang, tetapi tetap bisa mengembalikan dan melunasi denda.
- **FR-MEM-04** Kartu anggota dengan QR/barcode (cetak PDF).
- **FR-MEM-05** Pendaftaran: oleh admin (MVP) atau pendaftaran mandiri dengan persetujuan admin.

### 6.6 Notifikasi dan Reminder

- **FR-NOT-01** Reminder sebelum jatuh tempo (H-2, H-1) dan pada hari jatuh tempo; notifikasi terlambat berkala (mis. H+1, H+7, H+14, konfigurabel).
- **FR-NOT-02** Notifikasi reservasi siap diambil, pengingat 12 jam sebelum hold berakhir, dan pemberitahuan hold berakhir.
- **FR-NOT-03** Notifikasi tunggakan denda berkala (konfigurabel).
- **FR-NOT-04** Template pesan dapat diedit admin dengan variabel (nama, judul, tanggal jatuh tempo).
- **FR-NOT-05** Anggota tanpa kontak valid masuk ke daftar "perlu dihubungi manual" di dashboard admin.
- **FR-NOT-06** Semua notifikasi lewat **outbox** (tabel `notifications`) dengan kunci deduplikasi sehingga job yang berjalan ulang tidak mengirim pesan ganda; status pengiriman dan kegagalan terlihat oleh admin.

### 6.7 Dashboard dan Laporan

- **FR-RPT-01** Dashboard: pinjaman aktif, jatuh tempo hari ini/minggu ini, terlambat, reservasi menunggu, copy bermasalah (rusak/hilang/perbaikan).
- **FR-RPT-02** Statistik: judul/barang paling populer, kategori paling diminati, anggota paling aktif, per periode.
- **FR-RPT-03** Laporan keterlambatan dan rekap denda (ditagih, dibayar, dihapuskan, outstanding) per periode.
- **FR-RPT-04** Tren peminjaman mingguan/bulanan (grafik).
- **FR-RPT-05** Daftar **tindak lanjut manual**: pinjaman terlambat melebihi ambang (default 30 hari, konfigurabel) dengan kontak anggota dan riwayat notifikasi.
- **FR-RPT-06** Ekspor Excel/PDF (Fase 2).

## 7. Aturan Bisnis dan State Machine

Status **eksemplar** dan status **pinjaman** dipisah agar model tetap konsisten. "Telat" bukan status eksemplar, melainkan kondisi pinjaman.

**Status Copy**

- `TERSEDIA` → `DIPINJAM` (checkout)
- `DIPINJAM` → `TERSEDIA` (kembali, antrian kosong, kondisi baik)
- `DIPINJAM` → `DITAHAN` (kembali, ada antrian)
- `DIPINJAM` → `RUSAK` (kembali dalam kondisi rusak) atau `HILANG` (dilaporkan hilang)
- `DITAHAN` → `DIPINJAM` (diambil pemegang hold) atau → `DITAHAN` untuk antrian berikutnya / `TERSEDIA` (hold kedaluwarsa)
- `RUSAK` → `DALAM_PERBAIKAN` → `TERSEDIA` atau `DITARIK`
- `HILANG` → `TERSEDIA` (ditemukan) atau `DITARIK`
- Transisi di luar daftar ini ditolak oleh lapisan domain.

**Status Pinjaman**

- `AKTIF` → `DIKEMBALIKAN` | `HILANG`
- **Terlambat** diturunkan secara hitungan: `due_at < sekarang AND returned_at IS NULL`. Karena diturunkan, sistem tetap benar walaupun scheduled job tertunda; job hanya mengirim notifikasi dan membuat tanda tindak lanjut.

**Status Reservasi**

- `MENUNGGU` → `SIAP_DIAMBIL` → `TERPENUHI` | `KEDALUWARSA` | `DIBATALKAN`; `MENUNGGU` → `DIBATALKAN`.

**Aturan lintas-fitur**

- Jika antrian suatu judul tidak kosong, copy yang `TERSEDIA` tidak dapat dipinjam walk-in kecuali jumlah copy tersedia melebihi jumlah reservasi `SIAP_DIAMBIL` (praktisnya, copy yang dikembalikan langsung berstatus `DITAHAN`, jadi aturan ini otomatis terpenuhi).
- Hold kedaluwarsa tidak menghilangkan hak antri di masa depan, tetapi anggota masuk ke ujung antrian bila reservasi ulang. Batas "gagal klaim" sebelum kena penalti dapat dikonfigurasi (opsional).
- Semua perubahan status menghasilkan baris di `audit_logs` (aktor, waktu, nilai sebelum/sesudah, alasan).

## 8. Model Data Tingkat Tinggi

Entitas utama (semua memuat `organization_id`, `created_at`, `updated_at`):

- **organizations** — nama, zona waktu, pengaturan global.
- **users** — akun login (staf maupun anggota), email, password hash, peran.
- **members** — profil anggota; `user_id` opsional (anggota boleh tanpa akun), `member_category_id`, nomor anggota unik, status, masa berlaku.
- **member\_categories** — siswa, guru, warga, tamu, dst.
- **item\_categories** — hierarki kategori barang.
- **locations** — hierarki gedung → ruangan → rak.
- **item\_types** — judul/jenis barang: `kind`, judul, deskripsi, `category_id`, `isbn` (nullable), atribut JSONB, cover.
- **book\_metadata** (opsional, 1:1 dengan item\_types) — penulis, penerbit, tahun, bahasa, jumlah halaman.
- **isbn\_cache** — respons API publik per ISBN dengan sumber dan waktu ambil.
- **item\_copies** — `item_type_id`, `barcode` (unik), `status`, `location_id`, kondisi, tanggal/harga perolehan, `version` (untuk optimistic locking).
- **loan\_policies** — `member_category_id` × `item_category_id/kind` → durasi hari, kuota, maks perpanjangan, durasi perpanjangan, aturan denda (referensi atau JSON terversi), apakah boleh.
- **loans** — `copy_id`, `member_id`, `checked_out_at`, `due_at`, `returned_at`, `renewal_count`, `status`, `condition_out/in`, `processed_by`, **snapshot kebijakan** yang berlaku saat transaksi.
- **loan\_events** — checkout, renew, return, mark\_lost, override (histori pinjaman).
- **reservations** — `item_type_id`, `member_id`, `status`, `queued_at`, `ready_at`, `hold_expires_at`, `held_copy_id`.
- **fines** — `loan_id`, `member_id`, jenis (terlambat/hilang/rusak), `amount`, `amount_paid`, status, alasan waive.
- **payments** dan **payment\_allocations** — pembayaran dan alokasinya ke denda.
- **notifications** — outbox: tipe, kanal, penerima, payload, `dedupe_key` (unik), status, percobaan, `sent_at`, error.
- **notification\_templates**, **audit\_logs** (append-only), **job\_runs**, **holidays**, **settings**.

**Relasi kunci:** item\_type 1—N copy; copy 1—N loan (histori); anggota 1—N loan/reservation/fine; loan 1—N fine; payment N—N fine lewat allocation.

**Indeks penting:** unik `(organization_id, barcode)`; parsial unik `loans(copy_id) WHERE returned_at IS NULL`; `loans(due_at) WHERE returned_at IS NULL`; `reservations(item_type_id, queued_at) WHERE status IN ('MENUNGGU','SIAP_DIAMBIL')`; `notifications(dedupe_key)` unik; trigram/GIN untuk pencarian.

## 9. Pertimbangan Teknis: Concurrency

**Tujuan:** dua anggota (atau dua admin, atau satu admin yang memindai dua kali) tidak boleh sama-sama berhasil memproses copy yang sama.

Strategi berlapis (pertahanan paling akhir selalu database):

1. **Constraint database sebagai penjaga mutlak.** Indeks parsial unik `loans(copy_id) WHERE returned_at IS NULL` menjamin maksimal satu pinjaman terbuka per copy. Jika dua transaksi balapan, salah satunya gagal dengan unique violation dan diterjemahkan menjadi pesan "barang sudah dipinjam".
2. **Transaksi tunggal + row lock.** Checkout berjalan dalam satu transaksi: `SELECT ... FROM item_copies WHERE id = $1 FOR UPDATE`, validasi status, insert loan, update status copy, tulis event dan audit. Commit atau rollback sepenuhnya.
3. **Update bersyarat.** `UPDATE item_copies SET status='DIPINJAM', version=version+1 WHERE id=$1 AND status IN ('TERSEDIA','DITAHAN')` dan cek jumlah baris terpengaruh; 0 baris berarti gagal.
4. **Kuota anggota diserialkan.** Dua checkout paralel untuk anggota yang sama bisa sama-sama lolos cek kuota. Karena itu transaksi mengunci baris `members` (`FOR UPDATE`) sebelum menghitung pinjaman aktif. Urutan lock selalu sama (member lalu copy, copy diurutkan menurut id) untuk menghindari deadlock.
5. **Pengembalian dan antrian atomik.** Dalam transaksi return: kunci copy, tutup loan, pilih reservasi terdepan dengan `SELECT ... WHERE status='MENUNGGU' ORDER BY queued_at, id LIMIT 1 FOR UPDATE SKIP LOCKED`, ubah menjadi `SIAP_DIAMBIL`, set copy `DITAHAN`. Dua pengembalian bersamaan dari judul yang sama tidak akan memberi hold ke reservasi yang sama.
6. **Scheduled job idempoten dan aman paralel.** Job kedaluwarsa hold memakai `FOR UPDATE SKIP LOCKED`, memproses per batch kecil, dan aman dijalankan dua kali.
7. **Idempotency key** pada endpoint mutasi (checkout, return, bayar) untuk menahan double-click/double-scan dan retry jaringan.
8. **Isolation level.** `READ COMMITTED` + lock eksplisit di atas sudah cukup; transaksi kritis diberi retry untuk serialization/deadlock error.
9. **Pengujian.** Wajib ada integration test yang menembakkan N request paralel ke copy yang sama (hasil: tepat satu sukses), kuota paralel, dan antrian paralel; serta query integritas berkala (mis. copy `DIPINJAM` tanpa loan terbuka).

Tampilan UI tidak pernah dianggap sumber kebenaran: status yang terlihat di layar bisa basi, sehingga server selalu memvalidasi ulang.

## 10. Scheduled Jobs

Worker terpisah dari proses web memakai antrian job berbasis PostgreSQL. Semua job idempoten dan mencatat `job_runs`.

- **Tiap 5–15 menit:** kedaluwarsakan hold yang lewat `hold_expires_at` lalu teruskan ke antrian berikutnya; kirim notifikasi dari outbox (dengan retry dan backoff).
- **Harian (pagi, mis. 07:00 waktu organisasi):** buat notifikasi H-2, H-1, hari-H, dan terlambat; pengingat tunggakan; tandai pinjaman melewati ambang tindak lanjut; tandai keanggotaan kedaluwarsa.
- **Harian (malam):** pemeriksaan integritas data, ringkasan statistik untuk dashboard bila perlu, backup database.

## 11. Rekomendasi Tech Stack

Preferensi Next.js/Node.js cocok untuk skala ini. Rekomendasi:

- **Aplikasi:** Next.js (App Router) + TypeScript, satu codebase untuk UI admin, portal anggota, dan API (Route Handlers/Server Actions). Logika domain (sirkulasi, denda, antrian) ditaruh di modul layanan terpisah yang tidak bergantung pada Next.js, agar mudah diuji dan dipindah ke backend terpisah (mis. NestJS) bila tim membesar.
- **Database:** PostgreSQL 16+ (wajib untuk partial unique index, row lock, `SKIP LOCKED`, JSONB, full-text/trigram).
- **ORM/migrasi:** Prisma atau Drizzle; gunakan SQL mentah untuk query lock kritis.
- **Job/scheduler:** **pg-boss** (berbasis Postgres, tanpa Redis tambahan) sebagai worker Node terpisah. BullMQ + Redis adalah alternatif bila nanti butuh throughput lebih besar.
- **Auth:** Auth.js atau library sesi sederhana; password di-hash dengan argon2/bcrypt; RBAC di server; rate limiting login.
- **UI:** Tailwind CSS + komponen (shadcn/ui), tabel dan form dengan validasi Zod.
- **Barcode/QR:** pembuatan label dengan `bwip-js`/`qrcode` ke PDF; scanner USB memerlukan input teks fokus (tidak perlu library); scan kamera Fase 2 dengan `@zxing/browser` atau `html5-qrcode`.
- **Email:** SMTP atau penyedia seperti Resend/Postmark/Amazon SES. **WhatsApp (Fase 2):** WhatsApp Business Platform resmi lewat penyedia (pesan template, ada biaya per percakapan); hindari gateway tidak resmi karena risiko nomor diblokir. Abstraksikan lewat antarmuka `NotificationChannel`.
- **Ekspor:** `exceljs` (Excel), `pdfmake`/`@react-pdf/renderer` (PDF).
- **Observabilitas:** log terstruktur (pino), error tracking (Sentry opsional), health check endpoint.
- **Deploy:** Docker Compose di satu VPS (app, worker, Postgres, reverse proxy Caddy/Nginx dengan HTTPS). Backup harian `pg_dump` ke penyimpanan eksternal, PITR opsional. Bila lebih suka managed, Vercel + Neon/Supabase untuk app/DB dengan worker di layanan terpisah (perhatikan: scheduled job panjang tidak cocok di serverless murni).
- **Pengujian:** Vitest untuk logika domain, integration test dengan Postgres nyata (Testcontainers) untuk concurrency, Playwright untuk alur utama.

## 12. Kebutuhan Non-Fungsional

- **Performa:** checkout/return p95 < 1 detik; pencarian katalog p95 < 500 ms pada 50.000 copy.
- **Ketersediaan:** target 99% pada jam operasional; RPO ≤ 24 jam, RTO ≤ 4 jam.
- **Keamanan:** HTTPS, RBAC, proteksi CSRF/XSS, rate limiting, secret di environment, audit log tak dapat diubah dari UI, sesi dengan masa berlaku.
- **Privasi:** patuhi prinsip UU PDP (UU No. 27 Tahun 2022): kumpulkan data seperlunya, dapatkan persetujuan untuk notifikasi WhatsApp/email, sediakan kebijakan retensi (mis. anonimkan riwayat anggota nonaktif setelah N tahun) dan kemampuan menghapus/anonimkan atas permintaan, tanpa merusak statistik agregat.
- **Aksesibilitas dan perangkat:** web responsif (desktop admin, ponsel anggota), kontras dan navigasi keyboard memadai untuk meja sirkulasi.
- **Data finansial:** bilangan bulat Rupiah; denda dan pembayaran tidak pernah dihapus, hanya dikoreksi dengan entri penyesuaian.
- **Kemudahan operasi:** konfigurasi lewat UI (kebijakan, template, ambang), bukan kode.

## 13. Risiko dan Mitigasi

- **Adopsi rendah / kebiasaan manual.** Mitigasi: impor CSV, alur scan super cepat, pelatihan singkat, masa transisi paralel 2–4 minggu.
- **Pelabelan ribuan barang memakan waktu.** Mitigasi: cetak label massal, impor kode eksisting, prioritaskan barang bernilai/populer lebih dulu.
- **Internet meja sirkulasi putus.** MVP tidak offline; mitigasi dengan prosedur cadangan (catat manual lalu input susulan) dan evaluasi PWA offline di Fase 3.
- **WhatsApp berbayar atau diblokir.** Mitigasi: email sebagai kanal utama MVP, WhatsApp resmi di Fase 2, fallback daftar "hubungi manual".
- **API ISBN tidak lengkap untuk buku Indonesia.** Mitigasi: dua sumber, edit manual, cache lokal.
- **Konflik kebijakan (denda, hold) dengan kebiasaan komunitas.** Mitigasi: semua parameter konfigurabel dan kebijakan disalin sebagai snapshot ke setiap pinjaman agar perubahan aturan tidak mengubah riwayat.
- **Barang komunal butuh booking tanggal, bukan antrian.** Mitigasi: konfirmasi kebutuhan di awal; model reservasi dibuat cukup terpisah agar booking kalender bisa ditambahkan.

## 14. Rencana Rilis

1. **Minggu 1–2:** fondasi (auth, RBAC, skema DB, master data), desain UI inti, keputusan kebijakan awal.
2. **Minggu 3–5:** katalog, copy, label, ISBN, anggota, impor CSV.
3. **Minggu 6–8:** sirkulasi, kebijakan, denda, pembayaran, concurrency test.
4. **Minggu 9–10:** reservasi/antrian, worker dan scheduled jobs, notifikasi email.
5. **Minggu 11–12:** dashboard dasar, portal anggota, UAT dengan data nyata, pilot di satu lokasi.

## 15. Asumsi yang Perlu Dikonfirmasi

1. Apakah barang komunal (mis. tenda, proyektor) perlu **booking per tanggal** untuk acara tertentu, atau cukup antrian FIFO? (Default: antrian di MVP.)
2. Satu organisasi per instalasi, atau sejak awal melayani beberapa organisasi/RT sekaligus? (Default: satu, skema siap multi-organisasi.)
3. Berapa jumlah anggota, barang, dan transaksi per hari yang realistis? (Default: lihat Bagian 4.)
4. Apakah semua anggota punya email/WhatsApp? Apakah anggota tanpa akun perlu dilayani sepenuhnya oleh admin? (Default: ya, boleh tanpa akun.)
5. Apakah durasi pinjam perlu satuan jam (mis. proyektor 4 jam) atau cukup hari? (Default: hari; jam di fase lanjutan.)
6. Apakah denda berlaku untuk semua jenis barang, termasuk perkakas dan peralatan, dan apakah ada denda kerusakan? (Default: ya, dikonfigurasi per kebijakan.)
7. Berapa lama data riwayat anggota boleh disimpan setelah tidak aktif? (Default: 3 tahun lalu dianonimkan.)
8. Siapa yang berwenang menghapuskan denda atau melakukan override? (Default: Super Admin, dengan alasan wajib.)
9. Apakah WhatsApp wajib di MVP atau cukup email dulu? (Default: email dulu.)

## 16. Persona dan Alur Pengguna

**Persona**

- **Bu Rina, petugas perpustakaan sekolah.** Melayani 30–80 transaksi per hari, terutama saat jam istirahat. Butuh alur scan cepat dan pesan error yang jelas. Tidak teknis.
- **Pak Dedi, pengurus RT/RW.** Mengelola perkakas, tenda, dan proyektor. Ingin tahu siapa memegang barang apa dan kapan harus kembali; sering bekerja dari ponsel.
- **Sinta, siswa.** Ingin tahu apakah buku tersedia, mengantri bila tidak, dan menerima pengingat lewat email atau WhatsApp.
- **Pak Anton, warga tanpa email.** Dilayani lewat admin dan dihubungi lewat WhatsApp atau telepon.
- **Bu Maya, kepala sekolah/ketua pengurus.** Hanya membaca laporan bulanan dan membutuhkan ekspor Excel/PDF (Fase 2).

**A1. Peminjaman di meja sirkulasi**

1. Admin membuka Meja Sirkulasi; kursor otomatis berada di kolom scan.
2. Admin memindai kartu anggota. Layar menampilkan nama, kategori, kuota terpakai, total denda, dan peringatan (suspend, keanggotaan hampir habis, dst.).
3. Admin memindai satu atau beberapa copy. Setiap scan langsung divalidasi, lalu masuk keranjang lengkap dengan tanggal jatuh tempo dari kebijakan.
4. Admin menekan Enter atau tombol Selesaikan. Seluruh transaksi dikomit atomik.
5. Layar menampilkan ringkasan dan opsi cetak/kirim bukti. Siap untuk anggota berikutnya dengan satu tombol.

**A2. Pengembalian**

1. Admin memindai copy (tanpa perlu memindai anggota). Sistem menampilkan peminjam, tanggal pinjam, jatuh tempo, dan estimasi denda.
2. Admin memilih kondisi: Baik (default), Rusak, atau Hilang.
3. Admin mengonfirmasi. Bila ada denda, muncul panel Catat pembayaran sekarang atau Tagih nanti.
4. Bila ada antrian untuk judul tersebut, layar menampilkan pesan besar: **TAHAN untuk \[nama anggota\] — letakkan di rak Hold**, dilengkapi batas waktu klaim.
5. Bila lokasi copy berbeda dari lokasi asalnya, sistem menawarkan pembaruan lokasi.

**A3. Reservasi sampai pengambilan**

1. Sinta mencari judul di portal dan melihat 0 dari 2 copy tersedia, serta perkiraan tanggal tersedia.
2. Sinta menekan Reservasi dan melihat posisi antriannya.
3. Saat copy dikembalikan, sistem menahannya untuk Sinta dan mengirim notifikasi dengan batas waktu 48 jam.
4. Sinta datang ke meja; admin memindai kartu dan copy yang ditahan, lalu meminjamkannya. Reservasi menjadi Terpenuhi.
5. Jika Sinta tidak datang, hold berakhir otomatis dan diteruskan ke antrian berikutnya.

**A4. Perpanjangan.** Anggota menekan Perpanjang di portal (atau admin melakukannya di meja). Sistem memeriksa batas perpanjangan, antrian, denda, dan status anggota, lalu menampilkan jatuh tempo baru atau alasan penolakan.

**A5. Barang hilang.** Admin membuka pinjaman → Tandai hilang → sistem membuat denda penggantian sesuai kebijakan, menghentikan akrual keterlambatan, mengubah status copy menjadi `HILANG`, dan mencatat di audit.

**A6. Pelunasan denda.** Admin membuka profil anggota → tab Denda → memilih satu atau beberapa denda → memasukkan jumlah dan metode → menyimpan → mencetak struk.

**A7. Pendaftaran anggota baru.** Admin mengisi data minimum (nama, kategori, kontak), sistem membuat nomor anggota, lalu mencetak kartu. Bila anggota punya email, undangan membuat password dikirim otomatis.

**A8. Persiapan awal organisasi (onboarding)**

1. Isi profil organisasi dan zona waktu.
2. Buat kategori anggota dan kebijakan pinjam (mulai dari template default Bagian 18).
3. Buat lokasi dan kategori barang.
4. Impor katalog dan eksemplar, lalu cetak dan tempel label.
5. Impor anggota dan pinjaman aktif dari spreadsheet lama.
6. Uji coba dengan data nyata sebelum cutover.

## 17. Spesifikasi Layar dan UX

**Prinsip UX**

- Meja Sirkulasi *keyboard-first*: seluruh alur bisa dilakukan tanpa mouse.
- Umpan balik instan: sukses (hijau + bunyi pendek), peringatan (kuning), gagal (merah + bunyi berbeda). Bunyi dapat dimatikan.
- Pesan error menyebut penyebab dan langkah berikutnya, misalnya: “Kuota pinjam siswa (3 buku) sudah penuh. Kembalikan salah satu buku, atau minta Super Admin melakukan override.”
- Aksi destruktif (arsip, tarik dari koleksi, hapus denda) selalu meminta konfirmasi dan alasan.
- Format tanggal `dd MMM yyyy`, Rupiah `Rp12.500`.
- Tabel: pencarian, filter, sort, paginasi di server, dan filter terakhir diingat.
- Portal anggota *mobile-first*; panel admin *desktop-first* tetapi tetap layak dipakai di tablet.
- Empty state yang informatif, skeleton saat memuat, dan status jaringan yang jelas.
- Aksesibilitas: kontras WCAG AA, label form, indikator fokus terlihat, dukungan pembaca layar untuk form utama.

**Format kode.** Copy: `BK-000123` (buku), `EQ-000045` (peralatan), `OT-000007` (lainnya). Anggota: `M-000123`. Barcode (Code 128) dan/atau QR hanya berisi kode teks, bukan URL, supaya dapat dibaca scanner apa pun dan tidak bergantung pada domain. Digit pemeriksa (checksum) opsional untuk mengurangi salah baca. Prefix dipakai Meja Sirkulasi untuk mengenali jenis kode secara otomatis.

**Daftar layar**

1. **Login dan lupa password.**
2. **Dashboard admin.** Kartu angka (pinjaman aktif, jatuh tempo hari ini, terlambat, hold menunggu diambil, denda outstanding), daftar Perlu tindakan hari ini, dan grafik mini 30 hari.
3. **Meja Sirkulasi.** Tab Pinjam, Kembali, Perpanjang dengan satu kolom scan yang selalu fokus; panel anggota di kiri dan keranjang di kanan; pintasan F2 (pinjam), F3 (kembali), F4 (perpanjang), Esc (batal).
4. **Katalog.** Daftar item type dengan filter (jenis, kategori, lokasi, ketersediaan). Form tambah dengan input ISBN dan tombol Ambil data. Halaman detail dengan tab Eksemplar (kode, status, lokasi, peminjam saat ini, jatuh tempo), Riwayat, dan Antrian. Aksi massal: tambah N copy sekaligus, cetak label terpilih, pindah lokasi.
5. **Detail copy.** Status, riwayat transisi, dan tombol ubah status yang hanya menampilkan transisi sah.
6. **Anggota.** Daftar dan detail dengan tab Ringkasan, Pinjaman aktif, Riwayat, Reservasi, Denda dan Pembayaran, serta Catatan/Audit. Tombol Suspend/Blokir dan Cetak kartu.
7. **Reservasi.** Dua tampilan: Siap diambil (dengan hitung mundur hold) dan Antrian per judul.
8. **Denda dan Pembayaran.** Daftar denda, catat pembayaran untuk beberapa denda sekaligus, hapuskan denda (waive), cetak struk.
9. **Laporan** (Bagian 26).
10. **Pengaturan.** Organisasi, kategori anggota, kebijakan pinjam (tampilan matriks), kategori barang, lokasi, template notifikasi, hari libur, pengguna dan peran, impor/ekspor, log audit.
11. **Portal anggota.** Beranda (pencarian besar dan pinjaman yang segera jatuh tempo); hasil pencarian dengan badge ketersediaan; detail judul (jumlah copy tersedia dari total, **perkiraan tanggal tersedia**, posisi antrian); Reservasi Saya; Pinjaman Saya (tombol Perpanjang); Denda; Profil.

*Perkiraan tanggal tersedia* dihitung dengan aturan sederhana: jatuh tempo paling awal di antara pinjaman aktif judul tersebut. Label di UI harus jelas bahwa ini perkiraan.

## 18. Kebijakan Default (Contoh Konfigurasi Awal)

Angka berikut adalah **contoh template** untuk mempercepat onboarding, bukan keputusan final. Semuanya dapat diubah lewat UI.

**Template Sekolah**

- Siswa — buku: 7 hari, maks 3 buku, 1× perpanjang (7 hari), denda Rp500/hari.
- Guru — buku: 14 hari, maks 10 buku, 2× perpanjang (14 hari), denda Rp500/hari.
- Peralatan (proyektor, dll.): hanya guru, 2 hari, maks 1 item, tanpa perpanjangan, denda Rp5.000/hari.
- Tamu: tidak diizinkan.

**Template RT/RW**

- Warga — buku: 7 hari, maks 2, 1× perpanjang, denda Rp500/hari.
- Warga — perkakas: 3 hari, maks 2 item, 1× perpanjang (2 hari), denda Rp5.000/hari.
- Warga — tenda/proyektor: 2 hari, maks 1 item, tanpa perpanjangan, denda Rp10.000/hari.
- Pengurus: durasi dan kuota lebih longgar.
- Tamu: buku saja, 7 hari, maks 1, tanpa perpanjangan.

**Template Kantor**

- Karyawan — buku: 14 hari, maks 5, 2× perpanjang.
- Karyawan — peralatan: 3 hari, maks 1, 1× perpanjang.
- Denda dapat dinonaktifkan dan diganti pengingat saja.

**Parameter global (default)**

- Window klaim hold: 48 jam; pengingat 12 jam sebelum hold berakhir.
- Ambang blokir denda: Rp0 (ada denda apa pun memblokir pinjaman baru).
- Ambang tindak lanjut manual: terlambat 30 hari.
- Reminder jatuh tempo: H-2, H-1, hari-H. Reminder terlambat: H+1, H+7, H+14.
- Maks reservasi aktif per anggota: 3.
- Perpanjangan ditolak bila ada antrian: ya. Perpanjangan saat sudah terlambat: tidak.
- Masa tenggang denda (grace): 0 hari.

**Catatan:** untuk barang komunal bernilai tinggi, organisasi mungkin ingin *deposit/jaminan*. Ini belum masuk MVP; lihat Bagian 30 (backlog).

## 19. Aturan Perhitungan Denda (dengan Contoh)

**Definisi hari terlambat.** Dihitung berdasarkan tanggal kalender zona waktu organisasi:

`hari_terlambat = max(0, tanggal_kembali − tanggal_jatuh_tempo − grace_days)`

Barang yang dikembalikan tepat pada tanggal jatuh tempo tidak terlambat. Di Fase 2, hari libur yang ditandai pada kalender dapat dikecualikan dari hitungan.

**Jenis aturan**

- **Flat:** `denda = hari_terlambat × tarif_per_hari`.
- **Bertingkat:** daftar rentang hari dengan tarif masing-masing, dihitung kumulatif.
- **Batas maksimum (cap):** nominal tetap, atau harga perolehan copy, mana yang berlaku sesuai kebijakan. Denda akhir = `min(denda, cap)`.

**Contoh 1 — Flat.** Jatuh tempo 5 Okt, kembali 9 Okt, tarif Rp500/hari, grace 0 → 4 hari → **Rp2.000**.

**Contoh 2 — Bertingkat dengan grace.** Jatuh tempo 1 Okt, kembali 12 Okt (11 hari lewat), grace 1 hari → 10 hari kena denda. Tarif: hari 1–7 = Rp500, hari 8 dan seterusnya = Rp1.000. Hitungan: 7 × 500 + 3 × 1.000 = **Rp6.500**.

**Contoh 3 — Cap.** Perkakas dengan tarif flat Rp5.000/hari, terlambat 10 hari = Rp50.000; harga perolehan Rp40.000 dan cap = harga perolehan → denda **Rp40.000**.

**Aturan lain**

- **Estimasi berjalan** di UI memakai fungsi murni yang sama dengan perhitungan resmi: `calculateFine(policy, dueDate, returnDate)`. Satu sumber kebenaran, diuji dengan unit test dan *property-based test* (denda tidak negatif, monoton naik terhadap hari, tidak melebihi cap).
- **Hilang:** tanggal pelaporan hilang menghentikan akrual keterlambatan. Denda penggantian = harga perolehan × persentase penggantian (default 100%) + biaya administrasi tetap (default Rp0). Bila harga kosong, admin wajib mengisi nominal manual.
- **Rusak:** biaya diinput manual oleh admin, alasan wajib.
- **Alokasi pembayaran:** default denda tertua lebih dulu; admin dapat memilih denda tertentu. Pembayaran yang melebihi total tunggakan ditolak (saldo kredit tidak ada di MVP).
- **Koreksi:** denda yang salah dikoreksi lewat entri penyesuaian atau waive berizin; kolom `amount` tidak diubah langsung setelah ada pembayaran.
- **Snapshot:** parameter perhitungan (hari, tarif, tingkat, cap) disimpan di `fines.computed_from` agar hasil bisa ditelusuri walau kebijakan berubah.

## 20. Hak Akses (RBAC)

Izin bersifat granular dan dipetakan ke peran. Semua pemeriksaan dilakukan di server; UI hanya menyembunyikan tombol.

- **Lihat katalog:** semua peran termasuk anggota.
- **Kelola katalog** (tambah/ubah item type dan copy, cetak label): Admin, Super Admin.
- **Tarik copy dari koleksi / arsipkan item:** Super Admin.
- **Kelola anggota** (buat, ubah, nonaktifkan): Admin, Super Admin.
- **Suspend/blokir dan buka blokir:** Admin, Super Admin (alasan wajib).
- **Pinjam, kembali, perpanjang, tandai hilang:** Admin, Super Admin.
- **Override aturan pinjam** (melewati kuota, denda, dst.): Super Admin, atau Admin yang diberi izin khusus; alasan wajib.
- **Void transaksi** (koreksi salah input): Admin dalam 10 menit pertama; setelahnya Super Admin. Void membatalkan pinjaman dengan status `DIBATALKAN`, bukan menghapus baris.
- **Catat pembayaran:** Admin, Super Admin.
- **Waive denda:** Super Admin, atau Admin dengan izin khusus dan batas nominal.
- **Lihat laporan dan dashboard:** Admin, Pengurus, Super Admin.
- **Ekspor data:** Admin, Pengurus, Super Admin; setiap ekspor tercatat di audit.
- **Ubah kebijakan, pengaturan, template notifikasi:** Super Admin.
- **Kelola pengguna dan peran:** Super Admin.
- **Lihat audit log:** Super Admin dan Pengurus (read-only).
- **Anggota:** melihat katalog; membuat dan membatalkan reservasi sendiri; memperpanjang pinjaman sendiri (jika kebijakan mengizinkan); melihat data pinjaman, denda, dan profil sendiri. Anggota **tidak** dapat melihat data anggota lain, termasuk siapa yang sedang memegang suatu barang (privasi).

Peran kustom (kombinasi izin bebas) masuk Fase 2. Super Admin minimal dua orang per organisasi untuk menghindari kunci akses.

## 21. Katalog Notifikasi dan Template

**Jenis notifikasi**

- `REMINDER_H2`, `REMINDER_H1`, `REMINDER_DUE` — pinjaman akan/sedang jatuh tempo.
- `OVERDUE_1`, `OVERDUE_7`, `OVERDUE_14` — pinjaman terlambat (jadwal konfigurabel).
- `HOLD_READY` — barang reservasi siap diambil.
- `HOLD_EXPIRING` — hold berakhir 12 jam lagi.
- `HOLD_EXPIRED` — hold berakhir dan giliran diteruskan.
- `RESERVATION_CANCELLED` — reservasi dibatalkan sistem (mis. semua copy ditarik).
- `FINE_OUTSTANDING` — pengingat tunggakan (mingguan, konfigurabel).
- `MEMBER_SUSPENDED` dan `MEMBER_REACTIVATED`.
- `MEMBERSHIP_EXPIRING` — H-14 sebelum masa berlaku habis.
- `ACCOUNT_INVITE` dan `PASSWORD_RESET` — transaksional, email saja.

**Variabel template:** `{nama}`, `{nomor_anggota}`, `{judul}`, `{daftar_judul}`, `{kode_copy}`, `{tanggal_jatuh_tempo}`, `{sisa_hari}`, `{denda_total}`, `{batas_waktu}`, `{lokasi_ambil}`, `{nama_organisasi}`, `{kontak_admin}`.

**Contoh template**

- `HOLD_READY`: “Halo {nama}, {judul} yang Anda reservasi sudah tersedia. Silakan ambil di {lokasi\_ambil} sebelum {batas\_waktu}. Jika tidak diambil, giliran akan diteruskan ke antrian berikutnya.”
- `REMINDER_H2`: “Halo {nama}, {sisa\_hari} hari lagi jatuh tempo: {daftar\_judul}. Kembalikan atau perpanjang sebelum {tanggal\_jatuh\_tempo} agar tidak kena denda.”
- `FINE_OUTSTANDING`: “Halo {nama}, Anda memiliki tunggakan denda Rp{denda\_total}. Peminjaman baru ditangguhkan sampai lunas. Hubungi {kontak\_admin}.”

**Aturan pengiriman**

- **Digest:** beberapa pinjaman dengan jatuh tempo sama digabung menjadi satu pesan per anggota per kanal.
- **Jam tenang:** WhatsApp tidak dikirim pukul 20:00–07:00 waktu organisasi; pesan ditunda ke pagi (kecuali `HOLD_READY` yang boleh dikirim sampai 21:00).
- **Preferensi kanal:** anggota/admin memilih email, WhatsApp, atau keduanya. Reminder biasa dapat dimatikan; notifikasi hold dan tunggakan tetap terkirim minimal lewat satu kanal.
- **Kunci deduplikasi:** `{tipe}:{id_entitas}:{tanggal}` — contoh `REMINDER_H1:loan_8f2a:2026-10-14`. Job yang berjalan ulang tidak membuat pesan ganda.
- **Retry:** hingga 3 kali dengan jeda 5 menit, 30 menit, 2 jam. Setelah gagal, status `FAILED` dan masuk daftar Perlu dihubungi manual.
- **Pembatasan laju:** maksimal N pesan per anggota per hari (default 5) agar tidak mengganggu.
- **Bukti:** `provider_message_id`, waktu, dan error tersimpan agar admin bisa menjawab “sudah dikirim atau belum?”.

## 22. Skema Database Rinci

**Konvensi:** primary key UUID (v7 agar terurut waktu); kolom waktu `timestamptz`; uang `bigint` (Rupiah); enum disimpan sebagai `text` dengan `CHECK`; tidak ada hard delete untuk entitas yang punya riwayat (pakai `archived_at`); semua tabel memuat `organization_id`.

**item\_copies:** `id`, `item_type_id`, `barcode` (unik per organisasi), `status`, `location_id`, `condition`, `acquired_at`, `acquisition_price`, `source` (beli/hibah/lainnya), `notes`, `archived_at`, `version`.

**loans:** `id`, `copy_id`, `member_id`, `checked_out_at`, `due_date` (date), `due_at` (timestamptz), `returned_at`, `status` (`AKTIF`/`DIKEMBALIKAN`/`HILANG`/`DIBATALKAN`), `renewal_count`, `policy_snapshot` (jsonb), `condition_out`, `condition_in`, `processed_by`, `returned_processed_by`, `void_reason`, `idempotency_key`.

**reservations:** `id`, `item_type_id`, `member_id`, `status`, `queued_at`, `ready_at`, `hold_expires_at`, `held_copy_id`, `fulfilled_loan_id`, `cancel_reason`, `created_by`.

**fines:** `id`, `member_id`, `loan_id`, `type` (`TERLAMBAT`/`HILANG`/`RUSAK`/`LAINNYA`), `amount`, `amount_paid`, `status`, `computed_from` (jsonb), `waived_by`, `waive_reason`.

**payments:** `id`, `member_id`, `amount`, `method` (`TUNAI`/`TRANSFER`/`QRIS_MANUAL`/`LAINNYA`), `received_by`, `paid_at`, `reference`, `notes`, `voided_at`. **payment\_allocations:** `payment_id`, `fine_id`, `amount`.

**loan\_policies:** `member_category_id`, `item_category_id` (nullable), `item_kind` (nullable), `allowed`, `loan_days`, `max_items`, `max_renewals`, `renewal_days`, `grace_days`, `fine_rule` (jsonb: tipe flat/bertingkat, tarif, tingkat, cap). **Resolusi kebijakan:** pilih yang paling spesifik, yaitu (kategori anggota + kategori barang) → (kategori anggota + jenis barang) → (kategori anggota saja). Kuota total ada di `member_categories.max_total_items`, kuota per kelompok di `loan_policies.max_items`; keduanya harus terpenuhi.

**notifications:** `id`, `type`, `channel`, `member_id`, `payload` (jsonb), `dedupe_key` (unik), `status` (`PENDING`/`SENDING`/`SENT`/`FAILED`/`SKIPPED`), `attempts`, `next_attempt_at`, `sent_at`, `provider_message_id`, `error`.

**audit\_logs** (append-only): `id` (bigserial), `actor_user_id`, `action`, `entity_type`, `entity_id`, `before` (jsonb), `after` (jsonb), `reason`, `ip`, `created_at`. User database aplikasi hanya diberi hak `INSERT` dan `SELECT` pada tabel ini.

**Constraint kunci**

```sql
CREATE UNIQUE INDEX uq_loans_open_per_copy
  ON loans (copy_id) WHERE returned_at IS NULL AND status = 'AKTIF';

CREATE UNIQUE INDEX uq_res_active_per_member
  ON reservations (item_type_id, member_id)
  WHERE status IN ('MENUNGGU','SIAP_DIAMBIL');

CREATE UNIQUE INDEX uq_res_held_copy
  ON reservations (held_copy_id) WHERE status = 'SIAP_DIAMBIL';

ALTER TABLE fines ADD CONSTRAINT chk_fine_paid
  CHECK (amount >= 0 AND amount_paid >= 0 AND amount_paid <= amount);

CREATE UNIQUE INDEX uq_notif_dedupe ON notifications (dedupe_key);
```

**Urutan operasi Checkout (dalam satu transaksi)**

1. `BEGIN`; cek `idempotency_key` (bila sudah ada, kembalikan hasil sebelumnya).
2. `SELECT ... FROM members WHERE id=$1 FOR UPDATE`.
3. Validasi status anggota, masa berlaku, dan denda outstanding.
4. `SELECT ... FROM item_copies WHERE barcode = ANY($codes) ORDER BY id FOR UPDATE`.
5. Per copy: validasi status dan kepemilikan hold, tentukan kebijakan, hitung kuota (pinjaman terbuka + isi keranjang).
6. `INSERT` loans; `UPDATE` copy menjadi `DIPINJAM` (dengan `WHERE status IN (...)`); bila dari hold, ubah reservasi menjadi `TERPENUHI`.
7. Tulis `loan_events`, `audit_logs`, dan (opsional) notifikasi.
8. `COMMIT`. Bila terjadi unique violation atau serialization failure, `ROLLBACK` dan petakan ke kode error domain (`COPY_NOT_AVAILABLE`, dst.). Seluruh keranjang bersifat atomik: bila satu copy gagal karena balapan, UI menampilkan copy yang gagal dan admin mengulang tanpa copy tersebut.

**Urutan operasi Return**

1. `BEGIN`; kunci copy dan loan terbuka (`FOR UPDATE`).
2. Hitung denda dengan `calculateFine`, buat entri `fines` bila > 0.
3. Tutup loan (`returned_at`, `condition_in`).
4. Jika kondisi Baik: pilih reservasi `MENUNGGU` terdepan untuk judul tersebut dengan `FOR UPDATE SKIP LOCKED`; bila ada → reservasi `SIAP_DIAMBIL` + copy `DITAHAN` + notifikasi `HOLD_READY`; bila tidak → copy `TERSEDIA`.
5. Jika kondisi Rusak: copy `RUSAK`, tidak ada hold dibuat, antrian tetap menunggu copy lain.
6. Tulis audit, `COMMIT`.

## 23. Spesifikasi API (Ringkas)

Gaya REST di bawah `/api/v1`. Autentikasi memakai sesi cookie (`HttpOnly`, `Secure`, `SameSite=Lax`) dengan proteksi CSRF. Semua endpoint mutasi menerima header `Idempotency-Key`.

**Endpoint utama**

- **Auth:** `POST /auth/login`, `POST /auth/logout`, `POST /auth/password-reset`.
- **Katalog:** `GET/POST /item-types`, `GET/PATCH /item-types/:id`, `POST /item-types/:id/copies` (tambah N copy), `GET /isbn/:isbn` (ambil metadata), `GET/PATCH /copies/:id`, `POST /copies/:id/status`.
- **Anggota:** `GET/POST /members`, `GET/PATCH /members/:id`, `POST /members/:id/suspend`, `POST /members/:id/reactivate`.
- **Sirkulasi:** `POST /circulation/checkout` (`memberCode`, `copyCodes[]`), `POST /circulation/return` (`copyCode`, `condition`), `POST /circulation/renew` (`loanId`), `POST /circulation/mark-lost` (`loanId`), `POST /circulation/:loanId/void`.
- **Reservasi:** `POST /reservations`, `DELETE /reservations/:id`, `GET /item-types/:id/queue`.
- **Denda dan pembayaran:** `GET /fines`, `POST /payments` (dengan alokasi), `POST /fines/:id/waive`, `POST /payments/:id/void`.
- **Laporan:** `GET /reports/:name?from=&to=&format=json|xlsx|pdf`.
- **Pengaturan:** `GET/PUT /settings/policies`, `/settings/templates`, `/settings/categories`, `/settings/locations`.
- **Impor/ekspor:** `POST /imports` (unggah dan dry-run), `POST /imports/:id/commit`, `GET /imports/:id/report`.

**Format error:** `{ "error": { "code": "QUOTA_EXCEEDED", "message": "...", "details": { ... } } }`. Pesan `message` berbahasa Indonesia; `code` stabil untuk klien.

**Kode error domain:** `COPY_NOT_AVAILABLE`, `HOLD_RESERVED_FOR_OTHER`, `MEMBER_SUSPENDED`, `MEMBERSHIP_EXPIRED`, `QUOTA_EXCEEDED`, `FINES_OUTSTANDING`, `NOT_ELIGIBLE`, `RENEWAL_LIMIT_REACHED`, `RENEWAL_BLOCKED_BY_QUEUE`, `INVALID_TRANSITION`, `DUPLICATE_REQUEST`, `NOT_FOUND`, `FORBIDDEN`, `VALIDATION_ERROR`.

**Status HTTP:** 200/201 sukses, 400/422 validasi, 401 belum login, 403 tidak berizin, 404 tidak ditemukan, 409 konflik bisnis (termasuk balapan), 429 rate limit.

**Konvensi:** paginasi berbasis kursor, filter lewat query string, waktu dalam ISO 8601 UTC, kontrak API didokumentasikan dengan OpenAPI yang dihasilkan dari skema Zod agar validasi dan dokumen tidak berbeda.

## 24. Kasus Tepi dan Keputusan Perilaku

- **Scan copy yang sama dua kali:** scan kedua pada keranjang yang sama diabaikan dengan peringatan kuning; di database dijaga idempotency key dan unique index.
- **Copy dikembalikan oleh orang lain (bukan peminjam):** diizinkan; pengembalian tercatat atas nama peminjam asli, pemroses tercatat terpisah.
- **Copy berstatus `TERSEDIA` dipindai saat Kembali:** peringatan “tidak sedang dipinjam”, tanpa perubahan data; opsi memperbarui lokasi.
- **Copy rusak saat dikembalikan padahal ada antrian:** hold tidak dibuat; antrian tetap `MENUNGGU` hingga ada copy lain yang kembali dalam kondisi baik. Bila tidak ada copy aktif tersisa sama sekali, admin diberi peringatan dan reservasi dapat dibatalkan massal dengan notifikasi.
- **Copy `DITAHAN` ditarik/hilang/rusak (ditemukan rusak di rak hold):** reservasi kembali `MENUNGGU` dengan `queued_at` asli (posisi antrian tidak hilang), lalu sistem mencoba menahan copy lain.
- **Anggota disuspend saat punya reservasi `SIAP_DIAMBIL`:** hold dibatalkan dan diteruskan ke antrian berikutnya; anggota diberi tahu.
- **Keanggotaan kedaluwarsa saat memegang pinjaman:** tetap boleh mengembalikan; tidak boleh pinjam/perpanjang/reservasi; denda tetap berjalan.
- **Perubahan kebijakan di tengah pinjaman:** pinjaman aktif memakai `policy_snapshot` saat transaksi; perpanjangan memakai kebijakan saat ini untuk durasi tambahan, kecuali dikonfigurasi lain.
- **Perubahan kategori anggota:** berlaku untuk transaksi baru; pinjaman berjalan tidak berubah.
- **Salah input (misal salah anggota):** *void* dalam 10 menit oleh Admin (alasan wajib); setelahnya hanya Super Admin. Void mengembalikan status copy dan menghapus efek denda/hold terkait lewat entri koreksi.
- **Kode tidak ditemukan:** pesan jelas; admin berizin ditawari membuat copy baru dari kode tersebut.
- **Jatuh tempo pada hari libur:** MVP tidak menggeser; Fase 2 menyediakan opsi geser ke hari kerja berikutnya per organisasi.
- **Pinjaman multi-copy:** atomik. Validasi awal dilakukan saat scan; bila balapan membuat satu copy gagal saat commit, seluruh transaksi dibatalkan dan UI menunjukkan copy yang gagal untuk diulang.
- **Duplikat anggota:** peringatan saat input (nama + kontak mirip); fitur gabung anggota di Fase 2.
- **Copy ditemukan setelah dinyatakan hilang:** dipulihkan ke `TERSEDIA`; denda penggantian dibatalkan lewat entri koreksi (bila sudah dibayar, dicatat sebagai pengembalian dana manual).
- **Server atau job tertunda:** status terlambat dihitung dari data (bukan job), sehingga tampilan dan blokir tetap benar; job yang tertinggal mengejar saat pulih tanpa kirim ganda berkat deduplikasi.
- **Anggota mereservasi judul padahal ada copy `TERSEDIA`:** ditolak dengan arahan untuk meminjam langsung.

## 25. Kriteria Penerimaan Fitur Kunci

**Checkout berhasil**

- *Given* anggota Siswa aktif tanpa denda dengan kuota 3 dan 2 pinjaman aktif, *When* admin memindai copy `TERSEDIA` bertipe buku, *Then* pinjaman dibuat dengan jatuh tempo sesuai kebijakan Siswa, copy menjadi `DIPINJAM`, dan baris audit tercatat.

**Checkout ditolak: kuota**

- *Given* anggota dengan kuota penuh, *When* admin memindai copy tambahan, *Then* sistem menolak dengan kode `QUOTA_EXCEEDED` dan pesan berisi batas serta jumlah terpakai; tidak ada data berubah.

**Checkout ditolak: denda**

- *Given* anggota memiliki denda `BELUM_BAYAR` di atas ambang, *When* mencoba pinjam atau perpanjang, *Then* ditolak dengan `FINES_OUTSTANDING`; pengembalian tetap diizinkan.

**Balapan pada satu copy**

- *Given* satu copy `TERSEDIA`, *When* dua permintaan checkout oleh dua anggota berbeda dikirim bersamaan (100 kali percobaan berulang), *Then* tepat satu berhasil dan satu mendapat `COPY_NOT_AVAILABLE` (409) pada setiap percobaan; tidak pernah ada dua pinjaman terbuka untuk copy tersebut.

**Balapan kuota**

- *Given* anggota dengan sisa kuota 1, *When* dua checkout copy berbeda dikirim bersamaan, *Then* tepat satu berhasil.

**Pengembalian dengan antrian**

- *Given* judul X punya tiga reservasi `MENUNGGU`, *When* copy X dikembalikan dalam kondisi Baik, *Then* reservasi tertua menjadi `SIAP_DIAMBIL` dengan `hold_expires_at` = sekarang + 48 jam, copy menjadi `DITAHAN`, dan notifikasi `HOLD_READY` masuk outbox, semua dalam satu transaksi.

**Hold kedaluwarsa**

- *Given* hold yang sudah melewati `hold_expires_at`, *When* job kedaluwarsa berjalan (sekali atau berulang), *Then* reservasi menjadi `KEDALUWARSA`, hold berpindah ke antrian berikutnya (atau copy menjadi `TERSEDIA` bila antrian kosong), dan tidak ada notifikasi ganda.

**Walk-in tidak bisa mengambil copy hold**

- *Given* copy `DITAHAN` untuk anggota A, *When* admin mencoba meminjamkannya ke anggota B, *Then* ditolak dengan `HOLD_RESERVED_FOR_OTHER` kecuali ada override berizin dengan alasan.

**Perpanjangan**

- *Given* pinjaman dengan batas perpanjangan 1 kali dan tanpa antrian, *When* diperpanjang pertama kali, *Then* jatuh tempo bertambah sesuai `renewal_days` dan `renewal_count` = 1; *When* diperpanjang lagi, *Then* ditolak `RENEWAL_LIMIT_REACHED`.
- *Given* ada antrian untuk judul, *When* anggota memperpanjang, *Then* ditolak `RENEWAL_BLOCKED_BY_QUEUE`.

**Denda otomatis**

- *Given* kebijakan bertingkat (hari 1–7 Rp500, hari 8+ Rp1.000, grace 1), jatuh tempo 1 Okt, *When* dikembalikan 12 Okt, *Then* denda `TERLAMBAT` = Rp6.500 dengan `computed_from` berisi rincian.

**Pembayaran sebagian**

- *Given* denda Rp6.500, *When* admin mencatat pembayaran Rp4.000, *Then* `amount_paid` = 4.000, status `SEBAGIAN`, sisa Rp2.500, dan peminjaman baru tetap diblokir sampai lunas.

**Notifikasi tidak ganda**

- *Given* job reminder H-1 dijalankan dua kali pada hari yang sama, *Then* hanya satu notifikasi per pinjaman tercipta (unique `dedupe_key`).

**Suspend**

- *Given* anggota disuspend, *Then* pinjam/perpanjang/reservasi ditolak, pengembalian dan pembayaran tetap bisa, dan perubahan tercatat dengan alasan di audit.

## 26. Spesifikasi Laporan

**Definisi metrik**

- **Populer:** jumlah *checkout* per item type dalam periode (perpanjangan tidak dihitung).
- **Rasio keterlambatan:** pinjaman yang dikembalikan setelah jatuh tempo ÷ total pinjaman yang dikembalikan pada periode.
- **Denda outstanding:** jumlah (`amount` − `amount_paid`) untuk denda berstatus `BELUM_BAYAR` atau `SEBAGIAN`.
- **Utilisasi copy:** hari dalam status `DIPINJAM` ÷ hari tersedia di koleksi selama periode (berguna untuk memutuskan pembelian tambahan, terutama barang komunal).
- **Copy dormant:** tidak pernah dipinjam dalam 12 bulan terakhir.

**Daftar laporan**

1. **Sirkulasi harian/bulanan:** jumlah pinjam, kembali, perpanjang per hari; filter kategori anggota dan jenis barang.
2. **Pinjaman aktif dan jatuh tempo:** per rentang tanggal, dengan kontak anggota.
3. **Keterlambatan:** daftar dan agregat (rata-rata hari terlambat, rasio), per kategori anggota.
4. **Rekap denda:** ditagih, dibayar, dihapuskan, outstanding; per periode dan per petugas penerima.
5. **Populer dan kategori diminati:** peringkat judul/barang dan kategori.
6. **Tren:** grafik mingguan dan bulanan (pinjam, kembali, terlambat, denda).
7. **Tindak lanjut manual:** terlambat lebih dari ambang; kolom: anggota, kontak, barang, hari terlambat, notifikasi terakhir, catatan tindak lanjut (bisa diisi admin).
8. **Anggota:** aktif/pasif, paling aktif, anggota dengan tunggakan terbesar, keanggotaan segera habis.
9. **Inventaris:** jumlah copy per status, per lokasi, per kategori; daftar rusak/hilang/perbaikan; copy dormant; utilisasi.
10. **Antrian reservasi:** judul dengan antrian terpanjang dan rata-rata waktu tunggu (sinyal untuk menambah copy).
11. **Audit:** pencarian log berdasarkan aktor, entitas, dan rentang waktu.

**Ketentuan umum:** setiap laporan punya filter periode, dapat diekspor (Excel/PDF di Fase 2; CSV di MVP), mencantumkan waktu pembuatan, zona waktu, dan filter yang dipakai. Angka di dashboard dan laporan harus konsisten karena memakai query definisi yang sama.

## 27. Impor dan Migrasi Data

**Template CSV:** katalog (item type), eksemplar, anggota, pinjaman aktif, saldo awal denda. Setiap template punya kolom wajib dan contoh baris, dapat diunduh dari UI.

**Alur impor**

1. Unggah file dan pilih jenis impor.
2. Pemetaan kolom (disimpan untuk pemakaian berikutnya).
3. **Dry-run:** validasi seluruh baris (format, referensi kategori/lokasi, duplikat ISBN dan nomor anggota, kode barcode ganda), tampilkan pratinjau dan daftar error per baris.
4. Admin memperbaiki file atau menyetujui impor baris yang valid.
5. **Commit** per batch dalam transaksi; kegagalan satu batch tidak merusak yang lain.
6. Laporan hasil (berhasil, dilewati, gagal) dapat diunduh.

**Aturan:** impor idempoten lewat `external_id` (impor ulang memperbarui, bukan menggandakan); pinjaman aktif yang diimpor harus menunjuk copy dan anggota yang valid dan membuat copy berstatus `DIPINJAM`; denda awal diimpor sebagai entri `LAINNYA` dengan keterangan “saldo awal”; ukuran file dibatasi (mis. 5 MB) dan diproses sebagai job latar untuk file besar.

**Rencana cutover**

1. Bekukan pencatatan manual pada tanggal yang disepakati (freeze).
2. Impor data akhir (pinjaman aktif dan saldo denda).
3. Dua minggu paralel: catat di sistem; buku lama hanya untuk cadangan.
4. Evaluasi, perbaiki data, lalu matikan pencatatan manual.
5. Rencana mundur: ekspor data sistem ke CSV tersedia setiap saat sehingga organisasi tidak terkunci.

**Pelabelan fisik:** cetak label per rak/lokasi, prioritaskan barang bernilai dan paling sering dipinjam; barang yang belum berlabel tetap dilayani lewat pencarian judul dan pembuatan copy sementara oleh admin.

## 28. Strategi Pengujian dan QA

- **Unit test:** `calculateFine`, resolusi kebijakan, validator state machine (semua transisi sah dan tidak sah), perhitungan jatuh tempo dan zona waktu, template notifikasi. Property-based test untuk denda dan state machine.
- **Integration test dengan PostgreSQL asli** (Testcontainers): semua use case sirkulasi, reservasi, denda, pembayaran; skenario *concurrency* Bagian 25 dengan 20–100 permintaan paralel dan ulangan banyak kali.
- **Job test:** jam disimulasikan (fake clock) untuk memastikan reminder, kedaluwarsa hold, dan tindak lanjut jalan tepat waktu, idempoten, dan tahan terhadap job yang tertunda.
- **E2E (Playwright):** alur A1–A7 Bagian 16, termasuk input scanner (ketik cepat diakhiri Enter).
- **Uji beban ringan (k6):** 50 pengguna paralel di portal + 5 admin checkout; target p95 sesuai Bagian 12.
- **Uji keamanan:** checklist OWASP ASVS level dasar, uji otorisasi per peran (anggota tidak bisa mengakses data anggota lain), uji CSRF/XSS/injeksi, pemindaian dependensi.
- **Pemeriksaan integritas malam hari:** query yang harus selalu mengembalikan 0 baris, misalnya copy `DIPINJAM` tanpa loan terbuka; loan terbuka pada copy yang tidak `DIPINJAM`; `DITAHAN` tanpa reservasi `SIAP_DIAMBIL`; `amount_paid` tidak sama dengan jumlah alokasi; reservasi ganda aktif. Hasil dikirim ke Super Admin bila ada anomali.
- **UAT:** 1–2 minggu dengan petugas nyata memakai daftar periksa skenario; setiap temuan dikategorikan blocker/mayor/minor.
- **Data uji:** skrip *seed* yang menghasilkan organisasi contoh (anggota, katalog, pinjaman terlambat, antrian) untuk demo dan pengujian.

## 29. Operasional, Pemantauan, dan Keamanan Rinci

**Lingkungan dan rilis:** dev, staging, produksi. CI (mis. GitHub Actions): lint, type-check, test, build, migrasi. Migrasi database maju-saja dan bisa diulang; rilis dengan jendela pemeliharaan singkat di luar jam sirkulasi. Fitur Fase 2–3 disembunyikan di balik *feature flag*.

**Backup dan pemulihan:** `pg_dump` harian terenkripsi ke penyimpanan terpisah, retensi 30 hari; uji pemulihan (restore drill) tiap kuartal; WAL archiving/PITR opsional bila organisasi menginginkan RPO lebih kecil.

**Pemantauan dan peringatan**

- Uptime check dan endpoint `/health`.
- Keterlambatan job: peringatan bila scheduler tidak berjalan lebih dari 30 menit.
- Rasio notifikasi gagal tinggi; antrian outbox menumpuk.
- Error rate dan latensi endpoint sirkulasi; disk dan koneksi database.
- Log terstruktur dengan ID permintaan; **jangan** menulis data pribadi (kontak, nama lengkap) ke log aplikasi.

**Keamanan**

- Cookie sesi `HttpOnly`, `Secure`, `SameSite`; masa sesi dengan pembaruan; logout dari semua perangkat.
- Password argon2/bcrypt, kebijakan panjang minimum, pembatasan percobaan login dan penguncian sementara.
- 2FA opsional untuk Super Admin (Fase 2).
- User database aplikasi dengan hak minimum; audit log append-only; backup terenkripsi; rahasia hanya di environment/secret manager.
- Header keamanan (CSP, HSTS), validasi input di server dengan Zod, escaping output, batas ukuran unggahan dan tipe file untuk foto/impor.
- Pemindaian dependensi dan pembaruan keamanan berkala.

**Runbook admin singkat:** cara menambah staf, mengganti password, memulihkan dari backup, menjalankan ulang job notifikasi gagal, mengatasi scanner yang tidak terbaca, dan prosedur saat internet mati.

**Biaya (indikatif, perlu diverifikasi):** VPS kecil (2 vCPU, 4 GB RAM) sudah memadai untuk skala Bagian 4; email transaksional umumnya punya tier gratis untuk volume kecil; WhatsApp resmi dikenai biaya per pesan/percakapan template menurut tarif penyedia saat implementasi.

## 30. Backlog Fase Lanjutan, Kriteria Rilis, dan Glosarium

**Kriteria rilis MVP (Definition of Done)**

1. Semua kebutuhan MVP Bagian 5 lolos kriteria penerimaan Bagian 25.
2. Tes concurrency lulus 100% pada 100 ulangan; pemeriksaan integritas bersih.
3. Pemulihan dari backup berhasil diuji.
4. Data nyata satu lokasi pilot berhasil diimpor, dan petugas pilot menyelesaikan skenario A1–A7 tanpa bantuan developer.
5. Dokumentasi pengguna singkat dan runbook admin tersedia.
6. Tidak ada bug blocker/mayor terbuka dari UAT.

**Epic backlog Fase 2**

- Notifikasi WhatsApp resmi; preferensi kanal per anggota.
- Scan kamera HP; label massal dan rak.
- Laporan lengkap, grafik tren, ekspor Excel/PDF terjadwal.
- Stock opname berbasis scan (pencocokan fisik vs sistem, daftar selisih).
- Kalender hari libur; opsi geser jatuh tempo.
- Checklist kelengkapan dan foto kondisi saat pinjam/kembali.
- Auto-suspend dan penalti gagal klaim hold.
- Gabung anggota duplikat; peran kustom; 2FA Super Admin.
- Deposit/jaminan untuk barang bernilai tinggi.

**Epic backlog Fase 3**

- Kiosk self-service dan peminjaman mandiri (kartu + PIN, persetujuan petugas untuk barang bernilai).
- Payment gateway/QRIS terintegrasi dan rekonsiliasi otomatis.
- Booking berbasis tanggal/kalender untuk barang komunal.
- Multi-cabang/multi-organisasi, OPAC publik, SSO sekolah/kantor, PWA offline, durasi pinjam dalam jam.

**Glosarium**

- **Item type:** judul buku atau jenis barang (mis. “Bor Listrik Bosch”).
- **Copy/eksemplar:** satu barang fisik dengan kode unik.
- **Hold:** penahanan copy untuk anggota di antrian pertama selama window klaim.
- **Window klaim:** batas waktu (default 48 jam) bagi pemegang hold untuk mengambil barang.
- **Grace period:** hari tenggang sebelum denda dihitung.
- **Cap denda:** batas maksimum denda per pinjaman.
- **Waive:** penghapusan denda oleh pihak berwenang dengan alasan.
- **Void:** pembatalan transaksi salah input tanpa menghapus jejak.
- **Override:** pelanggaran aturan yang disengaja oleh pihak berizin dengan alasan wajib.
- **Outbox:** tabel notifikasi yang menjamin pengiriman diproses andal dan tidak ganda.
- **Idempotency key:** kunci unik per permintaan agar pengiriman ulang tidak menghasilkan transaksi ganda.
- **Stock opname:** penghitungan fisik inventaris untuk dicocokkan dengan catatan sistem.
- **Dormant:** copy yang lama tidak pernah dipinjam.
