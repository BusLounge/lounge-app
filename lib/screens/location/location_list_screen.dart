import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../presentation/providers/transport_location_provider.dart';
import '../../presentation/providers/registration_provider.dart';

/// Screen to display all saved transport locations
class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  String? _selectedLoungeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final registrationProvider = context.read<RegistrationProvider>();

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
    await context
        .read<TransportLocationProvider>()
        .loadTransportLocations(_selectedLoungeId!);
  }

  Future<void> _deleteLocation(String locationId) async {
    if (_selectedLoungeId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Location',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to delete this location?',
        ),
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
      final provider = context.read<TransportLocationProvider>();
      final success = await provider.deleteTransportLocation(
        loungeId: _selectedLoungeId!,
        locationId: locationId,
      );

      if (!mounted) return;

      if (success) {
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

  Future<void> _editLocation(String locationId, String currentName) async {
    if (_selectedLoungeId == null) return;

    final nameController = TextEditingController(text: currentName);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Location',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Location Name',
            border: OutlineInputBorder(),
          ),
        ),
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final provider = context.read<TransportLocationProvider>();
      final success = await provider.updateTransportLocation(
        loungeId: _selectedLoungeId!,
        locationId: locationId,
        locationName: nameController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to update location'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    nameController.dispose();
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
          'Location List',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadLocations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer2<TransportLocationProvider, RegistrationProvider>(
        builder: (context, provider, registrationProvider, child) {
          final verifiedLounges = registrationProvider.verifiedLounges;

          if (verifiedLounges.isEmpty) {
            return const Center(
              child: Text(
                'No verified lounges yet',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            );
          }

          if (provider.isLoading && provider.locations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

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
                        'No locations saved yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add locations from Transportation Service',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLocations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: provider.locations.length,
                    itemBuilder: (context, index) {
                      final location = provider.locations[index];
                      final prices = location.prices ?? {};

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Location header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: 24,
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
                                    Icons.edit_outlined,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () => _editLocation(
                                    location.id,
                                    location.locationName,
                                  ),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => _deleteLocation(location.id),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),

                            // Coordinates
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.public,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildMetaChip(
                                  icon: Icons.schedule,
                                  label: '${location.estDuration ?? 0} min',
                                ),
                                const SizedBox(width: 8),
                                _buildMetaChip(
                                  icon: Icons.route,
                                  label:
                                      '${(location.distance ?? 0).toStringAsFixed(1)} km',
                                ),
                              ],
                            ),

                            if (prices.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),

                              // Prices
                              const Text(
                                'Pricing',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),

                              ...prices.entries.map((entry) {
                                final price = entry.value;
                                if (price <= 0) return const SizedBox.shrink();

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
                                          entry.key,
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
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Rs. ${price.toStringAsFixed(2)}',
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
                          ],
                        ),
                      );
                    },
                  ),
                );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Container(
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
                ),
              ),
              Expanded(
                child: Stack(
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'three wheeler':
        return Icons.electric_rickshaw;
      case 'car':
        return Icons.directions_car;
      case 'van':
        return Icons.airport_shuttle;
      default:
        return Icons.local_taxi;
    }
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
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
}
