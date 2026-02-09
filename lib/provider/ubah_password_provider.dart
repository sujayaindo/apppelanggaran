import 'package:flutter/material.dart';
import '../layanan/api_servis.dart';
import '../layanan/api_konfig.dart';

class UbahPasswordProvider with ChangeNotifier {
  final ApiServis _apiServis = ApiServis();

  bool _sedangLoading = false;
  String? _pesanError;

  bool get sedangLoading => _sedangLoading;
  String? get pesanError => _pesanError;

  // Fungsi untuk mengubah password
  Future<bool> ubahPassword(
    String token,
    String passwordLama,
    String passwordBaru,
    String konfirmasiPassword,
  ) async {
    // Validasi input
    if (passwordLama.isEmpty || passwordBaru.isEmpty || konfirmasiPassword.isEmpty) {
      _pesanError = "Semua field harus diisi";
      notifyListeners();
      return false;
    }

    if (passwordBaru != konfirmasiPassword) {
      _pesanError = "Password baru dan konfirmasi tidak cocok";
      notifyListeners();
      return false;
    }

    if (passwordBaru.length < 6) {
      _pesanError = "Password minimal 6 karakter";
      notifyListeners();
      return false;
    }

    _sedangLoading = true;
    _pesanError = null;
    notifyListeners();

    final hasil = await _apiServis.kirimPermintaan(ApiKonfig.ubahPassword, {
      'token': token,
      'password_lama': passwordLama,
      'password_baru': passwordBaru,
      'konfirmasi_password': konfirmasiPassword,
    });

    _sedangLoading = false;

    if (hasil['status'] == 'sukses') {
      _pesanError = null;
      notifyListeners();
      return true;
    } else if (hasil['status'] == 'logout') {
      _pesanError = "Sesi tidak valid. Silakan login kembali.";
      notifyListeners();
      return false;
    } else {
      _pesanError = hasil['pesan'] ?? "Gagal mengubah password";
      notifyListeners();
      return false;
    }
  }

  // Reset pesan error
  void resetPesanError() {
    _pesanError = null;
    notifyListeners();
  }
}
