import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class TransferScreen extends StatefulWidget {
  final List<dynamic> accounts;
  final VoidCallback onSuccess;

  const TransferScreen({
    super.key,
    required this.accounts,
    required this.onSuccess,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toAccountController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _apiService = ApiService();

  String? _selectedFromAccount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) {
      _selectedFromAccount = widget.accounts[0]['account_number'];
    }
  }

  @override
  void dispose() {
    _toAccountController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      
      await _apiService.transfer(
        fromAccount: _selectedFromAccount!,
        toAccount: _toAccountController.text,
        amount: amount,
        description: _descriptionController.text.isEmpty
            ? 'Transfer'
            : _descriptionController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer successful!'),
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
        title: const Text('Transfer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // From Account
              DropdownButtonFormField<String>(
                value: _selectedFromAccount,
                decoration: const InputDecoration(
                  labelText: 'From Account',
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
                  setState(() => _selectedFromAccount = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select source account';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // To Account
              TextFormField(
                controller: _toAccountController,
                decoration: const InputDecoration(
                  labelText: 'To Account Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter destination account';
                  }
                  if (value == _selectedFromAccount) {
                    return 'Cannot transfer to same account';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
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
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Transfer Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleTransfer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Transfer Now',
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
