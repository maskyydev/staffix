import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_sidebar.dart';
import 'presensi_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic>? initialUserData;
  const DashboardPage({super.key, this.initialUserData});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String baseUrl = 'https://izerobase.com/staffix';

  @override
  void initState() {
    super.initState();
    if (widget.initialUserData != null) {
      userData = widget.initialUserData;
      isLoading = false;
    } else {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/profil'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            userData = data['data'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
          ),
        ),
      );
    }

    if (userData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat data profil',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    Map<String, dynamic> sidebarData = Map.from(userData!);

    int roleIdValue = 7;
    if (sidebarData['role_id'] != null) {
      roleIdValue = sidebarData['role_id'];
    } else if (sidebarData['role'] != null) {
      if (sidebarData['role'] is Map) {
        roleIdValue = sidebarData['role']['id'] ?? 7;
      } else if (sidebarData['role'] is String) {
        if (sidebarData['role'] == 'super-admin')
          roleIdValue = 1;
        else if (sidebarData['role'] == 'owner')
          roleIdValue = 2;
        else if (sidebarData['role'] == 'hr-manager')
          roleIdValue = 3;
        else if (sidebarData['role'] == 'hr-staff')
          roleIdValue = 4;
        else if (sidebarData['role'] == 'payroll-admin')
          roleIdValue = 5;
        else if (sidebarData['role'] == 'manager')
          roleIdValue = 6;
        else
          roleIdValue = 7;
      }
    }
    sidebarData['role_id'] = roleIdValue;

    String roleSlugValue = '';
    if (sidebarData['role'] != null && sidebarData['role'] is Map) {
      roleSlugValue = sidebarData['role']['slug'] ?? 'employee';
    } else if (sidebarData['role'] is String) {
      roleSlugValue = sidebarData['role'];
    } else if (sidebarData['role_slug'] != null) {
      roleSlugValue = sidebarData['role_slug'];
    } else {
      roleSlugValue = 'employee';
    }
    sidebarData['role'] = roleSlugValue;

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

    final String role = sidebarData['role'] ?? 'employee';
    final String name = sidebarData['name'] ?? 'User';
    final int paketId = sidebarData['paket_id'] ?? 1;
    final String? fotoProfil = sidebarData['foto_profil'];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Dashboard HRMI",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'edit_profil') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProfilePage(userData: userData!)),
                  ).then((_) => _refreshData());
                } else if (value == 'pengaturan') {}
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit_profil',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 20, color: Colors.black87),
                      SizedBox(width: 10),
                      Text('Edit Profil'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'pengaturan',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined,
                          size: 20, color: Colors.black87),
                      SizedBox(width: 10),
                      Text('Pengaturan'),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1E40AF),
                child: fotoProfil != null && fotoProfil.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          fotoProfil,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            );
                          },
                        ),
                      )
                    : Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
              ),
            ),
          ),
        ],
      ),
      drawer: CustomSidebar(userData: sidebarData),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF1E40AF),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(name, role, fotoProfil),
              const SizedBox(height: 25),
              const Text("Menu Navigasi",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildGridMenu(context, role, paketId, userData!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name, String role, String? fotoProfil) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            backgroundImage: fotoProfil != null && fotoProfil.isNotEmpty
                ? NetworkImage(fotoProfil)
                : null,
            child: fotoProfil == null || fotoProfil.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.bold,
                        fontSize: 28),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selamat Datang,",
                    style: TextStyle(color: Colors.white.withOpacity(0.8))),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(role.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context, String role, int paketId,
      Map<String, dynamic> userData) {
    List<Widget> menus = [];

    if (role == 'superadmin') {
      menus.add(_menuTile(
          "Kontrol Sistem", Icons.settings_suggest, Colors.purple, () {}));
      menus.add(
          _menuTile("Data Perusahaan", Icons.business, Colors.indigo, () {}));
      menus.add(_menuTile(
          "Paket & Fitur", Icons.card_membership, Colors.amber, () {}));
      menus.add(_menuTile("Transaksi", Icons.wallet, Colors.teal, () {}));
    } else if (role == 'admin' || role == 'hr-manager' || role == 'owner') {
      menus.add(
          _menuTile("Data Karyawan", Icons.people_alt, Colors.orange, () {}));
      menus.add(_menuTile(
          "Jadwal Absensi", Icons.calendar_month, Colors.purple, () {}));
      menus.add(_menuTile("Sistem Absensi", Icons.fingerprint, Colors.blue, () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PresensiPage(userData: userData)));
      }));

      if (paketId >= 2) {
        menus.add(_menuTile("Payroll & Slip", Icons.account_balance_wallet,
            Colors.green, () {}));
        menus.add(_menuTile("Dokumen", Icons.folder, Colors.teal, () {}));
      }
      if (paketId >= 3) {
        menus.add(_menuTile(
            "WhatsApp API", Icons.chat, const Color(0xFF00E676), () {}));
        menus.add(_menuTile("Audit Log", Icons.history, Colors.amber, () {}));
      }
    } else {
      menus.add(_menuTile("Presensi", Icons.fingerprint, Colors.blue, () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PresensiPage(userData: userData)));
      }));
      menus.add(
          _menuTile("Riwayat", Icons.calendar_month, Colors.indigo, () {}));
      menus.add(_menuTile("Izin / Cuti", Icons.event_note, Colors.pink, () {}));

      if (paketId >= 2) {
        menus.add(
            _menuTile("E-Slip Gaji", Icons.description, Colors.teal, () {}));
        menus.add(_menuTile(
            "Dokumen Saya", Icons.folder_shared, Colors.orange, () {}));
      }
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: menus,
    );
  }

  Widget _menuTile(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
