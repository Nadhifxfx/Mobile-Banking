import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
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
                                txn['description']?.toString() ?? _getTransactionType(typeCode),
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
