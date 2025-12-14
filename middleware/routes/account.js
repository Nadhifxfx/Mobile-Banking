/**
 * Account Routes
 * Handles balance inquiry, account management
 */

const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const serviceLayer = require('../services/serviceLayerClient');
const authenticate = require('../middleware/authenticate');

// All routes require authentication
router.use(authenticate);

// ===== Get Balance (All Accounts) =====

router.get('/balance', async (req, res) => {
  try {
    const customer_id = req.user.customer_id;

    // Get all accounts
    const accounts = await serviceLayer.getAccountsByCustomer(customer_id, true);

    // Calculate total balance
    const totalBalance = accounts.reduce((sum, acc) => sum + acc.available_balance, 0);

    res.json({
      status: 'success',
      total_balance: totalBalance,
      accounts: accounts.map(acc => ({
        id: acc.id,
        account_number: acc.account_number,
        account_name: acc.account_name,
        account_type: acc.account_type,
        currency: acc.currency_code,
        balance: acc.available_balance
      }))
    });

  } catch (error) {
    console.error('Get balance error:', error);
    res.status(error.status || 500).json({
      error: 'Failed to Get Balance',
      message: error.message || 'Unable to retrieve balance'
    });
  }
});

// ===== Get Account Details =====

router.get('/details/:accountNumber', async (req, res) => {
  try {
    const { accountNumber } = req.params;
    const customer_id = req.user.customer_id;

    // Get account details
    const account = await serviceLayer.getAccountByNumber(accountNumber);

    // Verify ownership
    if (account.m_customer_id !== customer_id) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have permission to access this account'
      });
    }

    res.json({
      status: 'success',
      account: {
        id: account.id,
        account_number: account.account_number,
        account_name: account.account_name,
        account_type: account.account_type,
        currency: account.currency_code,
        clear_balance: account.clear_balance,
        available_balance: account.available_balance,
        is_active: account.is_active,
        created_at: account.created_at
      }
    });

  } catch (error) {
    console.error('Get account details error:', error);
    res.status(error.status || 500).json({
      error: 'Failed to Get Account Details',
      message: error.message || 'Unable to retrieve account details'
    });
  }
});

// ===== Create New Account =====

router.post('/create',
  [
    body('account_number').notEmpty().withMessage('Account number is required'),
    body('account_name').notEmpty().withMessage('Account name is required'),
    body('account_type').notEmpty().withMessage('Account type is required'),
    body('initial_balance').optional().isNumeric().withMessage('Initial balance must be a number')
  ],
  async (req, res) => {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ 
          error: 'Validation Error',
          details: errors.array() 
        });
      }

      const customer_id = req.user.customer_id;
      const { account_number, account_name, account_type, initial_balance = 0 } = req.body;

      // Create account via service layer
      const account = await serviceLayer.createAccount({
        m_customer_id: customer_id,
        account_number,
        account_name,
        account_type,
        currency_code: 'IDR',
        clear_balance: initial_balance,
        available_balance: initial_balance
      });

      res.status(201).json({
        status: 'success',
        message: 'Account created successfully',
        account: {
          id: account.id,
          account_number: account.account_number,
          account_name: account.account_name,
          account_type: account.account_type,
          balance: account.available_balance
        }
      });

    } catch (error) {
      console.error('Create account error:', error);
      res.status(error.status || 500).json({
        error: 'Failed to Create Account',
        message: error.message || 'Unable to create account'
      });
    }
  }
);

// ===== Get All Accounts =====

router.get('/list', async (req, res) => {
  try {
    const customer_id = req.user.customer_id;

    // Get all accounts
    const accounts = await serviceLayer.getAccountsByCustomer(customer_id, true);

    res.json({
      status: 'success',
      count: accounts.length,
      accounts: accounts.map(acc => ({
        id: acc.id,
        account_number: acc.account_number,
        account_name: acc.account_name,
        account_type: acc.account_type,
        currency: acc.currency_code,
        balance: acc.available_balance,
        is_active: acc.is_active
      }))
    });

  } catch (error) {
    console.error('Get accounts error:', error);
    res.status(error.status || 500).json({
      error: 'Failed to Get Accounts',
      message: error.message || 'Unable to retrieve accounts'
    });
  }
});

// ===== Get Account Transactions =====

router.get('/:account_number/transactions', async (req, res) => {
  try {
    const customer_id = req.user.customer_id;
    const { account_number } = req.params;

    // Verify account ownership
    const accounts = await serviceLayer.getAccountsByCustomer(customer_id, true);
    const accountExists = accounts.some(acc => acc.account_number === account_number);

    if (!accountExists) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Akun tidak ditemukan atau bukan milik Anda'
      });
    }

    // Get transactions from service layer
    const transactions = await serviceLayer.getTransactionsByCustomer(customer_id);
    
    // Filter by account number
    const accountTransactions = transactions.filter(tx => 
      tx.account_number === account_number
    );

    res.json({
      status: 'success',
      account_number,
      count: accountTransactions.length,
      transactions: accountTransactions
    });

  } catch (error) {
    console.error('Get account transactions error:', error);
    res.status(error.status || 500).json({
      error: 'Failed to Get Transactions',
      message: error.message || 'Unable to retrieve transactions'
    });
  }
});

module.exports = router;

