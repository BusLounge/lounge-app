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

// ─────────────────────────────────────────────────────────────────────────────
// Helper widget: a dynamic multi-item text input list with + / − controls
// ─────────────────────────────────────────────────────────────────────────────
class _MultiItemInput extends StatefulWidget {
  final String label;
  final String hint;
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _MultiItemInput({
    required this.label,
    required this.hint,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_MultiItemInput> createState() => _MultiItemInputState();
}

class _MultiItemInputState extends State<_MultiItemInput> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(widget.controllers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.controllers[i],
                    decoration: InputDecoration(
                      labelText: '${widget.label} ${i + 1}',
                      hintText: widget.hint,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Remove button (only when more than 1)
                if (widget.controllers.length > 1)
                  InkWell(
                    onTap: () => widget.onRemove(i),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.remove,
                          color: AppColors.error, size: 18),
                    ),
                  ),
              ],
            ),
          );
        }),
        // Add button
        TextButton.icon(
          onPressed: widget.onAdd,
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: Text('Add ${widget.label}'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widget: a styled section toggle card
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? expandedContent;

  const _ToggleCard({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.expandedContent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppColors.primary.withOpacity(0.4) : AppColors.border,
          width: value ? 1.5 : 1,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: subtitle != null
                ? Text(subtitle!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary))
                : null,
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: value && expandedContent != null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: expandedContent!,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────
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

  // ── Basic fields ──────────────────────────────────────────────────────────
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _paxController;
  SpecialPackageType _selectedType = SpecialPackageType.standard;

  // ── Image ─────────────────────────────────────────────────────────────────
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  // ── Transport ─────────────────────────────────────────────────────────────
  bool _transportStatus = false;
  TransportMode? _transportMode;

  // ── Meal ──────────────────────────────────────────────────────────────────
  bool _mealStatus = false;

  bool _breakfastStatus = false;
  List<TextEditingController> _breakfastControllers = [TextEditingController()];

  bool _lunchStatus = false;
  List<TextEditingController> _lunchControllers = [TextEditingController()];

  bool _eveningSnackStatus = false;
  List<TextEditingController> _eveningSnackControllers = [
    TextEditingController()
  ];

  bool _dinnerStatus = false;
  List<TextEditingController> _dinnerControllers = [TextEditingController()];

  // ── Places ────────────────────────────────────────────────────────────────
  List<TextEditingController> _placesControllers = [TextEditingController()];

  bool get _isEditMode => widget.package != null;

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<TextEditingController> _initControllers(List<String>? values) {
    if (values == null || values.isEmpty) return [TextEditingController()];
    return values.map((v) => TextEditingController(text: v)).toList();
  }

  List<String> _collectNonEmpty(List<TextEditingController> controllers) {
    return controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final c in controllers) {
      c.dispose();
    }
  }

  void _addItem(List<TextEditingController> controllers) {
    setState(() => controllers.add(TextEditingController()));
  }

  void _removeItem(List<TextEditingController> controllers, int index) {
    setState(() {
      controllers[index].dispose();
      controllers.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();

    final pkg = widget.package;
    _nameController = TextEditingController(text: pkg?.packageName ?? '');
    _descriptionController =
        TextEditingController(text: pkg?.description ?? '');
    _priceController = TextEditingController(text: pkg?.price ?? '');
    _paxController =
        TextEditingController(text: pkg?.pax?.toString() ?? '');

    if (pkg != null) {
      _selectedType = pkg.packageType;
      _existingImageUrl = pkg.imageUrl;

      _transportStatus = pkg.transportStatus ?? false;
      _transportMode = pkg.transportMode;

      _mealStatus = pkg.mealStatus ?? false;
      _breakfastStatus = pkg.breakfastStatus ?? false;
      _breakfastControllers = _initControllers(pkg.breakfastType);
      _lunchStatus = pkg.lunchStatus ?? false;
      _lunchControllers = _initControllers(pkg.lunchType);
      _eveningSnackStatus = pkg.eveningSnackStatus ?? false;
      _eveningSnackControllers = _initControllers(pkg.eveningSnackType);
      _dinnerStatus = pkg.dinnerStatus ?? false;
      _dinnerControllers = _initControllers(pkg.dinnerType);
      _placesControllers = _initControllers(pkg.places);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _paxController.dispose();
    _disposeControllers(_breakfastControllers);
    _disposeControllers(_lunchControllers);
    _disposeControllers(_eveningSnackControllers);
    _disposeControllers(_dinnerControllers);
    _disposeControllers(_placesControllers);
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
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
              // ── Image picker ─────────────────────────────────────────────
              _buildImagePicker(),
              const SizedBox(height: AppSpacing.large),

              // ── Basic Information ─────────────────────────────────────────
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: AppSpacing.medium),
              _buildNameField(),
              const SizedBox(height: AppSpacing.medium),
              _buildDescriptionField(),
              const SizedBox(height: AppSpacing.medium),
              _buildPackageTypeDropdown(),

              const SizedBox(height: AppSpacing.large),

              // ── Pricing ───────────────────────────────────────────────────
              _buildSectionTitle('Pricing & Capacity'),
              const SizedBox(height: AppSpacing.medium),
              _buildPriceField(),
              const SizedBox(height: AppSpacing.medium),
              _buildPaxField(),

              const SizedBox(height: AppSpacing.large),

              // ── Transport section ─────────────────────────────────────────
              _buildSectionTitle('Transport'),
              const SizedBox(height: AppSpacing.medium),
              _buildTransportToggle(),

              const SizedBox(height: AppSpacing.large),

              // ── Meal section ──────────────────────────────────────────────
              _buildSectionTitle('Meals'),
              const SizedBox(height: AppSpacing.medium),
              _buildMealToggle(),

              const SizedBox(height: AppSpacing.large),

              // ── Places section ────────────────────────────────────────────
              _buildSectionTitle('Places / Destinations'),
              const SizedBox(height: AppSpacing.medium),
              _buildPlacesSection(),

              const SizedBox(height: AppSpacing.xLarge),

              // ── Submit ────────────────────────────────────────────────────
              _buildSubmitButton(),
              const SizedBox(height: AppSpacing.large),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION TITLE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE PICKER
  // ─────────────────────────────────────────────────────────────────────────
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BASIC FIELDS
  // ─────────────────────────────────────────────────────────────────────────
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
      maxLines: 5,
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
          setState(() => _selectedType = value);
        }
      },
      validator: (value) {
        if (value == null) return 'Please select a package type';
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
        if (price == null || price <= 0) return 'Invalid price';
        return null;
      },
    );
  }

  Widget _buildPaxField() {
    return TextFormField(
      controller: _paxController,
      decoration: const InputDecoration(
        labelText: 'Number of Guests (PAX)',
        hintText: 'e.g., 2',
        prefixIcon: Icon(Icons.people_outline),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final n = int.tryParse(value);
          if (n == null || n <= 0) return 'PAX must be greater than 0';
        }
        return null;
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TRANSPORT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTransportToggle() {
    return _ToggleCard(
      title: 'Transport Included',
      subtitle: 'Toggle on if this package includes transport',
      value: _transportStatus,
      onChanged: (v) => setState(() {
        _transportStatus = v;
        if (!v) _transportMode = null;
      }),
      expandedContent: _buildTransportExpanded(),
    );
  }

  Widget _buildTransportExpanded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 12),
        DropdownButtonFormField<TransportMode>(
          value: _transportMode,
          decoration: const InputDecoration(
            labelText: 'Transport Mode *',
            prefixIcon: Icon(Icons.directions_car_outlined),
          ),
          hint: const Text('Select transport type'),
          items: TransportMode.values.map((mode) {
            return DropdownMenuItem<TransportMode>(
              value: mode,
              child: Text(mode.displayName),
            );
          }).toList(),
          onChanged: (v) => setState(() => _transportMode = v),
          validator: (v) {
            if (_transportStatus && v == null) {
              return 'Please select a transport mode';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MEAL TREE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMealToggle() {
    return _ToggleCard(
      title: 'Meals Included',
      subtitle: 'Toggle on if this package includes meals',
      value: _mealStatus,
      onChanged: (v) => setState(() {
        _mealStatus = v;
        if (!v) {
          _breakfastStatus = false;
          _lunchStatus = false;
          _eveningSnackStatus = false;
          _dinnerStatus = false;
        }
      }),
      expandedContent: _buildMealExpanded(),
    );
  }

  Widget _buildMealExpanded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Breakfast
        _buildMealSubToggle(
          title: 'Breakfast',
          value: _breakfastStatus,
          onChanged: (v) => setState(() => _breakfastStatus = v),
          controllers: _breakfastControllers,
          label: 'Breakfast Option',
          hint: 'e.g., Continental Breakfast',
        ),
        const SizedBox(height: 12),

        // Lunch
        _buildMealSubToggle(
          title: 'Lunch',
          value: _lunchStatus,
          onChanged: (v) => setState(() => _lunchStatus = v),
          controllers: _lunchControllers,
          label: 'Lunch Option',
          hint: 'e.g., Buffet Lunch',
        ),
        const SizedBox(height: 12),

        // Evening Snack
        _buildMealSubToggle(
          title: 'Evening Snack',
          value: _eveningSnackStatus,
          onChanged: (v) => setState(() => _eveningSnackStatus = v),
          controllers: _eveningSnackControllers,
          label: 'Evening Snack Option',
          hint: 'e.g., Tea & Cookies',
        ),
        const SizedBox(height: 12),

        // Dinner
        _buildMealSubToggle(
          title: 'Dinner',
          value: _dinnerStatus,
          onChanged: (v) => setState(() => _dinnerStatus = v),
          controllers: _dinnerControllers,
          label: 'Dinner Option',
          hint: 'e.g., 3-Course Dinner',
        ),
      ],
    );
  }

  Widget _buildMealSubToggle({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required List<TextEditingController> controllers,
    required String label,
    required String hint,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: value
            ? AppColors.primary.withOpacity(0.04)
            : Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value
              ? AppColors.primary.withOpacity(0.25)
              : AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(
              title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: value
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: _MultiItemInput(
                      label: label,
                      hint: hint,
                      controllers: controllers,
                      onAdd: () => _addItem(controllers),
                      onRemove: (i) => _removeItem(controllers, i),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PLACES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPlacesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: _MultiItemInput(
        label: 'Place',
        hint: 'e.g., Bandaranaike International Airport',
        controllers: _placesControllers,
        onAdd: () => _addItem(_placesControllers),
        onRemove: (i) => _removeItem(_placesControllers, i),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return Consumer<LoungeSpecialPackageProvider>(
      builder: (context, provider, _) {
        final isLoading =
            provider.isSubmitting || _isUploadingImage || _isSubmitting;
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

  // ─────────────────────────────────────────────────────────────────────────
  // SUBMIT LOGIC
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Extra validation: transport mode required when transport is on
    if (_transportStatus && _transportMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a transport mode'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

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

      // 2. Collect extended data
      final int? pax = _paxController.text.trim().isEmpty
          ? null
          : int.tryParse(_paxController.text.trim());

      final List<String>? breakfastType =
          _breakfastStatus ? _collectNonEmpty(_breakfastControllers) : null;
      final List<String>? lunchType =
          _lunchStatus ? _collectNonEmpty(_lunchControllers) : null;
      final List<String>? eveningSnackType =
          _eveningSnackStatus ? _collectNonEmpty(_eveningSnackControllers) : null;
      final List<String>? dinnerType =
          _dinnerStatus ? _collectNonEmpty(_dinnerControllers) : null;
      final List<String>? places = _collectNonEmpty(_placesControllers).isEmpty
          ? null
          : _collectNonEmpty(_placesControllers);

      // 3. Create or update
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
          pax: pax,
          transportStatus: _transportStatus,
          transportMode: _transportStatus ? _transportMode : null,
          mealStatus: _mealStatus,
          breakfastStatus: _mealStatus ? _breakfastStatus : null,
          breakfastType: _mealStatus ? breakfastType : null,
          lunchStatus: _mealStatus ? _lunchStatus : null,
          lunchType: _mealStatus ? lunchType : null,
          eveningSnackStatus: _mealStatus ? _eveningSnackStatus : null,
          eveningSnackType: _mealStatus ? eveningSnackType : null,
          dinnerStatus: _mealStatus ? _dinnerStatus : null,
          dinnerType: _mealStatus ? dinnerType : null,
          places: places,
        );
      } else {
        success = await provider.createPackage(
          loungeId: widget.loungeId,
          packageName: _nameController.text.trim(),
          imageUrl: imageUrl,
          packageType: _selectedType,
          description: _descriptionController.text.trim(),
          price: _priceController.text.trim(),
          pax: pax,
          transportStatus: _transportStatus,
          transportMode: _transportStatus ? _transportMode : null,
          mealStatus: _mealStatus,
          breakfastStatus: _mealStatus ? _breakfastStatus : null,
          breakfastType: _mealStatus ? breakfastType : null,
          lunchStatus: _mealStatus ? _lunchStatus : null,
          lunchType: _mealStatus ? lunchType : null,
          eveningSnackStatus: _mealStatus ? _eveningSnackStatus : null,
          eveningSnackType: _mealStatus ? eveningSnackType : null,
          dinnerStatus: _mealStatus ? _dinnerStatus : null,
          dinnerType: _mealStatus ? dinnerType : null,
          places: places,
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
