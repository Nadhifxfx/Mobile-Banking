import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _apiService = ApiService();

  int _currentStep = 0; // 0: input amount, 1: input PIN, 2: success
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
          SnackBar(content: Text('Error loading accounts: $e')),
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

  Future<void> _handleNext() async {
    if (_amountController.text.isEmpty || _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field')),
      );
      return;
    }

    setState(() => _currentStep = 1);
  }

  Future<void> _verifyPinAndDeposit() async {
    if (_pinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN harus 6 digit')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text);
      
      await _apiService.deposit(
        accountNumber: _selectedAccount!,
        amount: amount,
        pin: _pinController.text,
      );

      setState(() {
        _isSubmitting = false;
        _currentStep = 2;
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
          title: const Text('Top Up'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Top Up'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _currentStep == 0
          ? _buildStep1()
          : _currentStep == 1
              ? _buildStep2()
              : _buildSuccessScreen(),
      bottomNavigationBar: _currentStep == 0
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
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Lanjutkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          : _currentStep == 1
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
                    onPressed: _isSubmitting ? null : _verifyPinAndDeposit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Konfirmasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              : null,
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
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_circle, color: AppColors.primaryBlue, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Up Saldo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Tambahkan saldo ke rekening Anda', style: TextStyle(fontSize: 12, color: AppColors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nominal
          const Text('Nominal Top Up', style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
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

          // Rekening Tujuan
          const Text('Rekening Tujuan', style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
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
              _buildQuickAmount('200.000'),
              _buildQuickAmount('500.000'),
              _buildQuickAmount('1.000.000'),
              _buildQuickAmount('2.000.000'),
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

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: AppColors.primaryBlue),
          const SizedBox(height: 24),
          const Text('Masukkan PIN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Masukkan PIN 6 digit untuk konfirmasi top up', style: TextStyle(color: AppColors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _pinController,
            decoration: InputDecoration(
              hintText: '• • • • • •',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
              counterText: '${_pinController.text.length}/6',
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final amount = double.parse(_amountController.text);
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
          const Text('Top Up Berhasil!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
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
                _buildDetailRow('Rekening Tujuan', _selectedAccount ?? '-'),
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
