-- ============================================================
-- 01_schema.sql - Skema SALAM beserta tabel, constraint, view,
-- trigger audit, dan data awal.
-- Dieksekusi otomatis saat container postgres_ariel pertama kali
-- dinyalakan (folder ter-mount ke /docker-entrypoint-initdb.d).
-- M. Ariel Davinsyah Putra - 1247050122
-- ============================================================

-- Nama skema ditulis SALAM tanpa tanda kutip; PostgreSQL menyimpannya
-- sebagai "salam" (huruf kecil) di katalog. \dn akan menampilkan salam.
CREATE SCHEMA SALAM;

-- ------------------------------------------------------------
-- Tabel utama: mahasiswas
-- Constraint wajib soal: PRIMARY KEY, UNIQUE, CHECK
-- ------------------------------------------------------------
CREATE TABLE salam.mahasiswas (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nim            VARCHAR(15)  NOT NULL,
    nama           VARCHAR(100) NOT NULL,
    email          VARCHAR(120) NOT NULL,
    jenis_kelamin  CHAR(1)      NOT NULL,
    angkatan       SMALLINT     NOT NULL,
    ipk            NUMERIC(3,2) NOT NULL DEFAULT 0.00,
    semester       SMALLINT     NOT NULL,
    status         VARCHAR(12)  NOT NULL DEFAULT 'aktif',
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT uq_mahasiswas_nim   UNIQUE (nim),
    CONSTRAINT uq_mahasiswas_email UNIQUE (email),
    CONSTRAINT jk_valid      CHECK (jenis_kelamin IN ('L', 'P')),
    CONSTRAINT angkatan_range CHECK (angkatan BETWEEN 2018 AND 2026),
    CONSTRAINT ipk_range     CHECK (ipk >= 0.00 AND ipk <= 4.00),
    CONSTRAINT semester_range CHECK (semester BETWEEN 1 AND 14),
    CONSTRAINT status_valid  CHECK (status IN ('aktif', 'cuti', 'lulus', 'keluar'))
);

-- ------------------------------------------------------------
-- FITUR PEMBEDA 1: tabel nilais (relasi ke mahasiswas)
-- Menambahkan FOREIGN KEY, UNIQUE gabungan, dan CHECK enum nilai.
-- ------------------------------------------------------------
CREATE TABLE salam.nilais (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mahasiswa_id     BIGINT       NOT NULL,
    kode_matkul      VARCHAR(10)  NOT NULL,
    nama_matkul      VARCHAR(80)  NOT NULL,
    sks              SMALLINT     NOT NULL,
    semester_diambil SMALLINT     NOT NULL,
    nilai_angka      NUMERIC(4,2) NOT NULL,
    nilai_huruf      CHAR(2)      NOT NULL,

    CONSTRAINT fk_nilais_mahasiswa
        FOREIGN KEY (mahasiswa_id) REFERENCES salam.mahasiswas (id)
        ON DELETE CASCADE,
    CONSTRAINT sks_range      CHECK (sks BETWEEN 1 AND 6),
    CONSTRAINT semester_ambil CHECK (semester_diambil BETWEEN 1 AND 14),
    CONSTRAINT nilai_angka_range CHECK (nilai_angka BETWEEN 0.00 AND 100.00),
    CONSTRAINT nilai_huruf_valid
        CHECK (nilai_huruf IN ('A', 'AB', 'B', 'BC', 'C', 'D', 'E')),
    CONSTRAINT uq_nilais_matkul
        UNIQUE (mahasiswa_id, kode_matkul, semester_diambil)
);

-- ------------------------------------------------------------
-- FITUR PEMBEDA 2: tabel audit riwayat_status + trigger
-- Setiap perubahan kolom status pada mahasiswas dicatat otomatis
-- (old value -> new value + waktu), contoh "aktivitas" khas yang
-- membedakan pekerjaan ini dari teman sekelas.
-- ------------------------------------------------------------
CREATE TABLE salam.riwayat_status (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mahasiswa_id  BIGINT      NOT NULL,
    status_lama   VARCHAR(12) NOT NULL,
    status_baru   VARCHAR(12) NOT NULL,
    diubah_pada   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION salam.catat_riwayat_status()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO salam.riwayat_status
            (mahasiswa_id, status_lama, status_baru)
        VALUES (OLD.id, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_riwayat_status
    BEFORE UPDATE ON salam.mahasiswas
    FOR EACH ROW
    EXECUTE FUNCTION salam.catat_riwayat_status();

-- ------------------------------------------------------------
-- FITUR PEMBEDA 3: view rekapitulasi (JOIN + agregasi)
-- Dipakai role bi_dev sebagai contoh "view" yang hanya bisa dibaca.
-- ------------------------------------------------------------
CREATE VIEW salam.v_rekap_mahasiswa AS
SELECT
    m.id,
    m.nim,
    m.nama,
    m.ipk,
    m.status,
    COALESCE(COUNT(n.id), 0)                    AS jumlah_matkul,
    COALESCE(SUM(n.sks), 0)                     AS total_sks,
    ROUND(COALESCE(AVG(n.nilai_angka), 0), 2)   AS rata_nilai
FROM salam.mahasiswas m
LEFT JOIN salam.nilais n ON n.mahasiswa_id = m.id
GROUP BY m.id, m.nim, m.nama, m.ipk, m.status;

-- ------------------------------------------------------------
-- Dokumentasi objek di katalog (COMMENT ON)
-- ------------------------------------------------------------
COMMENT ON SCHEMA salam IS 'Skema utama UTS Manajemen Basis Data (Ariel, 1247050122)';
COMMENT ON TABLE  salam.mahasiswas     IS 'Data mahasiswa; PK id, UNIQUE nim & email, CHECK ipk/semester/status';
COMMENT ON COLUMN salam.mahasiswas.ipk IS 'Indeks prestasi kumulatif 0.00 s.d. 4.00 (constraint ipk_range)';
COMMENT ON TABLE  salam.nilais         IS 'Nilai mata kuliah per mahasiswa; FK ke mahasiswas ON DELETE CASCADE';
COMMENT ON TABLE  salam.riwayat_status IS 'Audit trail perubahan status mahasiswa, diisi trigger trg_riwayat_status';
COMMENT ON VIEW   salam.v_rekap_mahasiswa IS 'Rekap jumlah matkul, total SKS, dan rata nilai per mahasiswa';

-- ------------------------------------------------------------
-- Data awal
-- ------------------------------------------------------------
INSERT INTO salam.mahasiswas
    (nim, nama, email, jenis_kelamin, angkatan, ipk, semester, status)
VALUES
    ('1247050122', 'M. Ariel Davinsyah Putra', 'ariel.davinsyah@yopmail.com', 'L', 2024, 3.45, 5, 'aktif'),
    ('1247050101', 'Bunga Aulia Rahma',        'bunga-122@yopmail.com',       'P', 2024, 3.60, 5, 'aktif'),
    ('1247050110', 'Damar Wicaksana',          'damar-122@yopmail.com',       'L', 2024, 3.10, 5, 'aktif'),
    ('1247050115', 'Intan Permatasari',        'intan-122@yopmail.com',       'P', 2023, 3.75, 7, 'cuti');

INSERT INTO salam.nilais
    (mahasiswa_id, kode_matkul, nama_matkul, sks, semester_diambil, nilai_angka, nilai_huruf)
VALUES
    (1, 'MBD121', 'Manajemen Basis Data',   3, 5, 88.00, 'A'),
    (1, 'PBO121', 'Pemrograman Berorientasi Objek', 4, 5, 82.50, 'AB'),
    (1, 'Jarkom1', 'Jaringan Komputer',     3, 4, 79.00, 'B'),
    (2, 'MBD121', 'Manajemen Basis Data',   3, 5, 91.00, 'A'),
    (2, 'RPL121', 'Rekayasa Perangkat Lunak', 3, 5, 86.75, 'A'),
    (3, 'MBD121', 'Manajemen Basis Data',   3, 5, 74.25, 'BC'),
    (4, 'MBD121', 'Manajemen Basis Data',   3, 5, 95.50, 'A');
