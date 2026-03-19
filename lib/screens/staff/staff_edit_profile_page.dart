import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/lounge_staff_provider.dart';

class StaffEditProfilePage extends StatefulWidget {
  const StaffEditProfilePage({super.key});

  @override
  State<StaffEditProfilePage> createState() => _StaffEditProfilePageState();
}

class _StaffEditProfilePageState extends State<StaffEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _nicCtrl;
  late TextEditingController _emailCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loungeStaffProvider = Provider.of<LoungeStaffProvider>(
      context,
      listen: false,
    );
    final user = authProvider.user;
    final staff = loungeStaffProvider.selectedStaff;

    _nameCtrl = TextEditingController(
      text: staff?.fullName ?? user?.firstName ?? '',
    );
    _phoneCtrl = TextEditingController(
      text: staff?.phone ?? user?.phoneNumber ?? '',
    );
    _nicCtrl = TextEditingController(text: staff?.nicNumber ?? user?.nic ?? '');
    _emailCtrl = TextEditingController(text: staff?.email ?? user?.email ?? '');

    if (staff == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loungeStaffProvider.getMyStaffProfile();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nicCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final loungeStaffProvider = Provider.of<LoungeStaffProvider>(
        context,
        listen: false,
      );

      final success = await loungeStaffProvider.updateProfile(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        nicNumber: _nicCtrl.text.trim().toUpperCase(),
        email: _emailCtrl.text.trim(),
      );

      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loungeStaffProvider.error ?? 'Failed to update profile',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      if (authProvider.user != null) {
        final updatedUser = authProvider.user!.copyWith(
          firstName: _nameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          nic: _nicCtrl.text.trim().toUpperCase(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          updatedAt: DateTime.now(),
        );

        await authProvider.updateUserProfile(updatedUser);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Full Name Field
                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }

                    final trimmedValue = value.trim();

                    if (trimmedValue.length < 3) {
                      return 'Name must be at least 3 characters';
                    }

                    if (trimmedValue.length > 50) {
                      return 'Name must not exceed 50 characters';
                    }

                    // Check for valid characters (letters, spaces, hyphens, apostrophes)
                    final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
                    if (!nameRegex.hasMatch(trimmedValue)) {
                      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
                    }

                    // Check for at least one letter
                    if (!RegExp(r'[a-zA-Z]').hasMatch(trimmedValue)) {
                      return 'Name must contain at least one letter';
                    }

                    // Check for excessive spaces
                    if (trimmedValue.contains(RegExp(r'\s{2,}'))) {
                      return 'Name cannot contain consecutive spaces';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Phone Number
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }

                    final normalized = value.trim().replaceAll(' ', '');
                    final phonePattern = RegExp(r'^\+?\d{10,15}$');
                    if (!phonePattern.hasMatch(normalized)) {
                      return 'Invalid phone number (10-15 digits)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Email Field
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    final emailRegex = RegExp(
                      r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // NIC Number Field
                const Text(
                  'NIC Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nicCtrl,
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  maxLength: 12,
                  decoration: InputDecoration(
                    hintText: 'Enter your NIC number',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    helperText: 'Format: 9 digits + V/X or 12 digits',
                    helperStyle: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your NIC number';
                    }

                    final trimmedValue = value.trim().toUpperCase();

                    // Old NIC format: 9 digits followed by V or X
                    final oldNicRegex = RegExp(r'^\d{9}[VvXx]$');

                    // New NIC format: 12 digits
                    final newNicRegex = RegExp(r'^\d{12}$');

                    if (!oldNicRegex.hasMatch(trimmedValue) &&
                        !newNicRegex.hasMatch(trimmedValue)) {
                      return 'Invalid NIC format. Use 9 digits + V/X or 12 digits';
                    }

                    // Additional validation for old format
                    if (oldNicRegex.hasMatch(trimmedValue)) {
                      final year = int.tryParse(trimmedValue.substring(0, 2));
                      final days = int.tryParse(trimmedValue.substring(2, 5));

                      if (year == null || days == null) {
                        return 'Invalid NIC number';
                      }

                      // Days should be between 1-366 for males, 501-866 for females
                      if ((days < 1 || days > 366) &&
                          (days < 501 || days > 866)) {
                        return 'Invalid NIC number';
                      }
                    }

                    // Additional validation for new format
                    if (newNicRegex.hasMatch(trimmedValue)) {
                      final year = int.tryParse(trimmedValue.substring(0, 4));
                      final days = int.tryParse(trimmedValue.substring(4, 7));

                      if (year == null || days == null) {
                        return 'Invalid NIC number';
                      }

                      // Year should be reasonable (e.g., 1900-2026)
                      if (year < 1900 || year > 2026) {
                        return 'Invalid birth year in NIC';
                      }

                      // Days should be between 1-366 for males, 501-866 for females
                      if ((days < 1 || days > 366) &&
                          (days < 501 || days > 866)) {
                        return 'Invalid NIC number';
                      }
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: AppColors.primary.withOpacity(
                        0.5,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textLight,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
