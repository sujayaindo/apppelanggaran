import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../layanan/api_servis.dart';
import '../layanan/api_konfig.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;

class InputPelanggaranProvider with ChangeNotifier {
  final ApiServis _apiServis = ApiServis();
  final ImagePicker _picker = ImagePicker();
  Timer? _debounce;

  // --- STATE VARIABLES ---
  List<dynamic> _masterPelanggaran = [];
  String _filterQuery = '';
  List<dynamic> _daftarSiswa = [];
  List<dynamic> _riwayatHariIni = [];
  final List<int> _selectedPelanggaran = [];

  Map<String, dynamic>? _siswaTerpilih;
  XFile? _fotoBukti;
  Uint8List? _webImage; // Menyimpan bytes foto untuk Web
  Uint8List? _fotoBuktiBytes; // Bytes foto terkompres untuk upload
  String? _lastErrorMessage;
  Map<String, dynamic>? _lastErrorDetail;
  bool _isProcessingImage = false;

  bool _loadingMaster = false;
  bool _loadingRiwayat = false;
  bool _isSaving = false;

  // --- GETTERS ---
  List<dynamic> get masterPelanggaran => _masterPelanggaran;
  String get filterQuery => _filterQuery;
  List<dynamic> get filteredMasterPelanggaran {
    final q = _filterQuery.trim().toLowerCase();
    if (q.isEmpty) return _masterPelanggaran;
    return _masterPelanggaran.where((e) {
      final name = (e['nama_pelanggaran'] ?? '').toString().toLowerCase();
      final kategori = (e['kategori'] ?? '').toString().toLowerCase();
      return name.contains(q) || kategori.contains(q);
    }).toList();
  }

  List<dynamic> get daftarSiswa => _daftarSiswa;
  List<dynamic> get riwayatHariIni => _riwayatHariIni;
  List<int> get selectedPelanggaran => _selectedPelanggaran;
  Map<String, dynamic>? get siswaTerpilih => _siswaTerpilih;
  XFile? get fotoBukti => _fotoBukti;
  Uint8List? get webImage => _webImage; // Digunakan di UI (Image.memory)
  String? get lastErrorMessage => _lastErrorMessage;
  Map<String, dynamic>? get lastErrorDetail => _lastErrorDetail;
  bool get isProcessingImage => _isProcessingImage;

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

  void pilihSiswa(Map<String, dynamic>? siswa) {
    _siswaTerpilih = siswa;
    _daftarSiswa = [];
    notifyListeners();
  }

  Future<void> ambilFoto(bool dariKamera) async {
    _isProcessingImage = true;
    notifyListeners();

    final XFile? image = await _picker.pickImage(
      source: dariKamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    try {
      if (image != null) {
        final originalBytes = await image.readAsBytes();
        final compressed = _compressToTarget(
          originalBytes,
          maxSide: 256,
          maxBytes: 50 * 1024,
        );
        _fotoBukti = image;
        _fotoBuktiBytes = compressed;
        _webImage = compressed;
      }
    } finally {
      _isProcessingImage = false;
      notifyListeners();
    }
  }

  // --- API CALLS ---

  Future<void> ambilMasterPelanggaran(String token) async {
    _loadingMaster = true;
    notifyListeners();
    try {
      final hasil = await _apiServis.kirimPermintaan(
        ApiKonfig.masterPelanggaran,
        {'token': token},
      );
      if (hasil['status'] == 'sukses') {
        _masterPelanggaran = hasil['data'];
        _filterQuery = '';
      }
    } finally {
      _loadingMaster = false;
      notifyListeners();
    }
  }

  void setFilter(String q) {
    _filterQuery = q;
    notifyListeners();
  }

  void clearFilter() {
    _filterQuery = '';
    notifyListeners();
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
          'keyword': keyword,
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
      final hasil = await _apiServis.kirimPermintaan(ApiKonfig.riwayatHariIni, {
        'token': token,
      });
      if (hasil['status'] == 'sukses') {
        _riwayatHariIni = hasil['data'];
      }
    } finally {
      _loadingRiwayat = false;
      notifyListeners();
    }
  }

  Future<bool> simpanPelanggaran(String token) async {
    if (_siswaTerpilih == null || _selectedPelanggaran.isEmpty) {
      _lastErrorMessage = 'Pilih siswa dan pelanggaran terlebih dahulu.';
      _lastErrorDetail = null;
      return false;
    }

    _lastErrorMessage = null;
    _lastErrorDetail = null;
    _isSaving = true;
    notifyListeners();

    try {
      var uri = Uri.parse(ApiKonfig.simpanPelanggaran);
      var request = http.MultipartRequest('POST', uri);

      request.fields['token'] = token;
      request.fields['siswa_kelas_id'] = _siswaTerpilih!['siswa_kelas_id']
          .toString();
      request.fields['pelanggaran_ids'] = _selectedPelanggaran.join(',');
      request.fields['keterangan'] = "Dicatat via Mobile";

      if (_fotoBukti != null) {
        if (kIsWeb) {
          final bytes = _fotoBuktiBytes ?? await _fotoBukti!.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'foto',
              bytes,
              filename: 'pelanggaran.jpg',
            ),
          );
        } else {
          final bytes = _fotoBuktiBytes ?? await _fotoBukti!.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'foto',
              bytes,
              filename: 'pelanggaran.jpg',
            ),
          );
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        _lastErrorMessage = 'Gagal menghubungi server (${response.statusCode}).';
        _lastErrorDetail = {'response_body': response.body};
        return false;
      }

      final hasil = json.decode(response.body);

      if (hasil['status'] == 'sukses') {
        _selectedPelanggaran.clear();
        _siswaTerpilih = null;
        _fotoBukti = null;
        _webImage = null; // Reset pratinjau foto
        _fotoBuktiBytes = null;
        _filterQuery = '';
        ambilRiwayatHariIni(token);
        return true;
      }

      _lastErrorMessage = (hasil['pesan'] ?? 'Gagal menyimpan data.').toString();
      _lastErrorDetail = hasil['detail'] is Map
          ? Map<String, dynamic>.from(hasil['detail'])
          : {'detail': hasil['detail']};
      return false;
    } catch (e) {
      _lastErrorMessage = 'Terjadi kesalahan saat menyimpan.';
      _lastErrorDetail = {'error': e.toString()};
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> hapusPelanggaran(String token, String id) async {
    try {
      final response = await http.post(
        Uri.parse(ApiKonfig.hapusPelanggaran),
        body: {"token": token, "id": id},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'sukses') {
          ambilRiwayatHariIni(token); // Refresh list internal
          return true; // WAJIB ada return true
        }
      }
      return false; // WAJIB ada return false jika gagal
    } catch (e) {
      //print("Error hapus: $e");
      return false;
    }
  }

  void hapusFoto() {
    _fotoBukti = null;
    _webImage = null; // Reset untuk pratinjau web
    _fotoBuktiBytes = null;
    _isProcessingImage = false;
    notifyListeners();
  }

  Uint8List _compressToTarget(
    Uint8List input, {
    required int maxSide,
    required int maxBytes,
  }) {
    final decoded = img.decodeImage(input);
    if (decoded == null) return input;

    var resized = decoded;
    if (decoded.width > maxSide || decoded.height > maxSide) {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxSide : null,
        height: decoded.height > decoded.width ? maxSide : null,
        interpolation: img.Interpolation.average,
      );
    }

    var quality = 85;
    var output = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    while (output.lengthInBytes > maxBytes && quality > 35) {
      quality -= 10;
      output = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    }

    while (output.lengthInBytes > maxBytes) {
      final newWidth = (resized.width * 0.9).round();
      final newHeight = (resized.height * 0.9).round();
      if (newWidth < 100 || newHeight < 100) break;
      resized = img.copyResize(
        resized,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.average,
      );
      output = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    }

    return output;
  }
}
