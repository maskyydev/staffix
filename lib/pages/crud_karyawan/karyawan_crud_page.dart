import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../custom_sidebar.dart';

class Karyawan {
  final int id;
  final String name;
  final String email;
  final int roleId;
  final String? fotoProfil;
  final String? nomorTelepon;
  final String? nip;
  final String? jabatan;
  final String? divisi;
  final String? statusKaryawan;
  final DateTime? tanggalBergabung;
  final DateTime? kontrakBerakhir;
  final String? bankName;
  final String? bankAccountNumber;
  final String? npwp;
  final String? bpjsKesehatan;
  final String? bpjsKetenagakerjaan;
  final String? tempatLahir;
  final DateTime? tanggalLahir;
  final String? alamatKtp;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final Map<String, dynamic>? role;

  Karyawan({
    required this.id,
    required this.name,
    required this.email,
    required this.roleId,
    this.fotoProfil,
    this.nomorTelepon,
    this.nip,
    this.jabatan,
    this.divisi,
    this.statusKaryawan,
    this.tanggalBergabung,
    this.kontrakBerakhir,
    this.bankName,
    this.bankAccountNumber,
    this.npwp,
    this.bpjsKesehatan,
    this.bpjsKetenagakerjaan,
    this.tempatLahir,
    this.tanggalLahir,
    this.alamatKtp,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.role,
  });

  factory Karyawan.fromJson(Map<String, dynamic> json) {
    return Karyawan(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roleId: json['role_id'] ?? 0,
      fotoProfil: json['foto_profil'],
      nomorTelepon: json['nomor_telepon'],
      nip: json['nip'],
      jabatan: json['jabatan'],
      divisi: json['divisi'],
      statusKaryawan: json['status_karyawan'],
      tanggalBergabung: json['tanggal_bergabung'] != null
          ? DateTime.tryParse(
              json['tanggal_bergabung'].toString().split('T')[0])
          : null,
      kontrakBerakhir: json['kontrak_berakhir'] != null
          ? DateTime.tryParse(json['kontrak_berakhir'].toString().split('T')[0])
          : null,
      bankName: json['detail'] != null ? json['detail']['bank_name'] : null,
      bankAccountNumber:
          json['detail'] != null ? json['detail']['bank_account_number'] : null,
      npwp: json['detail'] != null ? json['detail']['npwp'] : null,
      bpjsKesehatan:
          json['detail'] != null ? json['detail']['bpjs_kesehatan'] : null,
      bpjsKetenagakerjaan: json['detail'] != null
          ? json['detail']['bpjs_ketenagakerjaan']
          : null,
      tempatLahir:
          json['detail'] != null ? json['detail']['tempat_lahir'] : null,
      tanggalLahir:
          json['detail'] != null && json['detail']['tanggal_lahir'] != null
              ? DateTime.tryParse(
                  json['detail']['tanggal_lahir'].toString().split('T')[0])
              : null,
      alamatKtp: json['detail'] != null ? json['detail']['alamat_ktp'] : null,
      emergencyContactName: json['detail'] != null
          ? json['detail']['emergency_contact_name']
          : null,
      emergencyContactPhone: json['detail'] != null
          ? json['detail']['emergency_contact_phone']
          : null,
      role: json['role'],
    );
  }
}

class KaryawanCrudPage extends StatefulWidget {
  const KaryawanCrudPage({super.key});

  @override
  State<KaryawanCrudPage> createState() => _KaryawanCrudPageState();
}

class _KaryawanCrudPageState extends State<KaryawanCrudPage> {
  List<Karyawan> _karyawanList = [];
  List<Karyawan> _filteredKaryawanList = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  late ScrollController _scrollController;
  Map<String, dynamic> _userData = {};

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomorTeleponController = TextEditingController();
  final _nipController = TextEditingController();
  final _jabatanController = TextEditingController();
  final _divisiController = TextEditingController();
  final _statusKaryawanController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _npwpController = TextEditingController();
  final _bpjsKesehatanController = TextEditingController();
  final _bpjsKetenagakerjaanController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _alamatKtpController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();

  DateTime? _selectedTanggalBergabung;
  DateTime? _selectedKontrakBerakhir;
  DateTime? _selectedTanggalLahir;
  File? _selectedFoto;
  int? _selectedRoleId;
  int? _editingId;
  String? _existingFotoProfil;

  final String _baseUrl = 'https://izerobase.com/staffix/api/karyawan';
  String _authToken = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nomorTeleponController.dispose();
    _nipController.dispose();
    _jabatanController.dispose();
    _divisiController.dispose();
    _statusKaryawanController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _npwpController.dispose();
    _bpjsKesehatanController.dispose();
    _bpjsKetenagakerjaanController.dispose();
    _tempatLahirController.dispose();
    _alamatKtpController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _loadMoreData() {
    if (_paginatedKaryawan.length < _filteredKaryawanList.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('token') ?? '';

    final String userDataString = prefs.getString('user') ?? '{}';

    try {
      _userData = json.decode(userDataString);
    } catch (e) {
      _userData = {};
    }

    await _fetchKaryawan();
  }

  Future<void> _fetchKaryawan() async {
    if (_authToken.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> karyawanData = data['data'];
          setState(() {
            _karyawanList =
                karyawanData.map((item) => Karyawan.fromJson(item)).toList();
            _filteredKaryawanList = _karyawanList;
            _currentPage = 1;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load data';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (_searchQuery.isEmpty) {
        _filteredKaryawanList = _karyawanList;
      } else {
        _filteredKaryawanList = _karyawanList.where((karyawan) {
          return karyawan.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              karyawan.email
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (karyawan.nip
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false);
        }).toList();
      }
      _currentPage = 1;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _filteredKaryawanList = _karyawanList;
      _currentPage = 1;
    });
  }

  List<Karyawan> get _paginatedKaryawan {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    if (startIndex >= _filteredKaryawanList.length) {
      return [];
    }
    if (endIndex > _filteredKaryawanList.length) {
      return _filteredKaryawanList.sublist(startIndex);
    }
    return _filteredKaryawanList.sublist(startIndex, endIndex);
  }

  bool get _hasMoreData {
    return _paginatedKaryawan.length < _filteredKaryawanList.length;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _selectedFoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        if (type == 'bergabung') {
          _selectedTanggalBergabung = picked;
        } else if (type == 'kontrak') {
          _selectedKontrakBerakhir = picked;
        } else if (type == 'lahir') {
          _selectedTanggalLahir = picked;
        }
      });
    }
  }

  Future<void> _createKaryawan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Role ID harus diisi')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.headers['Authorization'] = 'Bearer $_authToken';

      request.fields['name'] = _nameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['password'] = _passwordController.text;
      request.fields['role_id'] = _selectedRoleId.toString();

      if (_nomorTeleponController.text.isNotEmpty)
        request.fields['nomor_telepon'] = _nomorTeleponController.text;
      if (_nipController.text.isNotEmpty)
        request.fields['nip'] = _nipController.text;
      if (_jabatanController.text.isNotEmpty)
        request.fields['jabatan'] = _jabatanController.text;
      if (_divisiController.text.isNotEmpty)
        request.fields['divisi'] = _divisiController.text;
      if (_statusKaryawanController.text.isNotEmpty)
        request.fields['status_karyawan'] = _statusKaryawanController.text;
      if (_selectedTanggalBergabung != null)
        request.fields['tanggal_bergabung'] =
            DateFormat('yyyy-MM-dd').format(_selectedTanggalBergabung!);
      if (_selectedKontrakBerakhir != null)
        request.fields['kontrak_berakhir'] =
            DateFormat('yyyy-MM-dd').format(_selectedKontrakBerakhir!);
      if (_bankNameController.text.isNotEmpty)
        request.fields['bank_name'] = _bankNameController.text;
      if (_bankAccountNumberController.text.isNotEmpty)
        request.fields['bank_account_number'] =
            _bankAccountNumberController.text;
      if (_npwpController.text.isNotEmpty)
        request.fields['npwp'] = _npwpController.text;
      if (_bpjsKesehatanController.text.isNotEmpty)
        request.fields['bpjs_kesehatan'] = _bpjsKesehatanController.text;
      if (_bpjsKetenagakerjaanController.text.isNotEmpty)
        request.fields['bpjs_ketenagakerjaan'] =
            _bpjsKetenagakerjaanController.text;
      if (_tempatLahirController.text.isNotEmpty)
        request.fields['tempat_lahir'] = _tempatLahirController.text;
      if (_selectedTanggalLahir != null)
        request.fields['tanggal_lahir'] =
            DateFormat('yyyy-MM-dd').format(_selectedTanggalLahir!);
      if (_alamatKtpController.text.isNotEmpty)
        request.fields['alamat_ktp'] = _alamatKtpController.text;
      if (_emergencyContactNameController.text.isNotEmpty)
        request.fields['emergency_contact_name'] =
            _emergencyContactNameController.text;
      if (_emergencyContactPhoneController.text.isNotEmpty)
        request.fields['emergency_contact_phone'] =
            _emergencyContactPhoneController.text;

      if (_selectedFoto != null) {
        final fileStream = http.ByteStream(_selectedFoto!.openRead());
        final fileLength = await _selectedFoto!.length();
        final multipartFile = http.MultipartFile(
          'foto_profil',
          fileStream,
          fileLength,
          filename: _selectedFoto!.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 && data['success'] == true) {
        _resetForm();
        await _fetchKaryawan();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Karyawan berhasil ditambahkan')));
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? 'Gagal menambahkan karyawan')));
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateKaryawan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('$_baseUrl/$_editingId?_method=PUT'));
      request.headers['Authorization'] = 'Bearer $_authToken';

      request.fields['name'] = _nameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['role_id'] = _selectedRoleId.toString();

      if (_passwordController.text.isNotEmpty)
        request.fields['password'] = _passwordController.text;
      if (_nomorTeleponController.text.isNotEmpty)
        request.fields['nomor_telepon'] = _nomorTeleponController.text;
      if (_nipController.text.isNotEmpty)
        request.fields['nip'] = _nipController.text;
      if (_jabatanController.text.isNotEmpty)
        request.fields['jabatan'] = _jabatanController.text;
      if (_divisiController.text.isNotEmpty)
        request.fields['divisi'] = _divisiController.text;
      if (_statusKaryawanController.text.isNotEmpty)
        request.fields['status_karyawan'] = _statusKaryawanController.text;
      if (_selectedTanggalBergabung != null)
        request.fields['tanggal_bergabung'] =
            DateFormat('yyyy-MM-dd').format(_selectedTanggalBergabung!);
      if (_selectedKontrakBerakhir != null)
        request.fields['kontrak_berakhir'] =
            DateFormat('yyyy-MM-dd').format(_selectedKontrakBerakhir!);
      if (_bankNameController.text.isNotEmpty)
        request.fields['bank_name'] = _bankNameController.text;
      if (_bankAccountNumberController.text.isNotEmpty)
        request.fields['bank_account_number'] =
            _bankAccountNumberController.text;
      if (_npwpController.text.isNotEmpty)
        request.fields['npwp'] = _npwpController.text;
      if (_bpjsKesehatanController.text.isNotEmpty)
        request.fields['bpjs_kesehatan'] = _bpjsKesehatanController.text;
      if (_bpjsKetenagakerjaanController.text.isNotEmpty)
        request.fields['bpjs_ketenagakerjaan'] =
            _bpjsKetenagakerjaanController.text;
      if (_tempatLahirController.text.isNotEmpty)
        request.fields['tempat_lahir'] = _tempatLahirController.text;
      if (_selectedTanggalLahir != null)
        request.fields['tanggal_lahir'] =
            DateFormat('yyyy-MM-dd').format(_selectedTanggalLahir!);
      if (_alamatKtpController.text.isNotEmpty)
        request.fields['alamat_ktp'] = _alamatKtpController.text;
      if (_emergencyContactNameController.text.isNotEmpty)
        request.fields['emergency_contact_name'] =
            _emergencyContactNameController.text;
      if (_emergencyContactPhoneController.text.isNotEmpty)
        request.fields['emergency_contact_phone'] =
            _emergencyContactPhoneController.text;

      if (_selectedFoto != null) {
        final fileStream = http.ByteStream(_selectedFoto!.openRead());
        final fileLength = await _selectedFoto!.length();
        final multipartFile = http.MultipartFile(
          'foto_profil',
          fileStream,
          fileLength,
          filename: _selectedFoto!.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 && data['success'] == true) {
        _resetForm();
        await _fetchKaryawan();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Karyawan berhasil diperbarui')));
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? 'Gagal memperbarui karyawan')));
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteKaryawan(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Hapus Karyawan'),
        content: Text('Apakah Anda yakin ingin menghapus $name?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json'
        },
      );
      final data = json.decode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        await _fetchKaryawan();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Karyawan berhasil dihapus')));
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? 'Gagal menghapus karyawan')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _nomorTeleponController.clear();
    _nipController.clear();
    _jabatanController.clear();
    _divisiController.clear();
    _statusKaryawanController.clear();
    _bankNameController.clear();
    _bankAccountNumberController.clear();
    _npwpController.clear();
    _bpjsKesehatanController.clear();
    _bpjsKetenagakerjaanController.clear();
    _tempatLahirController.clear();
    _alamatKtpController.clear();
    _emergencyContactNameController.clear();
    _emergencyContactPhoneController.clear();
    _selectedTanggalBergabung = null;
    _selectedKontrakBerakhir = null;
    _selectedTanggalLahir = null;
    _selectedFoto = null;
    _selectedRoleId = null;
    _editingId = null;
    _existingFotoProfil = null;
  }

  void _editKaryawan(Karyawan karyawan) {
    _editingId = karyawan.id;
    _nameController.text = karyawan.name;
    _emailController.text = karyawan.email;
    _selectedRoleId = karyawan.roleId;
    _nomorTeleponController.text = karyawan.nomorTelepon ?? '';
    _nipController.text = karyawan.nip ?? '';
    _jabatanController.text = karyawan.jabatan ?? '';
    _divisiController.text = karyawan.divisi ?? '';
    _statusKaryawanController.text = karyawan.statusKaryawan ?? '';
    _selectedTanggalBergabung = karyawan.tanggalBergabung;
    _selectedKontrakBerakhir = karyawan.kontrakBerakhir;
    _bankNameController.text = karyawan.bankName ?? '';
    _bankAccountNumberController.text = karyawan.bankAccountNumber ?? '';
    _npwpController.text = karyawan.npwp ?? '';
    _bpjsKesehatanController.text = karyawan.bpjsKesehatan ?? '';
    _bpjsKetenagakerjaanController.text = karyawan.bpjsKetenagakerjaan ?? '';
    _tempatLahirController.text = karyawan.tempatLahir ?? '';
    _selectedTanggalLahir = karyawan.tanggalLahir;
    _alamatKtpController.text = karyawan.alamatKtp ?? '';
    _emergencyContactNameController.text = karyawan.emergencyContactName ?? '';
    _emergencyContactPhoneController.text =
        karyawan.emergencyContactPhone ?? '';
    _existingFotoProfil = karyawan.fotoProfil;
    _showFormDialog();
  }

  void _showFormDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateBottomSheet) {
              return Container(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                            border:
                                Border(bottom: BorderSide(color: Colors.grey))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                _editingId == null
                                    ? 'Tambah Karyawan'
                                    : 'Edit Karyawan',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Center(
                                child: Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(60),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: _selectedFoto != null
                                      ? ClipOval(
                                          child: Image.file(_selectedFoto!,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover))
                                      : (_existingFotoProfil != null &&
                                              _existingFotoProfil!.isNotEmpty)
                                          ? ClipOval(
                                              child: Image.network(
                                                _existingFotoProfil!,
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(Icons.person,
                                                        size: 40),
                                              ),
                                            )
                                          : const Icon(Icons.camera_alt,
                                              size: 40),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap',
                                  border: OutlineInputBorder()),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Nama harus diisi'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder()),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Email harus diisi';
                                if (!value.contains('@'))
                                  return 'Email tidak valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_editingId == null ||
                                _passwordController.text.isNotEmpty)
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: _editingId == null
                                      ? 'Password'
                                      : 'Password (kosongkan jika tidak diubah)',
                                  border: const OutlineInputBorder(),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (_editingId == null &&
                                      (value == null || value.isEmpty))
                                    return 'Password harus diisi';
                                  if (value != null &&
                                      value.isNotEmpty &&
                                      value.length < 8)
                                    return 'Password minimal 8 karakter';
                                  return null;
                                },
                              ),
                            const SizedBox(height: 12),
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Role ID',
                                  border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              initialValue: _selectedRoleId?.toString() ?? '',
                              onChanged: (value) =>
                                  _selectedRoleId = int.tryParse(value),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Role ID harus diisi'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                                controller: _nipController,
                                decoration: const InputDecoration(
                                    labelText: 'NIP',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nomorTeleponController,
                              decoration: const InputDecoration(
                                  labelText: 'Nomor Telepon',
                                  border: OutlineInputBorder()),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                                controller: _jabatanController,
                                decoration: const InputDecoration(
                                    labelText: 'Jabatan',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 12),
                            TextFormField(
                                controller: _divisiController,
                                decoration: const InputDecoration(
                                    labelText: 'Divisi',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 12),
                            TextFormField(
                                controller: _statusKaryawanController,
                                decoration: const InputDecoration(
                                    labelText: 'Status Karyawan',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 12),
                            ListTile(
                              title: const Text('Tanggal Bergabung'),
                              subtitle: Text(_selectedTanggalBergabung != null
                                  ? DateFormat('dd MMMM yyyy')
                                      .format(_selectedTanggalBergabung!)
                                  : 'Belum dipilih'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _selectDate(context, 'bergabung'),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              title: const Text('Kontrak Berakhir'),
                              subtitle: Text(_selectedKontrakBerakhir != null
                                  ? DateFormat('dd MMMM yyyy')
                                      .format(_selectedKontrakBerakhir!)
                                  : 'Belum dipilih'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _selectDate(context, 'kontrak'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                                controller: _bankNameController,
                                decoration: const InputDecoration(
                                    labelText: 'Nama Bank',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bankAccountNumberController,
                              decoration: const InputDecoration(
                                  labelText: 'Nomor Rekening',
                                  border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                                controller: _npwpController,
                                decoration: const InputDecoration(
                                    labelText: 'NPWP',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bpjsKesehatanController,
                              decoration: const InputDecoration(
                                  labelText: 'BPJS Kesehatan',
                                  border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bpjsKetenagakerjaanController,
                              decoration: const InputDecoration(
                                  labelText: 'BPJS Ketenagakerjaan',
                                  border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                                controller: _tempatLahirController,
                                decoration: const InputDecoration(
                                    labelText: 'Tempat Lahir',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 12),
                            ListTile(
                              title: const Text('Tanggal Lahir'),
                              subtitle: Text(_selectedTanggalLahir != null
                                  ? DateFormat('dd MMMM yyyy')
                                      .format(_selectedTanggalLahir!)
                                  : 'Belum dipilih'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _selectDate(context, 'lahir'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _alamatKtpController,
                              decoration: const InputDecoration(
                                  labelText: 'Alamat KTP',
                                  border: OutlineInputBorder()),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emergencyContactNameController,
                              decoration: const InputDecoration(
                                  labelText: 'Emergency Contact Name',
                                  border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emergencyContactPhoneController,
                              decoration: const InputDecoration(
                                  labelText: 'Emergency Contact Phone',
                                  border: OutlineInputBorder()),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : (_editingId == null
                                      ? _createKaryawan
                                      : _updateKaryawan),
                              style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.white),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Text(_editingId == null
                                      ? 'Tambah Karyawan'
                                      : 'Update Karyawan'),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ).then((_) => _resetForm());
  }

  Widget _buildKaryawanCard(Karyawan karyawan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editKaryawan(karyawan),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.grey.shade300, width: 2)),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: (karyawan.fotoProfil != null &&
                            karyawan.fotoProfil!.isNotEmpty)
                        ? NetworkImage(karyawan.fotoProfil!)
                        : null,
                    child: (karyawan.fotoProfil == null ||
                            karyawan.fotoProfil!.isEmpty)
                        ? Text(
                            karyawan.name.isNotEmpty
                                ? karyawan.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600))
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(karyawan.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(karyawan.email,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      if (karyawan.jabatan != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.work,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(karyawan.jabatan!,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                      if (karyawan.divisi != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.business_center,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(karyawan.divisi!,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editKaryawan(karyawan),
                      icon: Icon(Icons.edit, color: Colors.blue.shade600),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.shade50),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () =>
                          _deleteKaryawan(karyawan.id, karyawan.name),
                      icon: Icon(Icons.delete, color: Colors.red.shade600),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: TextField(
          onChanged: _performSearch,
          decoration: InputDecoration(
            hintText: 'Cari karyawan...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade600),
                    onPressed: _clearSearch)
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Data Karyawan',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext menuContext) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () {
                Scaffold.of(menuContext).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
              onPressed: _fetchKaryawan,
              icon: const Icon(Icons.refresh, color: Colors.black87)),
        ],
      ),
      drawer: _userData.isNotEmpty ? CustomSidebar(userData: _userData) : null,
      floatingActionButton: FloatingActionButton(
        onPressed: _showFormDialog,
        backgroundColor: Colors.black87,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchKaryawan,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: _filteredKaryawanList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Tidak ada karyawan yang ditemukan'
                                        : 'Belum ada data karyawan',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _searchQuery.isNotEmpty
                                        ? _clearSearch
                                        : _showFormDialog,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black87,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    child: Text(_searchQuery.isNotEmpty
                                        ? 'Hapus Filter'
                                        : 'Tambah Karyawan'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchKaryawan,
                              color: Colors.black54,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _paginatedKaryawan.length +
                                    (_hasMoreData ? 1 : 0),
                                itemBuilder: (BuildContext context, int index) {
                                  if (index == _paginatedKaryawan.length &&
                                      _hasMoreData) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.black54))),
                                    );
                                  }
                                  return _buildKaryawanCard(
                                      _paginatedKaryawan[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
