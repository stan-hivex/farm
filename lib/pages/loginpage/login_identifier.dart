String normalizeLoginIdentifier(String? input) {
  final trimmed = input?.trim() ?? '';
  return trimmed.replaceAll(RegExp(r'\s+'), '');
}

bool looksLikeEmail(String? input) {
  final normalized = normalizeLoginIdentifier(input);
  return normalized.contains('@');
}
