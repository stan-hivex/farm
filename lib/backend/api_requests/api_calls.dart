import 'dart:convert';

import '/core/app_config.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

class RegisterCall {
  static Future<ApiCallResponse> call({
    String? firstName = '',
    String? lastName = '',
    String? username = '',
    String? phone = '',
    String? email = '',
    String? password = '',
    String? country = 'Kenya',
  }) async {
    final body = jsonEncode({
      "first_name": firstName,
      "last_name": lastName,
      "username": username,
      "phone": phone,
      "email": email,
      "password": password,
      "country": country,
    });

    return ApiManager.instance.makeApiCall(
      callName: 'register',
      apiUrl: '${AppConfig.api}/auth/register',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
      },
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      cache: false,
    );
  }
}

class LoginCall {
  static Future<ApiCallResponse> call({
    String? identifier = '',
    String? password = '',
  }) async {
    final body = jsonEncode({
      "identifier": identifier,
      "password": password,
    });

    return ApiManager.instance.makeApiCall(
      callName: 'login',
      apiUrl: '${AppConfig.api}/auth/login',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
      },
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      cache: false,
    );
  }
}


class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
