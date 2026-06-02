import 'dart:math';
import 'package:geolocator/geolocator.dart';

class PresensiService {
  static const double kantorLat = -7.546831;
  static const double kantorLng = 112.226482;
  static const double maxRadius = 500.0;

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi (GPS) dinonaktifkan.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak secara permanen.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  double hitungJarak(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a));
  }

  Future<Map<String, dynamic>> kirimDataAbsensi({
    required double lat,
    required double lng,
    required String jenis,
    required String tipe,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'success': true,
      'message': 'Presensi $tipe harian $jenis berhasil dilakukan.',
    };
  }
}
