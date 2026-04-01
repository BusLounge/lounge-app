import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme_config.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class StaffRegistrationOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String loungeId;
  final String fullName;
  final String nicNumber;
  final String email;

  const StaffRegistrationOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.loungeId,
    required this.fullName,
    required this.nicNumber,
    required this.email,
  });

  @override
  State<StaffRegistrationOtpScreen> createState() =>
      _StaffRegistrationOtpScreenState();
}

class _StaffRegistrationOtpScreenState
    extends State<StaffRegistrationOtpScreen> {
  final _otpController = TextEditingController();
  bool _isSubmitting = false;
  String? _topErrorMessage;

  String _mapUserErrorMessage(String? message) {
    final raw = (message ?? '').trim();
    if (raw.isEmpty) {
      return 'Registration failed. Please try again.';
    }

    final lower = raw.toLowerCase();
    if ((lower.contains('lounge') &&
            lower.contains('not') &&
            lower.contains('approved')) ||
        lower.contains('lounge_not_approved') ||
        lower.contains('selected_lounge_not_approved')) {
      return 'The selected lounge is not yet approved. Please try another lounge.';
    }

    if (lower.contains('nic') &&
        (lower.contains('invalid') ||
            lower.contains('format') ||
            lower.contains('not valid'))) {
      return 'ID number format is incorrect. Use 12 digits or 9 digits + 1 letter.';
    }

    if ((lower.contains('failed to create user account') ||
            lower.contains('user_creation_failed')) &&
        !lower.contains('email')) {
      return 'This email is already registered. Please retype a different email address.';
    }

    if ((lower.contains('email') || lower.contains('users_email_key')) &&
        (lower.contains('already') ||
            lower.contains('duplicate') ||
            lower.contains('exists') ||
            lower.contains('registered') ||
            lower.contains('23505'))) {
      return 'This email is already registered.';
    }

    return raw;
  }

  Future<void> _completeRegistration() async {
    if (_isSubmitting) {
      return;
    }

    if (_otpController.text.length != AppConstants.otpLength) {
      setState(() {
        _topErrorMessage = 'OTP must be ${AppConstants.otpLength} digits';
      });
      return;
    }

    setState(() {
      _topErrorMessage = null;
    });

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final result = await authProvider.verifyOtpLoungeStaff(
        phoneNumber: widget.phoneNumber,
        otp: _otpController.text,
        loungeId: widget.loungeId,
        fullName: widget.fullName,
        nicNumber: widget.nicNumber,
        email: widget.email,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/staff-pending-approval',
          (route) => false,
          arguments: {
            'loungeId': widget.loungeId,
          },
        );
      } else {
        setState(() {
          _topErrorMessage = _mapUserErrorMessage(
            (result['message'] as String?) ?? authProvider.error,
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _topErrorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enter OTP'),
          backgroundColor: AppColors.primary,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_topErrorMessage != null) ...[
                  MaterialBanner(
                    content: Text(_topErrorMessage!),
                    backgroundColor: AppColors.error.withOpacity(0.1),
                    contentTextStyle: const TextStyle(color: AppColors.error),
                    actions: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _topErrorMessage = null;
                          });
                        },
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Enter Verification Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Code sent to ${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                Pinput(
                  controller: _otpController,
                  length: AppConstants.otpLength,
                  defaultPinTheme: PinTheme(
                    width: 56,
                    height: 60,
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 56,
                    height: 60,
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  onCompleted: (_) => _completeRegistration(),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Complete Registration',
                  onPressed: _isSubmitting ? null : _completeRegistration,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
