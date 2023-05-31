
import 'package:dio/dio.dart';
import 'package:repo_viewer/auth/infrastructure/credentials_storage/credentials_storage.dart';
import 'package:repo_viewer/auth/infrastructure/github_authenticator.dart';
import 'package:riverpod/riverpod.dart';

import '../application/auth_notifier.dart';
final flutterSecureStorageProvider = Provider((ref) => FlutterSecureStorage());
final CredentialsStorageProvider = Provider<CredentialsStorage>((ref) => SecureCredentialStorage(ref.watch(flutterSecureStorageProvider)));

final dioProvider = Provider((ref) => Dio());

final githubAuthenticatorProvider = Provider((ref) => GithubAuthenticator(ref.watch(CredentialsStorageProvider), ref.watch(dioProvider)));

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref.watch(githubAuthenticatorProvider)));
