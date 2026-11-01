-- ============================================================
-- 02_roles.sql - Tiga role SQL sesuai kebutuhan soal:
--   backend_dev    : CRUD semua tabel (tanpa boleh membuat objek)
--   bi_dev         : hanya SELECT (baca) semua tabel dan view
--   data_engineer  : CREATE/MODIFY/DROP semua objek + CRUD semua tabel
-- Dieksekusi otomatis setelah 01_schema.sql saat boot pertama.
--
-- Catatan: password role tertulis di skrip inisialisasi ini demi
-- kemudahan penilaian kelas; pada produksi seharusnya diprovisi
-- lewat secret manager, bukan plaintext.
-- ============================================================

CREATE ROLE backend_dev   LOGIN PASSWORD 'backend_dev_122';
CREATE ROLE bi_dev        LOGIN PASSWORD 'bi_dev_122';
CREATE ROLE data_engineer LOGIN PASSWORD 'data_engineer_122';

-- ------------------------------------------------------------
-- 1) Kepemilikan objek dipindahkan ke data_engineer
--    Di PostgreSQL hanya OWNER yang boleh ALTER/DROP objek,
--    jadi syarat "data_engineer bisa modify & drop semua objek"
--    dipenuhi dengan kepemilikan, bukan sekadar GRANT.
-- ------------------------------------------------------------
ALTER SCHEMA salam OWNER TO data_engineer;
ALTER TABLE  salam.mahasiswas     OWNER TO data_engineer;
ALTER TABLE  salam.nilais         OWNER TO data_engineer;
ALTER TABLE  salam.riwayat_status OWNER TO data_engineer;
ALTER VIEW   salam.v_rekap_mahasiswa OWNER TO data_engineer;
ALTER FUNCTION salam.catat_riwayat_status() OWNER TO data_engineer;

-- Hak membuat schema baru (objek tingkat database)
GRANT CREATE ON DATABASE uts_mbd TO data_engineer;

-- ------------------------------------------------------------
-- 2) backend_dev: CRUD semua tabel + baca view, TANPA CREATE
-- ------------------------------------------------------------
GRANT USAGE ON SCHEMA salam TO backend_dev;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA salam TO backend_dev;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA salam TO backend_dev;

-- ------------------------------------------------------------
-- 3) bi_dev: hanya SELECT semua tabel dan view
-- ------------------------------------------------------------
GRANT USAGE ON SCHEMA salam TO bi_dev;
GRANT SELECT ON ALL TABLES IN SCHEMA salam TO bi_dev;

-- ------------------------------------------------------------
-- 4) data_engineer: CRUD semua tabel (sebagai owner sudah penuh,
--    grant eksplisit ditulis agar maksudnya terbaca)
-- ------------------------------------------------------------
GRANT USAGE ON SCHEMA salam TO data_engineer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA salam TO data_engineer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA salam TO data_engineer;

-- ------------------------------------------------------------
-- 5) Default privileges: tabel yang NANTI dibuat data_engineer
--    otomatis tetap bisa di-CRUD backend_dev dan dibaca bi_dev,
--    sehingga pembagian hak tidak bocor saat objek baru muncul.
-- ------------------------------------------------------------
ALTER DEFAULT PRIVILEGES FOR ROLE data_engineer IN SCHEMA salam
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO backend_dev;
ALTER DEFAULT PRIVILEGES FOR ROLE data_engineer IN SCHEMA salam
    GRANT SELECT ON TABLES TO bi_dev;
ALTER DEFAULT PRIVILEGES FOR ROLE data_engineer IN SCHEMA salam
    GRANT USAGE, SELECT ON SEQUENCES TO backend_dev;
