import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/services/biometric_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading             = false;
  bool _obscurePassword     = true;
  bool _isSignUp            = false;
  String? _error;
  String? _success;

  // Biometria
  bool _biometricAvailable    = false;
  bool _hasSavedCredentials   = false;
  String? _savedEmail;
  bool _biometricLoading      = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.instance.isAvailable();
    final hasCreds  = await BiometricService.instance.hasStoredCredentials();
    final email     = await BiometricService.instance.getStoredEmail();
    if (mounted) {
      setState(() {
        _biometricAvailable  = available;
        _hasSavedCredentials = hasCreds;
        _savedEmail          = email;
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 44),
                      _buildFormCard(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Logo ─────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF1DE9B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.45),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 22),
        const Text(
          'Moneta',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sua vida financeira, inteligente.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ─── Form card ────────────────────────────────────────────────────────────

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _TabButton(label: 'Entrar', selected: !_isSignUp, onTap: () => setState(() { _isSignUp = false; _error = null; _success = null; })),
                _TabButton(label: 'Criar conta', selected: _isSignUp, onTap: () => setState(() { _isSignUp = true; _error = null; _success = null; })),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'E-mail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          // Password
          _buildTextField(
            controller: _passwordController,
            label: 'Senha',
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

          // ── Esqueci minha senha (apenas na aba "Entrar") ─────────────────
          if (!_isSignUp) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _showForgotPasswordSheet,
                child: Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    color: const Color(0xFF4CAF50).withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          // Error / Success messages
          if (_error != null) ...[
            const SizedBox(height: 14),
            _MessageBanner(message: _error!, isError: true),
          ],
          if (_success != null) ...[
            const SizedBox(height: 14),
            _MessageBanner(message: _success!, isError: false),
          ],

          const SizedBox(height: 24),

          // CTA button
          GestureDetector(
            onTap: _loading ? null : (_isSignUp ? _signUp : _signIn),
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
                    : Text(
                        _isSignUp ? 'Criar conta' : 'Entrar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),

          // ── Botão biométrico (apenas na aba "Entrar") ────────────────────
          if (!_isSignUp && _biometricAvailable && _hasSavedCredentials) ...[
            const SizedBox(height: 16),
            _buildBiometricButton(),
          ],

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('seguro & privado', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Biometric button ────────────────────────────────────────────────────

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _biometricLoading ? null : _loginWithBiometric,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4), width: 1.5),
        ),
        child: Center(
          child: _biometricLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Color(0xFF4CAF50), strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fingerprint_rounded, color: Color(0xFF4CAF50), size: 24),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entrar com digital',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_savedEmail != null)
                          Text(
                            _savedEmail!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

  // ─── Forgot Password Sheet ─────────────────────────────────────────────────

  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPasswordSheet(
        initialEmail: _emailController.text.trim(),
      ),
    );
  }

  // ─── Biometric login ──────────────────────────────────────────────────────

  Future<void> _loginWithBiometric() async {
    setState(() { _biometricLoading = true; _error = null; _success = null; });
    try {
      final creds = await BiometricService.instance.authenticateAndGetCredentials();
      if (creds == null) {
        setState(() => _error = 'Autenticação biométrica cancelada ou falhou.');
        return;
      }
      await Supabase.instance.client.auth.signInWithPassword(
        email: creds.email,
        password: creds.password,
      );
      await NotificationService.instance.getAndSyncToken();
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = 'Não foi possível autenticar. Tente com e-mail e senha.');
    } finally {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await NotificationService.instance.getAndSyncToken();

      // Oferecer salvar credenciais para biometria futura
      if (mounted && _biometricAvailable && !_hasSavedCredentials) {
        _promptSaveBiometric(email, password);
      }

      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = 'E-mail ou senha inválidos.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Após login bem-sucedido, pergunta se o usuário quer ativar a biometria.
  void _promptSaveBiometric(String email, String password) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: Color(0xFF4CAF50)),
            SizedBox(width: 10),
            Text('Ativar login por digital?', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          'Nas próximas vezes, você poderá entrar usando sua digital sem digitar a senha.',
          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Agora não', style: TextStyle(color: Colors.white.withOpacity(0.4))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await BiometricService.instance.saveCredentials(email, password);
              await _checkBiometric();
            },
            child: const Text('Ativar', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _signUp() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Informe um e-mail válido.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'moneta://login-callback',
      );
      setState(() => _success = 'Verifique seu e-mail para confirmar o cadastro.');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Erro ao criar conta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Forgot Password Bottom Sheet ─────────────────────────────────────────────

class _ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordSheet({required this.initialEmail});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _emailCtrl;
  bool _loading  = false;
  bool _sent     = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Informe um e-mail válido.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'moneta://reset-password',
      );
      setState(() => _sent = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao enviar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1F2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (!_sent) ...[
            const Text(
              'Redefinir senha',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Informe o e-mail da sua conta e enviaremos um link para redefinir sua senha.',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Email field
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'E-mail',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38, size: 20),
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
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              _MessageBanner(message: _error!, isError: true),
            ],

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _loading ? null : _sendReset,
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
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Enviar link de redefinição',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ] else ...[
            // Sucesso
            const Center(
              child: Icon(Icons.mark_email_read_rounded, color: Color(0xFF4CAF50), size: 64),
            ),
            const SizedBox(height: 20),
            const Text(
              'E-mail enviado!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tab button widget ────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF4CAF50) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white38,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Message banner ───────────────────────────────────────────────────────────

class _MessageBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _MessageBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFFF4444) : const Color(0xFF4CAF50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
