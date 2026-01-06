import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../utils/constants.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _apiService = ApiService();

  int _currentStep = 0; // 0: pilih type, 1: input amount, 2: success
  String _transactionType = ''; // 'deposit' or 'withdraw'
  String _selectedLocation = 'ATM'; // For withdraw only
  String? _selectedAccount;
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final balanceData = await _apiService.getBalance();
      setState(() {
        _accounts = balanceData['accounts'] ?? [];
        if (_accounts.isNotEmpty) {
          _selectedAccount = _accounts[0]['account_number'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading accounts: \$e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _selectType(String type) {
    setState(() {
      _transactionType = type;
      _currentStep = 1;
    });
  }

  Future<void> _saveTransaction({
    required String type,
    required double amount,
    required String accountNumber,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load existing transactions
      final transactionsJson = prefs.getString('recent_transactions');
      List<Map<String, dynamic>> transactions = [];
      
      if (transactionsJson != null) {
        final List<dynamic> decoded = jsonDecode(transactionsJson);
        transactions = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      // Add new transaction at the beginning
      transactions.insert(0, {
        'type': type == 'deposit' ? 'Setor Tunai' : 'Tarik Tunai',
        'account': accountNumber,
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'status': 'SUCCESS',
      });
      
      // Keep only last 20 transactions
      if (transactions.length > 20) {
        transactions = transactions.sublist(0, 20);
      }
      
      await prefs.setString('recent_transactions', jsonEncode(transactions));
    } catch (e) {
      print('Error saving transaction: \$e');
    }
  }

  Future<void> _handleNext() async {
    if (_amountController.text.isEmpty || _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text);
      
      if (_transactionType == 'deposit') {
        await _apiService.deposit(
          accountNumber: _selectedAccount!,
          amount: amount,
          pin: '123456', // Default PIN
        );
      } else {
        await _apiService.withdraw(
          accountNumber: _selectedAccount!,
          amount: amount,
          pin: '123456', // Default PIN
        );
      }

      // Save transaction to SharedPreferences
      await _saveTransaction(
        type: _transactionType,
        amount: amount,
        accountNumber: _selectedAccount!,
      );

      setState(() {
        _isSubmitting = false;
        _currentStep = 2; // Langsung ke success
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Setor & Tarik Tunai'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Setor & Tarik Tunai'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _currentStep == 0
          ? _buildStep0()
          : _currentStep == 1
              ? _buildStep1()
              : _buildSuccessScreen(),
      bottomNavigationBar: _currentStep == 1
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('${_transactionType == "deposit" ? "Setor" : "Tarik"} Sekarang', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          : null,
    );
  }

  Widget _buildStep0() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('Pilih Jenis Transaksi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _buildTypeCard(
            'Setor Tunai',
            'Setor uang tunai ke rekening Anda',
            Icons.add_circle_outline,
            Colors.green,
            () => _selectType('deposit'),
          ),
          const SizedBox(height: 16),
          _buildTypeCard(
            'Tarik Tunai',
            'Tarik uang tunai dari rekening Anda',
            Icons.money_off,
            AppColors.briOrange,
            () => _selectType('withdraw'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_transactionType == 'deposit' ? Colors.green : AppColors.briOrange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _transactionType == 'deposit' ? Icons.add_circle : Icons.money_off,
                    color: _transactionType == 'deposit' ? Colors.green : AppColors.briOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _transactionType == 'deposit' ? 'Setor Tunai' : 'Tarik Tunai',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _transactionType == 'deposit' ? 'Setor uang tunai ke rekening' : 'Tarik uang tunai dari rekening',
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Lokasi (only for withdraw)
          if (_transactionType == 'withdraw') ...[
            const Text('Lokasi Pengambilan', style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedLocation,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.location_on, color: AppColors.primaryBlue),
              ),
              items: const [
                DropdownMenuItem(value: 'ATM', child: Text('ATM')),
                DropdownMenuItem(value: 'Indomaret', child: Text('Indomaret')),
                DropdownMenuItem(value: 'Alfamart', child: Text('Alfamart')),
              ],
              onChanged: (value) => setState(() => _selectedLocation = value!),
            ),
            const SizedBox(height: 20),
          ],

          // Nominal
          Text('Nominal ${_transactionType == "deposit" ? "Setor" : "Tarik"}', style: const TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              hintText: 'Masukkan nominal',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.attach_money, color: AppColors.primaryBlue),
              prefixText: 'Rp ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),

          // Rekening
          Text('Rekening ${_transactionType == "deposit" ? "Tujuan" : "Sumber"}', style: const TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedAccount,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.account_balance_wallet, color: AppColors.primaryBlue),
            ),
            items: _accounts.map((account) {
              return DropdownMenuItem<String>(
                value: account['account_number'],
                child: Text('${account['account_number']}'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedAccount = value),
          ),
          const SizedBox(height: 20),

          // Quick Amount
          const Text('Nominal Cepat', style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickAmount('50.000'),
              _buildQuickAmount('100.000'),
              _buildQuickAmount('150.000'),
              _buildQuickAmount('200.000'),
              _buildQuickAmount('250.000'),
              _buildQuickAmount('300.000'),
              _buildQuickAmount('350.000'),
              _buildQuickAmount('400.000'),
              _buildQuickAmount('450.000'),
              _buildQuickAmount('500.000'),
              _buildQuickAmount('550.000'),
              _buildQuickAmount('600.000'),
              _buildQuickAmount('650.000'),
              _buildQuickAmount('700.000'),
              _buildQuickAmount('750.000'),
              _buildQuickAmount('800.000'),
              _buildQuickAmount('850.000'),
              _buildQuickAmount('900.000'),
              _buildQuickAmount('950.000'),
              _buildQuickAmount('1.000.000'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmount(String amount) {
    return InkWell(
      onTap: () {
        setState(() {
          _amountController.text = amount.replaceAll('.', '');
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
        ),
        child: Text('Rp $amount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final amount = double.parse(_amountController.text);
    final isDeposit = _transactionType == 'deposit';
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, size: 80, color: Colors.green),
          ),
          const SizedBox(height: 24),
          Text('${isDeposit ? "Setor" : "Tarik"} Tunai Berhasil!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDeposit ? Colors.green : AppColors.briOrange)),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('Jenis Transaksi', isDeposit ? 'Setor Tunai' : 'Tarik Tunai'),
                if (!isDeposit) ...[
                  const Divider(height: 24),
                  _buildDetailRow('Lokasi', _selectedLocation),
                ],
                const Divider(height: 24),
                _buildDetailRow('Rekening', _selectedAccount ?? '-'),
                const Divider(height: 24),
                _buildDetailRow('Waktu', DateTime.now().toString().substring(0, 16)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Selesai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
