import 'package:flutter/foundation.dart';
import '../../core/utils/logger.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../domain/entities/lounge_product.dart';
import '../../domain/entities/marketplace_category.dart';

/// State for marketplace operations
enum MarketplaceState {
  initial,
  loading,
  loaded,
  error,
}

/// Provider for marketplace state management
class MarketplaceProvider extends ChangeNotifier {
  final MarketplaceRepository _repository;

  static const Set<String> _excludedCategoryTerms = {
    'charging',
    'wifi',
    'wi-fi',
    'shower',
    'rest area',
    'storage',
  };

  MarketplaceProvider({required MarketplaceRepository repository})
      : _repository = repository;

  // State
  MarketplaceState _state = MarketplaceState.initial;
  MarketplaceState get state => _state;

  // Categories
  List<MarketplaceCategory> _categories = [];
  List<MarketplaceCategory> get categories => _categories;

  // Products for current lounge
  List<LoungeProduct> _products = [];
  List<LoungeProduct> get products => _products;

  // Filtered products by category
  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  List<LoungeProduct> get filteredProducts {
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      return _products;
    }
    return _products
        .where((product) => product.categoryId == _selectedCategoryId)
        .toList();
  }

  // Current lounge ID
  String? _currentLoungeId;
  String? get currentLoungeId => _currentLoungeId;

  // Error handling
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Loading states for individual operations
  bool _isCreating = false;
  bool get isCreating => _isCreating;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  /// Set the current lounge and load its products
  Future<void> setCurrentLounge(String loungeId) async {
    if (_currentLoungeId == loungeId && _products.isNotEmpty) {
      return; // Already loaded
    }
    _currentLoungeId = loungeId;
    await loadProducts(loungeId);
  }

  /// Load marketplace categories
  Future<void> loadCategories() async {
    try {
      AppLogger.info('Loading marketplace categories');
      _state = MarketplaceState.loading;
      _errorMessage = null;
      notifyListeners();

      _categories = _filterCategories(await _repository.getCategories());
      _state = MarketplaceState.loaded;
      AppLogger.info('Loaded ${_categories.length} categories');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading categories', e);
      _errorMessage = 'Failed to load categories: ${e.toString()}';
      _state = MarketplaceState.error;
      notifyListeners();
    }
  }

  /// Load products for a lounge
  Future<void> loadProducts(String loungeId) async {
    try {
      AppLogger.info('Loading products for lounge: $loungeId');
      _state = MarketplaceState.loading;
      _errorMessage = null;
      _currentLoungeId = loungeId;
      notifyListeners();

      _products = await _repository.getProductsByLoungeId(loungeId);
      _state = MarketplaceState.loaded;
      AppLogger.info('Loaded ${_products.length} products');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading products', e);
      _errorMessage = 'Failed to load products: ${e.toString()}';
      _state = MarketplaceState.error;
      notifyListeners();
    }
  }

  /// Load both categories and products
  Future<void> loadAll(String loungeId) async {
    try {
      _state = MarketplaceState.loading;
      _errorMessage = null;
      _currentLoungeId = loungeId;
      notifyListeners();

      // Load categories and products in parallel
      await Future.wait([
        _loadCategoriesInternal(),
        _loadProductsInternal(loungeId),
      ]);

      _state = MarketplaceState.loaded;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading marketplace data', e);
      _errorMessage = 'Failed to load marketplace data: ${e.toString()}';
      _state = MarketplaceState.error;
      notifyListeners();
    }
  }

  Future<void> _loadCategoriesInternal() async {
    _categories = _filterCategories(await _repository.getCategories());
  }

  List<MarketplaceCategory> _filterCategories(
    List<MarketplaceCategory> categories,
  ) {
    return categories.where((category) {
      final normalizedName = category.name.trim().toLowerCase();
      return !_excludedCategoryTerms.any(normalizedName.contains);
    }).toList();
  }

  Future<void> _loadProductsInternal(String loungeId) async {
    _products = await _repository.getProductsByLoungeId(loungeId);
  }

  /// Filter products by category
  void filterByCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Clear category filter
  void clearCategoryFilter() {
    _selectedCategoryId = null;
    notifyListeners();
  }

  /// Create a new product
  Future<LoungeProduct?> createProduct(LoungeProduct product) async {
    if (_currentLoungeId == null) {
      _errorMessage = 'No lounge selected';
      notifyListeners();
      return null;
    }

    try {
      AppLogger.info('Creating product: ${product.name}');
      _isCreating = true;
      _errorMessage = null;
      notifyListeners();

      final createdProduct = await _repository.createProduct(
        _currentLoungeId!,
        product,
      );

      _products.add(createdProduct);
      _isCreating = false;
      AppLogger.info('Product created successfully: ${createdProduct.id}');
      notifyListeners();
      return createdProduct;
    } catch (e) {
      AppLogger.error('Error creating product', e);
      _errorMessage = 'Failed to create product: ${e.toString()}';
      _isCreating = false;
      notifyListeners();
      return null;
    }
  }

  /// Update an existing product
  Future<LoungeProduct?> updateProduct(LoungeProduct product) async {
    if (_currentLoungeId == null) {
      _errorMessage = 'No lounge selected';
      notifyListeners();
      return null;
    }

    try {
      AppLogger.info('Updating product: ${product.id}');
      _isUpdating = true;
      _errorMessage = null;
      notifyListeners();

      final updatedProduct = await _repository.updateProduct(
        _currentLoungeId!,
        product,
      );

      // Update product in local list
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }

      _isUpdating = false;
      AppLogger.info('Product updated successfully');
      notifyListeners();
      return updatedProduct;
    } catch (e) {
      AppLogger.error('Error updating product', e);
      _errorMessage = 'Failed to update product: ${e.toString()}';
      _isUpdating = false;
      notifyListeners();
      return null;
    }
  }

  /// Delete a product
  Future<bool> deleteProduct(String productId) async {
    if (_currentLoungeId == null) {
      _errorMessage = 'No lounge selected';
      notifyListeners();
      return false;
    }

    try {
      AppLogger.info('Deleting product: $productId');
      _isDeleting = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.deleteProduct(_currentLoungeId!, productId);

      // Remove product from local list
      _products.removeWhere((p) => p.id == productId);

      _isDeleting = false;
      AppLogger.info('Product deleted successfully');
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting product', e);
      _errorMessage = 'Failed to delete product: ${e.toString()}';
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle product availability
  Future<bool> toggleProductAvailability(String productId) async {
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );

    final updatedProduct = product.copyWith(isAvailable: !product.isAvailable);
    final result = await updateProduct(updatedProduct);
    return result != null;
  }

  /// Get category name by ID
  String getCategoryName(String categoryId) {
    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => MarketplaceCategory(
        id: '',
        name: 'Unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return category.name;
  }

  /// Get product by ID
  LoungeProduct? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get products count by category
  Map<String, int> getProductsCountByCategory() {
    final countMap = <String, int>{};
    for (final product in _products) {
      countMap[product.categoryId] = (countMap[product.categoryId] ?? 0) + 1;
    }
    return countMap;
  }

  /// Refresh products
  Future<void> refreshProducts() async {
    if (_currentLoungeId != null) {
      await loadProducts(_currentLoungeId!);
    }
  }

  /// Clear all data
  void clear() {
    _state = MarketplaceState.initial;
    _categories = [];
    _products = [];
    _selectedCategoryId = null;
    _currentLoungeId = null;
    _errorMessage = null;
    _isCreating = false;
    _isUpdating = false;
    _isDeleting = false;
    notifyListeners();
  }
}
