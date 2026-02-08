import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../layanan/api_servis.dart';
import '../layanan/api_konfig.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; 
import 'package:flutter/foundation.dart' show kIsWeb;

class InputPelanggaranProvider with ChangeNotifier {
  final ApiServis _apiServis = ApiServis();
  final ImagePicker _picker = ImagePicker();
  Timer? _debounce;

  // --- STATE VARIABLES ---
  List<dynamic> _masterPelanggaran = [];
  List<dynamic> _daftarSiswa = [];
  List<dynamic> _riwayatHariIni = [];
  final List<int> _selectedPelanggaran = []; 
  
  Map<String, dynamic>? _siswaTerpilih;
  XFile? _fotoBukti;
  Uint8List? _webImage; // Menyimpan bytes foto untuk Web

  bool _loadingMaster = false;
  bool _loadingRiwayat = false;
  bool _isSaving = false;

  // --- GETTERS ---
  List<dynamic> get masterPelanggaran => _masterPelanggaran;
  List<dynamic> get daftarSiswa => _daftarSiswa;
  List<dynamic> get riwayatHariIni => _riwayatHariIni;
  List<int> get selectedPelanggaran => _selectedPelanggaran;
  Map<String, dynamic>? get siswaTerpilih => _siswaTerpilih;
  XFile? get fotoBukti => _fotoBukti;
  Uint8List? get webImage => _webImage; // Digunakan di UI (Image.memory)
  
  bool get loadingMaster => _loadingMaster;
  bool get loadingRiwayat => _loadingRiwayat;
  bool get isSaving => _isSaving;

  // --- LOGIKA UI ---

  void togglePelanggaran(int id) {
    if (_selectedPelanggaran.contains(id)) {
      _selectedPelanggaran.remove(id);
    } else {
      _selectedPelanggaran.add(id);
    }
    notifyListeners();
  }

  void pilihSiswa(Map<String, dynamic> siswa) {
    _siswaTerpilih = siswa;
    notifyListeners();
  }

  Future<void> ambilFoto(bool dariKamera) async {
    final XFile? image = await _picker.pickImage(
      source: dariKamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 50,
    );
    
    if (image != null) {
      _fotoBukti = image;
      
      // PERBAIKAN: Isi _webImage jika di Web agar preview muncul
      if (kIsWeb) {
        _webImage = await image.readAsBytes();
      }
      
      notifyListeners();
    }
  }

  // --- API CALLS ---

  Future<void> ambilMasterPelanggaran(String token) async {
    _loadingMaster = true;
    notifyListeners();
    try {
      final hasil = await _apiServis.kirimPermintaan(ApiKonfig.masterPelanggaran, {'token': token});
      if (hasil['status'] == 'sukses') {
        _masterPelanggaran = hasil['data'];
      }
    } finally {
      _loadingMaster = false;
      notifyListeners();
    }
  }

  Future<void> cariSiswa(String token, String keyword) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (keyword.trim().isEmpty) {
        _daftarSiswa.clear();
        notifyListeners();
        return;
      }

      if (keyword.length < 3) return;

      try {
        final hasil = await _apiServis.kirimPermintaan(ApiKonfig.cariSiswa, {
          'token': token,
          'keyword': keyword
        });

        if (hasil['status'] == 'sukses') {
          _daftarSiswa = hasil['data'];
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Error cariSiswa: $e");
      }
    });
  }

  Future<void> ambilRiwayatHariIni(String token) async {
    _loadingRiwayat = true;
    notifyListeners();
    try {
      final hasil = await _apiServis.kirimPermintaan(ApiKonfig.riwayatHariIni, {'token': token});
      if (hasil['status'] == 'sukses') {
        _riwayatHariIni = hasil['data'];
      }
    } finally {
      _loadingRiwayat = false;
      notifyListeners();
    }
  }

  Future<bool> simpanPelanggaran(String token) async {
    if (_siswaTerpilih == null || _selectedPelanggaran.isEmpty) return false;
    
    _isSaving = true;
    notifyListeners();

    try {
      var uri = Uri.parse(ApiKonfig.simpanPelanggaran);
      var request = http.MultipartRequest('POST', uri);

      request.fields['token'] = token;
      request.fields['siswa_kelas_id'] = _siswaTerpilih!['siswa_kelas_id'].toString();
      request.fields['pelanggaran_ids'] = _selectedPelanggaran.join(',');
      request.fields['keterangan'] = "Dicatat via Mobile";

      if (_fotoBukti != null) {
        if (kIsWeb) {
          final bytes = await _fotoBukti!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'foto', 
            bytes, 
            filename: 'pelanggaran.jpg'
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('foto', _fotoBukti!.path));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      final hasil = json.decode(response.body);

      if (hasil['status'] == 'sukses') {
        _selectedPelanggaran.clear();
        _siswaTerpilih = null;
        _fotoBukti = null;
        _webImage = null; // Reset pratinjau foto
        ambilRiwayatHariIni(token);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error simpanPelanggaran: $e");
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> hapusPelanggaran(String token, String id) async {
    final hasil = await _apiServis.kirimPermintaan(ApiKonfig.hapusPelanggaran, {
      'token': token,
      'id': id
    });
    if (hasil['status'] == 'sukses') {
      ambilRiwayatHariIni(token);
    }
  }
}