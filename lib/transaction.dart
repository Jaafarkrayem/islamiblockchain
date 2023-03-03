import 'dart:convert';
import 'package:crypto/crypto.dart';

class Transaction {
  final String sender;
  final String receiver;
  final double amount;
  final String coin;
  String signature;

  Transaction({
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.coin,
  }) : signature = '';

  String calculateHash() {
    final data = '$sender$receiver$amount$coin';
    return sha256.convert(utf8.encode(data)).toString();
  }

  void sign(String privateKey) {
    signature = sha256.convert(utf8.encode(privateKey)).toString();
  }

  bool isValid() {
    final expectedHash = calculateHash();
    final actualHash = sha256
        .convert(utf8.encode('$sender$receiver$amount$coin$signature'))
        .toString();
    return expectedHash == actualHash;
  }
}
