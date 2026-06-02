import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dashboard_page.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _contentController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isDark = false;
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _autoLoginCheck();
  }

  void _autoLoginCheck() async {
    final user = await _authService.checkSession();
    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => DashboardPage(initialUserData: user)),
      );
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _authService.login(
        _emailController.text, _passwordController.text);

    if (mounted) setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) =>
                DashboardPage(initialUserData: result['user'])),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDark ? _darkTheme() : _lightTheme();
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Align(
                            alignment: Alignment.centerRight,
                            child: _buildThemeToggle()),
                        _buildHeader(),
                        const SizedBox(height: 50),
                        _buildFormFields(),
                        const SizedBox(height: 40),
                        _buildSubmitButton(),
                        const SizedBox(height: 40),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isDark = !_isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isDark
              ? Colors.indigo.withOpacity(0.2)
              : Colors.orange.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
            _isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: _isDark ? Colors.indigoAccent : Colors.orange),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _contentController,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: _isDark
                    ? Colors.indigoAccent.withOpacity(0.1)
                    : Colors.indigo.withOpacity(0.05),
                shape: BoxShape.circle),
            child: Icon(Icons.security_rounded,
                size: 80,
                color: _isDark
                    ? const Color(0xFF00D2FF)
                    : const Color(0xFF1E40AF)),
          ),
          const SizedBox(height: 24),
          Text("HRM iZeroBase",
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: _isDark ? Colors.white : const Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          Text("Otentikasi Manajemen SDM",
              style: TextStyle(
                  fontSize: 14,
                  color: _isDark ? Colors.white70 : Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel("Email Perusahaan"),
        TextFormField(
          controller: _emailController,
          validator: (v) => v!.isEmpty ? "Email wajib diisi" : null,
          style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
          decoration: _inputDecoration(
              "email@izerobase.com", Icons.alternate_email_rounded),
        ),
        const SizedBox(height: 25),
        _buildInputLabel("Kata Sandi"),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscure,
          validator: (v) => v!.isEmpty ? "Sandi wajib diisi" : null,
          style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
          decoration: _inputDecoration("••••••••", Icons.lock_person_rounded,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              )),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
            colors: _isDark
                ? [const Color(0xFF00D2FF), const Color(0xFF3A7BD5)]
                : [const Color(0xFF1E40AF), const Color(0xFF3B82F6)]),
        boxShadow: [
          BoxShadow(
              color: (const Color(0xFF00D2FF)).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : const Text("MASUK SISTEM",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }

  Widget _buildFooter() => Text("© 2024 iZeroBase Tech",
      style: TextStyle(
          color: _isDark ? Colors.white24 : Colors.grey[400], fontSize: 12));

  Widget _buildInputLabel(String t) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(t,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _isDark ? Colors.white70 : const Color(0xFF475569))));

  InputDecoration _inputDecoration(String h, IconData i, {Widget? suffix}) =>
      InputDecoration(
        hintText: h,
        hintStyle: TextStyle(
            color: _isDark ? Colors.white24 : Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(i,
            color: _isDark ? const Color(0xFF00D2FF) : const Color(0xFF64748B),
            size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
                color: _isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
                color:
                    _isDark ? const Color(0xFF00D2FF) : const Color(0xFF1E40AF),
                width: 2)),
      );

  Widget _buildAnimatedBackground() => AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) => Stack(children: [
          Positioned(
              top: -100 + (math.sin(_bgController.value * 2 * math.pi) * 20),
              right: -50,
              child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_isDark ? Colors.indigo : Colors.blue)
                          .withOpacity(0.1)))),
        ]),
      );

  ThemeData _lightTheme() => ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC));
  ThemeData _darkTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A));
}
