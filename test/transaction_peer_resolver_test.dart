import 'package:farm/utils/transaction_peer_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction peer resolver', () {
    test('extracts a username from nested profile data', () {
      final tx = {
        'sender': {
          'profile': {
            'username': 'alice_trader',
          },
        },
      };

      final resolved = resolveTransactionPeer(tx, outgoing: false);

      expect(resolved, 'alice_trader');
    });

    test('prefers direct recipient username fields over fallback values', () {
      final tx = {
        'recipient_user': {
          'user_name': 'recipient_alt',
        },
        'recipient_username': 'recipient_direct',
      };

      final resolved = resolveTransactionPeer(tx, outgoing: true);

      expect(resolved, 'recipient_direct');
    });

    test('extracts username from a nested list of sender maps', () {
      final tx = {
        'sender': [
          {'not_username': 'nope'},
          {'username': 'bob_the_sender'},
        ],
      };

      final resolved = resolveTransactionPeer(tx, outgoing: false);

      expect(resolved, 'bob_the_sender');
    });

    test('uses users_recipient for outgoing transactions', () {
      final tx = {
        'is_outgoing': true,
        'users_recipient': {'username': 'jane_recipient'},
        'users_sender': {'username': 'current_user'},
      };

      final resolved = resolveTransactionPeer(tx, outgoing: true);

      expect(resolved, 'jane_recipient');
    });

    test('uses users_sender for incoming transactions', () {
      final tx = {
        'is_outgoing': false,
        'users_sender': {'username': 'alex_sender'},
        'users_recipient': {'username': 'current_user'},
      };

      final resolved = resolveTransactionPeer(tx, outgoing: false);

      expect(resolved, 'alex_sender');
    });

    test('uses sender_user object when sender_username is missing', () {
      final tx = {
        'is_outgoing': false,
        'sender_user': {'username': 'sender_user_name'},
      };

      final resolved = resolveTransactionPeer(tx, outgoing: false);

      expect(resolved, 'sender_user_name');
    });

    test('uses recipient_user object when recipient_username is missing', () {
      final tx = {
        'is_outgoing': true,
        'recipient_user': {'username': 'recipient_user_name'},
      };

      final resolved = resolveTransactionPeer(tx, outgoing: true);

      expect(resolved, 'recipient_user_name');
    });

    test('uses backend wallet receiver user nested object', () {
      final tx = {
        'is_outgoing': true,
        'wallets_transactions_receiver_wallet_idTowallets': {
          'users': {
            'username': 'nested_receiver',
          },
        },
      };

      final resolved = resolveTransactionPeer(tx, outgoing: true);

      expect(resolved, 'nested_receiver');
    });

    test('uses backend wallet sender user nested object', () {
      final tx = {
        'is_outgoing': false,
        'wallets_transactions_sender_wallet_idTowallets': {
          'users': {
            'username': 'nested_sender',
          },
        },
      };

      final resolved = resolveTransactionPeer(tx, outgoing: false);

      expect(resolved, 'nested_sender');
    });

    test('falls back to first and last name when username is missing', () {
      final tx = {
        'recipient': {
          'first_name': 'Jane',
          'last_name': 'Doe',
        },
      };

      final resolved = resolveTransactionPeer(tx, outgoing: true);

      expect(resolved, 'Jane Doe');
    });
  });
}
