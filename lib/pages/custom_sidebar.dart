import 'package:flutter/material.dart';
import 'login_page.dart';
import 'presensi_page.dart';
import 'profile_page.dart';
import '../services/auth_service.dart';

class CustomSidebar extends StatelessWidget {
  final Map<String, dynamic> userData;

  const CustomSidebar({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final int roleId = userData['role_id'] ?? 7;

    final String name = userData['name'] ?? 'User';
    final String roleName = _getRoleDisplayName(roleId);

    int paketId = 1;
    if (userData['paket_id'] != null) {
      paketId = userData['paket_id'];
    } else if (userData['perusahaan'] != null &&
        userData['perusahaan']['paket_id'] != null) {
      paketId = userData['perusahaan']['paket_id'];
    } else if (userData['paket'] != null && userData['paket']['id'] != null) {
      paketId = userData['paket']['id'];
    }

    final String divisi = userData['divisi'] ?? 'Karyawan';
    final bool isPremium = userData['is_premium'] ?? false;
    final String fotoProfil = userData['foto_profil'] ?? '';

    bool isOwner = roleId == 2;
    bool isHrManager = roleId == 3;
    bool isHrStaff = roleId == 4;
    bool isPayrollAdmin = roleId == 5;
    bool isManager = roleId == 6;

    bool hasAdminAccess = isOwner || isHrManager || isHrStaff;
    bool hasManagementAccess = isOwner || isHrManager || isManager;

    return Drawer(
      child: Container(
        color: const Color(0xFF0F172A),
        child: Column(
          children: [
            _buildDrawerHeader(name, divisi, roleName, fotoProfil),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _buildSidebarMenu(
                  context,
                  roleId,
                  paketId,
                  hasAdminAccess,
                  hasManagementAccess,
                  isPremium,
                  isPayrollAdmin,
                  userData,
                ),
              ),
            ),
            _buildStatusAkun(divisi),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
      String name, String divisi, String roleName, String fotoProfil) {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF312E81),
            const Color(0xFF1E1B4B),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage:
                    fotoProfil.isNotEmpty ? NetworkImage(fotoProfil) : null,
                child: fotoProfil.isEmpty
                    ? const Icon(Icons.person,
                        color: Color(0xFF312E81), size: 30)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF818CF8).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        roleName.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.business_center,
                    color: Colors.white54, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    divisi,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(int roleId) {
    switch (roleId) {
      case 1:
        return 'Super Admin';
      case 2:
        return 'Owner';
      case 3:
        return 'HR Manager';
      case 4:
        return 'HR Staff';
      case 5:
        return 'Payroll Admin';
      case 6:
        return 'Manager';
      case 7:
        return 'Karyawan';
      default:
        return 'Karyawan';
    }
  }

  List<Widget> _buildSidebarMenu(
      BuildContext context,
      int roleId,
      int paketId,
      bool hasAdminAccess,
      bool hasManagementAccess,
      bool isPremium,
      bool isPayrollAdmin,
      Map<String, dynamic> userData) {
    List<Widget> list = [];

    list.add(_sectionHeader("Menu Personal"));
    list.addAll([
      _drawerTile("Beranda", Icons.home, const Color(0xFF818CF8), () {
        Navigator.pop(context);
      }),
      _drawerTile("Profil Saya", Icons.person, const Color(0xFF818CF8), () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProfilePage(userData: userData)),
        );
      }),
      _drawerTile(
          "Presensi Masuk/Keluar", Icons.fingerprint, const Color(0xFF10B981),
          () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PresensiPage(userData: userData)),
        );
      }),
      _drawerTile("Riwayat Kehadiran", Icons.calendar_today,
          const Color(0xFF818CF8), () {}),
      _drawerTile("Pengajuan Izin/Cuti", Icons.assignment, Colors.amber, () {}),
    ]);

    if (hasAdminAccess) {
      list.add(_sectionHeader("Manajemen Utama"));
      list.addAll([
        _drawerTile("Dashboard", Icons.dashboard, Colors.white, () {
          Navigator.pop(context);
        }),
        _drawerTile(
            "Data Karyawan & Jabatan", Icons.badge, Colors.white, () {}),
        _drawerTile(
            "Jadwal Absensi", Icons.calendar_month, Colors.white, () {}),
        _drawerTile(
            "Sistem Absensi Masuk & Keluar", Icons.fingerprint, Colors.white,
            () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PresensiPage(userData: userData)),
          );
        }),
        _drawerTile(
            "Riwayat & Status Kehadiran", Icons.analytics, Colors.white, () {}),
        _drawerTile(
            "Pengajuan Izin & Cuti", Icons.edit_calendar, Colors.white, () {}),
        _drawerTile("Approval Izin oleh Admin", Icons.check_circle,
            Colors.white, () {}),
        _drawerTile("Dashboard Ringkasan Real-time", Icons.timeline,
            Colors.white, () {}),
        _drawerTile(
            "Multi-role (Admin & Karyawan)", Icons.groups, Colors.white, () {}),
        _drawerTile("Notifikasi Status Pengajuan", Icons.notifications,
            Colors.white, () {}),
      ]);
    } else if (roleId == 6) {
      list.add(_sectionHeader("Menu Manager"));
      list.addAll([
        _drawerTile("Dashboard Manager", Icons.dashboard, Colors.white, () {
          Navigator.pop(context);
        }),
        _drawerTile("Data Karyawan", Icons.people, Colors.white, () {}),
        _drawerTile(
            "Approval Izin Karyawan", Icons.check_circle, Colors.white, () {}),
        _drawerTile(
            "Laporan Kehadiran", Icons.pie_chart, const Color(0xFF10B981), () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PresensiPage(userData: userData)),
          );
        }),
      ]);
    } else if (roleId == 5) {
      list.add(_sectionHeader("Menu Payroll"));
      list.addAll([
        _drawerTile("Dashboard Payroll", Icons.dashboard, Colors.white, () {
          Navigator.pop(context);
        }),
        _drawerTile("Data Gaji Karyawan", Icons.payments, Colors.white, () {}),
        _drawerTile("Slip Gaji", Icons.receipt, Colors.white, () {}),
        _drawerTile("Laporan Payroll", Icons.pie_chart, Colors.white, () {}),
      ]);
    }

    if ((paketId >= 2 || isPremium) && hasAdminAccess) {
      list.add(_sectionHeader("Manajemen Dokumen & Payroll"));
      list.addAll([
        _drawerTile("Manajemen Dokumen Karyawan", Icons.folder_open,
            const Color(0xFF10B981), () {}),
        _drawerTile("Ekspor Data & Laporan", Icons.file_upload,
            const Color(0xFF10B981), () {}),
        _drawerTile("Sistem Payroll & Slip Gaji Digital", Icons.payments,
            const Color(0xFF10B981), () {}),
        _drawerTile("Manajemen Jam Kerja & Toleransi", Icons.schedule,
            const Color(0xFF10B981), () {}),
        _drawerTile("Multi-level Approval (HR & Manager)", Icons.layers,
            const Color(0xFF10B981), () {}),
        _drawerTile("Statistik Kehadiran & Grafik Analitik", Icons.bar_chart,
            const Color(0xFF10B981), () {}),
        _drawerTile("Notifikasi Email & Reminder Sistem", Icons.email,
            const Color(0xFF10B981), () {}),
        _drawerTile("Role Akses: Admin, Manager & Karyawan", Icons.security,
            const Color(0xFF10B981), () {}),
      ]);
    } else if ((paketId >= 2 || isPremium) && roleId == 7) {
      list.add(_sectionHeader("Keuangan & Dokumen"));
      list.addAll([
        _drawerTile("Slip Gaji Digital", Icons.monetization_on,
            const Color(0xFF10B981), () {}),
        _drawerTile(
            "Dokumen Saya", Icons.folder, const Color(0xFF818CF8), () {}),
      ]);
    } else if ((paketId >= 2 || isPremium) && roleId == 6) {
      list.add(_sectionHeader("Laporan Manager"));
      list.addAll([
        _drawerTile(
            "Laporan Kehadiran", Icons.pie_chart, const Color(0xFF10B981), () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PresensiPage(userData: userData)),
          );
        }),
        _drawerTile(
            "Laporan Karyawan", Icons.people, const Color(0xFF10B981), () {}),
      ]);
    }

    if ((paketId >= 3 || isPremium) && hasAdminAccess) {
      list.add(_sectionHeader("Fitur Enterprise Premium", isAmber: true));
      list.addAll([
        _drawerTile("Integrasi WhatsApp API & Automation", Icons.chat,
            Colors.green, () {}),
        _drawerTile("Advanced Analytics & KPI Karyawan", Icons.analytics,
            Colors.amber, () {}),
        _drawerTile("Audit Log (Lacak Aktivitas User)", Icons.history,
            Colors.amber, () {}),
        _drawerTile(
            "Custom & Granular Permission", Icons.lock, Colors.amber, () {}),
        _drawerTile(
            "API & Webhook Integration", Icons.code, Colors.amber, () {}),
        _drawerTile("Support Progressive Web App (PWA)", Icons.phone_android,
            Colors.amber, () {}),
        _drawerTile("Laporan Custom & Otomatisasi", Icons.description,
            Colors.amber, () {}),
      ]);
    }

    return list;
  }

  Widget _sectionHeader(String title, {bool isAmber = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color:
              isAmber ? Colors.amber.withOpacity(0.5) : const Color(0x99818CF8),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _drawerTile(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      horizontalTitleGap: 8,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildStatusAkun(String divisi) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF312E81).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "STATUS AKUN",
            style: TextStyle(
              color: Color(0xFF818CF8),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                divisi,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF10B981), size: 12),
              const SizedBox(width: 4),
              const Text(
                "Aktif",
                style: TextStyle(color: Color(0xFF818CF8), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () async {
          await AuthService().logout();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.redAccent, size: 18),
              SizedBox(width: 10),
              Text(
                "Logout",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
