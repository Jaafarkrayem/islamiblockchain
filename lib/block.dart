import 'transaction.dart';

class Block {
  final int index;
  final DateTime timestamp;
  final List<Transaction> transactions;
  final String previousHash;
  final String coin;
  late final String hash;

  Block({
    required this.index,
    required this.timestamp,
    required this.transactions,
    required this.previousHash,
    required this.coin,
    this.hash = '',
  });
}
