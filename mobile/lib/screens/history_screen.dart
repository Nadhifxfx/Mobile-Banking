import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _apiService = ApiService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _txnSub;
  final Map<String, String> _nicknameByAccount = {};

  @override
  void initState() {
    super.initState();
    _loadNicknames();
    _loadTransactions();

    // Realtime updates
    RealtimeService.instance.connect();
    _txnSub = RealtimeService.instance.transactionStream.listen((event) {
      if (!mounted) return;
      setState(() {
        _transactions.insert(0, event);
      });
    });
  }

  Future<void> _loadNicknames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('saved_contacts');
      if (contactsJson == null) return;

      final decoded = jsonDecode(contactsJson);
      if (decoded is! List) return;

      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final account = map['account']?.toString();
        final name = map['name']?.toString();
        if (account == null || account.isEmpty) continue;
        if (name == null || name.isEmpty) continue;
        _nicknameByAccount.putIfAbsent(account, () => name);
      }
    } catch (_) {
      // ignore
    }
  }

  String? _nicknameForAccount(dynamic account) {
    final key = account?.toString();
    if (key == null || key.isEmpty) return null;
    return _nicknameByAccount[key];
  }

  String _transferTitle(Map<String, dynamic> txn, dynamic toAccount) {
    final enriched = (txn['to_name'] ?? txn['counterparty_name'] ?? txn['name'])?.toString();
    if (enriched != null && enriched.isNotEmpty) {
      return 'Transfer ke $enriched';
    }

    final desc = (txn['description'] ?? '').toString();
    final destAccount = toAccount?.toString();

    // If description already contains a destination, try to replace numeric account with nickname.
    if (desc.toLowerCase().startsWith('transfer ke ')) {
      final tail = desc.substring('transfer ke '.length).trim();
      if (RegExp(r'^\d+$').hasMatch(tail)) {
        final nickname = _nicknameForAccount(tail);
        if (nickname != null) return 'Transfer ke $nickname';
      }
      return desc;
    }

    final nickname = _nicknameForAccount(destAccount);
    if (nickname != null) return 'Transfer ke $nickname';
    if (destAccount != null && destAccount.isNotEmpty) return 'Transfer ke $destAccount';
    return 'Transfer';
  }

  @override
  void dispose() {
    _txnSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions = await _apiService.getTransactions();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _normalizeTypeCode(Map<String, dynamic> txn) {
    final raw = (txn['transaction_type'] ?? txn['type'] ?? '').toString();
    final upper = raw.toUpperCase();
    if (upper == 'TR' || upper == 'WD' || upper == 'DP') return upper;
    if (upper == 'TRANSFER') return 'TR';
    if (upper == 'WITHDRAWAL' || upper == 'TARIK TUNAI') return 'WD';
    if (upper == 'DEPOSIT' || upper == 'SETOR TUNAI') return 'DP';
    return '';
  }

  String _getTransactionType(String typeCode) {
    switch (typeCode.toUpperCase()) {
      case 'TR':
        return 'Transfer';
      case 'WD':
        return 'Withdrawal';
      case 'DP':
        return 'Deposit';
      default:
        return 'Transaction';
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toUpperCase()) {
      case 'TR':
        return Icons.send;
      case 'WD':
        return Icons.arrow_downward;
      case 'DP':
        return Icons.arrow_upward;
      default:
        return Icons.payment;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type.toUpperCase()) {
      case 'TR':
      case 'WD':
        return Colors.red;
      case 'DP':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _transactions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No transactions yet'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      child: ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final txn = Map<String, dynamic>.from(_transactions[index] as Map);
                          final typeCode = _normalizeTypeCode(txn);
                            final rawAmount = txn['transaction_amount'] ?? txn['amount'] ?? 0;
                            final amount = rawAmount is num
                              ? rawAmount.toDouble()
                              : (double.tryParse(rawAmount.toString()) ?? 0);
                          final isDebit = typeCode == 'TR' || typeCode == 'WD';

                          final dateText = (txn['transaction_date'] ??
                              txn['date'] ??
                              txn['created_at'] ??
                              '')
                            .toString();
                          final fromAccount = txn['from_account_number'] ?? txn['from_account'];
                          final toAccount = txn['to_account_number'] ?? txn['to_account'];

                            final title = typeCode == 'TR'
                              ? _transferTitle(txn, toAccount)
                              : typeCode == 'WD'
                                ? 'Tarik Tunai'
                                : typeCode == 'DP'
                                  ? 'Setor Tunai'
                                  : (txn['description']?.toString() ?? _getTransactionType(typeCode));

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getTransactionColor(typeCode).withOpacity(0.2),
                                child: Icon(
                                  _getTransactionIcon(typeCode),
                                  color: _getTransactionColor(typeCode),
                                ),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(dateText),
                                  if (fromAccount != null) Text('From: $fromAccount'),
                                  if (toAccount != null) Text('To: $toAccount'),
                                ],
                              ),
                              trailing: Text(
                                '${isDebit ? '-' : '+'} ${_formatCurrency(amount)}',
                                style: TextStyle(
                                  color: _getTransactionColor(typeCode),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
