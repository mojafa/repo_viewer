// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:oauth2/oauth2.dart';
import 'package:oauth2/oauth2.dart';

import '../../core/shared/encoders.dart';
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
  final Dio _dio; 
  GithubAuthenticator(this._credentialsStorage, this._dio);

  static const clientId = '54f032abd2d30be84f7f';
  static const clientSecret = '3ea174a0c668cd4b66609f06f37cc44d10db7352';
  static const scopes = ['read:user', 'repo']; 

  static final authorizationEndpoint = Uri.parse('https://github.com/login/oauth/authorize');
  static final tokenEndpoint = Uri.parse('https://github.com/login/oauth/access_token');
 static final revocationEndpoint = Uri.parse('https://api.github.com/applications/$clientId/token');
  static final redirectUrl = Uri.parse('http://localhost:3000/callback');


Future<Credentials?> getSignedInCredentials() async{
  try{
      final storedCredentials = await _credentialsStorage.read();
 
  if (storedCredentials != null){
  if (storedCredentials.canRefresh && storedCredentials.isExpired){
    //TODO: refresh token
    final failureOrCredentials = await refresh(storedCredentials);
    return failureOrCredentials.fold((l) => null, (r) => r);

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

  Future<Either<AuthFailure, Unit>> signOut() async {
    final accessToken = await _credentialsStorage.read().then((credentials) =>  credentials?.accessToken);
    utf8.encode('$clientId:$clientSecret');

     final usernameAndPassword = stringToBase64.encode('$clientId:$clientSecret');

    try {
      try {
      _dio.deleteUri(
        revocationEndpoint,
        data: {
          'access_token': accessToken, 
          'client_id': clientId,
          'client_secret': clientSecret,
        },
        options: Options(
          headers: {
            'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
            'Accept': 'application/vnd.github.v3+json',
          },
        ), 
      ); 
      } on DioError catch (e) {
        if (e.isNoConnectionError) {
          // ignore: avoid_print
          // print('Token not revoked');
        } else {
          rethrow;
        } 
      }
      await _credentialsStorage.clear();
      return right(unit);
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  } 

Future<Either<AuthFailure, Credentials>> refresh(
  Credentials credentials,
  ) async {
    final refreshedCredentials = await credentials.refresh(
      identifier: clientId, 
      secret: clientSecret,
      httpClient: GithubOAuthHttpClient(),
    );
    await _credentialsStorage.save(refreshedCredentials);
    return right(refreshedCredentials);
  } on FormatException {
      return left( AuthFailure.server());
    } on AuthorizationException catch (e){
      return left(AuthFailure.server('${e.error}: ${e.description}'));
    } on PlatformException{
      return left( AuthFailure.storage());
    }



  //exceptions can be recovered from, errors cannot be recoevered from
}
