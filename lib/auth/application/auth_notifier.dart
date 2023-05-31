import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:repo_viewer/auth/infrastructure/github_authenticator.dart';

import '../domain/auth_failure.dart';

@freezed
class AuthState with _$AuthState {
  const AuthState._();
  const factory AuthState.initial() = _Initial;
  const factory AuthState.authenticated() = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.failure(AuthFailure failure) = _Failure;
}



typedef AuthUriCallback = Future<Uri> Function(Uri authorizationUrl);

class AuthNotifier extends StateNotifier<AuthState>{
  final GithubAuthenticator _authenticator;
  AuthNotifier(this._authenticator) : super(const AuthState.initial());

  Future<void> checkAndUpdateAuthStatus() async{
    state = (await _authenticator.isSignedIn())
    ? const AuthState.authenticated()
    : const AuthState.unauthenticated();
  }


  Future<void> signIn(AuthUriCallback authorizarionCallback) async{
    final grant = _authenticator.createGrant();
    final redirectUrl = await authorizarionCallback(_authenticator.getAuthorizationUrl(grant));
   final failureOrSuccess = await  _authenticator.handleAuthorizationResponse(grant, redirectUrl.queryParameters);
    state =  failureOrSuccess.fold(
      (l) => AuthState.failure(l),
     (r) => const AuthState.authenticated(),
     );
     grant.close();
  }


  Future<void> signOut() async{
    final failureOrSuccess =  await _authenticator.signOut();
       state =  failureOrSuccess.fold(
      (l) => AuthState.failure(l),
     (r) => const AuthState.unauthenticated(),
     );
  }
}