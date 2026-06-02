import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'custom_sidebar.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ProfilePage({super.key, this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String baseUrl = 'https://izerobase.com/staffix';
  String? _token;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      };

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_token == null) return;

    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profil'),
        headers: _headers,
      );
      final res = jsonDecode(response.body);
      if (res['success'] == true) {
        if (mounted) {
          setState(() => userData = res['data']);
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? sidebarData = userData;
    if (sidebarData != null) {
      sidebarData = Map.from(sidebarData);
      String roleValue =
          sidebarData['role'] != null && sidebarData['role'] is Map
              ? sidebarData['role']['slug'] ?? 'employee'
              : sidebarData['role'] ?? sidebarData['role_slug'] ?? 'employee';
      sidebarData['role'] = roleValue;

      int roleIdValue = 7;
      if (sidebarData['role_id'] != null) {
        roleIdValue = sidebarData['role_id'];
      } else if (sidebarData['role'] != null) {
        if (sidebarData['role'] is Map) {
          roleIdValue = sidebarData['role']['id'] ?? 7;
        } else if (sidebarData['role'] is String) {
          switch (sidebarData['role']) {
            case 'super-admin':
              roleIdValue = 1;
              break;
            case 'owner':
              roleIdValue = 2;
              break;
            case 'hr-manager':
              roleIdValue = 3;
              break;
            case 'hr-staff':
              roleIdValue = 4;
              break;
            case 'payroll-admin':
              roleIdValue = 5;
              break;
            case 'manager':
              roleIdValue = 6;
              break;
            default:
              roleIdValue = 7;
          }
        }
      }
      sidebarData['role_id'] = roleIdValue;

      int paketIdValue = 1;
      if (sidebarData['paket_id'] != null) {
        paketIdValue = sidebarData['paket_id'];
      } else if (sidebarData['perusahaan'] != null &&
          sidebarData['perusahaan']['paket_id'] != null) {
        paketIdValue = sidebarData['perusahaan']['paket_id'];
      } else if (sidebarData['paket'] != null &&
          sidebarData['paket']['id'] != null) {
        paketIdValue = sidebarData['paket']['id'];
      }
      sidebarData['paket_id'] = paketIdValue;

      if (sidebarData['perusahaan'] != null) {
        sidebarData['perusahaan_data'] = sidebarData['perusahaan'];
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: userData != null ? CustomSidebar(userData: sidebarData!) : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.black87),
                      SizedBox(width: 10),
                      Text('Keluar'),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade200,
                child: userData?['foto_profil'] != null &&
                        userData!['foto_profil'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          userData!['foto_profil'],
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              userData?['name'] != null &&
                                      userData!['name'].toString().isNotEmpty
                                  ? userData!['name'][0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        userData?['name'] != null &&
                                userData!['name'].toString().isNotEmpty
                            ? userData!['name'][0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.black54,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    _buildMenuSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: userData?['foto_profil'] != null &&
                        userData!['foto_profil'].toString().isNotEmpty
                    ? NetworkImage(userData!['foto_profil'])
                    : null,
                child: userData?['foto_profil'] == null ||
                        userData!['foto_profil'].toString().isEmpty
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey.shade600,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userData?['name'] ?? '-',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                userData?['jabatan'] ??
                    (userData?['role'] != null && userData!['role'] is Map
                        ? userData!['role']['name']
                        : userData?['role'] ?? userData?['role_slug'] ?? '-'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                userData?['email'] ?? '-',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.business_center,
          title: 'Informasi Perusahaan',
          subtitle: 'Kelola data perusahaan',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditCompanyPage(
                data: userData?['perusahaan'] is Map
                    ? userData!['perusahaan']
                    : null,
                baseUrl: baseUrl,
                headers: _headers,
              ),
            ),
          ).then((_) => _loadData()),
        ),
        const SizedBox(height: 12),
        _buildMenuTile(
          icon: Icons.person_outline,
          title: 'Informasi Pribadi',
          subtitle: 'Perbarui data diri',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditPersonalPage(
                data: userData,
                baseUrl: baseUrl,
                headers: _headers,
              ),
            ),
          ).then((_) => _loadData()),
        ),
        const SizedBox(height: 12),
        _buildMenuTile(
          icon: Icons.security,
          title: 'Keamanan Akun',
          subtitle: 'Ubah password',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditPasswordPage(
                baseUrl: baseUrl,
                headers: _headers,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.black54, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditCompanyPage extends StatefulWidget {
  final Map<String, dynamic>? data;
  final String baseUrl;
  final Map<String, String> headers;
  const EditCompanyPage(
      {super.key, this.data, required this.baseUrl, required this.headers});

  @override
  State<EditCompanyPage> createState() => _EditCompanyPageState();
}

class _EditCompanyPageState extends State<EditCompanyPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _radiusController;

  String _lat = '-';
  String _lng = '-';
  String _gmapsUrl = '';
  File? _selectedLogo;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.data?['nama_perusahaan'] ?? '');
    _emailController =
        TextEditingController(text: widget.data?['email_perusahaan'] ?? '');
    _addressController =
        TextEditingController(text: widget.data?['alamat'] ?? '');
    _lat = widget.data?['latitude']?.toString() ?? '-';
    _lng = widget.data?['longitude']?.toString() ?? '-';
    _gmapsUrl = widget.data?['lokasi'] ?? '';

    if (widget.data?['radius'] != null && widget.data!['radius'] != 500) {
      _radiusController =
          TextEditingController(text: widget.data!['radius'].toString());
    } else {
      _radiusController = TextEditingController(text: '');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _nameController.text = widget.data?['nama_perusahaan'] ?? '';
      _emailController.text = widget.data?['email_perusahaan'] ?? '';
      _addressController.text = widget.data?['alamat'] ?? '';
      _lat = widget.data?['latitude']?.toString() ?? '-';
      _lng = widget.data?['longitude']?.toString() ?? '-';
      _gmapsUrl = widget.data?['lokasi'] ?? '';
      if (widget.data?['radius'] != null && widget.data!['radius'] != 500) {
        _radiusController.text = widget.data!['radius'].toString();
      } else {
        _radiusController.text = '';
      }
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedLogo = File(picked.path));
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Layanan GPS perangkat mati.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Izin akses lokasi ditolak.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Izin lokasi ditolak permanen di pengaturan.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);

    String rawLat = position.latitude.toString();
    String rawLng = position.longitude.toString();

    setState(() {
      _lat = rawLat;
      _lng = rawLng;
      _gmapsUrl = 'https://www.google.com/maps?q=$_lat,$_lng';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lokasi Terdeteksi: $_lat, $_lng'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final request = http.MultipartRequest(
        'POST', Uri.parse('${widget.baseUrl}/api/profil/update-perusahaan'))
      ..headers.addAll(widget.headers)
      ..fields.addAll({
        'nama_perusahaan': _nameController.text,
        'email_perusahaan': _emailController.text,
        'alamat': _addressController.text,
        'latitude': _lat,
        'longitude': _lng,
        'lokasi': _gmapsUrl,
      });

    if (_radiusController.text.isNotEmpty) {
      request.fields['radius'] = _radiusController.text;
    }

    if (_selectedLogo != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'logo_perusahaan', _selectedLogo!.path));
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);
    setState(() => _isSaving = false);

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data perusahaan berhasil disimpan'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${responseBody.body}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Perusahaan',
            style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _selectedLogo != null
                          ? FileImage(_selectedLogo!) as ImageProvider
                          : (widget.data?['logo'] != null &&
                                  widget.data!['logo'].toString().isNotEmpty
                              ? NetworkImage(widget.data!['logo'].toString())
                                  as ImageProvider
                              : null),
                      child: _selectedLogo == null &&
                              (widget.data?['logo'] == null ||
                                  widget.data!['logo'].toString().isEmpty)
                          ? Icon(Icons.business,
                              size: 50, color: Colors.grey.shade600)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                  controller: _nameController,
                  label: 'Nama Perusahaan',
                  icon: Icons.business),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _emailController,
                  label: 'Email Perusahaan',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 20, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('Titik Koordinat Absensi',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _getLocation,
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('Deteksi'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Latitude',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(_lat,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Longitude',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(_lng,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_gmapsUrl.isNotEmpty && _gmapsUrl != '-')
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Google Maps URL',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text(_gmapsUrl,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                          ],
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _addressController,
                  label: 'Alamat Kantor',
                  icon: Icons.location_city,
                  maxLines: 2),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _radiusController,
                  label: 'Radius Absensi (Meter)',
                  icon: Icons.radio_button_checked,
                  keyboardType: TextInputType.number,
                  hintText: 'Harap masukan radius'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Data Perusahaan',
                          style: TextStyle(fontSize: 15)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (label == 'Radius Absensi (Meter)' &&
            (value == null || value.isEmpty)) {
          return 'Harap masukan radius';
        }
        if (label == 'Radius Absensi (Meter)' &&
            value != null &&
            value.isNotEmpty) {
          if (int.tryParse(value) == null) {
            return 'Radius harus berupa angka';
          }
        }
        return null;
      },
    );
  }
}

class EditPersonalPage extends StatefulWidget {
  final Map<String, dynamic>? data;
  final String baseUrl;
  final Map<String, String> headers;
  const EditPersonalPage(
      {super.key, this.data, required this.baseUrl, required this.headers});

  @override
  State<EditPersonalPage> createState() => _EditPersonalPageState();
}

class _EditPersonalPageState extends State<EditPersonalPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _nipController;
  late TextEditingController _jabatanController;
  late TextEditingController _divisiController;

  String _statusKaryawan = 'tetap';
  File? _selectedPhoto;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data?['name'] ?? '');
    _emailController = TextEditingController(text: widget.data?['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.data?['nomor_telepon'] ?? '');
    _nipController = TextEditingController(text: widget.data?['nip'] ?? '');
    _jabatanController =
        TextEditingController(text: widget.data?['jabatan'] ?? '');
    _divisiController =
        TextEditingController(text: widget.data?['divisi'] ?? '');
    if (['tetap', 'kontrak', 'magang', 'probation']
        .contains(widget.data?['status_karyawan'])) {
      _statusKaryawan = widget.data!['status_karyawan'];
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _nameController.text = widget.data?['name'] ?? '';
      _emailController.text = widget.data?['email'] ?? '';
      _phoneController.text = widget.data?['nomor_telepon'] ?? '';
      _nipController.text = widget.data?['nip'] ?? '';
      _jabatanController.text = widget.data?['jabatan'] ?? '';
      _divisiController.text = widget.data?['divisi'] ?? '';
      if (['tetap', 'kontrak', 'magang', 'probation']
          .contains(widget.data?['status_karyawan'])) {
        _statusKaryawan = widget.data!['status_karyawan'];
      }
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedPhoto = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final request = http.MultipartRequest(
        'POST', Uri.parse('${widget.baseUrl}/api/profil/update'))
      ..headers.addAll(widget.headers)
      ..fields.addAll({
        'name': _nameController.text,
        'email': _emailController.text,
        'nomor_telepon': _phoneController.text,
        'nip': _nipController.text,
        'jabatan': _jabatanController.text,
        'divisi': _divisiController.text,
        'status_karyawan': _statusKaryawan,
      });

    if (_selectedPhoto != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'foto_profil', _selectedPhoto!.path));
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);
    setState(() => _isSaving = false);

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data pribadi berhasil disimpan'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${responseBody.body}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Informasi Pribadi',
            style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _selectedPhoto != null
                          ? FileImage(_selectedPhoto!)
                          : (widget.data?['foto_profil'] != null &&
                                  widget.data!['foto_profil']
                                      .toString()
                                      .isNotEmpty
                              ? NetworkImage(widget.data!['foto_profil'])
                              : null) as ImageProvider?,
                      child: _selectedPhoto == null &&
                              (widget.data?['foto_profil'] == null ||
                                  widget.data!['foto_profil']
                                      .toString()
                                      .isEmpty)
                          ? Icon(Icons.person,
                              size: 50, color: Colors.grey.shade600)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _nameController,
                label: 'Nama Lengkap',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Nomor Telepon',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nipController,
                label: 'NIP',
                icon: Icons.badge,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _jabatanController,
                label: 'Jabatan',
                icon: Icons.work,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _divisiController,
                label: 'Divisi',
                icon: Icons.group,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _statusKaryawan,
                decoration: InputDecoration(
                  labelText: 'Status Karyawan',
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: Icon(Icons.assignment_ind, color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.black54, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ['tetap', 'kontrak', 'magang', 'probation']
                    .map((val) => DropdownMenuItem(
                        value: val, child: Text(val.toUpperCase())))
                    .toList(),
                onChanged: (val) => setState(() => _statusKaryawan = val!),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan Perubahan',
                          style: TextStyle(fontSize: 15)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class EditPasswordPage extends StatefulWidget {
  final String baseUrl;
  final Map<String, String> headers;
  const EditPasswordPage(
      {super.key, required this.baseUrl, required this.headers});

  @override
  State<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password tidak cocok'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final response = await http.post(
      Uri.parse('${widget.baseUrl}/api/profil/update-password'),
      headers: widget.headers,
      body: {
        'password': _passController.text,
        'password_confirmation': _confirmController.text,
      },
    );
    setState(() => _isSaving = false);

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password berhasil diupdate'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        final res = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal update password'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Keamanan Akun',
            style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.security, size: 70, color: Colors.black54),
                    const SizedBox(height: 20),
                    const Text(
                      'Ubah Password',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gunakan password yang kuat dan unik',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _passController,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon:
                            const Icon(Icons.lock, color: Colors.black54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.black54, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Password tidak boleh kosong';
                        if (value.length < 8)
                          return 'Password minimal 8 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Colors.black54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.black54, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Konfirmasi password tidak boleh kosong';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Update Password',
                                style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
