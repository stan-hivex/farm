Map<String, dynamic> attachTurnstileToken(
  Map<String, dynamic> body, {
  String? turnstileToken,
}) {
  if (turnstileToken == null || turnstileToken.trim().isEmpty) {
    return body;
  }

  final normalizedToken = turnstileToken.trim();

  final payload = <String, dynamic>{...body};
  payload['cf_turnstile_response'] = normalizedToken;
  payload['turnstile_token'] = normalizedToken;
  return payload;
}
