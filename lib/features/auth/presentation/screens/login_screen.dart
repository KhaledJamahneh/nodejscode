// lib/features/auth/presentation/screens/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(loginProvider.notifier).login(
          _usernameController.text,
          _passwordController.text,
        );

    final loginState = ref.read(loginProvider);

    loginState.whenOrNull(
      data: (_) {
        if (mounted) {
          if (StorageService.isAdmin()) {
            context.go('/admin/home');
          } else if (StorageService.isWorker()) {
            context.go('/worker/home');
          } else {
            // Default to client home (for clients or fallback)
            context.go('/client/home');
          }
        }
      },
      error: (error, stack) {
        if (mounted) {
          DialogUtils.showErrorDialog(context, error);
        }
      },
    );
  }

  void _showDemoAccounts() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassCard(
        color: Theme.of(context).scaffoldBackgroundColor,
        opacity: 0.95,
        blur: 30,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.iosGray4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.useDemoAccount,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 24),
              _buildDemoRow(l10n.clientView, 'testclient', 'Client123!'),
              const SizedBox(height: 12),
              _buildDemoRow(l10n.workerView, 'testworker', 'Worker123!'),
              const SizedBox(height: 12),
              _buildDemoRow(l10n.adminView, 'owner', 'Admin123!'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoRow(String role, String username, String password) {
    final l10n = AppLocalizations.of(context)!;
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      onTap: () {
        _usernameController.text = username;
        _passwordController.text = password;
        Navigator.pop(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text(username,
                  style: TextStyle(color: AppTheme.iosGray, fontSize: 14)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.select,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthMeter(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;

    Color color = AppTheme.criticalRed;
    String label = 'Weak';
    if (strength > 0.75) {
      color = AppTheme.successGreen;
      label = 'Strong';
    } else if (strength > 0.4) {
      color = AppTheme.midUrgentOrange;
      label = 'Fair';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: strength,
            backgroundColor: AppTheme.iosGray5,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordSheet() {
    final l10n = AppLocalizations.of(context)!;
    int step = 1;
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => GlassCard(
          color: Theme.of(context).scaffoldBackgroundColor,
          opacity: 0.98,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          margin: EdgeInsets.zero,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.iosGray4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 32),
                if (step == 1) ...[
                  Text(l10n.forgotPassword,
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: l10n.phone,
                      prefixIcon: const Icon(Icons.phone_rounded),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (phoneController.text.isEmpty) return;
                            setModalState(() => isLoading = true);
                            try {
                              await ref
                                  .read(passwordResetProvider.notifier)
                                  .requestReset(phoneController.text);
                              setModalState(() {
                                isLoading = false;
                                step = 2;
                              });
                            } catch (e) {
                              setModalState(() => isLoading = false);
                              if (context.mounted) {
                                DialogUtils.showErrorDialog(context, e);
                              }
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text("SEND OTP"),
                  ),
                ] else if (step == 2) ...[
                  const Text("Enter 6-digit OTP",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: otpController,
                    decoration: const InputDecoration(
                      labelText: "OTP Code",
                      prefixIcon: Icon(Icons.lock_clock_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (otpController.text.length < 4) return;
                      setModalState(() => step = 3);
                    },
                    child: const Text("VERIFY"),
                  ),
                ] else ...[
                  const Text("Set New Password",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: newPassController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.newPassword,
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPassController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.confirmNewPassword,
                      prefixIcon:
                          const Icon(Icons.check_circle_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (newPassController.text !=
                                confirmPassController.text) {
                              DialogUtils.showErrorDialog(context, l10n.passwordsDoNotMatch);
                              return;
                            }
                            setModalState(() => isLoading = true);
                            try {
                              await ref
                                  .read(passwordResetProvider.notifier)
                                  .verifyAndReset(
                                    phoneNumber: phoneController.text,
                                    code: otpController.text,
                                    newPassword: newPassController.text,
                                  );
                              if (context.mounted) {
                                Navigator.pop(context);
                                DialogUtils.showMessageDialog(context, 'Success', 'Password reset successful!');
                              }
                            } catch (e) {
                              setModalState(() => isLoading = false);
                              if (context.mounted) {
                                DialogUtils.showErrorDialog(context, e);
                              }
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text("RESET PASSWORD"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.isLoading;
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.light
                    ? [
                        const Color(0xFFF0F2F5),
                        Colors.white,
                        const Color(0xFFE3F2FD)
                      ]
                    : [
                        const Color(0xFF000000),
                        const Color(0xFF1C1C1E),
                        const Color(0xFF001220)
                      ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutExpo,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo Animation
                      Center(
                        child: Column(
                          children: [
                            Container(
                              height: 110,
                              width: 110,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: AppTheme.primaryGlow,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Image.asset(
                                  'assets/images/ein-logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.appTagline,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      Text(
                        l10n.welcomeBack,
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(fontSize: 32),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.signInSubtitle,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Form Section
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        margin: EdgeInsets.zero,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: l10n.companyUsername,
                                  prefixIcon: const Icon(Icons.person_rounded),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (value) => value?.isEmpty == true
                                    ? l10n.required
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: l10n.password,
                                  prefixIcon: const Icon(Icons.lock_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                onFieldSubmitted: (_) => _handleLogin(),
                                onChanged: (value) => setState(() {}),
                                validator: (value) => value?.isEmpty == true
                                    ? l10n.required
                                    : null,
                              ),
                              if (_passwordController.text.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildPasswordStrengthMeter(
                                    _passwordController.text),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordSheet,
                          child: Text(l10n.forgotPassword),
                        ),
                      ),

                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shadowColor: AppTheme.primary.withOpacity(0.5),
                          elevation: 8,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(l10n.login.toUpperCase()),
                      ),

                      const SizedBox(height: 48),

                      Center(
                        child: TextButton(
                          onPressed: _showDemoAccounts,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.iosGray,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.useDemoAccount,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Language Toggle (on top of everything)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: locale.languageCode == 'en' ? 20 : null,
            left: locale.languageCode == 'en' ? null : 20,
            child: GlassCard(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(20),
              child: TextButton.icon(
                onPressed: () =>
                    ref.read(localeProvider.notifier).toggleLocale(),
                icon: const Icon(Icons.language_rounded, size: 18),
                label: Text(
                    locale.languageCode == 'en' ? l10n.arabic : l10n.english),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
