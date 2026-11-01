# UTS Manajemen Basis Data: PostgreSQL + PGAdmin via Docker

M. Ariel Davinsyah Putra, NIM 1247050122. Tugas Ujian Tengah Semester mata kuliah
Manajemen Basis Data, dikerjakan individual.

## Ringkasan

Dua container dibangun dengan Docker Compose:

| Container | Image | Port host | Kegunaan |
|---|---|---|---|
| `postgres_ariel` | `postgres:15-alpine` (versi 15, memenuhi syarat 9 s.d. 15) | `22122` | Server database PostgreSQL 15 |
| `pgadmin_ariel` | `dpage/pgadmin4` | `44122` | Administrasi database lewat browser |

Port mengikuti ketentuan soal: 3 digit terakhir NIM `1247050122` adalah `122`,
sehingga PostgreSQL memakai `22` + `122` = **22122** dan PGAdmin memakai `44` + `122`
= **44122**.

Semua kredensial (user, password, database, port) **tidak di-hardcode** di
`docker-compose.yml`. Nilainya dibaca dari berkas `.env`. Di berkas compose, setiap
variabel ditulis `${VAR:?pesan}` sehingga apabila `.env` belum ada, `docker compose up`
langsung gagal dengan pesan yang menyebut variabel mana yang kurang. Itulah bukti
nilainya memang diambil dari `.env`.

## Struktur proyek

```
.
├── docker-compose.yml        # definisi 2 container, tanpa satu pun kredensial hardcode
├── .env                      # kredensial & port (sengaja di-commit untuk penilaian)
├── .env.example              # templat .env
├── db/
│   ├── init/                 # di-mount ke /docker-entrypoint-initdb.d (boot pertama)
│   │   ├── 01_schema.sql     # schema SALAM + tabel + constraint + view + trigger + data
│   │   └── 02_roles.sql      # role backend_dev, bi_dev, data_engineer + grant
│   └── uji/                  # skrip bukti, dijalankan manual (bukan auto-init)
│       ├── uji_constraint.sql
│       ├── uji_backend_dev.sql
│       ├── uji_bi_dev.sql
│       └── uji_data_engineer.sql
├── bukti/                    # transkrip output asli tiap pengujian
├── laporan/                  # laporan PDF untuk LMS
└── soal/Soal_UTS_MBD.pdf     # salinan soal UTS
```

## Cara menjalankan

```bash
cp .env.example .env      # lalu sesuaikan bila perlu
docker compose up -d      # tarik image lalu nyalakan kedua container
docker ps                 # pastikan postgres_ariel dan pgadmin_ariel Up (healthy)
```

Skrip di `db/init/` dijalankan otomatis saat boot pertama (volume masih kosong),
sehingga schema, tabel, role, dan data awal langsung tersedia. Untuk mengulang dari
nol: `docker compose down -v && docker compose up -d`.

## Konfigurasi (.env)

| Variabel | Nilai | Keterangan |
|---|---|---|
| `POSTGRES_USER` | `postgres` | sesuai ketentuan soal |
| `POSTGRES_PASSWORD` | `ifunggul` | sesuai ketentuan soal |
| `POSTGRES_DB` | `uts_mbd` | database kerja |
| `POSTGRES_PORT` | `22122` | 22 + 3 digit akhir NIM |
| `PGADMIN_DEFAULT_EMAIL` | `ariel.davinsyah@yopmail.com` | env wajib pgAdmin |
| `PGADMIN_DEFAULT_PASSWORD` | `arielpg122` | env wajib pgAdmin |
| `PGADMIN_PORT` | `44122` | 44 + 3 digit akhir NIM |

Catatan: `.env` sengaja di-commit karena penilaian menuntut dokumentasi isinya.
Pada proyek produksi, `.env` wajib masuk `.gitignore` dan kredensial dikelola lewat
secret manager. Nilai di `.env.example` sengaja dikosongkan (templat bersih).

pgAdmin dikonfigurasi mode desktop (`SERVER_MODE False`): halaman terbuka
langsung tanpa form login. Ini hanya dapat diterima karena port-nya diikat ke
`127.0.0.1` di docker-compose.yml (tidak bisa dijangkau dari komputer lain) dan
konteksnya ujian lokal.

## Tiga user SQL beserta haknya

| User | Password | Hak | Bukti |
|---|---|---|---|
| `backend_dev` | `backend_dev_122` | CRUD semua tabel & baca view; TIDAK boleh membuat/mengubah objek | `db/uji/uji_backend_dev.sql` |
| `bi_dev` | `bi_dev_122` | HANYA SELECT semua tabel & view; INSERT/UPDATE/DELETE ditolak | `db/uji/uji_bi_dev.sql` |
| `data_engineer` | `data_engineer_122` | CREATE/ALTER/DROP semua objek + CRUD semua tabel (menjadi owner objek) | `db/uji/uji_data_engineer.sql` |

Kunci desainnya: di PostgreSQL hanya **owner** objek yang boleh ALTER/DROP. Karena itu
`02_roles.sql` memindahkan kepemilikan schema `salam` beserta seluruh objeknya ke
`data_engineer`, lalu memberi grant CRUD ke `backend_dev` dan grant SELECT ke `bi_dev`,
plus `ALTER DEFAULT PRIVILEGES` supaya objek baru buatan `data_engineer` tetap
mewarisi pembagian hak tersebut.

Trade-off yang disadari: mandat soal "CRUD semua tabel" membuat `backend_dev`
juga bisa UPDATE/DELETE tabel audit `riwayat_status` (jejak auditnya sendiri).
Pada sistem produksi, tabel audit seharusnya append-only dan dikecualikan dari
grant UPDATE/DELETE.

## Skema SALAM dan constraint

Tabel utama `mahasiswas`: PRIMARY KEY `id`, UNIQUE ganda (`nim`, `email`), dan empat
CHECK (`jenis_kelamin`, `angkatan 2018-2026`, `ipk 0.00-4.00`, `semester 1-14`,
`status` enum). Nama schema ditulis `CREATE SCHEMA SALAM` tanpa tanda kutip sehingga
PostgreSQL menyimpannya sebagai `salam` (lowercase) di katalog; `\dn` menampilkan
`salam`. Semua pelanggaran diuji nyata di `uji_constraint.sql` dan transkripnya ada
di folder `bukti/`.

## Fitur pembeda (anti-kesamaan pekerjaan)

1. **Tabel `nilais`** berelasi ke `mahasiswas` lewat FOREIGN KEY `ON DELETE CASCADE`,
   dengan UNIQUE gabungan `(mahasiswa_id, kode_matkul, semester_diambil)` dan CHECK
   enum nilai huruf `A/AB/B/BC/C/D/E`.
2. **Trigger audit `trg_riwayat_status`**: setiap perubahan `status` mahasiswa dicatat
   otomatis ke tabel `riwayat_status` (status lama, status baru, waktu).
3. **View `v_rekap_mahasiswa`**: rekap jumlah mata kuliah, total SKS, dan rata-rata
   nilai per mahasiswa (LEFT JOIN + agregasi).
4. **Demonstrasi transaksi** dengan `SAVEPOINT` dan `ROLLBACK TO SAVEPOINT`:
   dua insert sah selamat, satu insert pelanggar CHECK dibatalkan sebagian.
5. **`COMMENT ON`** pada schema, tabel, dan view sehingga dokumentasi ikut hidup di
   katalog (`\dt+`, `pg_description`).
6. **Interpolasi wajib `${VAR:?pesan}`** di docker-compose.yml: tanpa `.env`,
   compose menolak jalan dengan pesan jelas, bukan diam-diam memakai default.
7. **Pengikat port `127.0.0.1:` dan image terkunci versi** (hasil audit keamanan
   pengerjaan sendiri): kedua port hanya mendengarkan komputer lokal sehingga
   pgAdmin mode desktop tanpa login tidak pernah terekspos ke jaringan kampus,
   dan `dpage/pgadmin4:9.18` dipin agar perilaku tidak berubah diam-diam
   (bukti `bukti/10-hardening-port.txt`).

## Bukti akses internal dan eksternal

- **Internal (dari dalam jaringan Docker)**: pgAdmin di `http://localhost:44122`
  (mode desktop, terbuka langsung tanpa login), lalu register server dengan host
  `postgres_ariel` (nama container) port `5432`. Koneksi ini tidak keluar dari
  jaringan Docker.
- **Eksternal (dari luar Docker)**: DBeaver (atau psql) dari komputer host ke
  `localhost:22122`, user misalnya `backend_dev`. Jalur ini melewati port mapping
  host, sama seperti aplikasi eksternal mana pun.

## Menjalankan uji bukti

```bash
# constraint (dari dalam container, sebagai postgres)
docker exec -i postgres_ariel psql -U postgres -d uts_mbd \
  -f - < db/uji/uji_constraint.sql

# tiga role (dari luar container, sekaligus bukti akses eksternal port 22122)
PGPASSWORD=backend_dev_122 psql -h localhost -p 22122 -U backend_dev -d uts_mbd \
  -f db/uji/uji_backend_dev.sql
PGPASSWORD=bi_dev_122 psql -h localhost -p 22122 -U bi_dev -d uts_mbd \
  -f db/uji/uji_bi_dev.sql
PGPASSWORD=data_engineer_122 psql -h localhost -p 22122 -U data_engineer -d uts_mbd \
  -f db/uji/uji_data_engineer.sql
```

Baris berlabel `[GAGAL - diharapkan]` memang harus mengeluarkan ERROR; justru error
itulah buktinya. Transkrip lengkap tiap uji tersimpan di folder `bukti/`.
