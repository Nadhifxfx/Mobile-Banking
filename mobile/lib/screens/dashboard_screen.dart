import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'transfer_screen.dart';
import 'history_screen.dart';
import 'withdraw_screen.dart';
import 'deposit_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

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
  String? _error;
  String _userName = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadData();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
    });
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

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.',
    );
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
                                  IconButton(icon: const Icon(Icons.headset_mic_outlined, color: Colors.white), onPressed: () {}),
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
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                                    ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildQuickAction(Icons.swap_horiz, 'Transfer', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen())).then((_) => _loadData()), false),
                                  _buildQuickAction(Icons.add_circle, 'Top Up', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepositScreen())).then((_) => _loadData()), false),
                                  _buildQuickAction(Icons.atm, 'Setor & Tarik Tunai', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen())).then((_) => _loadData()), false),
                                  _buildQuickAction(Icons.history, 'Riwayat', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())), false),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Fitur Segera Hadir
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Text('Fitur Segera Hadir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
                                  SizedBox(width: 8),
                                  Icon(Icons.schedule, color: AppColors.briOrange, size: 18),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Quick Actions Coming Soon
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildQuickAction(Icons.payment, 'BRIVA', () {}, true),
                                  _buildQuickAction(Icons.account_balance_wallet, 'e-Wallet', () {}, true),
                                  _buildQuickAction(Icons.phone_android, 'Pulsa / Data', () {}, true),
                                  _buildQuickAction(Icons.receipt_long, 'Tagihan', () {}, true),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Grid Menu Coming Soon
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildQuickAction(Icons.money, 'Pinjaman', () {}, true),
                                  _buildQuickAction(Icons.credit_card, 'Kartu Kredit', () {}, true),
                                  _buildQuickAction(Icons.receipt, 'QRIS', () {}, true),
                                  _buildQuickAction(Icons.more_horiz, 'Lainnya', () {}, true),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Tabungan Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tabungan SAE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
                                  TextButton.icon(onPressed: () {}, icon: const Text('Sembunyikan', style: TextStyle(fontSize: 12)), label: const Icon(Icons.keyboard_arrow_up, size: 16), style: TextButton.styleFrom(foregroundColor: AppColors.accentBlue)),
                                ],
                              ),
                            ),
                            if (_accounts.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.secondaryBlue, AppColors.accentBlue]), borderRadius: BorderRadius.circular(12)),
                                        child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Tabungan Utama', style: TextStyle(fontSize: 14, color: AppColors.grey)),
                                            const SizedBox(height: 4),
                                            Text(_accounts[0]['account_number'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                          ],
                        ),
            ),
          ],
        ),
      );
    } else if (_currentIndex == 1) {
      return const Center(child: Text('Tabungan'));
    } else if (_currentIndex == 3) {
      return const HistoryScreen();
    } else if (_currentIndex == 4) {
      return const ProfileScreen();
    }
    return const Center(child: Text('QR Code'));
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

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.account_balance_wallet_outlined, 'Tabungan', 1),
              _buildQRNavItem(),
              _buildNavItem(Icons.receipt_long_outlined, 'Mutasi', 3),
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
