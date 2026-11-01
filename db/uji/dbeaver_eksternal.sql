-- Uji akses eksternal lewat DBeaver (client di komputer host, bukan dalam container).
-- Koneksi: localhost:22122 sebagai backend_dev (lihat perintah -con di transkrip).
SELECT current_database() AS database, current_user AS pengguna, inet_server_addr()::text || ':' || inet_server_port() AS server_asli;
SELECT nim, nama, ipk, semester, status FROM salam.mahasiswas ORDER BY id;
SELECT * FROM salam.v_rekap_mahasiswa ORDER BY id;
