import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword        = true;
  bool _obscureConfirm         = true;
  bool _loading                = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordCtrl.text;
    final confirm  = _confirmPasswordCtrl.text;

    if (password.length < 6) {
      setState(() => _error = 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      // Após atualizar, encerra a sessão de recovery e volta ao login
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha atualizada com sucesso! Faça login com a nova senha.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        context.go('/login');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao atualizar a senha. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF071A0E),
              Color(0xFF0A1628),
              Color(0xFF0D0D1A),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF1DE9B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_reset_rounded, size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nova senha',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escolha uma senha forte para proteger sua conta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          controller: _passwordCtrl,
                          label: 'Nova senha',
                          icon: Icons.lock_outlined,
                          obscureText: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _confirmPasswordCtrl,
                          label: 'Confirmar nova senha',
                          icon: Icons.lock_outlined,
                          obscureText: _obscureConfirm,
                          suffix: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4444).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4444), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Color(0xFFFF4444),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        GestureDetector(
                          onTap: _loading ? null : _updatePassword,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: _loading
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: _loading ? Colors.white12 : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _loading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF4CAF50).withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'Salvar nova senha',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      ),
    );
  }
}
