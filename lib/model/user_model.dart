class UserModel {
  final int userId;
  final String username;
  final String nama;
  final String peran;
  final String token;

  UserModel({
    required this.userId,
    required this.username,
    required this.nama,
    required this.peran,
    required this.token,
  });

  // Fungsi untuk mengubah JSON dari PHP (API) menjadi Object Flutter
  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? "",
      nama: json['nama'] ?? json['username'], // Jika nama kosong, gunakan username sebagai cadangan
      peran: json['peran'] ?? "siswa",
      token: token,
    );
  }

  // Fungsi untuk menyimpan data kembali ke format JSON (Misal untuk SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'nama': nama,
      'peran': peran,
      'token': token,
    };
  }
}