class DeleteAccountValidationResult {
  const DeleteAccountValidationResult({required this.isValid, this.error});

  final bool isValid;
  final String? error;
}

class DeleteAccountValidator {
  static DeleteAccountValidationResult validate({
    required String password,
    required bool acknowledged,
    required bool confirmDelete,
  }) {
    if (password.trim().isEmpty) {
      return const DeleteAccountValidationResult(
        isValid: false,
        error: 'Please enter your password to continue.',
      );
    }

    if (!acknowledged) {
      return const DeleteAccountValidationResult(
        isValid: false,
        error: 'Please confirm that you understand this action is permanent.',
      );
    }

    if (!confirmDelete) {
      return const DeleteAccountValidationResult(
        isValid: false,
        error: 'Please confirm that you want to delete your account permanently.',
      );
    }

    return const DeleteAccountValidationResult(isValid: true);
  }
}
