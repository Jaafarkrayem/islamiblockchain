import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:bip39/bip39.dart' as bip39;

import 'transaction.dart';
import 'blockchain.dart';

class Wallet {
  String? _privateKey;
  String? _publicKey;
  double _balance = 0;

//final wallet = Wallet(blockchain);
  //final List<Wallet> _wallets;
  final Blockchain blockchain;

  Wallet(this.blockchain) {
    // generate a random private key when a new wallet is created
    _privateKey = _generatePrivateKey();
    _publicKey = _derivePublicKey(_privateKey!);
  }

  String? get privateKey => _privateKey;
  String? get publicKey => _publicKey;
  double get balance => _balance;

  void sendCoins(String receiverAddress, double amount) {
    if (amount > _balance) {
      throw Exception('Insufficient funds');
    }

    final tx = Transaction(
      sender: _publicKey!,
      receiver: receiverAddress,
      amount: amount,
      coin: 'ISLAMI',
    );

    // sign the transaction with the private key
    final signature = _signTransaction(tx);

    // add the signature to the transaction
    tx.signature = signature;

    // add the transaction to the pending transactions list
    // to be included in the next block
    Blockchain().getPendingTransactions().add(tx);
  }

  void receiveCoins(Transaction transaction) {
    if (transaction.receiver != _publicKey) {
      throw Exception('Invalid transaction');
    }

    // add the amount received to the balance
    _balance += transaction.amount;

    // update the blockchain with the new transaction
    blockchain.addTransaction(transaction);
  }

  static String _generatePrivateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _derivePublicKey(String privateKey) {
    final bytes = utf8.encode(privateKey);
    final digest = sha256.convert(bytes);
    return 'ISLAMI${digest.toString().substring(0, 24)}';
  }

  String _signTransaction(Transaction transaction) {
    final message =
        '${transaction.sender}:${transaction.receiver}:${transaction.amount}';
    final bytes = utf8.encode(message);
    final digest = sha256.convert(bytes);
    return 'SIG:${digest.toString()}';
  }

  static String generateMnemonic() {
    return bip39.generateMnemonic();
  }
}
