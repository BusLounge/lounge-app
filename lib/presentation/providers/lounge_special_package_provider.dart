import 'package:flutter/foundation.dart';
import '../../domain/entities/lounge_special_package.dart';
import '../../data/repositories/lounge_special_package_repository.dart';
import '../../data/models/lounge_special_package_model.dart';

enum SpecialPackageLoadState { initial, loading, loaded, error }

/// Provider / ViewModel for lounge special packages
class LoungeSpecialPackageProvider extends ChangeNotifier {
  final LoungeSpecialPackageRepository _repository;

  LoungeSpecialPackageProvider({required LoungeSpecialPackageRepository repository})
      : _repository = repository;

  // ─────────────────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────────────────
  SpecialPackageLoadState _state = SpecialPackageLoadState.initial;
  List<LoungeSpecialPackage> _packages = [];
  String? _error;
  bool _isSubmitting = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────────────────
  SpecialPackageLoadState get state => _state;
  List<LoungeSpecialPackage> get packages => _packages;
  String? get error => _error;
  bool get isSubmitting => _isSubmitting;
  bool get isLoading => _state == SpecialPackageLoadState.loading;

  // ─────────────────────────────────────────────────────────────────────────
  // Methods
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadPackages(String loungeId) async {
    _state = SpecialPackageLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _packages = await _repository.getSpecialPackages(loungeId);
      _state = SpecialPackageLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = SpecialPackageLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createPackage({
    required String loungeId,
    required String packageName,
    String? imageUrl,
    required SpecialPackageType packageType,
    required String description,
    required String price,
    // Extended
    int? pax,
    bool? transportStatus,
    TransportMode? transportMode,
    bool? mealStatus,
    bool? breakfastStatus,
    List<String>? breakfastType,
    bool? lunchStatus,
    List<String>? lunchType,
    bool? eveningSnackStatus,
    List<String>? eveningSnackType,
    bool? dinnerStatus,
    List<String>? dinnerType,
    List<String>? places,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final model = LoungeSpecialPackageModel(
        id: '',
        loungeId: loungeId,
        packageName: packageName,
        imageUrl: imageUrl,
        packageType: packageType,
        description: description,
        price: price,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pax: pax,
        transportStatus: transportStatus,
        transportMode: transportMode,
        mealStatus: mealStatus,
        breakfastStatus: breakfastStatus,
        breakfastType: breakfastType,
        lunchStatus: lunchStatus,
        lunchType: lunchType,
        eveningSnackStatus: eveningSnackStatus,
        eveningSnackType: eveningSnackType,
        dinnerStatus: dinnerStatus,
        dinnerType: dinnerType,
        places: places,
      );

      final created = await _repository.createSpecialPackage(loungeId, model);
      _packages = [created, ..._packages];
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updatePackage({
    required String loungeId,
    required String packageId,
    required String packageName,
    String? imageUrl,
    required SpecialPackageType packageType,
    required String description,
    required String price,
    // Extended
    int? pax,
    bool? transportStatus,
    TransportMode? transportMode,
    bool? mealStatus,
    bool? breakfastStatus,
    List<String>? breakfastType,
    bool? lunchStatus,
    List<String>? lunchType,
    bool? eveningSnackStatus,
    List<String>? eveningSnackType,
    bool? dinnerStatus,
    List<String>? dinnerType,
    List<String>? places,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final model = LoungeSpecialPackageModel(
        id: packageId,
        loungeId: loungeId,
        packageName: packageName,
        imageUrl: imageUrl,
        packageType: packageType,
        description: description,
        price: price,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pax: pax,
        transportStatus: transportStatus,
        transportMode: transportMode,
        mealStatus: mealStatus,
        breakfastStatus: breakfastStatus,
        breakfastType: breakfastType,
        lunchStatus: lunchStatus,
        lunchType: lunchType,
        eveningSnackStatus: eveningSnackStatus,
        eveningSnackType: eveningSnackType,
        dinnerStatus: dinnerStatus,
        dinnerType: dinnerType,
        places: places,
      );

      final updated = await _repository.updateSpecialPackage(loungeId, packageId, model);
      _packages = _packages
          .map((p) => p.id == packageId ? updated : p)
          .cast<LoungeSpecialPackage>()
          .toList();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deletePackage(String loungeId, String packageId) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteSpecialPackage(loungeId, packageId);
      _packages = _packages.where((p) => p.id != packageId).toList();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _state = SpecialPackageLoadState.initial;
    _packages = [];
    _error = null;
    _isSubmitting = false;
    notifyListeners();
  }
}
