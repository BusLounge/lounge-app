import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../config/constants.dart';
import '../../config/theme_config.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/lounge_owner_provider.dart';
import '../../presentation/providers/registration_provider.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/loading_overlay.dart';
import 'role_selection_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Logger _logger = Logger();

  int _resendCountdown = AppConstants.otpResendTimeout;
  Timer? _timer;
  bool _isVerifying = false; // Flag to prevent duplicate verification calls
  bool _canResend = false;
  String? _appSignature;

  @override
  void initState() {
    super.initState();

    // Owner flow only
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setSelectedRole('lounge_owner');
    _logger.i('🔧 OTP Screen: Selected role set to lounge_owner');

    _startCountdown();
    _listenForSmsCode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    cancel(); // Cancel SMS listener
    super.dispose();
  }

  @override
  void codeUpdated() {
    // This method is called when SMS with OTP is received
    if (code != null && code!.length == AppConstants.otpLength) {
      _logger.i('📱 SMS OTP Auto-filled: $code');
      setState(() {
        _otpController.text = code!;
      });
      // Auto-verify after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _otpController.text.length == AppConstants.otpLength) {
          _verifyOtp();
        }
      });
    }
  }

  void _listenForSmsCode() async {
    try {
      // Get app signature for logging (development only)
      _appSignature = await SmsAutoFill().getAppSignature;
      _logger.i('📱 App Signature: $_appSignature');
      _logger.i('📱 Listening for SMS with OTP...');

      // Start listening for OTP SMS
      // Note: With SMS Retriever API, no permission dialog is shown
      // If you want "Allow/Deny" dialog, you need to manually request
      // READ_SMS permission using permission_handler package
      listenForCode();
    } catch (e) {
      _logger.e('Error setting up SMS auto-fill: $e');
    }
  }

  void _startCountdown() {
    setState(() {
      _resendCountdown = AppConstants.otpResendTimeout;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    // Prevent duplicate verification calls
    if (_isVerifying) {
      _logger.i('⚠️ Verification already in progress, ignoring duplicate call');
      return;
    }

    if (_otpController.text.length != AppConstants.otpLength) {
      ErrorDialog.show(context: context, message: AppConstants.invalidOtpError);
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await authProvider.verifyOtp(
      widget.phoneNumber,
      _otpController.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      // Otherwise handle regular lounge owner flow
      final userId = result['userId'] as String?;
      final roles = result['roles'] as List<String>? ?? [];
      final registrationStep = result['registrationStep'] as String?;
      final isNewUser = result['isNewUser'] as bool? ?? false;
      final profileCompleted = result['profileCompleted'] as bool? ?? false;

      if (userId == null) {
        ErrorDialog.show(
          context: context,
          message: 'Failed to get user ID. Please try again.',
        );
        return;
      }

      _logger.i(
        '🔍 OTP Verification Result:\n'
        '   userId: $userId\n'
        '   roles: $roles\n'
        '   profileCompleted: $profileCompleted\n'
        '   registrationStep: $registrationStep\n'
        '   isNewUser (from backend): $isNewUser',
      );

      // ✅ SIMPLIFIED ROUTING LOGIC FOR EXISTING VS NEW USERS
      final hasLoungeOwnerRole = roles.contains('lounge_owner');
      final hasLoungeStaffRole = roles.contains('lounge_staff');
      final isExistingUser = hasLoungeOwnerRole || hasLoungeStaffRole;

      // Check if profile is actually complete
      // registrationStep == 'completed' means profile is complete (even if flag says false)
      final isProfileActuallyComplete =
          profileCompleted || registrationStep == 'completed';

      _logger.i(
        '🔍 User Status Check:\n'
        '   hasLoungeOwnerRole: $hasLoungeOwnerRole\n'
        '   hasLoungeStaffRole: $hasLoungeStaffRole\n'
        '   isExistingUser: $isExistingUser\n'
        '   profileCompleted: $profileCompleted\n'
        '   registrationStep: $registrationStep\n'
        '   isProfileActuallyComplete: $isProfileActuallyComplete',
      );

      // PRIORITY ROUTE: Approved lounge owners should always go to dashboard
      if (hasLoungeOwnerRole) {
        final loungeOwnerProvider = Provider.of<LoungeOwnerProvider>(
          context,
          listen: false,
        );

        final profileFetched =
            await loungeOwnerProvider.getLoungeOwnerProfile();
        final verificationStatus =
            loungeOwnerProvider.loungeOwner?.verificationStatus.toLowerCase();

        _logger.i(
          '🔍 Lounge Owner Verification Check:\n'
          '   profileFetched: $profileFetched\n'
          '   verificationStatus: $verificationStatus',
        );

        if (profileFetched && verificationStatus == 'approved') {
          _logger.i(
              '✅ APPROVED LOUNGE OWNER detected → DASHBOARD (forced priority)');
          if (!mounted) return;

          Navigator.of(context).pushNamedAndRemoveUntil(
            AppConstants.homeRoute,
            (route) => false,
          );
          return;
        }
      }

      // ROUTE 1: Existing user (lounge owner or staff) with COMPLETED profile → DASHBOARD
      if (isExistingUser && isProfileActuallyComplete) {
        _logger.i(
            '✅ EXISTING USER with completed profile (registrationStep=$registrationStep) → DASHBOARD');
        if (!mounted) return;

        Navigator.of(context).pushNamedAndRemoveUntil(
          AppConstants.homeRoute,
          (route) => false,
        );
      }
      // ROUTE 2: Existing lounge owner with INCOMPLETE profile → Continue Registration
      else if (hasLoungeOwnerRole && !isProfileActuallyComplete) {
        _logger.i(
            '✅ EXISTING LOUNGE OWNER with incomplete profile → Continue registration');
        if (!mounted) return;

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/lounge-owner-registration',
          (route) => false,
          arguments: {'userId': userId},
        );
      }
      // ROUTE 3: NEW USER (no lounge role) → Role Selection
      else if (!isExistingUser) {
        _logger.i('✅ NEW USER → ROLE SELECTION');

        // Reset registration data for new users
        final registrationProvider = Provider.of<RegistrationProvider>(
          context,
          listen: false,
        );
        registrationProvider.reset();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoleSelectionScreen(
              userId: userId,
              phoneNumber: widget.phoneNumber,
              otp: _otpController.text,
            ),
          ),
        );
      }
      // FALLBACK: Unexpected state
      else {
        _logger
            .w('⚠️ UNEXPECTED STATE - routing to ROLE SELECTION as fallback');
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoleSelectionScreen(
              userId: userId,
              phoneNumber: widget.phoneNumber,
              otp: _otpController.text,
            ),
          ),
        );
      }

      /* ORIGINAL NAVIGATION LOGIC (commented out for reference)
      // ✅ PRIMARY CHECK: profile_completed (simple and reliable)
      if (profileCompleted) {
        // Registration fully completed - go to home
        _logger.i('Profile completed - navigating to home');
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppConstants.homeRoute, (route) => false);
      } else {
        // Profile NOT completed - check registration_step to show correct form
        // Backward compatibility: treat 'lounge_added' as completed for old users
        if (registrationStep == 'lounge_added' ||
            registrationStep == 'completed') {
          _logger.i('Old user with lounge_added status - navigating to home');
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppConstants.homeRoute, (route) => false);
        } else {
          // Show registration forms at appropriate step
          _logger.i(
            'Registration not completed (step: $registrationStep) - showing registration forms',
          );
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/lounge-owner-registration',
            (route) => false,
            arguments: {'userId': userId},
          );
        }
      }
      */
    } else {
      // Reset flag on error
      setState(() {
        _isVerifying = false;
      });

      ErrorDialog.show(
        context: context,
        message: authProvider.error ?? 'Invalid OTP',
        onRetry: _verifyOtp,
      );
      _otpController.clear();
    }
  }

  Future<void> _resendOtp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(widget.phoneNumber);

    if (!mounted) return;

    if (success) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully. Please check your phone.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ErrorDialog.show(
        context: context,
        message: authProvider.error ?? 'Failed to resend OTP',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: 'Verifying OTP...',
          child: Scaffold(
            appBar: AppBar(title: const Text('Verify OTP'), centerTitle: true),
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
                              const SizedBox(height: AppSpacing.large),

                              // Icon
                              const Icon(
                                Icons.sms_outlined,
                                size: 64,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: AppSpacing.medium),

                              // Title
                              const Text(
                                'Enter Verification Code',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.small),

                              // Phone Number
                              Text(
                                'Code sent to ${PhoneFormatter.formatForDisplay(widget.phoneNumber)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.large),

                              // OTP Input
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
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onCompleted: (pin) => _verifyOtp(),
                                autofocus: true,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: AppSpacing.medium),

                              // Verify Button
                              CustomButton(
                                text: 'Verify',
                                onPressed: _verifyOtp,
                                icon: Icons.check_circle_outline,
                              ),
                              const SizedBox(height: AppSpacing.medium),

                              // Resend OTP
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Didn\'t receive code? ',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (_canResend)
                                    TextButton(
                                      onPressed: _resendOtp,
                                      child: const Text('Resend'),
                                    )
                                  else
                                    Text(
                                      'Resend in $_resendCountdown s',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.large),

                              // Change Number
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Change Phone Number'),
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
