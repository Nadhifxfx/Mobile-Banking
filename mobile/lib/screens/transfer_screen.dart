import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../utils/constants.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toAccountController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _apiService = ApiService();

  int _currentStep = 0; // 0: input account, 1: input amount, 2: input PIN, 3: success
  String? _selectedFromAccount;
  String _selectedBank = 'SAE BANK';
  final String _selectedMethod = 'Transfer SAE Fast';
  String _selectedInputType = 'No. Rekening';
  String? _destinationAccountName;
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _accounts = [];
  final List<String> _bankList = [
    'SAE BANK',
    'BCA - Bank Central Asia',
    'BRI - Bank Rakyat Indonesia',
    'Mandiri - Bank Mandiri',
    'BNI - Bank Negara Indonesia',
    'CIMB Niaga',
    'Permata Bank',
    'Danamon',
    'BTN - Bank Tabungan Negara',
    'Bank Syariah Indonesia',
  ];
  
  // Data dummy untuk setiap bank
  final Map<String, List<Map<String, String>>> _bankAccounts = {
    'SAE BANK': [
      {'account': '1234567890', 'name': 'Nadhif', 'bank': 'SAE BANK'},
      {'account': '5898452955', 'name': 'Udin', 'bank': 'SAE BANK'},
      {'account': '3533834869', 'name': 'Baqik', 'bank': 'SAE BANK'},
      {'account': '9876543210', 'name': 'Rafli', 'bank': 'SAE BANK'},
    ],
    'BCA - Bank Central Asia': [
      {'account': '1234567890', 'name': 'Ahmad BCA', 'bank': 'BCA'},
      {'account': '0987654321', 'name': 'Siti BCA', 'bank': 'BCA'},
      {'account': '5555666777', 'name': 'Budi BCA', 'bank': 'BCA'},
    ],
    'BRI - Bank Rakyat Indonesia': [
      {'account': '111122223333', 'name': 'Andi BRI', 'bank': 'BRI'},
      {'account': '444455556666', 'name': 'Dewi BRI', 'bank': 'BRI'},
      {'account': '777788889999', 'name': 'Rudi BRI', 'bank': 'BRI'},
    ],
    'Mandiri - Bank Mandiri': [
      {'account': '1000200030004', 'name': 'Hasan Mandiri', 'bank': 'Mandiri'},
      {'account': '5000600070008', 'name': 'Fitri Mandiri', 'bank': 'Mandiri'},
      {'account': '9000100020003', 'name': 'Yoga Mandiri', 'bank': 'Mandiri'},
    ],
    'BNI - Bank Negara Indonesia': [
      {'account': '2222333344445', 'name': 'Rina BNI', 'bank': 'BNI'},
      {'account': '6666777788889', 'name': 'Doni BNI', 'bank': 'BNI'},
    ],
    'CIMB Niaga': [
      {'account': '3333444455556', 'name': 'Linda CIMB', 'bank': 'CIMB'},
      {'account': '7777888899990', 'name': 'Agus CIMB', 'bank': 'CIMB'},
    ],
    'Permata Bank': [
      {'account': '4444555566667', 'name': 'Wati Permata', 'bank': 'Permata'},
      {'account': '8888999900001', 'name': 'Joko Permata', 'bank': 'Permata'},
    ],
    'Danamon': [
      {'account': '5555666677778', 'name': 'Maya Danamon', 'bank': 'Danamon'},
      {'account': '9999000011112', 'name': 'Eko Danamon', 'bank': 'Danamon'},
    ],
    'BTN - Bank Tabungan Negara': [
      {'account': '6666777788889', 'name': 'Sari BTN', 'bank': 'BTN'},
      {'account': '1111222233334', 'name': 'Tono BTN', 'bank': 'BTN'},
    ],
    'Bank Syariah Indonesia': [
      {'account': '7777888899990', 'name': 'Farah BSI', 'bank': 'BSI'},
      {'account': '2222333344445', 'name': 'Ilham BSI', 'bank': 'BSI'},
    ],
  };
  
  List<Map<String, String>> get _savedAccounts {
    List<Map<String, String>> accounts = List.from(_bankAccounts[_selectedBank] ?? []);
    // Tambahkan kontak yang disimpan dari SharedPreferences
    for (var contact in _savedContactsList) {
      if (contact['bank'] == _selectedBank) {
        // Cek apakah sudah ada di dummy data
        bool exists = accounts.any((acc) => acc['account'] == contact['account']);
        if (!exists) {
          accounts.insert(0, contact);
        }
      }
    }
    return accounts;
  }

  List<Map<String, String>> _savedContactsList = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadSavedContacts();
  }

  Future<void> _loadAccounts() async {
    try {
      final balanceData = await _apiService.getBalance();
      setState(() {
        _accounts = balanceData['accounts'] ?? [];
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

  Future<void> _loadSavedContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('saved_contacts');
      if (contactsJson != null) {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        setState(() {
          _savedContactsList = decoded.map((e) => Map<String, String>.from(e)).toList();
        });
      }
    } catch (e) {
      print('Error loading saved contacts: $e');
    }
  }

  Future<void> _saveContactAndTransaction({
    required String account,
    required String name,
    required String bank,
    required double amount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Simpan kontak
      final contactsJson = prefs.getString('saved_contacts');
      List<Map<String, String>> contacts = [];
      if (contactsJson != null) {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        contacts = decoded.map((e) => Map<String, String>.from(e)).toList();
      }
      
      // Tambahkan kontak baru jika belum ada
      bool exists = contacts.any((c) => c['account'] == account && c['bank'] == bank);
      if (!exists) {
        contacts.insert(0, {
          'account': account,
          'name': name,
          'bank': bank,
        });
        // Batasi maksimal 20 kontak
        if (contacts.length > 20) {
          contacts = contacts.sublist(0, 20);
        }
        await prefs.setString('saved_contacts', jsonEncode(contacts));
      }
      
      // Simpan transaksi untuk Recent Transaction
      final transactionsJson = prefs.getString('recent_transactions');
      List<Map<String, dynamic>> transactions = [];
      if (transactionsJson != null) {
        final List<dynamic> decoded = jsonDecode(transactionsJson);
        transactions = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      transactions.insert(0, {
        'type': 'Transfer',
        'account': account,
        'name': name,
        'bank': bank,
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'status': 'SUCCESS',
      });
      
      // Batasi maksimal 20 transaksi
      if (transactions.length > 20) {
        transactions = transactions.sublist(0, 20);
      }
      await prefs.setString('recent_transactions', jsonEncode(transactions));
      
      // Reload kontak
      await _loadSavedContacts();
    } catch (e) {
      print('Error saving contact and transaction: $e');
    }
  }

  @override
  void dispose() {
    _toAccountController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyAccountAndProceed() async {
    if (_toAccountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor rekening tujuan')),
      );
      return;
    }

    // Check if selected bank is SAE BANK
    if (_selectedBank != 'SAE BANK') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer hanya dapat dilakukan ke sesama SAE BANK. Silakan pilih SAE BANK sebagai bank tujuan.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Find account name from saved accounts
    final savedAccount = _savedAccounts.firstWhere(
      (acc) => acc['account'] == _toAccountController.text,
      orElse: () => {'account': _toAccountController.text, 'name': 'Unknown'},
    );

    setState(() {
      _destinationAccountName = savedAccount['name'];
      _currentStep = 1;
    });
  }

  Future<void> _handleTransfer() async {
    if (_amountController.text.isEmpty || _selectedFromAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text);
      
      await _apiService.transfer(
        fromAccount: _selectedFromAccount!,
        toAccount: _toAccountController.text,
        amount: amount,
        pin: '123456', // Default PIN, akan di-handle di backend
        description: 'Transfer ke $_destinationAccountName',
      );

      // Simpan kontak dan transaksi ke SharedPreferences
      await _saveContactAndTransaction(
        account: _toAccountController.text,
        name: _destinationAccountName ?? 'Unknown',
        bank: _selectedBank,
        amount: amount,
      );

      setState(() {
        _isSubmitting = false;
        _currentStep = 2; // Langsung ke success screen (step 2 sekarang adalah success)
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
          title: const Text('Transfer'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentStep == 2) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _currentStep == 0
          ? _buildStep1()
          : _buildStep2(),
      bottomNavigationBar: _currentStep == 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _verifyAccountAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Lanjutkan', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Transfer Sekarang', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
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
          // Bank Tujuan
          const Text('Bank Tujuan', style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedBank,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: AppColors.backgroundGrey,
              prefixIcon: const Icon(Icons.account_balance, color: AppColors.primaryBlue, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _bankList.map((bank) {
              return DropdownMenuItem<String>(
                value: bank,
                child: Text(bank, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedBank = value!),
          ),
          if (_selectedBank != 'SAE BANK')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '* Transfer antar bank akan segera hadir. Saat ini hanya tersedia transfer ke sesama SAE BANK.',
                style: TextStyle(fontSize: 11, color: Colors.orange[700], fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(height: 20),

          // Metode Transfer
          const Text('Metode Transfer', style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(_selectedMethod, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                Icon(Icons.keyboard_arrow_down, color: AppColors.grey),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Nomor Tujuan / Alias
          const Text('Nomor Tujuan / Alias', style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.contact_page, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('Pilih No. Rekening/Alias', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                Icon(Icons.keyboard_arrow_down, color: AppColors.grey),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Radio Options
          RadioListTile<String>(
            value: 'No. Rekening',
            groupValue: _selectedInputType,
            onChanged: (value) => setState(() => _selectedInputType = value!),
            title: const Text('No. Rekening', style: TextStyle(fontSize: 14)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: 'No. Handphone/No. Telepon',
            groupValue: _selectedInputType,
            onChanged: (value) => setState(() => _selectedInputType = value!),
            title: const Text('No. Handphone/No. Telepon', style: TextStyle(fontSize: 14)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: 'Email',
            groupValue: _selectedInputType,
            onChanged: (value) => setState(() => _selectedInputType = value!),
            title: const Text('Email', style: TextStyle(fontSize: 14)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          // Input Field
          TextField(
            controller: _toAccountController,
            decoration: InputDecoration(
              hintText: _selectedInputType == 'No. Rekening' ? 'Masukkan nomor rekening' : 
                        _selectedInputType == 'Email' ? 'Masukkan email' : 'Masukkan nomor telepon',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: AppColors.backgroundGrey,
            ),
            keyboardType: _selectedInputType == 'Email' ? TextInputType.emailAddress : TextInputType.number,
          ),
          const SizedBox(height: 20),

          // Daftar Tersimpan
          const Text('Daftar Tersimpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
          const SizedBox(height: 12),
          ..._savedAccounts.map((account) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: Text(account['name']![0], style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
              ),
              title: Text(account['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(account['account']!, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              onTap: () {
                _toAccountController.text = account['account']!;
              },
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nomer Tujuan
          const Text('Nomer Tujuan', style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(_destinationAccountName?[0] ?? 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_destinationAccountName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(_toAccountController.text, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Nominal Transfer
          const Text('Nominal Transfer', style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              hintText: 'Masukkan nominal',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: AppColors.backgroundGrey,
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.attach_money, color: AppColors.primaryBlue),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),

          // Sumber Dana
          const Text('Sumber Dana', style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedFromAccount,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: AppColors.backgroundGrey,
              prefixIcon: const Icon(Icons.account_balance_wallet, color: AppColors.primaryBlue),
            ),
            hint: const Text('Pilih sumber dana'),
            items: _accounts.map((account) {
              return DropdownMenuItem<String>(
                value: account['account_number'],
                child: Text('${account['account_number']}'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedFromAccount = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                ),
                child: const Icon(Icons.check_circle, size: 100, color: Colors.green),
              ),
              const SizedBox(height: 32),
              const Text('Transfer Berhasil!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
              const SizedBox(height: 16),
              Text('Rp ${_amountController.text}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
              const SizedBox(height: 8),
              Text('Ke $_destinationAccountName', style: const TextStyle(fontSize: 16, color: AppColors.grey)),
              Text(_toAccountController.text, style: const TextStyle(fontSize: 14, color: AppColors.grey)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Selesai', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _toAccountController.clear();
                    _amountController.clear();
                    _pinController.clear();
                    _selectedFromAccount = null;
                    _destinationAccountName = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.primaryBlue),
                ),
                child: const Text('Transfer Lagi', style: TextStyle(fontSize: 16, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
