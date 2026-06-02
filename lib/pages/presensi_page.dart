import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dashboard_page.dart';
import 'custom_sidebar.dart';
import 'dart:math' as math;

class PresensiPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const PresensiPage({super.key, this.userData});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _waktuString = "";
  String _tanggalString = "";
  late Timer _timer;
  late Timer _gpsTimer;

  bool _isGpsLoading = true;
  String _gpsStatusMessage = "Mendeteksi lokasi...";
  double? _userLat;
  double? _userLng;
  bool _isInRadius = false;
  double _radiusKantor = 500;
  double _kantorLat = -7.4409661;
  double _kantorLng = 112.3067495;

  bool _isSubmitting = false;
  bool _isLoadingData = true;
  bool _hasJadwal = false;
  String _jadwalErrorMessage = "";

  Map<String, dynamic>? _jadwalReguler;
  Map<String, dynamic>? _jadwalLembur;
  Map<String, dynamic>? _absensiReguler;
  Map<String, dynamic>? _absensiLembur;
  bool _isLibur = false;
  String _pesanLibur = "";
  Map<String, dynamic>? _userData;

  String _btnRegulerText = "";
  String _btnLemburText = "";
  Color _btnRegulerColor = const Color(0xFF4F46E5);
  Color _btnLemburColor = const Color(0xFFD97706);
  bool _btnRegulerEnabled = false;
  bool _btnLemburEnabled = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _updateWaktu();
      _timer = Timer.periodic(
          const Duration(seconds: 1), (Timer t) => _updateWaktu());
    });
    _tabController = TabController(length: 2, vsync: this);
    _userData = widget.userData;
    _initializeData();
  }

  @override
  void dispose() {
    _timer.cancel();
    _gpsTimer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _updateWaktu() {
    final DateTime now = DateTime.now();
    setState(() {
      _tanggalString = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
      _waktuString = "${DateFormat('HH:mm:ss').format(now)} WIB";
    });
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoadingData = true;
      _hasJadwal = false;
    });

    await _loadUserData();
    await _loadPerusahaanData();
    await _loadData();
    _startRealtimeGps();

    setState(() {
      _isLoadingData = false;
    });
  }

  void _startRealtimeGps() {
    _trackLokasiUser();
    _gpsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _trackLokasiUser();
    });
  }

  Future<void> _loadUserData() async {
    if (_userData != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        setState(() {
          _userData = jsonDecode(userDataStr);
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  int _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _updateButtonStatus() {
    final now = DateTime.now();
    final jamSekarang = now.hour * 60 + now.minute;

    if (_jadwalReguler == null) {
      setState(() {
        _btnRegulerEnabled = false;
        _btnRegulerText = "TIDAK ADA JADWAL";
      });
      return;
    }

    final jamMasukStr = _jadwalReguler!['jam_masuk'] ?? '08:00';
    final jamPulangStr = _jadwalReguler!['jam_pulang'] ?? '17:00';
    final toleransi = _jadwalReguler!['toleransi'] as int? ?? 0;

    final jamMasuk = _parseTimeToMinutes(jamMasukStr);
    final jamPulang = _parseTimeToMinutes(jamPulangStr);
    final batasAwalPulang = jamPulang - 120;

    setState(() {
      if (_absensiReguler != null &&
          _absensiReguler!['jam_masuk'] != null &&
          _absensiReguler!['jam_pulang'] != null) {
        _btnRegulerEnabled = false;
        _btnRegulerText = "ABSENSI SELESAI";
        _btnRegulerColor = Colors.grey;
        return;
      }

      if (_absensiReguler == null || _absensiReguler!['jam_masuk'] == null) {
        if (jamSekarang >= jamMasuk && jamSekarang <= jamMasuk + toleransi) {
          _btnRegulerEnabled = _isInRadius;
          _btnRegulerText = "ABSEN MASUK";
          _btnRegulerColor = const Color(0xFF4F46E5);
        } else {
          _btnRegulerEnabled = false;
          _btnRegulerText = "ABSEN DITUTUP";
          _btnRegulerColor = Colors.grey;
        }
      } else if (_absensiReguler!['jam_masuk'] != null &&
          (_absensiReguler!['jam_pulang'] == null)) {
        if (jamSekarang >= batasAwalPulang &&
            jamSekarang <= jamPulang + toleransi) {
          _btnRegulerEnabled = _isInRadius;
          _btnRegulerText = "ABSEN PULANG";
          _btnRegulerColor = const Color(0xFF4F46E5);
        } else {
          _btnRegulerEnabled = false;
          _btnRegulerText = "ABSEN DITUTUP";
          _btnRegulerColor = Colors.grey;
        }
      }
    });
  }

  void _updateLemburStatus() {
    if (_jadwalLembur == null) {
      setState(() {
        _btnLemburEnabled = false;
        _btnLemburText = "TIDAK ADA JADWAL";
      });
      return;
    }

    final now = DateTime.now();
    final jamSekarang = now.hour * 60 + now.minute;

    final jamMulaiStr = _jadwalLembur!['jam_mulai'] ?? '00:00';
    final jamSelesaiStr = _jadwalLembur!['jam_selesai'] ?? '00:00';
    final toleransi = _jadwalLembur!['toleransi'] as int? ?? 0;

    final jamMulai = _parseTimeToMinutes(jamMulaiStr);
    final jamSelesai = _parseTimeToMinutes(jamSelesaiStr);
    final batasAwalPulang = jamSelesai - 120;

    setState(() {
      if (_absensiLembur != null &&
          _absensiLembur!['jam_masuk'] != null &&
          _absensiLembur!['jam_pulang'] != null) {
        _btnLemburEnabled = false;
        _btnLemburText = "ABSENSI SELESAI";
        _btnLemburColor = Colors.grey;
        return;
      }

      if (_absensiLembur == null || _absensiLembur!['jam_masuk'] == null) {
        if (jamSekarang >= jamMulai && jamSekarang <= jamMulai + toleransi) {
          _btnLemburEnabled = _isInRadius;
          _btnLemburText = "ABSEN MASUK";
          _btnLemburColor = const Color(0xFFD97706);
        } else {
          _btnLemburEnabled = false;
          _btnLemburText = "ABSEN DITUTUP";
          _btnLemburColor = Colors.grey;
        }
      } else if (_absensiLembur!['jam_masuk'] != null &&
          (_absensiLembur!['jam_pulang'] == null)) {
        if (jamSekarang >= batasAwalPulang &&
            jamSekarang <= jamSelesai + toleransi) {
          _btnLemburEnabled = _isInRadius;
          _btnLemburText = "ABSEN PULANG";
          _btnLemburColor = const Color(0xFFD97706);
        } else {
          _btnLemburEnabled = false;
          _btnLemburText = "ABSEN DITUTUP";
          _btnLemburColor = Colors.grey;
        }
      }
    });
  }

  Future<void> _loadPerusahaanData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final baseUrl = 'https://izerobase.com/staffix';

      final response = await http.get(
        Uri.parse('$baseUrl/api/perusahaan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final perusahaan = data['data'];
          setState(() {
            if (perusahaan['latitude'] != null &&
                perusahaan['latitude'].toString() != '-') {
              _kantorLat = double.parse(perusahaan['latitude'].toString());
            }
            if (perusahaan['longitude'] != null &&
                perusahaan['longitude'].toString() != '-') {
              _kantorLng = double.parse(perusahaan['longitude'].toString());
            }
            if (perusahaan['radius'] != null && perusahaan['radius'] != 500) {
              _radiusKantor = double.parse(perusahaan['radius'].toString());
            }
          });
        }
      }
    } catch (e) {
      print('Error loading perusahaan data: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final baseUrl = 'https://izerobase.com/staffix';

      final response = await http.get(
        Uri.parse('$baseUrl/api/absensi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final responseData = data['data'];

          setState(() {
            _isLibur = responseData['is_libur'] ?? false;
            _pesanLibur = responseData['pesan_libur'] ?? '';

            if (!_isLibur) {
              _jadwalReguler = responseData['jadwal_final'];
              _jadwalLembur = responseData['jadwal_khusus'];
              _absensiReguler = responseData['absensi_reguler'];
              _absensiLembur = responseData['absensi_khusus'];

              bool jadwalValid = _jadwalReguler != null;

              if (jadwalValid) {
                _hasJadwal = true;
                _jadwalErrorMessage = "";
              } else {
                _hasJadwal = false;
                _jadwalErrorMessage =
                    "Jadwal anda belum disetting Atasan, Konfirmasikan ke atasan";
              }
            }
          });

          if (!_isLibur && _hasJadwal) {
            _updateButtonStatus();
            _updateLemburStatus();
          }
        }
      } else {
        setState(() {
          _hasJadwal = false;
          _jadwalErrorMessage =
              "Jadwal anda belum disetting Atasan, Konfirmasikan ke atasan";
        });
      }
    } catch (e) {
      setState(() {
        _hasJadwal = false;
        _jadwalErrorMessage =
            "Jadwal anda belum disetting Atasan, Konfirmasikan ke atasan";
      });
      print('Error loading data: $e');
    }
  }

  Future<void> _trackLokasiUser() async {
    try {
      if (!mounted) return;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isGpsLoading = false;
          _isInRadius = false;
          _gpsStatusMessage = "GPS tidak aktif";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isGpsLoading = false;
            _isInRadius = false;
            _gpsStatusMessage = "Izin lokasi ditolak";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isGpsLoading = false;
          _isInRadius = false;
          _gpsStatusMessage = "Izin lokasi ditolak permanen";
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);

      final jarak = _hitungJarak(
          position.latitude, position.longitude, _kantorLat, _kantorLng);
      final dalamRadius = jarak <= _radiusKantor;

      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
        _isInRadius = dalamRadius;
        _isGpsLoading = false;

        if (dalamRadius) {
          _gpsStatusMessage =
              "Lokasi: ${jarak.toStringAsFixed(0)}m (Dalam Radius $_radiusKantor m)";
        } else {
          _gpsStatusMessage =
              "Jarak: ${jarak.toStringAsFixed(0)}m (Luar Radius $_radiusKantor m)";
        }

        if (!_isLibur && _hasJadwal) {
          _updateButtonStatus();
          _updateLemburStatus();
        }
      });
    } catch (e) {
      setState(() {
        _isGpsLoading = false;
        _isInRadius = false;
        _gpsStatusMessage = "GPS Error, coba lagi";
      });
    }
  }

  double _hitungJarak(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000;
    double lat1Rad = lat1 * math.pi / 180;
    double lat2Rad = lat2 * math.pi / 180;
    double deltaLat = (lat2 - lat1) * math.pi / 180;
    double deltaLng = (lng2 - lng1) * math.pi / 180;

    double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  Future<void> _submitPresensiAction(String jenis) async {
    if (!_isInRadius || _userLat == null || _userLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Anda berada di luar radius absensi!'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final baseUrl = 'https://izerobase.com/staffix';

      final response = await http.post(
        Uri.parse('$baseUrl/api/absensi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'lat': _userLat.toString(),
          'lng': _userLng.toString(),
          'jenis': jenis,
        },
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message']),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Gagal melakukan absensi'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'), backgroundColor: Colors.redAccent));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _navigateToDashboard() {
    if (_userData != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(initialUserData: _userData!),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          title: const Text("Presensi Karyawan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
        ),
        drawer: _userData != null ? CustomSidebar(userData: _userData!) : null,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
        ),
      );
    }

    if (_isLibur) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          title: const Text("Presensi Karyawan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
        ),
        drawer: _userData != null ? CustomSidebar(userData: _userData!) : null,
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration_rounded,
                    size: 80, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 32),
              Text(
                _pesanLibur.isNotEmpty ? _pesanLibur : "Selamat Hari Libur",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  "Nikmati waktu istirahat Anda. Sistem absensi saat ini sedang dinonaktifkan untuk hari ini.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: _navigateToDashboard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.home_rounded, size: 18),
                label: const Text("Kembali ke Beranda"),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasJadwal) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          title: const Text("Presensi Karyawan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
        ),
        drawer: _userData != null ? CustomSidebar(userData: _userData!) : null,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber,
                    size: 80, color: Color(0xFFF59E0B)),
                const SizedBox(height: 16),
                Text(
                  _jadwalErrorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Text("Presensi Karyawan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      drawer: _userData != null ? CustomSidebar(userData: _userData!) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Text("E-PRESENSI",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Text(_tanggalString,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569))),
                        const SizedBox(height: 4),
                        Text(_waktuString,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4F46E5),
                                letterSpacing: 0.5)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "ABSENSI HARIAN"),
                  Tab(text: "LEMBUR"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 420,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPanelReguler(),
                  _buildPanelLembur(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPanelReguler() {
    final sudahMasuk =
        _absensiReguler != null && _absensiReguler!['jam_masuk'] != null;
    final sudahPulang =
        _absensiReguler != null && _absensiReguler!['jam_pulang'] != null;

    if (sudahMasuk && sudahPulang) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 64),
            const SizedBox(height: 16),
            const Text(
              "Terima kasih, absensi Anda hari ini sudah lengkap.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  color: const Color(0xFF4F46E5), size: 18),
              const SizedBox(width: 8),
              const Text(
                "Absensi Harian",
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(
                  child: _buildItemJam("Jam Masuk",
                      _jadwalReguler?['jam_masuk'] ?? "08:00 WIB")),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildItemJam("Jam Pulang",
                      _jadwalReguler?['jam_pulang'] ?? "17:00 WIB")),
            ],
          ),
          if ((_jadwalReguler?['toleransi'] ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Toleransi ${_jadwalReguler?['toleransi']} menit",
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isGpsLoading
                  ? const Color(0xFFFEF3C7)
                  : (_isInRadius
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEE2E2)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _isGpsLoading
                      ? const Color(0xFFFDE68A)
                      : (_isInRadius
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFFCA5A5))),
            ),
            child: Row(
              children: [
                _isGpsLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFB45309)))
                    : Icon(Icons.location_on,
                        color: _isInRadius
                            ? const Color(0xFF047857)
                            : const Color(0xFFB91C1C),
                        size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _gpsStatusMessage,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isGpsLoading
                            ? const Color(0xFF78350F)
                            : (_isInRadius
                                ? const Color(0xFF065F46)
                                : const Color(0xFF991B1B))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_btnRegulerEnabled && _isInRadius && !_isSubmitting)
                  ? () => _submitPresensiAction('reguler')
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _btnRegulerColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                disabledForegroundColor: const Color(0xFF64748B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      _btnRegulerText,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.3),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelLembur() {
    if (_jadwalLembur == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF94A3B8), size: 64),
            const SizedBox(height: 16),
            const Text(
              "Tidak ada event / lembur hari ini",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  fontSize: 14),
            ),
          ],
        ),
      );
    }

    final sudahMasuk =
        _absensiLembur != null && _absensiLembur!['jam_masuk'] != null;
    final sudahPulang =
        _absensiLembur != null && _absensiLembur!['jam_pulang'] != null;

    if (sudahMasuk && sudahPulang) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFD97706), size: 64),
            const SizedBox(height: 16),
            const Text(
              "Terima kasih, absensi lembur Anda sudah lengkap.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  color: const Color(0xFFD97706), size: 18),
              const SizedBox(width: 8),
              Text(
                _jadwalLembur?['tipe'] ?? "Absensi Lembur",
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              children: [
                Text(
                  _jadwalLembur?['keterangan'] ?? "Lembur",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  "${_jadwalLembur?['jam_mulai'] ?? '00:00'} - ${_jadwalLembur?['jam_selesai'] ?? '00:00'} WIB",
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if ((_jadwalLembur?['toleransi'] ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Toleransi ${_jadwalLembur?['toleransi']} menit",
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF92400E)),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isGpsLoading
                  ? const Color(0xFFFEF3C7)
                  : (_isInRadius
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEE2E2)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _isGpsLoading
                      ? const Color(0xFFFDE68A)
                      : (_isInRadius
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFFCA5A5))),
            ),
            child: Row(
              children: [
                _isGpsLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFB45309)))
                    : Icon(Icons.location_on,
                        color: _isInRadius
                            ? const Color(0xFF047857)
                            : const Color(0xFFB91C1C),
                        size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _gpsStatusMessage,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isGpsLoading
                            ? const Color(0xFF78350F)
                            : (_isInRadius
                                ? const Color(0xFF065F46)
                                : const Color(0xFF991B1B))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_btnLemburEnabled && _isInRadius && !_isSubmitting)
                  ? () => _submitPresensiAction('khusus')
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _btnLemburColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                disabledForegroundColor: const Color(0xFF64748B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      _btnLemburText,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.3),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemJam(String status, String jam) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(status,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Text(jam,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF334155))),
        ],
      ),
    );
  }
}
