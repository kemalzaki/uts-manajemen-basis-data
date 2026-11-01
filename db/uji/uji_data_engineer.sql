-- ============================================================
-- uji_data_engineer.sql - Bukti role data_engineer:
-- CREATE / ALTER / DROP objek JALAN + CRUD semua tabel JALAN.
-- Jalankan dari luar container (bukti akses eksternal port 22122):
--   PGPASSWORD=data_engineer_122 psql -h localhost -p 22122 \
--     -U data_engineer -d uts_mbd -f db/uji/uji_data_engineer.sql
-- ============================================================

\echo '=== 1. CREATE objek baru: schema + tabel ==='
CREATE SCHEMA tes_engineer;
CREATE TABLE salam.tes_engineer (
    id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    catat VARCHAR(50) NOT NULL,
    CONSTRAINT catat_unik UNIQUE (catat),
    CONSTRAINT catat_isi CHECK (LENGTH(catat) > 0)
);

\echo '=== 2. INSERT ke tabel buatan sendiri ==='
INSERT INTO salam.tes_engineer (catat) VALUES ('baris pertama'), ('baris kedua');
SELECT id, catat FROM salam.tes_engineer ORDER BY id;

\echo '=== 3. ALTER TABLE: tambah kolom + constraint ==='
ALTER TABLE salam.tes_engineer ADD COLUMN dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE salam.tes_engineer ADD CONSTRAINT panjang_catat CHECK (LENGTH(catat) <= 50);
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema = 'salam' AND table_name = 'tes_engineer' ORDER BY ordinal_position;

\echo '=== 4. UPDATE + DELETE di tabel buatan sendiri ==='
UPDATE salam.tes_engineer SET catat = 'baris pertama diubah' WHERE id = 1;
DELETE FROM salam.tes_engineer WHERE id = 2;
SELECT id, catat FROM salam.tes_engineer ORDER BY id;

\echo '=== 5. ALTER objek milik proyek: ubah nama kolom tabel mahasiswas ==='
ALTER TABLE salam.mahasiswas RENAME COLUMN created_at TO dibuat_pada;
ALTER TABLE salam.mahasiswas RENAME COLUMN dibuat_pada TO created_at;
\echo '(nama kolom dikembalikan seperti semula, alter terbukti jalan)'

\echo '=== 6. CRUD tabel mahasiswas ==='
INSERT INTO salam.mahasiswas (nim, nama, email, jenis_kelamin, angkatan, ipk, semester, status)
VALUES ('1247050188', 'Uji Data Engineer', 'engineer-122@yopmail.com', 'P', 2024, 3.55, 5, 'aktif');
SELECT nim, nama, ipk FROM salam.mahasiswas WHERE nim = '1247050188';
UPDATE salam.mahasiswas SET ipk = 3.58 WHERE nim = '1247050188';
SELECT nim, ipk FROM salam.mahasiswas WHERE nim = '1247050188';
DELETE FROM salam.mahasiswas WHERE nim = '1247050188';
SELECT COUNT(*) AS sisa FROM salam.mahasiswas WHERE nim = '1247050188';

\echo '=== 7. DROP objek ==='
DROP TABLE salam.tes_engineer;
DROP SCHEMA tes_engineer;
\echo '(tabel dan schema buatan sendiri sudah di-drop)'

\echo '=== 8. View v_rekap masih bisa dibaca (objek proyek utuh) ==='
SELECT nim, nama, jumlah_matkul, total_sks FROM salam.v_rekap_mahasiswa ORDER BY id;
