// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:oauth2/oauth2.dart';

import '../domain/auth_failure.dart';
import 'credentials_storage/credentials_storage.dart';

// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http; 

class GithubOAuthHttpClient extends http.BaseClient{
  final httpClient = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return httpClient.send(request);
  }
}
class GithubAuthenticator {
  final CredentialsStorage _credentialsStorage;
  GithubAuthenticator(this._credentialsStorage);

  static const clientId = '54f032abd2d30be84f7f';
  static const clientSecret = '3ea174a0c668cd4b66609f06f37cc44d10db7352';
  static const scopes = ['read:user', 'repo']; 

  static final authorizationEndpoint = Uri.parse('https://github.com/login/oauth/authorize');
  static final tokenEndpoint = Uri.parse('https://github.com/login/oauth/access_token');
  static final redirectUrl = Uri.parse('http://localhost:3000/callback');


Future<Credentials?> getSignedInCredentials() async{
  try{
      final storedCredentials = await _credentialsStorage.read();
 
  if (storedCredentials != null){
  if (storedCredentials.canRefresh && storedCredentials.isExpired){
    //TODO: refresh token
   }
  }
   return storedCredentials;
} on PlatformException{
    return null;
  }
}


Future<bool> isSignedIn() => getSignedInCredentials().then((credentials) => credentials != null);  

AuthorizationCodeGrant createGrant(){
  return AuthorizationCodeGrant(
    clientId, 
    authorizationEndpoint, 
    tokenEndpoint, 
    secret: clientSecret,
    httpClient: GithubOAuthHttpClient(),
  );
}
  

Uri getAuthorizationUrl(AuthorizationCodeGrant grant){
  return grant.getAuthorizationUrl(redirectUrl, scopes: scopes); 
}

Future<Either<AuthFailure, Unit>> handleAuthorizationResponse(
  AuthorizationCodeGrant grant, 
  Map<String, String> queryParams,
  ) async{
    try{
    final httpClient = await grant.handleAuthorizationResponse(queryParams);
    await _credentialsStorage.save(httpClient.credentials);
    return right(unit);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e){
      return left(AuthFailure.server('${e.error}: ${e.description}'));
    } on PlatformException{
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Unit>> signOut

}