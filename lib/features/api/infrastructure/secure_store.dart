import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/repository.dart';

class DeviceSecretStore implements SecretStore {
  const DeviceSecretStore();
  // The macOS debug runner is ad-hoc signed and cannot use the data
  // protection keychain (SecItem* returns -34018 without that entitlement).
  // The regular login keychain remains protected and release signing can opt
  // into data protection later without changing the storage contract.
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SecureAuthStorage extends LocalStorage {
  const SecureAuthStorage(this.store, this.key);
  final SecretStore store;
  final String key;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => await store.read(key) != null;
  @override
  Future<String?> accessToken() => store.read(key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      store.write(key, persistSessionString);
  @override
  Future<void> removePersistedSession() => store.delete(key);
}

class SecurePkceStorage extends GotrueAsyncStorage {
  const SecurePkceStorage(this.store, this.scope);
  final SecretStore store;
  final String scope;
  @override
  Future<String?> getItem({required String key}) =>
      store.read('$scope.pkce.$key');
  @override
  Future<void> setItem({required String key, required String value}) =>
      store.write('$scope.pkce.$key', value);
  @override
  Future<void> removeItem({required String key}) =>
      store.delete('$scope.pkce.$key');
}
