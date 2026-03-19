import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/staff_bottom_nav_bar.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/lounge_staff_provider.dart';
import 'staff_edit_profile_page.dart';

class StaffProfilePage extends StatefulWidget {
  const StaffProfilePage({super.key});

  @override
  State<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends State<StaffProfilePage> {
  Future<void> _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Do you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loungeStaffProvider = Provider.of<LoungeStaffProvider>(
      context,
      listen: false,
    );

    try {
      await authProvider.logout();
    } catch (_) {
      // Always continue to login screen even if remote logout fails.
    }

    loungeStaffProvider.reset();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/staff-registered-login',
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loungeStaffProvider = Provider.of<LoungeStaffProvider>(
        context,
        listen: false,
      );

      if (loungeStaffProvider.selectedStaff == null &&
          !loungeStaffProvider.isLoading) {
        loungeStaffProvider.getMyStaffProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),

      /// APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      /// BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// PROFILE CARD
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  /// AVATAR
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(
                      Icons.person,
                      size: 38,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// NAME
                  Consumer2<AuthProvider, LoungeStaffProvider>(
                    builder: (context, authProvider, staffProvider, _) {
                      final user = authProvider.user;
                      final staff = staffProvider.selectedStaff;
                      return Text(
                        staff?.fullName ?? user?.firstName ?? 'Guest',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  /// ROLE & STATUS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _InfoChip(
                        text: 'Staff Member',
                        bgColor: Colors.blue.shade100,
                        textColor: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final user = authProvider.user;
                          return _InfoChip(
                            text: user?.phoneVerified == true
                                ? 'Verified'
                                : 'Unverified',
                            bgColor: user?.phoneVerified == true
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            textColor: user?.phoneVerified == true
                                ? Colors.green
                                : Colors.orange,
                            icon: user?.phoneVerified == true
                                ? Icons.check_circle
                                : Icons.pending,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// CONTACT INFORMATION
            Consumer2<AuthProvider, LoungeStaffProvider>(
              builder: (context, authProvider, staffProvider, _) {
                final user = authProvider.user;
                final staff = staffProvider.selectedStaff;
                final staffName = staff?.fullName ?? user?.firstName;
                final staffPhone = staff?.phone ?? user?.phoneNumber;
                final staffNic = staff?.nicNumber ?? user?.nic;

                return _SectionCard(
                  title: 'Contact Information',
                  children: [
                    _InfoTile(
                      icon: Icons.phone,
                      title: 'Phone Number',
                      value: staffPhone ?? 'Not available',
                    ),
                    _InfoTile(
                      icon: Icons.person,
                      title: 'Full Name',
                      value: staffName ?? 'Not available',
                    ),
                    if (staffNic != null && staffNic.isNotEmpty)
                      _InfoTile(
                        icon: Icons.badge,
                        title: 'NIC Number',
                        value: staffNic,
                      ),
                    if (staff?.email != null && staff!.email!.isNotEmpty)
                      _InfoTile(
                        icon: Icons.email,
                        title: 'Email',
                        value: staff.email!,
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            /// EDIT PROFILE
            _ActionTile(
              icon: Icons.edit,
              title: 'Edit Profile',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StaffEditProfilePage(),
                  ),
                );

                if (!mounted) return;
                await Provider.of<LoungeStaffProvider>(
                  context,
                  listen: false,
                ).getMyStaffProfile();
              },
            ),

            const SizedBox(height: 32),

            /// LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmAndLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      /// BOTTOM NAV
      bottomNavigationBar: const StaffBottomNavBar(currentIndex: 3),
    );
  }
}

/// ---------------- INFO CHIP ----------------
class _InfoChip extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;
  final IconData? icon;

  const _InfoChip({
    required this.text,
    required this.bgColor,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- SECTION CARD ----------------
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// ---------------- INFO TILE ----------------
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, size: 18, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

/// ---------------- ACTION TILE ----------------
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade50,
              child: Icon(icon, size: 18, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
