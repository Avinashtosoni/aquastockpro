import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric Authentication Service
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometric authentication is available
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Authenticate using biometrics
  static Future<BiometricResult> authenticate({
    String reason = 'Please authenticate to access AquaStock Pro',
    bool biometricOnly = false,
  }) async {
    try {
      final isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        return BiometricResult(
          success: false,
          errorCode: 'not_available',
          errorMessage: 'Biometric authentication is not available on this device',
        );
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );

      return BiometricResult(
        success: didAuthenticate,
        errorCode: didAuthenticate ? null : 'auth_failed',
        errorMessage: didAuthenticate ? null : 'Authentication failed',
      );
    } on PlatformException catch (e) {
      return BiometricResult(
        success: false,
        errorCode: e.code,
        errorMessage: _getErrorMessage(e.code),
      );
    }
  }

  /// Get user-friendly error message
  static String _getErrorMessage(String code) {
    switch (code) {
      case 'NotAvailable':
        return 'Biometric authentication is not available';
      case 'NotEnrolled':
        return 'No biometrics enrolled. Please set up fingerprint or face ID';
      case 'LockedOut':
        return 'Too many failed attempts. Biometric authentication is temporarily locked';
      case 'PermanentlyLockedOut':
        return 'Biometric authentication is permanently locked. Please use PIN';
      case 'PasscodeNotSet':
        return 'Device passcode is not set. Please set up a passcode first';
      default:
        return 'Authentication error occurred';
    }
  }

  /// Check if fingerprint is available
  static Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  /// Check if face ID is available
  static Future<bool> hasFaceId() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Get biometric type icon
  static IconData getBiometricIcon(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return Icons.face;
    } else if (types.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (types.contains(BiometricType.iris)) {
      return Icons.remove_red_eye;
    }
    return Icons.lock;
  }

  /// Get biometric type name
  static String getBiometricName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }
}

/// Result of biometric authentication
class BiometricResult {
  final bool success;
  final String? errorCode;
  final String? errorMessage;

  BiometricResult({
    required this.success,
    this.errorCode,
    this.errorMessage,
  });
}
