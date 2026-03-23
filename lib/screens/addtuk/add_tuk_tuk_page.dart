import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../presentation/providers/registration_provider.dart';
import '../../presentation/providers/driver_provider.dart';

class AddTukTukPage extends StatefulWidget {
  const AddTukTukPage({super.key});

  @override
  State<AddTukTukPage> createState() => _AddTukTukPageState();
}

class _AddTukTukPageState extends State<AddTukTukPage> {
  final _formKey = GlobalKey<FormState>();

  final _driverNameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _nicController = TextEditingController();

  String _selectedVehicleType = 'Three Wheeler';
  String? _selectedLoungeId;

  @override
  void initState() {
    super.initState();
    // Load lounges when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RegistrationProvider>(context, listen: false).loadMyLounges();
    });
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _vehicleNumberController.dispose();
    _contactNumberController.dispose();
    _nicController.dispose();
    super.dispose();
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLoungeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a lounge'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final driverProvider =
          Provider.of<DriverProvider>(context, listen: false);

      // Map vehicle type to backend format
      String vehicleType;
      switch (_selectedVehicleType) {
        case 'Three Wheeler':
          vehicleType = 'three_wheeler';
          break;
        case 'Van':
          vehicleType = 'van';
          break;
        case 'Car':
          vehicleType = 'car';
          break;
        default:
          vehicleType = 'three_wheeler';
      }

      // Format contact number to +94 format
      String formattedContact = _contactNumberController.text.trim();
      if (formattedContact.startsWith('0')) {
        formattedContact = '+94${formattedContact.substring(1)}';
      } else if (!formattedContact.startsWith('+')) {
        formattedContact = '+94$formattedContact';
      }

      final success = await driverProvider.addDriver(
        loungeId: _selectedLoungeId!,
        fullName: _driverNameController.text.trim(),
        nicNumber: _nicController.text.trim().toUpperCase(),
        contactNumber: formattedContact,
        vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
        vehicleType: vehicleType,
      );

      if (!mounted) return;

      if (success) {
        await _showSuccessDialog(
          title: 'Driver Added Successfully!',
          message: 'The driver has been added to your lounge.',
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(driverProvider.error ?? 'Failed to add driver'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFFFFBF5);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black87,
          ),
        ),
        title: const Text(
          'Add Vehicle Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_taxi,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Add New Vehicle',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Register your vehicle and driver details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Driver Information Section
                const Text(
                  'Driver Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _driverNameController,
                  decoration: _inputDecoration(
                    'Driver Name',
                    Icons.person_outline,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Please enter driver name'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nicController,
                  decoration: _inputDecoration(
                    'NIC Number',
                    Icons.badge_outlined,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter NIC number';
                    }
                    if (v.length != 10 && v.length != 12) {
                      return 'NIC must be 10 or 12 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _contactNumberController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _inputDecoration(
                    'Contact Number',
                    Icons.phone_outlined,
                  ),
                  validator: (v) => v == null || v.length != 10
                      ? 'Please enter valid contact number'
                      : null,
                ),
                const SizedBox(height: 24),

                // Vehicle Information Section
                const Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: _inputDecoration(
                    'Vehicle Number',
                    Icons.confirmation_number_outlined,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Please enter vehicle number'
                      : null,
                ),
                const SizedBox(height: 16),

                // Lounge Selection Dropdown
                Consumer<RegistrationProvider>(
                  builder: (context, provider, child) {
                    final lounges = provider.verifiedLounges;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedLoungeId,
                        hint: const Text(
                          'Select Lounge',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        disabledHint: const Text(
                          'No approved lounges available',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        items: lounges.map((lounge) {
                          return DropdownMenuItem<String>(
                            value: lounge.id,
                            child: Text(
                              lounge.loungeName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: lounges.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedLoungeId = value;
                                });
                              },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.apartment_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          isDense: true,
                        ),
                        icon: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        validator: (value) {
                          if (lounges.isEmpty) {
                            return 'No approved lounges available';
                          }
                          if (value == null || value.isEmpty) {
                            return 'Please select a lounge';
                          }
                          return null;
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedVehicleType,
                    items: ['Three Wheeler', 'Van', 'Car'].map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.local_taxi_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      isDense: true,
                    ),
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    onChanged: (value) =>
                        setState(() => _selectedVehicleType = value!),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                Consumer<DriverProvider>(
                  builder: (context, driverProvider, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            driverProvider.isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: AppColors.primary.withOpacity(0.3),
                        ),
                        child: driverProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Add Vehicle',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
