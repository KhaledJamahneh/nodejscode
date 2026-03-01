import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:einhod_water/core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../client/client_home_screen.dart';
import '../worker/worker_home_screen.dart';
import '../station/station_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;
  int _failedAttempts = 0;
  bool _isArabic = false;
  double _passwordStrength = 0;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final pwd = _passwordController.text;
    double strength = 0;
    if (pwd.length >= 8) strength += 0.25;
    if (pwd.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (pwd.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (pwd.contains(RegExp(r'[!@#\$%^&*]'))) strength += 0.25;
    setState(() => _passwordStrength = strength);
  }

  Color get _strengthColor {
    if (_passwordStrength < 0.5) return AppColors.danger;
    if (_passwordStrength < 0.75) return AppColors.warning;
    return AppColors.success;
  }

  String get _strengthLabel {
    if (_passwordStrength < 0.25) return 'Very Weak';
    if (_passwordStrength < 0.5) return 'Weak';
    if (_passwordStrength < 0.75) return 'Good';
    return 'Strong';
  }

  void _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _shakeController.forward(from: 0);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _isLoading = false);

    final username = _usernameController.text.toLowerCase();
    UserRole role;
    Widget destination;

    if (username.contains('admin') || username.contains('owner')) {
      role = UserRole.admin;
      destination = const AdminDashboardScreen();
    } else if (username.contains('driver') || username.contains('worker')) {
      role = UserRole.deliveryWorker;
      final random = math.Random();
      final displayName = username
          .split('.')
          .map((s) => s[0].toUpperCase() + s.substring(1))
          .join(' ');
      final worker = WorkerModel(
        id: 'w_${username.hashCode}',
        username: username,
        name: displayName,
        phone:
            '+962 7${(username.hashCode % 100000000).toString().padLeft(8, '0')}',
        role: UserRole.deliveryWorker,
        jobTitle: 'Delivery Profile',
        isOnShift: true,
        gpsActive: true,
        gallonsRemaining: 30 + random.nextInt(50),
        todayCompletedDeliveries: random.nextInt(10),
        totalDeliveriesToday: 15 + random.nextInt(10),
        pendingExpenses: random.nextInt(5),
        salary: 400 + random.nextInt(200).toDouble(),
      );
      destination = WorkerHomeScreen(worker: worker);
    } else if (username.contains('station') || username.contains('fadi')) {
      role = UserRole.stationWorker;
      final random = math.Random();
      final displayName = username
          .split('.')
          .map((s) => s[0].toUpperCase() + s.substring(1))
          .join(' ');
      final worker = WorkerModel(
        id: 's_${username.hashCode}',
        username: username,
        name: displayName,
        phone:
            '+962 7${(username.hashCode % 100000000).toString().padLeft(8, '0')}',
        role: UserRole.stationWorker,
        jobTitle: 'Onsite Worker Profile',
        isOnShift: true,
        gpsActive: false,
        gallonsRemaining: 0,
        todayCompletedDeliveries: 0,
        totalDeliveriesToday: 0,
        pendingExpenses: random.nextInt(3),
        salary: 350 + random.nextInt(150).toDouble(),
      );
      destination = StationDashboardScreen(worker: worker);
    } else {
      role = UserRole.client;
      // Create a specific client profile for the demo
      final random = math.Random();
      final displayName = username
          .split('.')
          .map((s) => s[0].toUpperCase() + s.substring(1))
          .join(' ');
      final client = ClientModel(
        id: 'c_${username.hashCode}',
        username: username,
        name: displayName,
        phone:
            '+962 7${(username.hashCode % 100000000).toString().padLeft(8, '0')}',
        address: '${random.nextInt(100) + 1} Al-Amal St, Amman',
        subscriptionType: 'Coupon Book',
        couponsRemaining: 15 + random.nextInt(30),
        totalCoupons: 60,
        subscriptionExpiry:
            DateTime.now().add(Duration(days: 5 + random.nextInt(25))),
        outstandingDebt: random.nextInt(200) / 10.0,
      );
      destination = ClientHomeScreen(client: client);
    }

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => destination));
  }

  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ForgotPasswordSheet(),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: isWide ? 460 : double.infinity),
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                          _shakeController.isAnimating
                              ? _shakeAnimation.value *
                                  ((_shakeController.value * 10).floor() % 2 ==
                                          0
                                      ? 1
                                      : -1)
                              : 0,
                          0),
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Language Toggle
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => setState(() => _isArabic = !_isArabic),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              boxShadow: AppShadows.card,
                            ),
                            child: Text(
                              _isArabic ? 'EN' : 'ع',
                              style: AppTypography.labelLarge
                                  .copyWith(color: AppColors.oceanBlue),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Logo & Branding
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.elevated,
                        ),
                        child: const Center(
                          child: Text('💧', style: TextStyle(fontSize: 40)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        'Einhod Pure Water',
                        style: AppTypography.displayMedium
                            .copyWith(color: AppColors.oceanBlue),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _isArabic ? 'نقاء في كل قطرة' : 'Purity in Every Drop',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.skyBlue),
                      ),

                      const SizedBox(height: AppSpacing.xxxl),

                      // Login Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppShadows.elevated,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isArabic ? 'تسجيل الدخول' : 'Sign In',
                              style: AppTypography.headlineLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _isArabic
                                  ? 'أدخل بيانات حسابك'
                                  : 'Enter your account credentials',
                              style: AppTypography.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Username
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: _isArabic
                                    ? 'اسم المستخدم / Company Username'
                                    : 'Company Username / اسم المستخدم',
                                prefixIcon: const Icon(Icons.person_outline,
                                    color: AppColors.textSecondary),
                                hintText: _isArabic
                                    ? 'اسم المستخدم'
                                    : 'e.g. ahmed.khalil',
                              ),
                              textDirection: TextDirection.ltr,
                              keyboardType: TextInputType.text,
                              autocorrect: false,
                            ),
                            const SizedBox(height: AppSpacing.base),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_passwordVisible,
                              decoration: InputDecoration(
                                labelText:
                                    _isArabic ? 'كلمة المرور' : 'Password',
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: AppColors.textSecondary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () => setState(() =>
                                      _passwordVisible = !_passwordVisible),
                                  tooltip: 'Toggle password visibility',
                                ),
                              ),
                            ),

                            // Password strength indicator
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.full),
                                      child: LinearProgressIndicator(
                                        value: _passwordStrength,
                                        backgroundColor: AppColors.divider,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                _strengthColor),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    _strengthLabel,
                                    style: AppTypography.bodySmall.copyWith(
                                        color: _strengthColor,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: AppSpacing.sm),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _showForgotPasswordSheet,
                                child: Text(
                                  _isArabic
                                      ? 'نسيت كلمة المرور؟'
                                      : 'Forgot Password?',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.oceanBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            PrimaryButton(
                              label: _isArabic
                                  ? 'تسجيل الدخول / Sign In'
                                  : 'Sign In / تسجيل الدخول',
                              onTap: _handleLogin,
                              isLoading: _isLoading,
                            ),

                            const SizedBox(height: AppSpacing.base),

                            // Quick access demo row
                            Text(
                              'Demo: type "admin", "driver", "station", or any name',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}

// ─── Forgot Password Bottom Sheet ────────────────────────────────────────────
class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  int _step = 0;
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _countdown = 60;
  bool _canResend = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
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
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          StepIndicator(totalSteps: 3, currentStep: _step),
          const SizedBox(height: AppSpacing.xl),

          if (_step == 0) ...[
            Text('Forgot Password', style: AppTypography.headlineLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('Enter your registered phone number',
                style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon:
                    Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                hintText: '+962 7X XXX XXXX',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
                label: 'Send OTP', onTap: () => setState(() => _step = 1)),
          ],

          if (_step == 1) ...[
            Text('Enter OTP', style: AppTypography.headlineLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('We sent a 6-digit code to ${_phoneController.text}',
                style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                  6,
                  (i) => SizedBox(
                        width: 44,
                        child: TextFormField(
                          controller: _otpControllers[i],
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          keyboardType: TextInputType.number,
                          style: AppTypography.headlineLarge,
                          decoration: const InputDecoration(counterText: ''),
                          onChanged: (val) {
                            if (val.isNotEmpty && i < 5) {
                              FocusScope.of(context).nextFocus();
                            }
                          },
                        ),
                      )),
            ),
            const SizedBox(height: AppSpacing.base),
            Center(
              child: Text(
                _canResend ? 'Resend OTP' : 'Resend in ${_countdown}s',
                style: AppTypography.bodySmall.copyWith(
                  color: _canResend
                      ? AppColors.oceanBlue
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
                label: 'Verify', onTap: () => setState(() => _step = 2)),
          ],

          if (_step == 2) ...[
            Text('New Password', style: AppTypography.headlineLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('Create a strong new password',
                style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon:
                    Icon(Icons.lock_outline, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon:
                    Icon(Icons.lock_outline, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PasswordRequirements(password: _newPasswordController.text),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Update Password',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password updated successfully!'),
                      backgroundColor: AppColors.success),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  final String password;
  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    final reqs = [
      ('8+ characters', password.length >= 8),
      ('Uppercase letter', password.contains(RegExp(r'[A-Z]'))),
      ('Number', password.contains(RegExp(r'[0-9]'))),
      ('Special character', password.contains(RegExp(r'[!@#\$%^&*]'))),
    ];

    return Column(
      children: reqs
          .map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      r.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: r.$2 ? AppColors.success : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(r.$1,
                        style: AppTypography.bodySmall.copyWith(
                          color: r.$2
                              ? AppColors.success
                              : AppColors.textSecondary,
                        )),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
