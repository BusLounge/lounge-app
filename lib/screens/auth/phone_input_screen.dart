import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme_config.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/loading_overlay.dart';

/// Input formatter to block leading zero in phone numbers
class NoLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Block input if user tries to enter "0" as first character
    if (newValue.text.isNotEmpty && newValue.text[0] == '0') {
      return oldValue; // Return old value, effectively blocking the "0"
    }
    return newValue; // Allow the input
  }
}

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({
    super.key,
  });

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _completePhoneNumber = '';
  bool _isValid = false;

  static const String _otpNetworkDelayMessage =
      'Network Delay Detected. OTP may still arrive. Please wait or retry.';

  bool _isTimeoutLikeOtpFailure(String? message) {
    final normalized = (message ?? '').toLowerCase();
    return normalized.contains('timeout') ||
        normalized.contains('timed out') ||
        normalized.contains('time out') ||
        normalized.contains('deadline exceeded');
  }

  void _showNetworkDelayNotice() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.medium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF7A4A00),
        content: Row(
          children: const [
            Icon(Icons.wifi_tethering_error_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                _otpNetworkDelayMessage,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    // Dismiss keyboard when Send OTP is tapped
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isValid) {
      ErrorDialog.show(
        context: context,
        message: AppConstants.invalidPhoneError,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.sendOtp(_completePhoneNumber);

    if (!mounted) return;

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your phone. Please check your messages.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to OTP verification
      Navigator.of(context).pushNamed(
        AppConstants.otpVerificationRoute,
        arguments: {
          'phoneNumber': _completePhoneNumber,
        },
      );
    } else {
      final errorMessage = authProvider.error ?? 'Failed to send OTP';
      if (_isTimeoutLikeOtpFailure(errorMessage)) {
        _showNetworkDelayNotice();
        return;
      }

      ErrorDialog.show(
        context: context,
        message: errorMessage,
        onRetry: _sendOtp,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: 'Sending OTP...',
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.large),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacementNamed(
                                      AppConstants.roleSelectionRoute,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: AppColors.textPrimary,
                                  ),
                                  tooltip: 'Back',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.small),

                              // Icon with gradient background
                              Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.primaryGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.badge_rounded,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.medium),

                              // Title
                              const Text(
                                'Enter your phone number',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.small),

                              // Subtitle
                              const Text(
                                'We\'ll send you a verification code',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              // Phone Input Field
                              IntlPhoneField(
                                controller: _phoneController,
                                inputFormatters: [
                                  NoLeadingZeroFormatter(), // Block leading "0"
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: '77 123 4567',
                                  border: OutlineInputBorder(),
                                ),
                                initialCountryCode: AppConstants.countryISOCode,
                                disableLengthCheck: false,
                                onChanged: (phone) {
                                  setState(() {
                                    _completePhoneNumber = phone.completeNumber;
                                    _isValid = phone.isValidNumber();
                                  });
                                },
                                validator: (phone) {
                                  if (phone == null || phone.number.isEmpty) {
                                    return 'Phone number is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.medium),

                              // Send OTP Button
                              CustomButton(
                                text: 'Send OTP',
                                onPressed: _sendOtp,
                                icon: Icons.send,
                              ),
                              const SizedBox(height: AppSpacing.medium),

                              // Info Text
                              Container(
                                padding: const EdgeInsets.all(
                                  AppSpacing.medium,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AppColors.info.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.info,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.small),
                                    Expanded(
                                      child: Text(
                                        'You can request OTP up to ${AppConstants.maxOtpAttempts} times in ${AppConstants.rateLimitWindow ~/ 60} minutes',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpacing.large),

                              // Terms and Conditions
                              const Text(
                                'By continuing, you agree to our Terms of Service and Privacy Policy',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.medium),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
