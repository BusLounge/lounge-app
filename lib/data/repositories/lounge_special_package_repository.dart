import '../../domain/entities/lounge_special_package.dart';
import '../datasources/lounge_special_package_remote_datasource.dart';
import '../models/lounge_special_package_model.dart';

/// Repository for lounge special packages
class LoungeSpecialPackageRepository {
  final LoungeSpecialPackageRemoteDataSource _dataSource;

  LoungeSpecialPackageRepository({
    required LoungeSpecialPackageRemoteDataSource dataSource,
  }) : _dataSource = dataSource;

  Future<List<LoungeSpecialPackage>> getSpecialPackages(
      String loungeId) async {
    final models = await _dataSource.getSpecialPackages(loungeId);
    return models;
  }

  Future<LoungeSpecialPackage> createSpecialPackage(
    String loungeId,
    LoungeSpecialPackageModel pkg,
  ) async {
    return _dataSource.createSpecialPackage(loungeId, pkg.toCreateJson());
  }

  Future<LoungeSpecialPackage> updateSpecialPackage(
    String loungeId,
    String packageId,
    LoungeSpecialPackageModel pkg,
  ) async {
    return _dataSource.updateSpecialPackage(loungeId, packageId, pkg.toUpdateJson());
  }

  Future<void> deleteSpecialPackage(
      String loungeId, String packageId) async {
    return _dataSource.deleteSpecialPackage(loungeId, packageId);
  }
}
