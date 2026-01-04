import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTransactions();
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

  String _getTransactionType(String type) {
    switch (type.toUpperCase()) {
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
                          final txn = _transactions[index];
                          final type = txn['transaction_type'] ?? '';
                          final amount = txn['transaction_amount']?.toDouble() ?? 0;
                          final isDebit = type == 'TR' || type == 'WD';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getTransactionColor(type).withOpacity(0.2),
                                child: Icon(
                                  _getTransactionIcon(type),
                                  color: _getTransactionColor(type),
                                ),
                              ),
                              title: Text(
                                txn['description'] ?? _getTransactionType(type),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(txn['transaction_date'] ?? txn['created_at'] ?? ''),
                                  if (txn['from_account_number'] != null)
                                    Text('From: ${txn['from_account_number']}'),
                                  if (txn['to_account_number'] != null)
                                    Text('To: ${txn['to_account_number']}'),
                                ],
                              ),
                              trailing: Text(
                                '${isDebit ? '-' : '+'} ${_formatCurrency(amount)}',
                                style: TextStyle(
                                  color: _getTransactionColor(type),
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
