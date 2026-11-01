-- ============================================================
-- uji_backend_dev.sql - Bukti role backend_dev:
-- CRUD semua tabel JALAN, tapi CREATE objek DITOLAK.
-- Jalankan dari luar container (bukti akses eksternal port 22122):
--   PGPASSWORD=backend_dev_122 psql -h localhost -p 22122 \
--     -U backend_dev -d uts_mbd -f db/uji/uji_backend_dev.sql
-- ============================================================

\echo '=== 1. SELECT (Read) tabel mahasiswas ==='
SELECT id, nim, nama, ipk, semester, status FROM salam.mahasiswas ORDER BY id;

\echo '=== 2. SELECT view v_rekap_mahasiswa ==='
SELECT nim, nama, jumlah_matkul, total_sks, rata_nilai FROM salam.v_rekap_mahasiswa ORDER BY id;

\echo '=== 3. INSERT (Create) satu mahasiswa ==='
INSERT INTO salam.mahasiswas (nim, nama, email, jenis_kelamin, angkatan, ipk, semester, status)
VALUES ('1247050199', 'Uji Backend Dev', 'backend-122@yopmail.com', 'L', 2024, 3.30, 5, 'aktif');
SELECT id, nim, nama FROM salam.mahasiswas WHERE nim = '1247050199';

\echo '=== 4. UPDATE: ganti ipk mahasiswa uji ==='
UPDATE salam.mahasiswas SET ipk = 3.42 WHERE nim = '1247050199';
SELECT nim, ipk FROM salam.mahasiswas WHERE nim = '1247050199';

\echo '=== 5. INSERT ke tabel nilais (CRUD lintas tabel) ==='
INSERT INTO salam.nilais (mahasiswa_id, kode_matkul, nama_matkul, sks, semester_diambil, nilai_angka, nilai_huruf)
SELECT id, 'AIK121', 'Kecerdasan Artifisial', 3, 5, 87.00, 'A'
FROM salam.mahasiswas WHERE nim = '1247050199';
SELECT COUNT(*) AS nilai_baru FROM salam.nilais n
JOIN salam.mahasiswas m ON m.id = n.mahasiswa_id WHERE m.nim = '1247050199';

\echo '=== 6. DELETE (Delete) mahasiswa uji, nilais ikut CASCADE ==='
DELETE FROM salam.mahasiswas WHERE nim = '1247050199';
SELECT COUNT(*) AS sisa FROM salam.mahasiswas WHERE nim = '1247050199';

\echo '=== 7. [GAGAL - diharapkan] CREATE TABLE ditolak untuk backend_dev ==='
CREATE TABLE salam.tes_backend (
    id   INT PRIMARY KEY,
    teks TEXT
);
