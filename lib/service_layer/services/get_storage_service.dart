import 'package:get_storage/get_storage.dart';

class GetStorageService {
  static final GetStorageService _instance = GetStorageService._internal();
  factory GetStorageService() => _instance;
  GetStorageService._internal();

  final GetStorage _box = GetStorage();

  Future<void> init() async {
    await GetStorage.init();
  }

  Future<void> write(String key, dynamic value) async {
    await _box.write(key, value);
  }

  T? read<T>(String key) {
    return _box.read<T>(key);
  }

  Future<void> remove(String key) async {
    await _box.remove(key);
  }
}
