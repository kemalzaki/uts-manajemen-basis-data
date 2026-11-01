-- Uji akses eksternal lewat GUI di komputer host (bukan dalam container).
-- Client pengganti DBeaver: Tabularis v0.30.0 (gratis, open source Apache-2.0),
-- koneksi tersimpan "uts_mbd lokal" -> 127.0.0.1:22122 sebagai backend_dev.
-- Query ini persis yang dijalankan di SQL Console Tabularis
-- (bukti shots/shot_tabularis_*.png).
SELECT current_database() AS basisdata, current_user AS pengguna,
       inet_server_addr()::text AS alamat, inet_server_port() AS port;
SELECT nim, nama, jenis_kelamin, angkatan, ipk, semester, status
  FROM salam.mahasiswas ORDER BY nim;
SELECT * FROM salam.v_rekap_mahasiswa ORDER BY nama;
