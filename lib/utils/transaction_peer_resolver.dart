String extractTransactionUsername(dynamic value) {
  if (value == null) return '';
  if (value is String) {
    final normalized = value.trim();
    return normalized;
  }

  if (value is List) {
    for (final item in value) {
      final username = extractTransactionUsername(item);
      if (username.isNotEmpty) return username;
    }
    return '';
  }

  if (value is Map) {
    final username = value['username']?.toString().trim() ?? '';
    if (username.isNotEmpty) return username;

    final alternateUsername = value['user_name']?.toString().trim() ?? '';
    if (alternateUsername.isNotEmpty) return alternateUsername;

    final accountName = value['account_name']?.toString().trim() ?? '';
    if (accountName.isNotEmpty) return accountName;

    final screenName = value['screen_name']?.toString().trim() ?? '';
    if (screenName.isNotEmpty) return screenName;

    final handle = value['handle']?.toString().trim() ?? '';
    if (handle.isNotEmpty) return handle;

    final name = value['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;

    final firstName = value['first_name']?.toString().trim() ?? '';
    final lastName = value['last_name']?.toString().trim() ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return [firstName, lastName].where((part) => part.isNotEmpty).join(' ');
    }

    for (final candidateKey in [
      'user',
      'profile',
      'data',
      'details',
      'account',
      'customer',
      'person',
      'user_data',
      'user_info',
      'customer_profile',
      'sender',
      'recipient',
      'to',
      'from',
      'counterparty',
      'metadata',
      'attributes',
      'info',
      'wallet',
      'wallets',
      'user_profile',
      'owners',
      'participant',
      'participants',
      'peer',
      'counterparty_user',
    ]) {
      final nestedValue = value[candidateKey];
      if (nestedValue != null) {
        final nestedUsername = extractTransactionUsername(nestedValue);
        if (nestedUsername.isNotEmpty) return nestedUsername;
      }
    }

    for (final fieldValue in value.values) {
      if (fieldValue is Map || fieldValue is List) {
        final nestedUsername = extractTransactionUsername(fieldValue);
        if (nestedUsername.isNotEmpty) return nestedUsername;
      }
    }
  }

  return '';
}

String resolveTransactionPeer(dynamic tx, {required bool outgoing}) {
  String safeString(dynamic value) => value?.toString().trim() ?? '';

  final recipientUsername = safeString(tx['recipient_username']);
  final senderUsername = safeString(tx['sender_username']);
  final alternateUsername = outgoing
      ? safeString(tx['to_username'])
      : safeString(tx['from_username']);
  final directIdentifier = outgoing
      ? safeString(tx['recipient_identifier'])
      : safeString(tx['sender_identifier']);

  if (outgoing) {
    if (recipientUsername.isNotEmpty) return recipientUsername;
    if (alternateUsername.isNotEmpty) return alternateUsername;
    if (directIdentifier.isNotEmpty) return directIdentifier;

    final recipientUser = extractTransactionUsername(tx['recipient_user']);
    if (recipientUser.isNotEmpty) return recipientUser;

    final usersRecipient = extractTransactionUsername(tx['users_recipient']);
    if (usersRecipient.isNotEmpty) return usersRecipient;

    final receiverWalletUser = extractTransactionUsername(
      tx['wallets_transactions_receiver_wallet_idTowallets']?['users'],
    );
    if (receiverWalletUser.isNotEmpty) return receiverWalletUser;

    final receiverWalletNested = extractTransactionUsername(
      tx['wallets_transactions_receiver_wallet_idTowallets'],
    );
    if (receiverWalletNested.isNotEmpty) return receiverWalletNested;

    final fallbackValues = [
      tx['recipient'],
      tx['recipient_details'],
      tx['recipient_info'],
      tx['target_user'],
      tx['counterparty'],
      tx['to_user'],
      tx['to'],
      tx['users_sender'],
    ];

    for (final candidate in fallbackValues) {
      final username = extractTransactionUsername(candidate);
      if (username.isNotEmpty) return username;
    }
  } else {
    if (senderUsername.isNotEmpty) return senderUsername;
    if (alternateUsername.isNotEmpty) return alternateUsername;
    if (directIdentifier.isNotEmpty) return directIdentifier;

    final senderUser = extractTransactionUsername(tx['sender_user']);
    if (senderUser.isNotEmpty) return senderUser;

    final usersSender = extractTransactionUsername(tx['users_sender']);
    if (usersSender.isNotEmpty) return usersSender;

    final senderWalletUser = extractTransactionUsername(
      tx['wallets_transactions_sender_wallet_idTowallets']?['users'],
    );
    if (senderWalletUser.isNotEmpty) return senderWalletUser;

    final senderWalletNested = extractTransactionUsername(
      tx['wallets_transactions_sender_wallet_idTowallets'],
    );
    if (senderWalletNested.isNotEmpty) return senderWalletNested;

    final fallbackValues = [
      tx['sender'],
      tx['sender_details'],
      tx['sender_info'],
      tx['source_user'],
      tx['counterparty'],
      tx['from_user'],
      tx['from'],
      tx['users_recipient'],
    ];

    for (final candidate in fallbackValues) {
      final username = extractTransactionUsername(candidate);
      if (username.isNotEmpty) return username;
    }
  }

  return 'unknown user';
}
