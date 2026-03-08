import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../main.dart';
import '../providers/profile_provider.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

/// Refreshes whenever we update user metadata so the UI rebuilds.
final _userRefreshProvider = StateProvider<int>((ref) => 0);

// ─── Page ─────────────────────────────────────────────────────────────────────

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _loggingOut = false;
  bool _uploadingAvatar = false;
  bool _sendingReset = false;

  // ── Helpers ──────────────────────────────────────────────────────────────

  User? get _user => Supabase.instance.client.auth.currentUser;

  String get _email => _user?.email ?? 'demo@moneta.app';

  String get _displayName {
    final meta = _user?.userMetadata;
    if (meta != null) {
      for (final k in ['full_name', 'name', 'display_name']) {
        final v = meta[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    final local = _email.split('@').first;
    return _cap(local.split(RegExp(r'[._+\-]')).first);
  }

  String get _avatarUrl {
    final meta = _user?.userMetadata;
    final url = meta?['avatar_url'];
    return url is String ? url : '';
  }

  String get _initials {
    final parts = _displayName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _displayName.substring(0, _displayName.length.clamp(0, 2)).toUpperCase();
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(_userRefreshProvider); // rebuild on metadata change
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, isDark)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Conta ─────────────────────────────────────────────
                  const _SectionTitle(label: 'Conta'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _SettingsTile(
                        icon: Icons.badge_outlined,
                        iconColor: AppTheme.incomeColor,
                        label: 'Nome exibido',
                        trailing: Text(
                          _displayName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                          ),
                        ),
                        showArrow: true,
                        onTap: () => _openEditName(context),
                      ),
                      _Divider(isDark: isDark),
                      _SettingsTile(
                        icon: Icons.email_outlined,
                        iconColor: const Color(0xFF29B6F6),
                        label: 'E-mail',
                        trailing: Text(
                          _email,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      _Divider(isDark: isDark),
                      _SettingsTile(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF7E57C2),
                        label: 'Alterar senha',
                        showArrow: !_sendingReset,
                        trailing: _sendingReset
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                        onTap: () => _sendPasswordReset(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Aparência ──────────────────────────────────────────
                  const _SectionTitle(label: 'Aparência'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _SettingsTile(
                        icon: Icons.brightness_4_outlined,
                        iconColor: const Color(0xFFFFB300),
                        label: 'Tema',
                        trailing: _ThemeSegmented(
                          current: themeMode,
                          onChanged: (mode) =>
                              ref.read(themeModeProvider.notifier).state = mode,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Preferências ───────────────────────────────────────
                  const _SectionTitle(label: 'Preferências'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      const _NotificationsToggle(),
                      _Divider(isDark: isDark),
                      _SettingsTile(
                        icon: Icons.language_outlined,
                        iconColor: const Color(0xFF7E57C2),
                        label: 'Idioma',
                        trailing: Text(
                          'Português (BR)',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Sobre ──────────────────────────────────────────────
                  const _SectionTitle(label: 'Sobre'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF29B6F6),
                        label: 'Versão',
                        trailing: Text(
                          '1.0.0',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      _Divider(isDark: isDark),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        iconColor: const Color(0xFF78909C),
                        label: 'Termos de uso',
                        showArrow: true,
                        onTap: () {},
                      ),
                      _Divider(isDark: isDark),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: const Color(0xFF78909C),
                        label: 'Política de privacidade',
                        showArrow: true,
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  _LogoutButton(
                    loading: _loggingOut,
                    onTap: () => _confirmLogout(context),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: [
              // Top row: back + title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),

              const SizedBox(height: 28),

              // Avatar with edit badge
              GestureDetector(
                onTap: () => _pickAvatar(context),
                child: Stack(
                  children: [
                    // Avatar circle
                    Container(
                      width: 88,
                      height: 88,
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
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _uploadingAvatar
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : _avatarUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _avatarUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Center(
                                      child: Text(
                                        _initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                      ),
                    ),

                    // Camera badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 15,
                          color: Color(0xFF1B6B45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Name with edit icon
              GestureDetector(
                onTap: () => _openEditName(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 2),

              Text(
                _email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.incomeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.incomeColor.withOpacity(0.4)),
                ),
                child: const Text(
                  'Conta ativa',
                  style: TextStyle(
                    color: Color(0xFF81C784),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Edit name ────────────────────────────────────────────────────────────

  Future<void> _openEditName(BuildContext context) async {
    final controller = TextEditingController(text: _displayName);
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditNameSheet(controller: controller),
    );
    if (saved == null || !mounted) return;
    await _saveName(context, saved.trim());
  }

  Future<void> _saveName(BuildContext context, String name) async {
    if (name.isEmpty) return;
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': name}),
      );
      ref.read(_userRefreshProvider.notifier).state++;
      if (mounted) AppFeedback.showSuccess(context, 'Nome atualizado!');
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Erro ao salvar nome.');
    }
  }

  // ─── Pick & upload avatar ─────────────────────────────────────────────────

  Future<void> _pickAvatar(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ImageSourceSheet(),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final userId = _user!.id;
      final bytes = await File(file.path).readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      // jpg é um alias — o MIME type correto é image/jpeg
      final mime = (ext == 'jpg') ? 'image/jpeg' : 'image/$ext';
      final storagePath = '$userId/avatar.${ext == 'jpg' ? 'jpg' : ext}';

      // Upload to Supabase Storage bucket "avatars"
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mime,
              upsert: true,
            ),
          );

      final url = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      // Bust cache by appending timestamp
      final bustUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': bustUrl}),
      );

      ref.read(_userRefreshProvider.notifier).state++;
      if (mounted) AppFeedback.showSuccess(context, 'Foto atualizada!');
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'Erro ao enviar foto. Verifique as permissões do bucket.',
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  // ─── Password reset ───────────────────────────────────────────────────────

  Future<void> _sendPasswordReset(BuildContext context) async {
    if (_sendingReset) return;
    setState(() => _sendingReset = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _email,
        redirectTo: 'moneta://login-callback',
      );
      if (mounted) AppFeedback.showSuccess(context, 'Link de redefinição enviado para $_email.');
    } on AuthException catch (e) {
      if (mounted) AppFeedback.showError(context, e.message);
    } catch (_) {
      if (mounted) AppFeedback.showError(context, 'Erro ao enviar redefinição. Tente novamente.');
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Sair da conta',
      message: 'Tem certeza que deseja sair do Moneta?',
      confirmLabel: 'Sair',
      confirmColor: AppTheme.errorColor,
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      // Remove o token do FCM do dispositivo para evitar notificações após logout.
      await FirebaseMessaging.instance.deleteToken();

      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        setState(() => _loggingOut = false);
        AppFeedback.showError(context, 'Erro ao sair. Tente novamente.');
      }
    }
  }
}

// ─── Edit Name Sheet ──────────────────────────────────────────────────────────

class _EditNameSheet extends StatelessWidget {
  final TextEditingController controller;
  const _EditNameSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171720) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Nome exibido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Este nome aparece no cabeçalho do app.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Seu nome',
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF0D0D0F) : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.incomeColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(controller.text),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B6B45), Color(0xFF1A3A5C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Salvar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
}

// ─── Image Source Sheet ───────────────────────────────────────────────────────

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171720) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Foto de perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),

          _SourceTile(
            icon: Icons.photo_library_outlined,
            color: const Color(0xFF29B6F6),
            label: 'Escolher da galeria',
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _SourceTile(
            icon: Icons.camera_alt_outlined,
            color: AppTheme.incomeColor,
            label: 'Tirar uma foto',
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _SourceTile(
            icon: Icons.delete_outline_rounded,
            color: AppTheme.errorColor,
            label: 'Remover foto',
            onTap: () => Navigator.of(context).pop(),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _SourceTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D0D0F) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark ? Colors.white38 : Colors.grey.shade500,
      ),
    );
  }
}

// ─── Settings card ────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171720) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                )
              ],
      ),
      child: Column(children: children),
    );
  }
}

// ─── Settings tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (trailing != null) trailing!,
            if (showArrow) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 66,
      endIndent: 16,
      color: isDark ? Colors.white10 : Colors.grey.shade100,
    );
  }
}

// ─── Theme segmented control ──────────────────────────────────────────────────

class _ThemeSegmented extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeSegmented({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ThemeBtn(
          icon: Icons.brightness_auto_rounded,
          selected: current == ThemeMode.system,
          isDark: isDark,
          onTap: () => onChanged(ThemeMode.system),
          tooltip: 'Sistema',
        ),
        const SizedBox(width: 4),
        _ThemeBtn(
          icon: Icons.wb_sunny_outlined,
          selected: current == ThemeMode.light,
          isDark: isDark,
          onTap: () => onChanged(ThemeMode.light),
          tooltip: 'Claro',
        ),
        const SizedBox(width: 4),
        _ThemeBtn(
          icon: Icons.nights_stay_outlined,
          selected: current == ThemeMode.dark,
          isDark: isDark,
          onTap: () => onChanged(ThemeMode.dark),
          tooltip: 'Escuro',
        ),
      ],
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final String tooltip;

  const _ThemeBtn({
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.incomeColor
                : (isDark ? Colors.white10 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white54 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

// ─── Notifications toggle ─────────────────────────────────────────────────────

class _NotificationsToggle extends ConsumerWidget {
  const _NotificationsToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final notifier = ref.read(profileNotifierProvider.notifier);

    // While loading or in demo mode, fall back to enabled=true visually
    final isEnabled = profileAsync.valueOrNull?.notificationsEnabled ?? true;
    final isLoading = ref.watch(profileNotifierProvider).isLoading;

    return _SettingsTile(
      icon: Icons.notifications_outlined,
      iconColor: const Color(0xFFFF7043),
      label: 'Notificações',
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch.adaptive(
              value: isEnabled,
              activeColor: AppTheme.incomeColor,
              onChanged: (value) async {
                final updated =
                    await notifier.setNotificationsEnabled(value);
                if (updated == null && context.mounted) {
                  AppFeedback.showError(
                    context,
                    'Erro ao atualizar preferências de notificação.',
                  );
                }
              },
            ),
    );
  }
}

// ─── Logout button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _LogoutButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.errorColor.withOpacity(0.25)),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.errorColor,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, color: AppTheme.errorColor, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Sair da conta',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
