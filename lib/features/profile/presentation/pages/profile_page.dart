import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../main.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _loggingOut = false;

  String get _email =>
      Supabase.instance.client.auth.currentUser?.email ?? 'demo@moneta.app';

  String get _initials {
    final parts = _email.split('@').first.split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _email.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ─── Header ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(context, isDark)),

          // ─── Sections ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Conta ──────────────────────────────────────────────
                  _SectionTitle(label: 'Conta'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _SettingsTile(
                        icon: Icons.email_outlined,
                        iconColor: AppTheme.incomeColor,
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
                        iconColor: const Color(0xFF29B6F6),
                        label: 'Alterar senha',
                        showArrow: true,
                        onTap: () => AppFeedback.showInfo(
                          context,
                          'Redefinição enviada para ${'$_email'}.',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Aparência ──────────────────────────────────────────
                  _SectionTitle(label: 'Aparência'),
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

                  // ── Notificações ───────────────────────────────────────
                  _SectionTitle(label: 'Preferências'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        iconColor: const Color(0xFFFF7043),
                        label: 'Notificações',
                        trailing: Switch.adaptive(
                          value: true,
                          activeColor: AppTheme.incomeColor,
                          onChanged: (_) => AppFeedback.showInfo(
                            context,
                            'Configurações de notificação em breve.',
                          ),
                        ),
                      ),
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
                  _SectionTitle(label: 'Sobre'),
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

                  // ── Logout button ──────────────────────────────────────
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
              // Back button row
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
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
                  const SizedBox(width: 40), // balance
                ],
              ),

              const SizedBox(height: 28),

              // Avatar
              Container(
                width: 80,
                height: 80,
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
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                ),
                child: Center(
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

              const SizedBox(height: 14),

              // Email
              Text(
                _email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 4),

              // Badge
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

  // ─── Actions ──────────────────────────────────────────────────────────────

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
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
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
            color: selected ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade600),
          ),
        ),
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
                  child: CircularProgressIndicator(color: AppTheme.errorColor, strokeWidth: 2),
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
