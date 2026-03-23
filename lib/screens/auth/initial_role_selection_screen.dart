import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../config/constants.dart';
import '../../presentation/providers/auth_provider.dart';
import 'staff_otp_registration_screen.dart';
import 'staff_registered_login_screen.dart';

/// Initial Role Selection Screen
/// Appears before phone input to let users choose:
/// - Lounge Owner
/// - Lounge Staff
class InitialRoleSelectionScreen extends StatelessWidget {
  const InitialRoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.large),

              // Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business_center_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.large),

              // Title
              const Text(
                'Select Your Role',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.small),

              // Subtitle
              const Text(
                'Choose how you want to use SmartTransit',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.large * 2),

              // Lounge Owner Button
              _RoleCard(
                icon: Icons.business,
                title: 'Lounge Owner',
                description: 'Manage your lounge and staff',
                onTap: () {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  authProvider.setSelectedRole('lounge_owner');

                  Navigator.of(context).pushReplacementNamed(
                    AppConstants.phoneInputRoute,
                    arguments: {'selectedRole': 'lounge_owner'},
                  );
                },
              ),
              const SizedBox(height: AppSpacing.large),

              // Lounge Staff Button
              _RoleCard(
                icon: Icons.person,
                title: 'Lounge Staff Sign Up',
                description: 'Work at your favorite lounge',
                onTap: () {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  authProvider.setSelectedRole('lounge_staff');

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const StaffOtpRegistrationScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.large),

              // Registered Lounge Staff Button
              _RoleCard(
                icon: Icons.verified_user,
                title: 'Lounge Staff Sign In',
                description: 'Login to view your staff profile',
                onTap: () {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  authProvider.setSelectedRole('lounge_staff');

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const StaffRegisteredLoginScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Info Text
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
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
                        'You can add more roles later in your profile settings',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.large),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.border,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.large),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
