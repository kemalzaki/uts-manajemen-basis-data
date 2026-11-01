-- ============================================================
-- uji_constraint.sql - Bukti PRIMARY KEY, UNIQUE, CHECK, FK CASCADE,
-- trigger audit, dan TRANSAKSI (SAVEPOINT / ROLLBACK TO).
-- Jalankan sebagai user postgres:
--   docker exec -it postgres_ariel psql -U postgres -d uts_mbd \
--     -f - < db/uji/uji_constraint.sql
-- Baris berlabel [GAGAL - diharapkan] WAJIB mengeluarkan ERROR;
-- justru error itulah bukti constraint bekerja.
-- ============================================================

\echo '=== A. PRIMARY KEY: INSERT id yang sudah ada (OVERRIDING) ==='
\echo '[GAGAL - diharapkan] duplikat primary key'
INSERT INTO salam.mahasiswas (id, nim, nama, email, jenis_kelamin, angkatan, ipk, semester, status)
OVERRIDING SYSTEM VALUE VALUES
    (1, '9999990001', 'Baru Satu', 'baru1-122@yopmail.com', 'L', 2024, 3.00, 5, 'aktif');

\echo '=== B. UNIQUE nim: NIM 1247050101 sudah dipakai Bunga ==='
\echo '[GAGAL - diharapkan] melanggar uq_mahasiswas_nim'
INSERT INTO salam.mahasiswas (nim, nama, email, jenis_kelamin, angkatan, ipk, semester, status)
VALUES ('1247050101', 'Palsu Bunga', 'palsu-bunga-122@yopmail.com', 'P', 2024, 3.00, 5, 'aktif');

\echo '=== C. UNIQUE email: email Bunga dipakai ulang dengan NIM beda ==='
\echo '[GAGAL - diharapkan] melanggar uq_mahasiswas_email'
INSERT INTO salam.mahasiswas (nim, nama, email, jenis_kelamin, angkatan, ipk, semester, status)
VALUES ('9999990002', 'Palsu Email', 'bunga-122@yopmail.com', 'P', 2024, 3.00, 5, 'aktif');

\echo '=== D. CHECK ipk: nilai 4.50 di luar 0.00-4.00 ==='
\echo '[GAGAL - diharapkan] melanggar ipk_range'
UPDATE salam.mahasiswas SET ipk = 4.50 WHERE nim = '1247050110';

\echo '=== E. CHECK semester: nilai 15 di luar 1-14 ==='
\echo '[GAGAL - diharapkan] melanggar semester_range'
UPDATE salam.mahasiswas SET semester = 15 WHERE nim = '1247050110';

\echo '=== F. CHECK status: nilai tidak termasuk enum ==='
\echo '[GAGAL - diharapkan] melanggar status_valid'
UPDATE salam.mahasiswas SET status = 'tidur' WHERE nim = '1247050110';

\echo '=== G. CHECK nilai_huruf di tabel nilais ==='
\echo '[GAGAL - diharapkan] melanggar nilai_huruf_valid'
INSERT INTO salam.nilais (mahasiswa_id, kode_matkul, nama_matkul, sks, semester_diambil, nilai_angka, nilai_huruf)
VALUES (3, 'PBO121', 'Pemrograman Berorientasi Objek', 4, 5, 85.00, 'Z');

\echo '=== H. FK ON DELETE CASCADE: hapus mahasiswa, nilais ikut terhapus ==='
\echo 'Sebelum delete (jumlah nilais milik NIM 1247050115):'
SELECT COUNT(*) AS jumlah_nilai FROM salam.nilais n
JOIN salam.mahasiswas m ON m.id = n.mahasiswa_id WHERE m.nim = '1247050115';
DELETE FROM salam.mahasiswas WHERE nim = '1247050115';
\echo 'Sesudah delete (jumlah nilais milik NIM 1247050115, harus 0 karena CASCADE):'
SELECT COUNT(*) AS sisa_nilai FROM salam.nilais n
JOIN salam.mahasiswas m ON m.id = n.mahasiswa_id WHERE m.nim = '1247050115';

\echo '=== I. TRIGGER audit: ubah status aktif -> lulus ==='
UPDATE salam.mahasiswas SET status = 'lulus' WHERE nim = '1247050110';
\echo 'Isi tabel audit riwayat_status (terisi otomatis oleh trigger):'
SELECT id, mahasiswa_id, status_lama, status_baru, diubah_pada FROM salam.riwayat_status;

\echo '=== J. TRANSAKSI: SAVEPOINT dan ROLLBACK TO ==='
\echo 'Skenario: 2 insert sah mengapit 1 insert pelanggar CHECK.'
\echo 'Rollback ke savepoint membatalkan HANYA insert yang salah.'
BEGIN;
INSERT INTO salam.mahasiswas (nim, nama, email, jenis_kelamin, angkatan, ipk, semester, status)
VALUES ('9999990101', 'Transaksi Satu', 'trx1-122@yopmail.com', 'L', 2024, 3.00, 5, 'aktif');
SAVEPOINT sebelum_salah;
\echo '[GAGAL - diharapkan] ipk 9.99 melanggar ipk_range di dalam transaksi'
INSERT INTO salam.mahasiswas (nim, nama, email, jenis_kelamin, angkatan, ipk, semester, status)
VALUES ('9999990102', 'Transaksi Salah', 'trx2-122@yopmail.com', 'P', 2024, 9.99, 5, 'aktif');
ROLLBACK TO SAVEPOINT sebelum_salah;
INSERT INTO salam.mahasiswas (nim, nama, email, jenis_kelamin, angkatan, ipk, semester, status)
VALUES ('9999990103', 'Transaksi Dua', 'trx3-122@yopmail.com', 'P', 2024, 3.20, 5, 'aktif');
COMMIT;
\echo 'Hasil commit: 9999990101 dan 9999990103 ada, 9999990102 tidak:'
SELECT nim, nama FROM salam.mahasiswas WHERE nim LIKE '99999901%' ORDER BY nim;

\echo '=== Bersih-bersih data transaksi ==='
DELETE FROM salam.mahasiswas WHERE nim LIKE '99999901%';
