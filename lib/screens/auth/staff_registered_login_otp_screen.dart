import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme_config.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/lounge_staff_provider.dart';
import '../../screens/auth/staff_pending_approval_screen.dart';
import '../../screens/staff/staff_dashboard_screen.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class StaffRegisteredLoginOtpScreen extends StatefulWidget {
  final String phoneNumber;

  const StaffRegisteredLoginOtpScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<StaffRegisteredLoginOtpScreen> createState() =>
      _StaffRegisteredLoginOtpScreenState();
}

class _StaffRegisteredLoginOtpScreenState
    extends State<StaffRegisteredLoginOtpScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _topErrorMessage;

  String _mapUserErrorMessage(String? message) {
    final raw = (message ?? '').trim();
    if (raw.isEmpty) {
      return 'OTP verification failed';
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

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;

    if (_otpController.text.length != AppConstants.otpLength) {
      setState(() {
        _topErrorMessage = 'OTP must be ${AppConstants.otpLength} digits';
      });
      return;
    }

    setState(() {
      _topErrorMessage = null;
      _isVerifying = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loungeStaffProvider =
        Provider.of<LoungeStaffProvider>(context, listen: false);

    try {
      final result = await authProvider.verifyOtpLoungeStaffRegistered(
        phoneNumber: widget.phoneNumber,
        otp: _otpController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final profileLoaded = await loungeStaffProvider.getMyStaffProfile();
        if (!mounted) return;

        if (profileLoaded && loungeStaffProvider.selectedStaff != null) {
          final staff = loungeStaffProvider.selectedStaff!;
          if (staff.isApproved) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const StaffPendingApprovalScreen(),
              ),
            );
          }
        } else {
          setState(() {
            _topErrorMessage = 'Failed to load staff profile';
          });
        }
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
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
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
      isLoading: _isVerifying,
      message: 'Verifying OTP...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text('Verify OTP'),
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
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
                const SizedBox(height: AppSpacing.small),
                const Text(
                  'Enter Verification Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Code sent to ${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
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
                  onCompleted: (_) => _verifyOtp(),
                ),
                const SizedBox(height: AppSpacing.large),
                CustomButton(
                  text: 'Continue',
                  onPressed: _isVerifying ? null : _verifyOtp,
                  isLoading: _isVerifying,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
