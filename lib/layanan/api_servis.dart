import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServis {
  // Tambahkan callback untuk menangani logout otomatis
  final Function? onLogout;

  ApiServis({this.onLogout});

  Future<Map<String, dynamic>> kirimPermintaan(String url, Map<String, String> data) async {
    try {
      final respon = await http.post(
        Uri.parse(url),
        body: data,
      ).timeout(const Duration(seconds: 10));

      if (respon.statusCode == 200) {
        final dataRespon = json.decode(respon.body);

        // CEK SINYAL LOGOUT DARI SERVER
        if (dataRespon['status'] == 'logout') {
          if (onLogout != null) {
            onLogout!(); // Picu fungsi logout di AuthProvider
          }
        }

        return dataRespon;
      } else {
        return {"status": "error", "pesan": "Server bermasalah (Code: ${respon.statusCode})"};
      }
    } catch (e) {
      return {"status": "error", "pesan": "Gagal terhubung ke server"};
    }
  }
}