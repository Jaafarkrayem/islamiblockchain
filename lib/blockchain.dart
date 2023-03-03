import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'validator.dart';
import 'block.dart';
import 'transaction.dart';
import 'wallet.dart';

class Blockchain {
  static const String coinName = 'ISLAMICOIN';
  static const int maxSupply = 10000000000; // 10 billion
  static const int decimals = 7;

  final List<Block> _chain = [genesisBlock];
  final List<Transaction> _pendingTransactions = [];
  final List<Validator> _validators = [];
  final List<Wallet> _wallets = [];

  final String _coin = 'ISLAMI';

  Block? get latestBlock => _chain.isNotEmpty ? _chain.last : null;

  void addTransaction(Transaction transaction) {
    _pendingTransactions.add(transaction);
  }

  List<Transaction> getPendingTransactions() {
    return List<Transaction>.from(_pendingTransactions);
  }

  Wallet findByPublicKey(String publicKey) {
    return _wallets.firstWhere((w) => w.publicKey == publicKey,
        orElse: () => throw Exception('Wallet not found'));
  }

  bool validateStake(String validatorAddress, double amount) {
    Validator? validator;
    for (final v in _validators) {
      if (v.address == validatorAddress) {
        validator = v;
        break;
      }
    }
    if (validator == null) {
      return false;
    }
    if (validator.isActive && validator.stake >= amount) {
      return true;
    }
    return false;
  }

  bool validateCoins(String address, double amount) {
    final balance = getBalance(address);
    if (balance >= amount) {
      return true;
    }
    return false;
  }

  double getBalance(String address) {
    double balance = 0;
    for (final block in _chain) {
      for (final tx in block.transactions) {
        if (tx.sender == address) {
          balance -= tx.amount;
        }
        if (tx.receiver == address) {
          balance += tx.amount;
        }
      }
    }
    return balance;
  }

  List<Validator> getActiveValidators() {
    final activeValidators = _validators.where((v) => v.isActive).toList();
    final stakes = activeValidators.map((v) => v.stake);
    final totalStake = stakes.fold<double>(0, (a, b) => a + b);
    for (final validator in activeValidators) {
      validator.updateScore(totalStake);
    }
    activeValidators.sort((a, b) => b.score.compareTo(a.score));
    return activeValidators;
  }

  void addValidator(Validator validator) {
    _validators.add(validator);
  }

  void stake(String validatorAddress, double amount) {
    Validator? validator;
    for (final v in _validators) {
      if (v.address == validatorAddress) {
        validator = v;
        break;
      }
    }
    if (validator == null) {
      final newValidator = Validator(
        address: validatorAddress,
        stake: amount,
        isActive: true,
      );
      _validators.add(newValidator);
    } else {
      final currentStake = validator.stake;
      if (currentStake + amount > getBalance(validatorAddress)) {
        throw Exception('Validator cannot stake more than they currently have');
      }
      validator.stake += amount;
    }
  }

  void unstake(String validatorAddress) {
    Validator? validator;
    for (final v in _validators) {
      if (v.address == validatorAddress) {
        validator = v;
        break;
      }
    }
    if (validator == null) {
      return;
    }
    if (validator.stake == 0) {
      _validators.remove(validator);
    } else {
      validator.isActive = false;
    }
  }

  void mine(String minerAddress) {
    if (_pendingTransactions.isEmpty) {
      return;
    }

    _updateValidators();
    final validator = _validators.isNotEmpty ? _validators.first : null;
    if (validator == null) {
      return;
    }

    final reward = _pendingTransactions.length * 0.1;
    final rewardTx = Transaction(
      sender: '',
      receiver: validator.address,
      amount: reward,
      coin: _coin,
    );
    _pendingTransactions.add(rewardTx);

    final previousHash = latestBlock!.hash;
    final timestamp = DateTime.now();
    final transactions = List<Transaction>.from(_pendingTransactions);
    final index = latestBlock!.index + 1;
    final block = Block(
      index: index,
      timestamp: timestamp,
      transactions: transactions,
      previousHash: previousHash,
      coin: _coin,
    );
    block.hash = _calculateHash(block);

    _chain.add(block);
    _pendingTransactions.clear();

    for (final tx in transactions) {
      if (tx.sender == '') {
        continue;
      }

      final senderWallet = findByPublicKey(tx.sender);
      senderWallet.sendCoins(tx.receiver, tx.amount);
    }
  }

  void _updateValidators() {
    final activeValidators = getActiveValidators();
    final stakes = activeValidators.map((v) => v.stake);
    final totalStake = stakes.fold<double>(0, (a, b) => a + b);

    for (final validator in activeValidators) {
      final stakePercent = validator.stake / totalStake;
      final probability = stakePercent * 100;
      final random = Random().nextInt(100);
      validator.isActive = random <= probability;
    }
  }

  String _calculateHash(Block block) {
    final encoded = jsonEncode(block);
    return sha256.convert(encoded.codeUnits).toString();
  }

  static Block get genesisBlock => Block(
        index: 0,
        timestamp: DateTime.now(),
        transactions: [],
        previousHash: '0',
        coin: '',
        hash: '',
      );
}
