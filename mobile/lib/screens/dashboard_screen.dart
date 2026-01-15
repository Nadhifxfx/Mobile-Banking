import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../services/api_service.dart';
import '../services/realtime_service.dart';
import '../utils/constants.dart';
import 'transfer_screen.dart';
import 'withdraw_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  StreamSubscription<Map<String, dynamic>>? _txnSub;
  bool _isLoading = true;
  double _totalBalance = 0;
  List<dynamic> _accounts = [];
  String? _error;
  Map<String, dynamic>? _userData;
  String _userName = '';
  String _cifNumber = '';
  int _currentIndex = 0;
  List<Map<String, String>> _savedContacts = [];
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadData();
    _loadSavedData();

    // Realtime updates for "Transaksi Terbaru"
    RealtimeService.instance.connect();
    _txnSub = RealtimeService.instance.transactionStream.listen(_handleRealtimeTransaction);
  }

  @override
  void dispose() {
    _txnSub?.cancel();
    super.dispose();
  }

  Future<void> _handleRealtimeTransaction(Map<String, dynamic> txn) async {
    if (!mounted) return;

    final rawAmount = txn['amount'] ?? txn['transaction_amount'] ?? 0;
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : (double.tryParse(rawAmount.toString()) ?? 0);

    final type = (txn['type'] ?? '').toString();
    final account = (txn['account'] ?? txn['to_account_number'] ?? txn['from_account_number'])?.toString();

    final normalized = <String, dynamic>{
      'type': type.isEmpty ? 'Transfer' : type,
      'account': account ?? '',
      'name': txn['name']?.toString(),
      'bank': (txn['bank'] ?? 'SAE BANK').toString(),
      'amount': amount,
      'date': (txn['date'] ?? txn['transaction_date'] ?? DateTime.now().toIso8601String()).toString(),
      'status': (txn['status'] ?? 'SUCCESS').toString(),
    };

    setState(() {
      _recentTransactions.insert(0, normalized);
      if (_recentTransactions.length > 20) {
        _recentTransactions = _recentTransactions.sublist(0, 20);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recent_transactions', jsonEncode(_recentTransactions));
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadUserName() async {
    final userData = await _apiService.getUserData();
    if (userData != null) {
      setState(() {
        _userName = userData['name'] ?? 'User';
        _cifNumber = userData['cif_number'] ?? '';
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final balanceData = await _apiService.getBalance();

      setState(() {
        _totalBalance = balanceData['total_balance']?.toDouble() ?? 0;
        _accounts = balanceData['accounts'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load saved contacts
      final contactsJson = prefs.getString('saved_contacts');
      if (contactsJson != null) {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        setState(() {
          _savedContacts = decoded.map((e) => Map<String, String>.from(e)).toList();
        });
      }
      
      // Load recent transactions
      final transactionsJson = prefs.getString('recent_transactions');
      if (transactionsJson != null) {
        final List<dynamic> decoded = jsonDecode(transactionsJson);
        setState(() {
          _recentTransactions = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      print('Error loading saved data: $e');
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.',
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 0) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primaryBlue,
        child: CustomScrollView(
          slivers: [
            // Header BRImo Style
            SliverAppBar(
              expandedHeight: 240,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Top Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'SAE BANK',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Hai,', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
                                  IconButton(
                                    icon: const Icon(Icons.menu, color: Colors.white),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Saldo Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Saldo Tabungan Utama', style: TextStyle(color: Colors.white, fontSize: 12)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Rp${_formatCurrency(_totalBalance)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Semua Tabunganmu
                          InkWell(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Semua Tabunganmu', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                                const SizedBox(height: 16),
                                Text('Error: $_error', style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue), child: const Text('Coba Lagi')),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            const SizedBox(height: 16),
                            // Fitur Tersedia
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Fitur Tersedia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildQuickAction(Icons.swap_horiz, 'Transfer', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen())).then((_) {
                                    _loadData();
                                    _loadSavedData();
                                  }), false),
                                  _buildQuickAction(Icons.atm, 'Setor & Tarik Tunai', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen())).then((_) => _loadData()), false),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Latest People Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Kontak Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppColors.secondaryBlue)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Latest People List
                            SizedBox(
                              height: 100,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                children: [
                                  _buildPersonItem(Icons.add, 'Tambah', () {
                                    _showAddContactDialog();
                                  }, isAdd: true),
                                  ..._savedContacts.take(5).map((contact) => 
                                    _buildPersonItem(
                                      Icons.person, 
                                      contact['name'] ?? 'Unknown',
                                      () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const TransferScreen()),
                                        ).then((_) {
                                          _loadData();
                                          _loadSavedData();
                                        });
                                      },
                                      accountNumber: contact['account'],
                                    )
                                  ),
                                  // Tampilkan dummy jika tidak ada kontak tersimpan
                                  if (_savedContacts.isEmpty) ...[
                                    _buildPersonItem(Icons.person, 'Nadhif', () {}, accountNumber: '1234567890'),
                                    _buildPersonItem(Icons.person, 'Udin', () {}, accountNumber: '5898452955'),
                                    _buildPersonItem(Icons.person, 'Baqik', () {}, accountNumber: '3533834869'),
                                    _buildPersonItem(Icons.person, 'Rafli', () {}, accountNumber: '9876543210'),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Recent Transaction Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Transaksi Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
                                  TextButton(
                                    onPressed: () {
                                      setState(() => _currentIndex = 1);
                                    },
                                    child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppColors.secondaryBlue)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Recent Transactions List
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: _recentTransactions.take(3).map((transaction) {
                                  final amount = transaction['amount'] as num;
                                  final dateStr = transaction['date'] ?? transaction['timestamp'];
                                  final timestamp = DateTime.parse(dateStr);
                                  final now = DateTime.now();
                                  final difference = now.difference(timestamp);
                                  
                                  String formattedDate;
                                  if (difference.inDays == 0) {
                                    formattedDate = 'Hari ini, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                                  } else if (difference.inDays == 1) {
                                    formattedDate = 'Kemarin, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                                  } else {
                                    formattedDate = '${timestamp.day} ${_getMonthName(timestamp.month)}, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                                  }
                                  
                                  // Determine transaction details based on type
                                  String transactionType = transaction['type'] ?? 'Transfer';
                                  IconData icon;
                                  Color iconColor;
                                  String title;
                                  Color amountColor;
                                  String amountPrefix;
                                  
                                  if (transactionType == 'Setor Tunai') {
                                    icon = Icons.arrow_downward;
                                    iconColor = Colors.green;
                                    title = 'Setor Tunai';
                                    amountColor = Colors.green;
                                    amountPrefix = '+ ';
                                  } else if (transactionType == 'Tarik Tunai') {
                                    icon = Icons.arrow_upward;
                                    iconColor = Colors.red;
                                    title = 'Tarik Tunai';
                                    amountColor = Colors.red;
                                    amountPrefix = '- ';
                                  } else {
                                    // Transfer
                                    icon = Icons.arrow_upward;
                                    iconColor = AppColors.briOrange;
                                    title = 'Transfer ke ${transaction['name'] ?? 'Unknown'}';
                                    amountColor = Colors.red;
                                    amountPrefix = '- ';
                                  }
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _buildTransactionItem(
                                      icon: icon,
                                      iconColor: iconColor,
                                      title: title,
                                      date: formattedDate,
                                      amount: '$amountPrefix Rp ${_formatCurrency(amount.toDouble())}',
                                      amountColor: amountColor,
                                      accountNumber: transaction['account'],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            // Tampilkan dummy jika tidak ada transaksi
                            if (_recentTransactions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: [
                                    _buildTransactionItem(
                                      icon: Icons.arrow_upward,
                                      iconColor: AppColors.briOrange,
                                      title: 'Transfer ke Udin',
                                      date: 'Hari ini, 10:30',
                                      amount: '- Rp 50.000',
                                      amountColor: Colors.red,
                                      accountNumber: '5898452955',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTransactionItem(
                                      icon: Icons.arrow_downward,
                                      iconColor: Colors.green,
                                      title: 'Diterima dari Baqik',
                                      date: 'Kemarin, 14:20',
                                      amount: '+ Rp 100.000',
                                      amountColor: Colors.green,
                                      accountNumber: '3533834869',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTransactionItem(
                                      icon: Icons.arrow_upward,
                                      iconColor: AppColors.briOrange,
                                      title: 'Transfer ke Rafli',
                                      date: '3 Jan, 09:15',
                                      amount: '- Rp 75.000',
                                      amountColor: Colors.red,
                                      accountNumber: '9876543210',
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 32),
                          ],
                        ),
            ),
          ],
        ),
      );
    } else if (_currentIndex == 1) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGrey,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Aktivitas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Semua Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
                    const SizedBox(height: 12),
                    _buildTransactionItem(
                      icon: Icons.arrow_upward,
                      iconColor: AppColors.briOrange,
                      title: 'Transfer ke Udin',
                      date: '5 Jan 2026, 10:30',
                      amount: '- Rp 50.000',
                      amountColor: Colors.red,
                      status: 'Sukses',
                    ),
                    const SizedBox(height: 8),
                    _buildTransactionItem(
                      icon: Icons.arrow_downward,
                      iconColor: Colors.green,
                      title: 'Diterima dari Baqik',
                      date: '4 Jan 2026, 14:20',
                      amount: '+ Rp 100.000',
                      amountColor: Colors.green,
                      status: 'Sukses',
                    ),
                    const SizedBox(height: 8),
                    _buildTransactionItem(
                      icon: Icons.arrow_upward,
                      iconColor: AppColors.briOrange,
                      title: 'Transfer ke Rafli',
                      date: '3 Jan 2026, 09:15',
                      amount: '- Rp 75.000',
                      amountColor: Colors.red,
                      status: 'Sukses',
                    ),
                    const SizedBox(height: 8),
                    _buildTransactionItem(
                      icon: Icons.atm,
                      iconColor: AppColors.primaryBlue,
                      title: 'Tarik Tunai ATM',
                      date: '2 Jan 2026, 15:45',
                      amount: '- Rp 200.000',
                      amountColor: Colors.red,
                      status: 'Sukses',
                    ),
                    const SizedBox(height: 8),
                    _buildTransactionItem(
                      icon: Icons.arrow_downward,
                      iconColor: Colors.green,
                      title: 'Diterima dari Nadhif',
                      date: '1 Jan 2026, 11:20',
                      amount: '+ Rp 150.000',
                      amountColor: Colors.green,
                      status: 'Sukses',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_currentIndex == 3) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGrey,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Kartu Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kartu Debit
                    if (_accounts.isNotEmpty) ..._accounts.map((account) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primaryBlue, AppColors.secondaryBlue, AppColors.accentBlue],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SAE BANK',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'DEBIT CARD',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 10,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.credit_card, color: Colors.white, size: 28),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NOMOR REKENING',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    account['account_number'] ?? '-',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PEMEGANG KARTU',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 9,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _userName.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'SALDO',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 9,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rp ${(account['balance'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_currentIndex == 4) {
      return const ProfileScreen();
    }
    return const Center(child: Text('QR Code'));
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return GestureDetector(
      onTap: isComingSoon ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.backgroundGrey),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isComingSoon ? AppColors.grey.withOpacity(0.2) : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isComingSoon ? AppColors.grey : color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isComingSoon ? AppColors.grey : AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isComingSoon ? AppColors.grey : AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isComingSoon ? AppColors.grey : AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutasiItem({
    required String referenceNo,
    required String amount,
    required String time,
    required bool isIncome,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referenceNo,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGrey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: AppColors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap, bool isComingSoon) {
    return InkWell(
      onTap: isComingSoon ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isComingSoon ? AppColors.grey.withOpacity(0.3) : AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: isComingSoon ? AppColors.grey : Colors.white, size: 24),
                ),
                if (isComingSoon)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.briOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Soon', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: isComingSoon ? AppColors.grey : AppColors.darkGrey),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonItem(IconData icon, String name, VoidCallback onTap, {bool isAdd = false, String? accountNumber}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isAdd 
                  ? const LinearGradient(colors: [AppColors.primaryBlue, AppColors.secondaryBlue])
                  : LinearGradient(colors: [AppColors.secondaryBlue.withOpacity(0.7), AppColors.accentBlue.withOpacity(0.7)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Center(
                child: isAdd 
                  ? const Icon(Icons.add, color: Colors.white, size: 28)
                  : Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontSize: 12, color: AppColors.darkGrey, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String date,
    required String amount,
    required Color amountColor,
    String? accountNumber,
    String? status,
  }) {
    return GestureDetector(
      onTap: accountNumber != null
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen())).then((_) => _loadData())
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.backgroundGrey),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGrey)),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                  if (status != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: amountColor)),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog() {
    final TextEditingController accountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Kontak', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: accountController,
              decoration: InputDecoration(
                labelText: 'Nomor Rekening',
                hintText: 'Masukkan nomor rekening',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.account_balance),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (accountController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kontak ${accountController.text} ditambahkan!'), backgroundColor: AppColors.primaryBlue),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Beranda', 0),
              _buildNavItem(Icons.apps, 'Aktivitas', 1),
              _buildQRNavItem(),
              _buildNavItem(Icons.credit_card, 'Kartu', 3),
              _buildNavItem(Icons.person_outline, 'Akun', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? AppColors.primaryBlue : AppColors.grey, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: isActive ? AppColors.primaryBlue : AppColors.grey, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildQRNavItem() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryBlue, AppColors.secondaryBlue]),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
    );
  }
}
