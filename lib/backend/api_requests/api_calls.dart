// Removed unused imports flagged by analyzer
import '/backend/services/api_service.dart';
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
    final resp = await ApiService.register(
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      username: username ?? '',
      phone: phone ?? '',
      password: password ?? '',
      email: email,
      country: country,
    );

    return ApiCallResponse.fromCloudCallResponse({
      'body': resp,
      'headers': {},
      'statusCode': 200,
    });
  }
}

class LoginCall {
  static Future<ApiCallResponse> call({
    String? identifier = '',
    String? password = '',
  }) async {
    final resp = await ApiService.login(
      identifier: identifier ?? '',
      password: password ?? '',
    );

    return ApiCallResponse.fromCloudCallResponse({
      'body': resp,
      'headers': {},
      'statusCode': 200,
    });
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
