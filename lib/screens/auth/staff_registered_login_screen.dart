import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme_config.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/lounge_staff_provider.dart';
import '../../screens/auth/staff_pending_approval_screen.dart';
import '../../screens/staff/staff_dashboard_screen.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';
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
  final _otpController = TextEditingController();
  final _phoneController = TextEditingController();

  String _completePhoneNumber = '';
  bool _isPhoneValid = false;
  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_completePhoneNumber.isEmpty || !_isPhoneValid) {
      ErrorDialog.show(
        context: context,
        message: AppConstants.invalidPhoneError,
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(_completePhoneNumber);

    if (!mounted) return;

    setState(() {
      _isSendingOtp = false;
      _otpSent = success;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your phone. Please check your messages.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ErrorDialog.show(
        context: context,
        message: authProvider.error ?? 'Failed to send OTP',
        onRetry: _sendOtp,
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_otpSent) {
      ErrorDialog.show(
        context: context,
        message: 'Please request and enter the OTP first',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loungeStaffProvider =
        Provider.of<LoungeStaffProvider>(context, listen: false);

    final result = await authProvider.verifyOtpLoungeStaffRegistered(
      phoneNumber: _completePhoneNumber,
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
                builder: (_) => const StaffPendingApprovalScreen()),
          );
        }
      } else {
        ErrorDialog.show(
          context: context,
          message: 'Failed to load staff profile',
        );
      }
    } else {
      ErrorDialog.show(
        context: context,
        message: result['message'] ?? 'OTP verification failed',
      );
    }

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
    }
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: AppConstants.otpLength,
                    enabled: _otpSent,
                    decoration: InputDecoration(
                      labelText: 'OTP Code',
                      hintText: 'Enter 6-digit OTP',
                      prefixIcon: const Icon(Icons.security),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (!_otpSent) {
                        return 'Please request OTP first';
                      }
                      if (value?.isEmpty ?? true) {
                        return 'OTP is required';
                      }
                      if (value!.length != AppConstants.otpLength) {
                        return 'OTP must be ${AppConstants.otpLength} digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.large),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onPressed: _isVerifying ? null : _verifyOtp,
                      text: 'Continue',
                      isLoading: _isVerifying,
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
