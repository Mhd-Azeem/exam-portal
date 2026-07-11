import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/secure_storage.dart';
import '../../student/student_shell.dart';
import '../../admin/admin_shell.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter username and password');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ApiClient.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final data = resp.data as Map<String, dynamic>;
      await SecureStorageService.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        role: data['role'] as String,
        userData: data['user'] as Map<String, dynamic>,
      );
      if (!mounted) return;
      final role = data['role'] as String;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              role == 'admin' ? const AdminShell() : const StudentShell(),
        ),
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      String msg;
      if (e.response == null) {
        msg = 'No response: ${e.message}';
      } else if (body is Map) {
        msg = body['message'] as String? ?? 'Error ${e.response!.statusCode}';
      } else {
        msg = 'Error ${e.response?.statusCode}: ${body.toString().substring(0, (body.toString().length).clamp(0, 80))}';
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = 'Exception: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.school, color: Colors.white, size: 56),
            const SizedBox(height: 10),
            const Text(
              'Team Maestro',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sign in to continue',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 13)),
                        ),
                      TextField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Username / Index Number',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        autofillHints: const [AutofillHints.password],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Sign In',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
