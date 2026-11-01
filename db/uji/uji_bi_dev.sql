-- ============================================================
-- uji_bi_dev.sql - Bukti role bi_dev: hanya bisa SELECT.
-- INSERT / UPDATE / DELETE semuanya DITOLAK.
-- Jalankan dari luar container (bukti akses eksternal port 22122):
--   PGPASSWORD=bi_dev_122 psql -h localhost -p 22122 \
--     -U bi_dev -d uts_mbd -f db/uji/uji_bi_dev.sql
-- ============================================================

\echo '=== 1. SELECT tabel mahasiswas (BOLEH) ==='
SELECT id, nim, nama, ipk, semester, status FROM salam.mahasiswas ORDER BY id;

\echo '=== 2. SELECT view v_rekap_mahasiswa (BOLEH) ==='
SELECT nim, nama, jumlah_matkul, total_sks, rata_nilai FROM salam.v_rekap_mahasiswa ORDER BY id;

\echo '=== 3. SELECT tabel nilais (BOLEH) ==='
SELECT kode_matkul, nama_matkul, sks, nilai_angka, nilai_huruf
FROM salam.nilais WHERE mahasiswa_id = 1 ORDER BY kode_matkul;

\echo '=== 4. [GAGAL - diharapkan] INSERT ditolak ==='
INSERT INTO salam.mahasiswas (nim, nama, email, jenis_kelamin, angkatan, ipk, semester, status)
VALUES ('9999990201', 'Boleh Nulis?', 'bi-122@yopmail.com', 'P', 2024, 3.00, 5, 'aktif');

\echo '=== 5. [GAGAL - diharapkan] UPDATE ditolak ==='
UPDATE salam.mahasiswas SET ipk = 0.00 WHERE nim = '1247050101';

\echo '=== 6. [GAGAL - diharapkan] DELETE ditolak ==='
DELETE FROM salam.mahasiswas WHERE nim = '1247050101';

\echo '=== 7. [GAGAL - diharapkan] CREATE TABLE ditolak ==='
CREATE TABLE salam.tes_bi (id INT PRIMARY KEY);
