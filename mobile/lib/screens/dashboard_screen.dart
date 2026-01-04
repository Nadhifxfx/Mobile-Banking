import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'transfer_screen.dart';
import 'history_screen.dart';
import 'withdraw_screen.dart';
import 'deposit_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  double _totalBalance = 0;
  List<dynamic> _accounts = [];
  List<dynamic> _recentTransactions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load balance and accounts
      final balanceData = await _apiService.getBalance();
      final transactions = await _apiService.getTransactions();

      setState(() {
        _totalBalance = balanceData['total_balance']?.toDouble() ?? 0;
        _accounts = balanceData['accounts'] ?? [];
        _recentTransactions = transactions.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _getTransactionIcon(String type) {
    switch (type.toUpperCase()) {
      case 'TR':
        return '↑';
      case 'WD':
        return '↓';
      case 'DP':
        return '↓';
      default:
        return '•';
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
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
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
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance Card
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Balance',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatCurrency(_totalBalance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_accounts.isNotEmpty)
                                Text(
                                  'Account: ${_accounts[0]['account_number']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Quick Actions
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickAction(
                                Icons.send,
                                'Transfer',
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TransferScreen(
                                        accounts: _accounts,
                                        onSuccess: _loadData,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildQuickAction(
                                Icons.account_balance_wallet,
                                'Withdraw',
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WithdrawScreen(
                                        accounts: _accounts,
                                        onSuccess: _loadData,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildQuickAction(
                                Icons.add_circle,
                                'Deposit',
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DepositScreen(
                                        accounts: _accounts,
                                        onSuccess: _loadData,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildQuickAction(
                                Icons.history,
                                'History',
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Recent Transactions
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Transactions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HistoryScreen(),
                                    ),
                                  );
                                },
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                        ),

                        // Transaction List
                        if (_recentTransactions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('No transactions yet'),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentTransactions.length,
                            itemBuilder: (context, index) {
                              final txn = _recentTransactions[index];
                              final type = txn['transaction_type'] ?? '';
                              final amount = txn['transaction_amount']?.toDouble() ?? 0;
                              final isDebit = type == 'TR' || type == 'WD';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getTransactionColor(type).withOpacity(0.2),
                                  child: Text(
                                    _getTransactionIcon(type),
                                    style: TextStyle(
                                      color: _getTransactionColor(type),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(txn['description'] ?? 'Transaction'),
                                subtitle: Text(txn['transaction_date'] ?? txn['created_at'] ?? ''),
                                trailing: Text(
                                  '${isDebit ? '-' : '+'} ${_formatCurrency(amount)}',
                                  style: TextStyle(
                                    color: _getTransactionColor(type),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
