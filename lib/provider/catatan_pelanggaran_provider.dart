import 'package:flutter/material.dart';
import '../layanan/api_servis.dart';
import '../layanan/api_konfig.dart';

class CatatanPelanggaranProvider with ChangeNotifier {
  final ApiServis _apiServis = ApiServis();

  List<dynamic> _dataPelanggaran = [];
  bool _isLoading = false;

  List<dynamic> get dataPelanggaran => _dataPelanggaran;
  bool get isLoading => _isLoading;

  // State untuk Filter
  final TextEditingController namaController = TextEditingController();
  final TextEditingController kelasController = TextEditingController();
  DateTime? tanggalAwal;
  DateTime? tanggalAkhir;

  CatatanPelanggaranProvider() {
    final now = DateTime.now();
    tanggalAwal = DateTime(now.year, now.month, now.day);
    tanggalAkhir = DateTime(now.year, now.month, now.day);
  }

  void setTanggalRange(DateTime? start, DateTime? end) {
    tanggalAwal = start;
    tanggalAkhir = end;
    notifyListeners();
  }

  void clearTanggalRange() {
    tanggalAwal = null;
    tanggalAkhir = null;
    notifyListeners();
  }

  void resetFilter() {
    namaController.clear();
    kelasController.clear();
    final now = DateTime.now();
    tanggalAwal = DateTime(now.year, now.month, now.day);
    tanggalAkhir = DateTime(now.year, now.month, now.day);
    notifyListeners();
  }

  Future<void> ambilData(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, String> params = {'token': token};
      
      // Masukkan parameter filter jika ada isinya
      if (namaController.text.isNotEmpty) params['nama'] = namaController.text;
      if (kelasController.text.isNotEmpty) params['kelas'] = kelasController.text;
      
      if (tanggalAwal != null && tanggalAkhir != null) {
        params['tanggal_awal'] = tanggalAwal!.toIso8601String().split('T')[0];
        params['tanggal_akhir'] = tanggalAkhir!.toIso8601String().split('T')[0];
      }

      final hasil = await _apiServis.kirimPermintaan(ApiKonfig.catatanPelanggaran, params);

      if (hasil['status'] == 'sukses') {
        _dataPelanggaran = hasil['data'];
        
      } else {
 
        _dataPelanggaran = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
