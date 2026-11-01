# Laporan sesi auto mode, 1 November 2026

Sesi berjalan di mode otomatis (user memantau sesekali). Lingkup: klarifikasi penggantian
DBeaver dengan Tabularis pada bukti akses eksternal, lalu pembaruan seluruh dokumen
(README, bukti, laporan) menyusul penggantian itu.

## Apa yang dikerjakan

1. **Penggantian DBeaver Community 26.2.0 dengan Tabularis v0.30.0** sebagai client GUI
   eksternal. DBeaver terkendala di komputer pengerjaan (sesi sering error, sulit
   dioperasikan konsisten) sehingga tidak pernah menghasilkan tangkapan layar bukti.
   Tabularis dipilih karena gratis, open source (Apache-2.0), dan punya MCP server
   bawaan yang juga gratis.
2. **Bukti GUI**: koneksi tersimpan "uts_mbd lokal" (127.0.0.1:22122, user backend_dev,
   password di Windows Credential Manager), lalu tiga query bukti dijalankan di SQL
   Console dan di-screenshot jendela penuh (4 file `shots/shot_tabularis_*.png`).
3. **Bukti MCP**: transkrip sesi MCP stdio JSON-RPC (`tabularis --mcp`) memakai lima tool
   bawaan (list_connections, list_databases, list_tables, describe_table, run_query)
   plus tiga query yang sama, tersimpan di `bukti/11-tabularis-mcp.txt`.
4. **Pembaruan dokumen**: rename `db/uji/dbeaver_eksternal.sql` menjadi
   `db/uji/uji_eksternal_gui.sql` (isi disesuaikan), blok klarifikasi di
   `bukti/08-dbeaver-eksternal.txt`, bagian klarifikasi di `README.md`, dan laporan
   (DOCX + PDF regenerasi, 19 menjadi 21 halaman: bagian 2.3 baru, Screenshot 8-11,
   baris rubrik dan catatan jujur diperbarui).
5. **Pengerasan .gitignore**: `tools/` (skrip otomasi GUI) dan `shots/_s*.png`
   (tangkapan sementara) tidak ikut di-commit.

## Verifikasi yang dijalankan beserta hasilnya

| Perintah | Hasil |
|---|---|
| `docker exec postgres_ariel psql \d salam.mahasiswas` | skema nyata dikonfirmasi (kolom `status`, bukan `status_aktif`) sebelum query ditulis |
| Sesi MCP `tabularis --mcp` (initialize, tools/list, tools/call) | semua balasan diterima; identitas server `uts_mbd`/`backend_dev`/`172.24.0.2:5432` |
| Query GUI di SQL Console | identitas 1 row 4 columns (46 ms), mahasiswas 3 rows 7 columns (48 ms), v_rekap 3 rows 8 columns (55 ms) |
| `pdfinfo laporan/*.pdf` | Pages: 21, ukuran 1.47 MB, timestamp sesudah regenerasi |
| `pdftotext lalu grep -i 'tabularis\|pengganti dbeaver\|screenshot 8-11'` | semua istilah penggantian ditemukan; sisa penyebutan DBeaver hanya kutipan soal dan klarifikasi jujur |
| `git check-ignore` untuk `tools/`, `shots/_s*.png` | kedunya terabaikan; `bukti/11` dan `shot_tabularis_*.png` tetap masuk |
| Audit keamanan diff oleh agent keamanan (sebelum commit) | hasil dicatat pada bagian di bawah |

Hasil audit keamanan: **tidak ada temuan kritis, sedang, maupun rendah yang memblokir
push.** Empat wilayah diperiksa: (1) `db/uji/uji_eksternal_gui.sql` hanya memuat tiga
SELECT bukti tanpa kredensial; (2) sapuan rahasia (pola token GitHub/AWS/slack/private
key) atas seluruh file teks diff, PDF, dan DOCX: nol hasil, password DB tidak muncul di
transkrip MCP; (3) keempat screenshot diperiksa visual: hanya data dummy yang disahkan;
(4) `git check-ignore` dua arah: `tools/` dan `shots/_s*.png` terabaikan, semua bukti
baru tetap ter-track. Dependency tidak berlaku karena diff tidak menyentuh manifest
paket. Audit dijalankan oleh agent keamanan sebelum commit.

## Yang gagal atau dilewati, beserta alasannya

- **Tangkapan layar DBeaver**: tidak diupayakan lagi karena sumber kendalanya ada di
  aplikasinya di komputer ini, bukan pada langkah yang bisa diperbaiki dari sisi kita;
  percobaan lama dipertahankan di `bukti/08` sebagai catatan jujur.
- **Membuat koneksi lewat MCP**: dilewati karena Tabularis memang tidak menyediakan tool
  pembuat koneksi; GUI dipakai sekali untuk membuat koneksi tersimpan, lalu seluruh
  bukti query murni lewat MCP.

## Kelemahan fondasi yang ditemukan dan penanganannya

- Tidak ada pada sesi ini; repo ujian diperiksa ulang setelah perubahan (port tetap
  terikat 127.0.0.1, tidak ada kredensial baru di luar `.env` yang memang disengaja
  di-commit demi penilaian).

## Commit

- `UTS: ganti DBeaver dengan Tabularis 0.30.0 untuk bukti akses eksternal (GUI + MCP),
  klarifikasi di README, bukti 08/11, dan laporan 21 halaman`: penggantian DBeaver
  dengan Tabularis (bukti GUI + MCP, klarifikasi dokumen, laporan 21 halaman).
