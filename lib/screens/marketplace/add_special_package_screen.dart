import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/theme_config.dart';
import '../../core/di/injection_container.dart';
import '../../core/services/image_cache_service.dart';
import '../../domain/entities/lounge_special_package.dart';
import '../../presentation/providers/lounge_special_package_provider.dart';

/// Screen to add or edit a lounge special package
class AddSpecialPackageScreen extends StatefulWidget {
  final String loungeId;
  final String loungeName;
  final LoungeSpecialPackage? package; // null = add mode

  const AddSpecialPackageScreen({
    super.key,
    required this.loungeId,
    required this.loungeName,
    this.package,
  });

  @override
  State<AddSpecialPackageScreen> createState() =>
      _AddSpecialPackageScreenState();
}

class _AddSpecialPackageScreenState extends State<AddSpecialPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  SpecialPackageType _selectedType = SpecialPackageType.standard;

  File? _selectedImage;
  String? _existingImageUrl;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.package != null;

  @override
  void initState() {
    super.initState();

    final pkg = widget.package;
    _nameController = TextEditingController(text: pkg?.packageName ?? '');
    _descriptionController =
        TextEditingController(text: pkg?.description ?? '');
    _priceController = TextEditingController(text: pkg?.price ?? '');

    if (pkg != null) {
      _selectedType = pkg.packageType;
      _existingImageUrl = pkg.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Package' : 'Add Package'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker
              _buildImagePicker(),
              const SizedBox(height: AppSpacing.large),

              // Basic Information Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: AppSpacing.medium),
              _buildNameField(),
              const SizedBox(height: AppSpacing.medium),
              _buildDescriptionField(),
              const SizedBox(height: AppSpacing.medium),
              _buildPackageTypeDropdown(),

              const SizedBox(height: AppSpacing.large),

              // Pricing Section
              _buildSectionTitle('Pricing'),
              const SizedBox(height: AppSpacing.medium),
              _buildPriceField(),

              const SizedBox(height: AppSpacing.xLarge),

              // Submit Button
              _buildSubmitButton(),
              const SizedBox(height: AppSpacing.large),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: _isUploadingImage
            ? const Center(child: CircularProgressIndicator())
            : _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_selectedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(_selectedImage!, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _selectedImage = null),
              ),
            ),
          ),
        ],
      );
    }

    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: OptimizedCachedImage(
              imageUrl: _existingImageUrl!,
              fit: BoxFit.cover,
              quality: 'sd',
              errorWidget: (_, __, ___) => _buildImagePlaceholder(),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 60,
          color: AppColors.textSecondary.withOpacity(0.5),
        ),
        const SizedBox(height: AppSpacing.small),
        const Text(
          'Tap to add package image',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Package Name *',
        hintText: 'e.g., VIP Airport Lounge Access',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a package name';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Package Description *',
        hintText: 'Describe all benefits (e.g., destinations, services, perks)...',
        alignLabelWithHint: true,
      ),
      maxLines: 8,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildPackageTypeDropdown() {
    return DropdownButtonFormField<SpecialPackageType>(
      value: _selectedType,
      decoration: const InputDecoration(labelText: 'Package Type *'),
      items: SpecialPackageType.values.map((type) {
        return DropdownMenuItem<SpecialPackageType>(
          value: type,
          child: Text(type.displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedType = value;
          });
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a package type';
        }
        return null;
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: const InputDecoration(
        labelText: 'Price (LKR) *',
        prefixText: 'LKR ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a price';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Invalid price';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<LoungeSpecialPackageProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isSubmitting || _isUploadingImage || _isSubmitting;
        return ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
            backgroundColor: AppColors.primary,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _isEditMode ? 'Update Package' : 'Add Package',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider =
          Provider.of<LoungeSpecialPackageProvider>(context, listen: false);

      // 1. Upload image if new one selected
      String? imageUrl = _existingImageUrl;
      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);
        try {
          final storageService = InjectionContainer().supabaseStorageService;
          imageUrl = await storageService.uploadSpecialPackageImage(
            imageFile: _selectedImage!,
            loungeId: widget.loungeId,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        } finally {
          if (mounted) setState(() => _isUploadingImage = false);
        }
      }

      // 2. Create or update package
      bool success;
      if (_isEditMode) {
        success = await provider.updatePackage(
          loungeId: widget.loungeId,
          packageId: widget.package!.id,
          packageName: _nameController.text.trim(),
          imageUrl: imageUrl,
          packageType: _selectedType,
          description: _descriptionController.text.trim(),
          price: _priceController.text.trim(),
        );
      } else {
        success = await provider.createPackage(
          loungeId: widget.loungeId,
          packageName: _nameController.text.trim(),
          imageUrl: imageUrl,
          packageType: _selectedType,
          description: _descriptionController.text.trim(),
          price: _priceController.text.trim(),
        );
      }

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Package updated successfully'
                  : 'Package added successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to save package'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
