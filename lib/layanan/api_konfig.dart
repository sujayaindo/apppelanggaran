class ApiKonfig {
  // Ganti localhost dengan IP Laptop Anda jika pakai HP fisik (misal: 192.168.1.5)
  //static const String baseUrl = "http://apisimple.smkn1abang.sch.id"; 
  static const String baseUrl = "http://192.168.1.5/apipelanggaran"; 
  
  static const String login = "$baseUrl/autentikasi/masuk.php";
  static const String cekSesi = "$baseUrl/autentikasi/cek_sesi.php";
  static const String logout = "$baseUrl/autentikasi/keluar.php";
  static const String statistikPelanggaran = "$baseUrl/pelanggaran/statistik_pelanggaran.php";
  static const String cariSiswa = "$baseUrl/pelanggaran/cari_siswa.php";
  static const String masterPelanggaran = "$baseUrl/pelanggaran/ambil_master_pelanggaran.php";
  static const String simpanPelanggaran = "$baseUrl/pelanggaran/simpan_pelanggaran.php";
  static const String riwayatHariIni = "$baseUrl/pelanggaran/ambil_input_hari_ini.php";
  static const String hapusPelanggaran = "$baseUrl/pelanggaran/hapus_pelanggaran.php";
}