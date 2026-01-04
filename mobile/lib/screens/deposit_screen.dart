import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class DepositScreen extends StatefulWidget {
  final List<dynamic> accounts;
  final VoidCallback onSuccess;

  const DepositScreen({
    super.key,
    required this.accounts,
    required this.onSuccess,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _apiService = ApiService();

  String? _selectedAccount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) {
      _selectedAccount = widget.accounts[0]['account_number'];
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      
      await _apiService.deposit(
        accountNumber: _selectedAccount!,
        amount: amount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit successful!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Account Selection
              DropdownButtonFormField<String>(
                value: _selectedAccount,
                decoration: const InputDecoration(
                  labelText: 'Select Account',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: widget.accounts.map((account) {
                  return DropdownMenuItem<String>(
                    value: account['account_number'],
                    child: Text(
                      '${account['account_number']} - Rp ${account['balance']?.toStringAsFixed(0)}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedAccount = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select account';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Deposit Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_circle),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Deposit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleDeposit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Deposit',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
