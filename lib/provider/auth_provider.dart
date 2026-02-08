import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../layanan/api_servis.dart';
import '../layanan/api_konfig.dart'; // Impor sudah diarahkan ke folder layanan
import '../model/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _sedangLoading = false;

  UserModel? get user => _user;
  bool get sedangLoading => _sedangLoading;

  late ApiServis _apiServis;

  AuthProvider() {
    // Callback logout otomatis jika sesi di server dihapus
    _apiServis = ApiServis(onLogout: () => logout());
  }

  // FUNGSI LOGIN: Sinkron dengan database u728046838_simple
  Future<bool> login(String username, String password) async {
    _sedangLoading = true;
    notifyListeners();

    final hasil = await _apiServis.kirimPermintaan(ApiKonfig.login, {
      'username': username,
      'password': password,
    });

    if (hasil['status'] == 'sukses') {
      // Mengambil token yang dihasilkan server saat login
      final String tokenBaru = hasil['data']['token'];
      
      // Membuat objek user dengan data lengkap termasuk NAMA asli
      _user = UserModel.fromJson(hasil['data'], tokenBaru);
      
      final pref = await SharedPreferences.getInstance();
      await pref.setString('token', _user!.token);
      await pref.setString('peran', _user!.peran);

      _sedangLoading = false;
      notifyListeners();
      return true;
    } else {
      _sedangLoading = false;
      notifyListeners();
      return false;
    }
  }

  // FUNGSI AUTO LOGIN: Berjalan saat aplikasi pertama kali dibuka
  Future<void> cekSesiOtomatis() async {
    final pref = await SharedPreferences.getInstance();
    final token = pref.getString('token');

    if (token != null) {
      final hasil = await _apiServis.kirimPermintaan(ApiKonfig.cekSesi, {
        'token': token,
      });

      if (hasil['status'] == 'sukses') {
        // Data nama diambil otomatis via JOIN di PHP
        _user = UserModel.fromJson(hasil['data'], token);
      } else {
        await pref.clear();
        _user = null;
      }
    }
    notifyListeners();
  }

  // FUNGSI LOGOUT: Menghapus sesi di HP dan Server
  Future<void> logout() async {
    if (_user != null) {
      await _apiServis.kirimPermintaan(ApiKonfig.logout, {
        'token': _user!.token,
      });
    }
    
    final pref = await SharedPreferences.getInstance();
    await pref.clear();
    _user = null;
    notifyListeners();
  }

  // FUNGSI CEK SESI AKTIF: Memastikan user tidak "ditendang" admin
  Future<void> cekSesiAktif() async {
    if (_user == null) return;
    await _apiServis.kirimPermintaan(ApiKonfig.cekSesi, {
      'token': _user!.token,
    });
  }
}