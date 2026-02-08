import 'package:flutter/material.dart';
import '../layanan/api_servis.dart';
import '../layanan/api_konfig.dart';

class DetailPelanggaranProvider with ChangeNotifier {
  final ApiServis _apiServis = ApiServis();

  bool _isLoading = false;
  List<Map<String, dynamic>> _detail = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get detail => _detail;
  String? get error => _error;

  Future<void> ambilDetailPelanggaran(String token, dynamic siswaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasil = await _apiServis.kirimPermintaan(ApiKonfig.detailPelanggaran, {
        'token': token,
        'siswa_id': siswaId.toString(),
      });

      if (hasil['status'] == 'sukses') {
        _detail = List<Map<String, dynamic>>.from(hasil['data']);
      } else if (hasil['status'] == 'logout') {
        _detail = [];
        _error = 'logout';
      } else {
        _detail = [];
        _error = hasil['pesan'] ?? 'Gagal mengambil data';
      }
    } catch (e) {
      _detail = [];
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _detail = [];
    _error = null;
    notifyListeners();
  }
}
