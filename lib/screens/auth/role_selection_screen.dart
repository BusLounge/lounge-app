import 'package:flutter/material.dart';
import 'package:lounge_owner_app/screens/lounge_owner/lounge_owner_registration_screen.dart';
import 'package:provider/provider.dart';
import '../../core/di/injection_container.dart';
import '../../data/datasources/lounge_owner_remote_datasource.dart';
import '../../presentation/providers/role_selection_provider.dart';
import '../../config/theme_config.dart';
import '../staff/staff_registration_page.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String userId;
  final String phoneNumber;
  final String otp;

  const RoleSelectionScreen({
    super.key,
    required this.userId,
    required this.phoneNumber,
    required this.otp,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedDistrict;
  String? _selectedLoungeOwner;
  String? _selectedLounge;

  late LoungeOwnerRemoteDataSource _loungeOwnerRemoteDataSource;
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _ownersForSelectedDistrict = [];
  List<Map<String, dynamic>> _loungesForSelection = [];
  bool _isLoadingDistricts = true;
  bool _isLoadingOwners = false;
  bool _isLoadingLounges = false;
  String? _districtsError;
  String? _ownersError;
  String? _loungesError;

  @override
  void initState() {
    super.initState();
    _loungeOwnerRemoteDataSource =
        InjectionContainer().loungeOwnerRemoteDataSource;
    // Fetch all lounges for staff dropdown when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoleSelectionProvider>().fetchAllLounges();
      _loadDistricts();
    });
  }

  Future<void> _loadDistricts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDistricts = true;
      _districtsError = null;
    });

    try {
      final districts = await _loungeOwnerRemoteDataSource.getAllDistricts();
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _districts = [];
        _isLoadingDistricts = false;
        _districtsError = 'Failed to load districts';
      });
    }
  }

  String? _selectedDistrictName() {
    if (_selectedDistrict == null) return null;
    for (final district in _districts) {
      final id = district['id'] as String?;
      if (id == _selectedDistrict) {
        return district['district'] as String?;
      }
    }
    return null;
  }

  Future<void> _loadOwnersForSelectedDistrict(String districtId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingOwners = true;
      _ownersError = null;
      _ownersForSelectedDistrict = [];
      _loungesForSelection = [];
      _selectedLoungeOwner = null;
      _selectedLounge = null;
    });

    try {
      final owners = await _loungeOwnerRemoteDataSource
          .getApprovedLoungeOwnersByDistrictId(districtId);
      if (!mounted) return;
      setState(() {
        _ownersForSelectedDistrict = owners;
        _isLoadingOwners = false;
        _loungesForSelection = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ownersForSelectedDistrict = [];
        _isLoadingOwners = false;
        _ownersError = 'Failed to load lounge owners';
        _loungesForSelection = [];
      });
    }
  }

  Future<void> _loadLoungesForOwnerAndDistrict({
    required String ownerId,
    required String districtId,
  }) async {
    if (!mounted) return;
    setState(() {
      _isLoadingLounges = true;
      _loungesError = null;
      _loungesForSelection = [];
      _selectedLounge = null;
    });

    try {
      final lounges = await _loungeOwnerRemoteDataSource.getLoungesByOwnerId(
        ownerId,
      );
      if (!mounted) return;
      setState(() {
        _loungesForSelection = lounges.where((lounge) {
          final loungeDistrict = lounge['district']?.toString() ??
              lounge['district_id']?.toString() ??
              '';
          return loungeDistrict == districtId;
        }).toList();
        _isLoadingLounges = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loungesForSelection = [];
        _isLoadingLounges = false;
        _loungesError = 'Failed to load lounges';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.large,
              vertical: AppSpacing.large,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Bus Icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    size: 50,
                    color: AppColors.textLight,
                  ),
                ),

                const SizedBox(height: AppSpacing.large),

                // Welcome Text
                Text(
                  'Select your role',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.small),

                // Subtitle
                Text(
                  'Please select your role to continue with registration',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxLarge),

                // Lounge Owner Card
                _buildLoungeOwnerCard(context),

                const SizedBox(height: AppSpacing.large),

                // Staff Member Card
                _buildStaffMemberCard(context),

                const SizedBox(height: AppSpacing.xLarge),

                // Footer Note
                Container(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.info),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Text(
                          'Your registration will be pending approval after submission',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoungeOwnerCard(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        // Navigate to lounge owner registration with userId, phone, and otp
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoungeOwnerRegistrationScreen(
              userId: widget.userId,
              phoneNumber: widget.phoneNumber,
              otp: widget.otp,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                size: 32,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              'Lounge Owner',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.small / 2),
            Text(
              'Register as a Lounge Owner',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.large,
                vertical: AppSpacing.small,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Select',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffMemberCard(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<RoleSelectionProvider>(
      builder: (context, provider, child) {
        final selectedDistrictName = _selectedDistrictName();
        final availableLounges = _loungesForSelection;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.large),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.secondary.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'Staff Member',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.small / 2),
              Text(
                'Register as a Staff Member',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Select District Dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small / 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: _isLoadingDistricts
                          ? const Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _districtsError != null
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _districtsError!,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loadDistricts,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                )
                              : DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: Text(
                                      'Select your district',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    value: _selectedDistrict,
                                    icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    items: _districts.map((district) {
                                      final id =
                                          district['id'] as String? ?? '';
                                      final name =
                                          district['district'] as String? ?? '';
                                      return DropdownMenuItem<String>(
                                        value: id,
                                        child: Text(
                                          name,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) async {
                                      setState(() {
                                        _selectedDistrict = newValue;
                                      });
                                      if (newValue == null ||
                                          newValue.isEmpty) {
                                        setState(() {
                                          _ownersForSelectedDistrict = [];
                                          _selectedLoungeOwner = null;
                                          _selectedLounge = null;
                                        });
                                        return;
                                      }
                                      await _loadOwnersForSelectedDistrict(
                                          newValue);
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.medium),

              // Select Lounge Owner Dropdown (only enabled if district is selected)
              Opacity(
                opacity: _selectedDistrict == null ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small / 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: Text(
                              _selectedDistrict == null
                                  ? 'Select district first'
                                  : _isLoadingOwners
                                      ? 'Loading lounge owners...'
                                      : _ownersError != null
                                          ? _ownersError!
                                          : _ownersForSelectedDistrict.isEmpty
                                              ? 'No lounge owners in this district'
                                              : 'Select lounge owner',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            value: _selectedLoungeOwner,
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            items: _ownersForSelectedDistrict.map((owner) {
                              final ownerId = owner['id'] as String? ?? '';
                              final ownerName =
                                  owner['business_name'] as String? ??
                                      owner['manager_name'] as String? ??
                                      owner['owner_name'] as String? ??
                                      owner['name'] as String? ??
                                      'Unknown';
                              return DropdownMenuItem<String>(
                                value: ownerId,
                                child: Text(
                                  ownerName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _selectedDistrict == null ||
                                    _isLoadingOwners ||
                                    _ownersForSelectedDistrict.isEmpty
                                ? null
                                : (String? newValue) async {
                                    setState(() {
                                      _selectedLoungeOwner = newValue;
                                      _selectedLounge =
                                          null; // Reset lounge when owner changes
                                    });
                                    if (newValue == null ||
                                        newValue.isEmpty ||
                                        _selectedDistrict == null ||
                                        _selectedDistrict!.isEmpty) {
                                      setState(() {
                                        _loungesForSelection = [];
                                      });
                                      return;
                                    }
                                    await _loadLoungesForOwnerAndDistrict(
                                      ownerId: newValue,
                                      districtId: _selectedDistrict!,
                                    );
                                  },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.medium),

              // Select Lounge Dropdown (only enabled if district and lounge owner are selected)
              Opacity(
                opacity:
                    _selectedDistrict == null || _selectedLoungeOwner == null
                        ? 0.5
                        : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small / 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.store_outlined,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: Text(
                              _selectedDistrict == null ||
                                      _selectedLoungeOwner == null
                                  ? 'Select lounge owner first'
                                  : _isLoadingLounges
                                      ? 'Loading lounges...'
                                      : _loungesError != null
                                          ? _loungesError!
                                          : availableLounges.isEmpty
                                              ? 'No lounges in this district'
                                              : 'Select your lounge',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            value: _selectedLounge,
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            items: availableLounges.map((lounge) {
                              final loungeId = lounge['id'] as String? ?? '';
                              final loungeName =
                                  lounge['lounge_name'] as String? ??
                                      lounge['name'] as String? ??
                                      'Unknown Lounge';
                              return DropdownMenuItem<String>(
                                value: loungeId,
                                child: Text(
                                  loungeName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _selectedDistrict == null ||
                                    _selectedLoungeOwner == null ||
                                    _isLoadingLounges ||
                                    availableLounges.isEmpty
                                ? null
                                : (String? newValue) {
                                    setState(() {
                                      _selectedLounge = newValue;
                                    });
                                  },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_selectedDistrict != null &&
                  _selectedLoungeOwner != null &&
                  availableLounges.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.small),
                  child: Text(
                    '${availableLounges.length} lounge${availableLounges.length == 1 ? '' : 's'} available in ${selectedDistrictName ?? 'selected district'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.medium),

              // Select Button
              InkWell(
                onTap: _selectedDistrict != null &&
                        _selectedLoungeOwner != null &&
                        _selectedLounge != null
                    ? () {
                        // Navigate to staff registration with userData
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StaffRegistrationPage(
                              userId: widget.userId,
                              phoneNumber: widget.phoneNumber,
                              otp: widget.otp,
                              selectedDistrict: _selectedDistrict,
                              selectedLoungeOwner: _selectedLoungeOwner,
                              selectedLounge: _selectedLounge,
                            ),
                          ),
                        );
                      }
                    : null,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.large,
                    vertical: AppSpacing.small,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedDistrict != null &&
                            _selectedLoungeOwner != null &&
                            _selectedLounge != null
                        ? AppColors.secondary
                        : AppColors.secondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: _selectedDistrict != null &&
                            _selectedLoungeOwner != null &&
                            _selectedLounge != null
                        ? [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    'Select',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
