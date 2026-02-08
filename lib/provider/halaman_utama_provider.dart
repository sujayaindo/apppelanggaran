import 'package:apppelanggaran/layanan/api_konfig.dart';
import 'package:flutter/material.dart';
import '../layanan/api_servis.dart';


class HalamanUtamaProvider with ChangeNotifier {
  List<Map<String, dynamic>> _statistikJenis = [];
  List<Map<String, dynamic>> get statistikJenis => _statistikJenis;

  bool _loadingStatistik = false;
  bool get loadingStatistik => _loadingStatistik;

  final ApiServis _apiServis = ApiServis();

  Future<void> ambilStatistik(String token) async {

    _loadingStatistik = true;
    notifyListeners();

    // Kirim token ke API untuk autentikasi
    final hasil = await _apiServis.kirimPermintaan(
      ApiKonfig.statistikPelanggaran, 
      {'token': token} 
    );

    if (hasil['status'] == 'sukses') {
      _statistikJenis = List<Map<String, dynamic>>.from(hasil['data']);
    }
    
    _loadingStatistik = false;
    notifyListeners();
  }
}