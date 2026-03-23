import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme_config.dart';
import '../../presentation/providers/transport_location_provider.dart';
import '../../presentation/providers/registration_provider.dart';
import '../../data/models/transport_location_model.dart';

class TukTukServiceSettingsPage extends StatefulWidget {
  const TukTukServiceSettingsPage({super.key});

  @override
  State<TukTukServiceSettingsPage> createState() =>
      _TukTukServiceSettingsPageState();
}

class _TukTukServiceSettingsPageState extends State<TukTukServiceSettingsPage> {
  final List<String> vehicleTypes = ["Three Wheeler", "Car", "Van"];
  final Map<String, Map<String, TextEditingController>> _priceControllers = {};
  String? _selectedLoungeId;
  bool _loadingDialogVisible = false;
  BuildContext? _loadingDialogContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  void _showLoadingDialog() {
    if (!mounted || _loadingDialogVisible) return;

    _loadingDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _loadingDialogContext = dialogContext;
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    ).then((_) {
      _loadingDialogVisible = false;
      _loadingDialogContext = null;
    });
  }

  void _hideLoadingDialog() {
    if (!_loadingDialogVisible) return;

    final dialogContext = _loadingDialogContext;
    if (dialogContext != null) {
      Navigator.of(dialogContext, rootNavigator: true).pop();
    } else if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    _loadingDialogVisible = false;
    _loadingDialogContext = null;
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Done',
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
    );
  }

  Future<void> _initialize() async {
    final registrationProvider = context.read<RegistrationProvider>();

    // Load lounges if not already loaded
    if (registrationProvider.myLounges.isEmpty) {
      await registrationProvider.loadMyLounges();
    }

    final verifiedLounges = registrationProvider.verifiedLounges;
    if (verifiedLounges.isNotEmpty) {
      setState(() {
        _selectedLoungeId = verifiedLounges.first.id;
      });
      await _loadLocations();
    }
  }

  Future<void> _loadLocations() async {
    if (_selectedLoungeId == null) return;

    final provider = context.read<TransportLocationProvider>();
    await provider.loadTransportLocations(_selectedLoungeId!);

    // Initialize price controllers
    for (var location in provider.locations) {
      _initializeControllersForLocation(location);
    }
  }

  void _initializeControllersForLocation(TransportLocationModel location) {
    _priceControllers[location.id] = {};
    for (var vehicleType in vehicleTypes) {
      final price = location.prices?[vehicleType];
      _priceControllers[location.id]![vehicleType] = TextEditingController(
        text: price != null ? price.toString() : '',
      );
    }
  }

  _addLocationDialog() {
    final TextEditingController locCtrl = TextEditingController();
    final TextEditingController latCtrl = TextEditingController();
    final TextEditingController lonCtrl = TextEditingController();
    final TextEditingController estDurationCtrl = TextEditingController();
    final TextEditingController distanceCtrl = TextEditingController();
    final TextEditingController threeWheelerPriceCtrl = TextEditingController();
    final TextEditingController carPriceCtrl = TextEditingController();
    final TextEditingController vanPriceCtrl = TextEditingController();
    bool isLoadingLocation = false;
    String? selectedLoungeId = _selectedLoungeId;

    final registrationProvider = context.read<RegistrationProvider>();
    final verifiedLounges = registrationProvider.verifiedLounges;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Add Location',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                // Lounge Selection Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Select Lounge *'),
                    value: selectedLoungeId,
                    items: verifiedLounges.map((lounge) {
                      return DropdownMenuItem<String>(
                        value: lounge.id,
                        child: Text(lounge.loungeName),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedLoungeId = newValue;
                      });
                    },
                  ),
                ),

                // Location Name Field
                TextField(
                  controller: locCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Location Name *',
                    hintText: 'e.g., Negombo railway station',
                    prefixIcon:
                        const Icon(Icons.location_on, color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),

                TextField(
                  controller: estDurationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Estimated Duration (minutes) *',
                    hintText: 'e.g., 15',
                    prefixIcon:
                        const Icon(Icons.schedule, color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),

                TextField(
                  controller: distanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Distance from Lounge (km) *',
                    hintText: 'e.g., 3.5',
                    prefixIcon:
                        const Icon(Icons.route, color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      const Text(
                        'Initial Prices (LKR) *',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextField(
                        controller: threeWheelerPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Three Wheeler Price *',
                          hintText: 'Minimum 50',
                          prefixIcon: const Icon(
                            Icons.electric_rickshaw,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      TextField(
                        controller: carPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Car Price *',
                          hintText: 'Minimum 50',
                          prefixIcon: const Icon(
                            Icons.directions_car,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      TextField(
                        controller: vanPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Van Price *',
                          hintText: 'Minimum 50',
                          prefixIcon: const Icon(
                            Icons.airport_shuttle,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Coordinates Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      const Text(
                        'Coordinates',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // Latitude Field
                      TextField(
                        controller: latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: 'Latitude (-90 to 90) *',
                          hintText: 'e.g., 7.21',
                          prefixIcon: const Icon(Icons.location_on_outlined,
                              color: AppColors.primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                      // Longitude Field
                      TextField(
                        controller: lonCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: 'Longitude (-180 to 180) *',
                          hintText: 'e.g., 79.84',
                          prefixIcon: const Icon(Icons.location_on_outlined,
                              color: AppColors.primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                      // Get Current Location Button
                      ElevatedButton.icon(
                        onPressed: isLoadingLocation
                            ? null
                            : () async {
                                setState(() => isLoadingLocation = true);
                                try {
                                  final permission =
                                      await Geolocator.checkPermission();
                                  if (permission == LocationPermission.denied) {
                                    await Geolocator.requestPermission();
                                  }

                                  if (permission ==
                                      LocationPermission.deniedForever) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Location permission is required'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  final Position position =
                                      await Geolocator.getCurrentPosition(
                                    desiredAccuracy: LocationAccuracy.best,
                                  );

                                  latCtrl.text =
                                      position.latitude.toStringAsFixed(6);
                                  lonCtrl.text =
                                      position.longitude.toStringAsFixed(6);

                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Location fetched successfully'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to fetch location: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                } finally {
                                  setState(() => isLoadingLocation = false);
                                }
                              },
                        icon: isLoadingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Get Current Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ],
                  ),
                ),

                // Required Fields Note
                const Text(
                  '* Required fields',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate lounge selection
                if (selectedLoungeId == null || selectedLoungeId!.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a lounge'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Validate inputs
                if (locCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a location name'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                int? estDuration;
                try {
                  estDuration = int.parse(estDurationCtrl.text);
                  if (estDuration <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Estimated duration must be a positive integer'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please enter a valid estimated duration in minutes'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                double? distance;
                try {
                  distance = double.parse(distanceCtrl.text);
                  if (distance < 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Distance must be zero or a positive number'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid distance in km'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                double? latitude, longitude;
                try {
                  latitude = double.parse(latCtrl.text);
                  longitude = double.parse(lonCtrl.text);

                  // Validate ranges
                  if (latitude < -90 || latitude > 90) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Latitude must be between -90 and 90'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  if (longitude < -180 || longitude > 180) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Longitude must be between -180 and 180'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid coordinates'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                double? threeWheelerPrice;
                double? carPrice;
                double? vanPrice;
                try {
                  threeWheelerPrice = double.parse(threeWheelerPriceCtrl.text);
                  carPrice = double.parse(carPriceCtrl.text);
                  vanPrice = double.parse(vanPriceCtrl.text);

                  if (threeWheelerPrice < 50 ||
                      carPrice < 50 ||
                      vanPrice < 50) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Each price must be at least 50 LKR for first setup'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please enter valid prices for all vehicles'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx); // Close the add location dialog

                final provider = context.read<TransportLocationProvider>();
                bool success = false;
                bool pricesSaved = false;

                try {
                  _showLoadingDialog();
                  final createdLocation = await provider.addTransportLocation(
                    loungeId: selectedLoungeId!,
                    locationName: locCtrl.text.trim(),
                    latitude: latitude,
                    longitude: longitude,
                    estDuration: estDuration,
                    distance: distance,
                  );

                  success = createdLocation != null;

                  if (createdLocation != null) {
                    pricesSaved = await provider.setLocationPrices(
                      loungeId: selectedLoungeId!,
                      locationId: createdLocation.id,
                      prices: {
                        'Three Wheeler': threeWheelerPrice,
                        'Car': carPrice,
                        'Van': vanPrice,
                      },
                    );
                  }

                  if (success) {
                    // Reload locations
                    await provider.loadTransportLocations(selectedLoungeId!);
                  }
                } finally {
                  _hideLoadingDialog();
                }

                if (!mounted) return;

                if (success && pricesSaved) {
                  await _showSuccessDialog(
                    title: 'Location Added Successfully!',
                    message:
                        'The location and its prices have been added for this lounge.',
                  );
                } else if (success && !pricesSaved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.error ??
                            'Location added, but failed to save prices. Please update prices.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.error ?? 'Failed to add location'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteLocation(String locationId) async {
    if (_selectedLoungeId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Location',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text('Are you sure you want to delete this location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      final provider = context.read<TransportLocationProvider>();
      final success = await provider.deleteTransportLocation(
        loungeId: _selectedLoungeId!,
        locationId: locationId,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (success) {
        _priceControllers.remove(locationId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to delete location'),
            backgroundColor: AppColors.error,
          ),
        );
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
        title: const Text(
          'Transportation Service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          onPressed: _addLocationDialog,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Location',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lounge Selection Dropdown
            Consumer<RegistrationProvider>(
              builder: (context, regProvider, child) {
                final verifiedLounges = regProvider.verifiedLounges;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text(
                      'Select Lounge',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    value: verifiedLounges
                            .any((lounge) => lounge.id == _selectedLoungeId)
                        ? _selectedLoungeId
                        : null,
                    items: verifiedLounges.map((lounge) {
                      return DropdownMenuItem<String>(
                        value: lounge.id,
                        child: Row(
                          children: [
                            const Icon(Icons.store,
                                size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                lounge.loungeName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        setState(() {
                          _selectedLoungeId = newValue;
                        });
                        await _loadLocations();
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'Service Locations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<TransportLocationProvider>(
                builder: (context, provider, child) {
                  final content = provider.locations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No locations added yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap the button below to add a location',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.locations.length,
                          itemBuilder: (context, index) {
                            final location = provider.locations[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Location name row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          location.locationName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () =>
                                            _deleteLocation(location.id),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _buildInfoChip(
                                        icon: Icons.schedule,
                                        label:
                                            '${location.estDuration ?? 0} min',
                                      ),
                                      const SizedBox(width: 8),
                                      _buildInfoChip(
                                        icon: Icons.route,
                                        label:
                                            '${(location.distance ?? 0).toStringAsFixed(1)} km',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 16),

                                  // Price UI for the 3 vehicles
                                  _buildPriceSection(location),
                                ],
                              ),
                            );
                          },
                        );

                  return Stack(
                    children: [
                      Positioned.fill(child: content),
                      if (provider.isLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.05),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget builder for price section with conditional rendering
  Widget _buildPriceSection(TransportLocationModel location) {
    final hasPrices = location.prices != null &&
        location.prices!.values.any((value) => value > 0);

    if (hasPrices) {
      // Show only prices display (read-only)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 20),
              SizedBox(width: 8),
              Text(
                'Prices Set',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...location.prices!.entries.map((entry) {
            // Format the display name from snake_case
            String displayName = entry.key
                .replaceAll('_price', '')
                .replaceAll('_', ' ')
                .split(' ')
                .map((word) => word[0].toUpperCase() + word.substring(1))
                .join(' ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _getVehicleIcon(entry.key),
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rs. ${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }

    // Show price input fields with Save button
    return Column(
      children: [
        priceInputRow(location, "Three Wheeler", Icons.electric_rickshaw,
            AppColors.primary),
        const SizedBox(height: 12),
        priceInputRow(location, "Car", Icons.directions_car, AppColors.primary),
        const SizedBox(height: 12),
        priceInputRow(
            location, "Van", Icons.airport_shuttle, AppColors.secondary),
        const SizedBox(height: 16),

        // Save button for this location
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _savePricesForLocation(location),
            icon: const Icon(Icons.save, size: 20),
            label: const Text('Save Prices'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'three wheeler':
      case 'three_wheeler_price':
        return Icons.electric_rickshaw;
      case 'car':
      case 'car_price':
        return Icons.directions_car;
      case 'van':
      case 'van_price':
        return Icons.airport_shuttle;
      default:
        return Icons.local_taxi;
    }
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePricesForLocation(TransportLocationModel location) async {
    if (_selectedLoungeId == null) return;

    final controllers = _priceControllers[location.id];
    if (controllers == null) return;

    final prices = <String, double>{};
    controllers.forEach((vehicleType, controller) {
      final priceText = controller.text.trim();
      if (priceText.isNotEmpty) {
        final price = double.tryParse(priceText);
        if (price != null && price > 0) {
          prices[vehicleType] = price;
        }
      }
    });

    if (prices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one price'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final provider = context.read<TransportLocationProvider>();
    final success = await provider.setLocationPrices(
      loungeId: _selectedLoungeId!,
      locationId: location.id,
      prices: prices,
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Close loading

    if (success) {
      await _showSuccessDialog(
        title: 'Prices Saved Successfully!',
        message: 'Location prices have been updated successfully.',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to save prices'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget buildPriceFields(TransportLocationModel location) {
    return Column(
      children: [
        priceInputRow(location, "Three Wheeler", Icons.electric_rickshaw,
            AppColors.primary),
        const SizedBox(height: 12),
        priceInputRow(location, "Car", Icons.directions_car, AppColors.primary),
        const SizedBox(height: 12),
        priceInputRow(
            location, "Van", Icons.airport_shuttle, AppColors.secondary),
      ],
    );
  }

  Widget priceInputRow(TransportLocationModel location, String type,
      IconData icon, Color color) {
    final controller = _priceControllers[location.id]?[type];
    if (controller == null) return const SizedBox.shrink();

    return Row(
      children: [
        // Vehicle Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(width: 12),

        // Price Text Field
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Enter price",
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              labelText: "$type Price (Rs.)",
              labelStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    _priceControllers.forEach((locationId, controllers) {
      controllers.forEach((vehicleType, controller) {
        controller.dispose();
      });
    });
    super.dispose();
  }
}
