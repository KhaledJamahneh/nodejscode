// lib/core/widgets/biometric_auth.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  static final _auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}

class BiometricLoginButton extends StatelessWidget {
  final VoidCallback onSuccess;

  const BiometricLoginButton({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: BiometricAuth.isAvailable(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();

        return IconButton(
          icon: const Icon(Icons.fingerprint, size: 48),
          onPressed: () async {
            final success = await BiometricAuth.authenticate();
            if (success) onSuccess();
          },
        );
      },
    );
  }
}
