// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:oauth2/oauth2.dart';

import 'credentials_storage.dart';

class SecureCredentialsStorage implements CredentialsStorage {
 final  FlutterSecureStorage _storage;
  SecureCredentialsStorage(
    this._storage,
  );

  @override
  Future read() {
    // TODO: implement read
    throw UnimplementedError();
  }

  @override
  Future<void> save(Credentials credentials) {
    // TODO: implement save
    throw UnimplementedError();
  }

  @override
  Future<void> clear() {
    // TODO: implement clear
    throw UnimplementedError();
  }



}
