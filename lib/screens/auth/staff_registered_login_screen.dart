import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme_config.dart';
import '../../presentation/providers/auth_provider.dart';
import 'staff_registered_login_otp_screen.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class NoLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isNotEmpty && newValue.text[0] == '0') {
      return oldValue;
    }
    return newValue;
  }
}

class StaffRegisteredLoginScreen extends StatefulWidget {
  const StaffRegisteredLoginScreen({super.key});

  @override
  State<StaffRegisteredLoginScreen> createState() =>
      _StaffRegisteredLoginScreenState();
}

class _StaffRegisteredLoginScreenState
    extends State<StaffRegisteredLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  String _completePhoneNumber = '';
  bool _isPhoneValid = false;
  bool _isSendingOtp = false;
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

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_completePhoneNumber.isEmpty || !_isPhoneValid) {
      setState(() {
        _topErrorMessage = AppConstants.invalidPhoneError;
      });
      return;
    }

    setState(() {
      _topErrorMessage = null;
    });

    setState(() {
      _isSendingOtp = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(_completePhoneNumber);

    if (!mounted) return;

    setState(() {
      _isSendingOtp = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your phone. Please check your messages.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StaffRegisteredLoginOtpScreen(
            phoneNumber: _completePhoneNumber,
          ),
        ),
      );
    } else {
      setState(() {
        _topErrorMessage =
            _mapUserErrorMessage(authProvider.error ?? 'Failed to send OTP');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isSendingOtp,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(
                AppConstants.roleSelectionRoute,
              );
            },
          ),
          title: const Text('Registered Staff Login'),
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Form(
              key: _formKey,
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
                    'Enter your phone number to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  IntlPhoneField(
                    controller: _phoneController,
                    inputFormatters: [
                      NoLeadingZeroFormatter(),
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
                        _isPhoneValid = phone.isValidNumber();
                      });
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onPressed: _isSendingOtp ? null : _sendOtp,
                      text: _isSendingOtp ? 'Sending OTP...' : 'Send OTP',
                      isLoading: _isSendingOtp,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
