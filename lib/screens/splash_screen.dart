import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../config/constants.dart';
import '../config/theme_config.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/lounge_owner_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false; // Prevent multiple navigations on hot reload
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Prevent re-navigation on hot reload
    if (_hasNavigated) {
      _logger.w('SPLASH: Navigation already happened, skipping...');
      return;
    }

    _logger.i('SPLASH: Starting auth check...');

    // Give splash screen a moment to show
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is authenticated (has valid tokens)
    await authProvider.checkAuthStatus();

    _logger.i('SPLASH: isAuthenticated = ${authProvider.isAuthenticated}');
    _logger.i('SPLASH: user = ${authProvider.user?.id}');

    if (!mounted) return;

    if (authProvider.isAuthenticated && authProvider.user != null) {
      //  User has valid tokens - check registration status
      _logger.i('SPLASH: User authenticated, checking registration status...');

      final user = authProvider.user;
      _logger.i('SPLASH: User roles = ${user?.roles}');

      // Check if user has lounge_owner role
      final hasLoungeOwnerRole = user?.roles.contains('lounge_owner') ?? false;

      if (!hasLoungeOwnerRole) {
        // No lounge_owner role - go to ROLE SELECTION SCREEN first
        _logger.w('SPLASH: No lounge_owner role - going to role selection');
        _hasNavigated = true;
        Navigator.of(
          context,
        ).pushReplacementNamed(AppConstants.roleSelectionRoute);
        return;
      }

      // User has lounge_owner role - check registration_step from backend
      _logger.i('SPLASH: Fetching registration status from backend...');

      final loungeOwnerProvider = Provider.of<LoungeOwnerProvider>(
        context,
        listen: false,
      );
      final profileFetched = await loungeOwnerProvider.getLoungeOwnerProfile();

      final loungeOwner = loungeOwnerProvider.loungeOwner;

      //  DEBUG: Log what provider returns
      print(' SPLASH - Provider returned:');
      print('   profileFetched: $profileFetched');
      print('   loungeOwner: ${loungeOwner != null ? "NOT NULL" : "NULL"}');
      if (loungeOwner != null) {
        print(
          '   loungeOwner.registrationStep: ${loungeOwner.registrationStep}',
        );
        print(
          '   loungeOwner.profileCompleted: ${loungeOwner.profileCompleted}',
        );
      } else {
        print('    loungeOwner is NULL - profile fetch may have failed');
      }

      // If profile fetch failed, logout and restart flow
      if (!profileFetched || loungeOwner == null) {
        _logger.w(
          'SPLASH:  Failed to fetch profile - logging out and restarting flow',
        );
        await authProvider.logout();
        _hasNavigated = true;
        Navigator.of(
          context,
        ).pushReplacementNamed(AppConstants.roleSelectionRoute);
        return;
      }

      final profileCompleted = loungeOwner.profileCompleted;
      final registrationStep = loungeOwner.registrationStep;
      final verificationStatus = loungeOwner.verificationStatus.toLowerCase();

      _logger.i(
        'SPLASH: profileCompleted = $profileCompleted, registration_step = $registrationStep, verificationStatus = $verificationStatus',
      );

      // Priority rule: approved lounge owners always go to dashboard
      if (verificationStatus == 'approved') {
        _logger.i('SPLASH: Approved lounge owner - Going to HOME (priority)');
        _hasNavigated = true;
        Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
        return;
      }

      //  PRIMARY CHECK: profile_completed (simple and reliable)
      if (profileCompleted) {
        // Registration fully completed - go to home
        _logger.i('SPLASH:  Profile completed - Going to HOME');
        _hasNavigated = true;
        Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
      } else {
        // Profile NOT completed - check registration_step for backward compatibility
        // Treat 'lounge_added' or 'completed' as completed for old users before the fix
        if (registrationStep == 'lounge_added' ||
            registrationStep == 'completed') {
          _logger.i(
            'SPLASH:  Old user with lounge_added/completed status - Going to HOME',
          );
          _hasNavigated = true;
          Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
        } else {
          // Registration not completed - logout and restart full flow
          // This ensures user goes through: Phone  OTP  Role Selection  Registration
          _logger.w(
            'SPLASH:  Registration not completed (step: $registrationStep) - logging out and restarting flow',
          );
          await authProvider.logout();
          _hasNavigated = true;
          Navigator.of(
            context,
          ).pushReplacementNamed(AppConstants.roleSelectionRoute);
        }
      }
    } else {
      //  Not authenticated (no tokens) - go to role selection
      _logger.i('SPLASH:  Not authenticated - going to role selection');
      _hasNavigated = true;
      Navigator.of(context)
          .pushReplacementNamed(AppConstants.roleSelectionRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo - LIOR with rounded background
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/lior_logo_no_bg.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),

              // Subtitle with Gold accent
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: AppGradients.goldGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Lounge Owner',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Loading Indicator
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
