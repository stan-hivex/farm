enum DepositLifecycleStatus { pending, completed, failed }

DepositLifecycleStatus parseDepositLifecycleStatus(Object? value) {
  final status = (value ?? '').toString().trim().toLowerCase();

  if (status == 'completed' || status == 'success' || status == 'paid') {
    return DepositLifecycleStatus.completed;
  }

  if (status == 'failed' || status == 'cancelled' || status == 'error' || status == 'declined') {
    return DepositLifecycleStatus.failed;
  }

  return DepositLifecycleStatus.pending;
}

String depositStatusLabel(Object? value) {
  switch (parseDepositLifecycleStatus(value)) {
    case DepositLifecycleStatus.completed:
      return 'completed';
    case DepositLifecycleStatus.failed:
      return 'failed';
    case DepositLifecycleStatus.pending:
      return 'pending';
  }
}
