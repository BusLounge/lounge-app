import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../domain/entities/lounge.dart';

class LoungeDetailsPage extends StatelessWidget {
  final Lounge lounge;

  const LoungeDetailsPage({super.key, required this.lounge});

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
          'Lounge Details',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'Basic Information',
                icon: Icons.info_outline,
                children: [
                  _buildInfoRow('Lounge Name', lounge.loungeName, Icons.store),
                  _buildInfoRow(
                    'Description',
                    lounge.description ?? 'Not provided',
                    Icons.description_outlined,
                  ),
                  _buildInfoRow('Address', lounge.address, Icons.location_on),
                  _buildInfoRow(
                    'Contact Number',
                    lounge.contactPhone ?? 'Not provided',
                    Icons.phone,
                  ),
                  _buildInfoRow(
                    'Capacity',
                    lounge.capacity?.toString() ?? 'Not provided',
                    Icons.people,
                  ),
                  _buildInfoRow('Status', lounge.status, Icons.verified_user),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Pricing',
                icon: Icons.currency_rupee,
                children: [
                  _buildInfoRow(
                    '1 Hour',
                    _priceLabel(lounge.price1Hour),
                    Icons.access_time,
                  ),
                  _buildInfoRow(
                    '2 Hours',
                    _priceLabel(lounge.price2Hours),
                    Icons.schedule,
                  ),
                  _buildInfoRow(
                    '3 Hours',
                    _priceLabel(lounge.price3Hours),
                    Icons.timelapse,
                  ),
                  _buildInfoRow(
                    'Until Bus',
                    _priceLabel(lounge.priceUntilBus),
                    Icons.directions_bus,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Location',
                icon: Icons.map_outlined,
                children: [
                  _buildInfoRow(
                    'State',
                    lounge.state ?? 'Not provided',
                    Icons.map,
                  ),
                  _buildInfoRow(
                    'Country',
                    lounge.country ?? 'Not provided',
                    Icons.public,
                  ),
                  _buildInfoRow(
                    'Postal Code',
                    lounge.postalCode ?? 'Not provided',
                    Icons.markunread_mailbox_outlined,
                  ),
                  _buildInfoRow(
                    'Latitude',
                    lounge.latitude ?? 'Not provided',
                    Icons.place_outlined,
                  ),
                  _buildInfoRow(
                    'Longitude',
                    lounge.longitude ?? 'Not provided',
                    Icons.place,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAmenitiesSection(),
              const SizedBox(height: 16),
              _buildRoutesSection(),
              const SizedBox(height: 16),
              _buildImagesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              image: lounge.primaryPhoto != null
                  ? DecorationImage(
                      image: NetworkImage(lounge.primaryPhoto!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: lounge.primaryPhoto == null
                ? Icon(
                    Icons.apartment,
                    size: 64,
                    color: Colors.grey.shade400,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            lounge.loungeName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(lounge.status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              lounge.status.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _statusColor(lounge.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    final amenities = lounge.amenities ?? const [];

    return _buildSectionCard(
      title: 'Amenities',
      icon: Icons.miscellaneous_services,
      children: [
        if (amenities.isEmpty)
          const Text(
            'No amenities available',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: amenities.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primary.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LoungeAmenities.icons[amenity] ?? Icons.check_circle,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      LoungeAmenities.labels[amenity] ?? amenity,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildRoutesSection() {
    final routes = lounge.routes ?? const [];

    return _buildSectionCard(
      title: 'Routes',
      icon: Icons.alt_route,
      children: [
        if (routes.isEmpty)
          const Text(
            'No routes available',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ...routes.asMap().entries.map(
                (entry) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route ${entry.key + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Master Route ID: ${entry.value.masterRouteId}'),
                      Text('Stop Before ID: ${entry.value.stopBeforeId}'),
                      Text('Stop After ID: ${entry.value.stopAfterId}'),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildImagesSection() {
    final images = lounge.images ?? const [];

    return _buildSectionCard(
      title: 'Images',
      icon: Icons.photo_library_outlined,
      children: [
        if (images.isEmpty)
          const Text(
            'No lounge images available',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images[index],
                  width: 140,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 140,
                    height: 110,
                    color: Colors.grey.shade100,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _priceLabel(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not provided';
    return 'LKR $value';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF2E7D32);
      case 'pending':
        return const Color(0xFFF57C00);
      case 'suspended':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
