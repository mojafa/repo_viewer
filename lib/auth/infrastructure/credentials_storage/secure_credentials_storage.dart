// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:oauth2/oauth2.dart';

import 'credentials_storage.dart';

class SecureCredentialsStorage implements CredentialsStorage {
 final  FlutterSecureStorage _storage;
  SecureCredentialsStorage(
    this._storage,
  );

  static const _key = 'oauth2_credentails';

Credentials?  _cachedCredentials;
  @override
  Future read() async {
  if (_cachedCredentials != null) {
      return _cachedCredentials;
    }
    final json = await _storage.read(key: _key);
      if (json == null) {
        return null;
      }
      try{
        return _cachedCredentials = Credentials.fromJson(json);
      } on FormatException{
       // await _storage.delete(key: _key);
        return null;
      }
    }
  

  @override
  Future<void> save(Credentials credentials) {
    _cachedCredentials = credentials;
    return _storage.write(
      key: _key,
      value: credentials.toJson(),
    );
  }

  @override
  Future<void> clear() {
    _cachedCredentials = null;
    return _storage.delete(key: _key);
  }



}
