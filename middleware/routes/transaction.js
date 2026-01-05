/**
 * Transaction Routes
 * Handles transfer, withdraw, deposit, and transaction history
 */

const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const serviceLayer = require('../services/serviceLayerClient');
const authenticate = require('../authenticate');

// All routes require authentication
router.use(authenticate);

// ===== Transfer =====

router.post('/transfer',
  [
    body('from_account').notEmpty().withMessage('Source account is required'),
    body('to_account').notEmpty().withMessage('Destination account is required'),
    body('amount').isNumeric().withMessage('Amount must be a number').custom((value) => {
      if (value <= 0) {
        throw new Error('Amount must be greater than 0');
      }
      return true;
    }),
    body('pin').notEmpty().withMessage('PIN is required').isLength({ min: 6, max: 6 }).withMessage('PIN must be 6 digits'),
    body('description').optional()
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
      const { from_account, to_account, amount, pin, description = 'Transfer' } = req.body;

      // 1. Verify PIN
      const customer = await serviceLayer.getCustomerById(customer_id);
      
      if (!customer || !customer.customer_pin) {
        return res.status(500).json({
          error: 'Server Error',
          message: 'Customer data incomplete'
        });
      }
      
      const isValidPin = await bcrypt.compare(pin, customer.customer_pin);
      
      if (!isValidPin) {
        return res.status(401).json({
          error: 'Unauthorized',
          message: 'PIN salah'
        });
      }

      // 2. Verify source account ownership
      const sourceAccount = await serviceLayer.getAccountByNumber(from_account);
      if (sourceAccount.m_customer_id !== customer_id) {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'You do not own the source account'
        });
      }

      // 3. Verify destination account exists
      const destAccount = await serviceLayer.getAccountByNumber(to_account);

      // 4. Check balance
      const balance = await serviceLayer.getAccountBalance(from_account);
      if (balance.available_balance < amount) {
        return res.status(400).json({
          error: 'Insufficient Balance',
          message: `Your balance is Rp ${balance.available_balance.toLocaleString('id-ID')}. Cannot transfer Rp ${amount.toLocaleString('id-ID')}`
        });
      }

      // 5. Debit source account
      await serviceLayer.debitAccount(from_account, amount);

      // 6. Credit destination account
      await serviceLayer.creditAccount(to_account, amount);

      // 7. Record transaction
      // 7. Record transaction
      const transaction = await serviceLayer.createTransaction({
        m_customer_id: customer_id,
        transaction_type: 'TR',
        transaction_amount: amount,
        from_account_number: from_account,
        to_account_number: to_account,
        status: 'SUCCESS',
        description: description
      });

      // 8. Get new balance
      const newBalance = await serviceLayer.getAccountBalance(from_account);

      res.json({
        status: 'success',
        message: 'Transfer successful',
        transaction: {
          id: transaction.id,
          type: 'Transfer',
          amount: amount,
          from: from_account,
          to: to_account,
          to_name: destAccount.account_name,
          description: description,
          date: transaction.transaction_date || transaction.created_at,
          new_balance: newBalance.available_balance
        }
      });

    } catch (error) {
      console.error('Transfer error:', error);
      res.status(error.status || 500).json({
        error: 'Transfer Failed',
        message: error.message || 'Unable to complete transfer'
      });
    }
  }
);

// ===== Withdraw (Tarik Tunai) =====

router.post('/withdraw',
  [
    body('account_number').notEmpty().withMessage('Account number is required'),
    body('amount').isNumeric().withMessage('Amount must be a number').custom((value) => {
      if (value <= 0) {
        throw new Error('Amount must be greater than 0');
      }
      return true;
    }),
    body('pin').notEmpty().withMessage('PIN is required').isLength({ min: 6, max: 6 }).withMessage('PIN must be 6 digits')
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
      const { account_number, amount, pin } = req.body;

      // 1. Verify PIN
      const customer = await serviceLayer.getCustomerById(customer_id);
      
      if (!customer || !customer.customer_pin) {
        return res.status(500).json({
          error: 'Server Error',
          message: 'Customer data incomplete'
        });
      }
      
      const isValidPin = await bcrypt.compare(pin, customer.customer_pin);
      
      if (!isValidPin) {
        return res.status(401).json({
          error: 'Unauthorized',
          message: 'PIN salah'
        });
      }

      // 2. Verify account ownership
      const account = await serviceLayer.getAccountByNumber(account_number);
      if (account.m_customer_id !== customer_id) {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'You do not own this account'
        });
      }

      // 2. Check balance
      const balance = await serviceLayer.getAccountBalance(account_number);
      if (balance.available_balance < amount) {
        return res.status(400).json({
          error: 'Insufficient Balance',
          message: `Your balance is Rp ${balance.available_balance.toLocaleString('id-ID')}`
        });
      }

      // 3. Debit account
      await serviceLayer.debitAccount(account_number, amount);

      // 4. Record transaction
      const transaction = await serviceLayer.createTransaction({
        m_customer_id: customer_id,
        transaction_type: 'WD',
        transaction_amount: amount,
        from_account_number: account_number,
        status: 'SUCCESS',
        description: 'Tarik Tunai'
      });

      // 5. Get new balance
      const newBalance = await serviceLayer.getAccountBalance(account_number);

      res.json({
        status: 'success',
        message: 'Withdrawal successful',
        transaction: {
          id: transaction.id,
          type: 'Withdrawal',
          amount: amount,
          account: account_number,
          date: transaction.transaction_date || transaction.created_at,
          new_balance: newBalance.available_balance
        }
      });

    } catch (error) {
      console.error('Withdraw error:', error);
      res.status(error.status || 500).json({
        error: 'Withdrawal Failed',
        message: error.message || 'Unable to complete withdrawal'
      });
    }
  }
);

// ===== Deposit (Setor Tunai) =====

router.post('/deposit',
  [
    body('account_number').notEmpty().withMessage('Account number is required'),
    body('amount').isNumeric().withMessage('Amount must be a number').custom((value) => {
      if (value <= 0) {
        throw new Error('Amount must be greater than 0');
      }
      return true;
    }),
    body('pin').notEmpty().withMessage('PIN is required').isLength({ min: 6, max: 6 }).withMessage('PIN must be 6 digits')
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
      const { account_number, amount, pin } = req.body;

      // 1. Verify PIN
      const customer = await serviceLayer.getCustomerById(customer_id);
      
      if (!customer || !customer.customer_pin) {
        return res.status(500).json({
          error: 'Server Error',
          message: 'Customer data incomplete'
        });
      }
      
      const isValidPin = await bcrypt.compare(pin, customer.customer_pin);
      
      if (!isValidPin) {
        return res.status(401).json({
          error: 'Unauthorized',
          message: 'PIN salah'
        });
      }

      // 2. Verify account ownership
      const account = await serviceLayer.getAccountByNumber(account_number);
      if (account.m_customer_id !== customer_id) {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'You do not own this account'
        });
      }

      // 2. Credit account
      await serviceLayer.creditAccount(account_number, amount);

      // 3. Record transaction
      const transaction = await serviceLayer.createTransaction({
        m_customer_id: customer_id,
        transaction_type: 'DP',
        transaction_amount: amount,
        to_account_number: account_number,
        status: 'SUCCESS',
        description: 'Setor Tunai'
      });

      // 4. Get new balance
      const newBalance = await serviceLayer.getAccountBalance(account_number);

      res.json({
        status: 'success',
        message: 'Deposit successful',
        transaction: {
          id: transaction.id,
          type: 'Deposit',
          amount: amount,
          account: account_number,
          date: transaction.transaction_date || transaction.created_at,
          new_balance: newBalance.available_balance
        }
      });

    } catch (error) {
      console.error('Deposit error:', error);
      res.status(error.status || 500).json({
        error: 'Deposit Failed',
        message: error.message || 'Unable to complete deposit'
      });
    }
  }
);

// ===== Get Transaction History =====

router.get('/history', async (req, res) => {
  try {
    const customer_id = req.user.customer_id;
    const { skip = 0, limit = 50 } = req.query;

    // Get transactions from service layer
    const transactions = await serviceLayer.getTransactionsByCustomer(
      customer_id,
      parseInt(skip),
      parseInt(limit)
    );

    // Format response
    const formattedTransactions = transactions.map(txn => ({
      id: txn.id,
      type: txn.transaction_type === 'TR' ? 'Transfer' : 
            txn.transaction_type === 'WD' ? 'Withdrawal' : 'Deposit',
      amount: txn.transaction_amount,
      from_account: txn.from_account_number,
      to_account: txn.to_account_number,
      status: txn.status,
      description: txn.description,
      date: txn.transaction_date || txn.created_at
    }));

    res.json({
      status: 'success',
      count: formattedTransactions.length,
      transactions: formattedTransactions
    });

  } catch (error) {
    console.error('Get history error:', error);
    res.status(error.status || 500).json({
      error: 'Failed to Get History',
      message: error.message || 'Unable to retrieve transaction history'
    });
  }
});

// ===== Get Transaction Detail =====

router.get('/detail/:transactionId', async (req, res) => {
  try {
    const { transactionId } = req.params;

    // Get transaction from service layer
    const transaction = await serviceLayer.getTransactionById(transactionId);

    // Verify ownership (customer_id harus match)
    if (transaction.m_customer_id !== req.user.customer_id) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have permission to view this transaction'
      });
    }

    res.json({
      status: 'success',
      transaction: {
        id: transaction.id,
        type: transaction.transaction_type === 'TR' ? 'Transfer' : 
              transaction.transaction_type === 'WD' ? 'Withdrawal' : 'Deposit',
        amount: transaction.transaction_amount,
        from_account: transaction.from_account_number,
        to_account: transaction.to_account_number,
        status: transaction.status,
        description: transaction.description,
        date: transaction.transaction_date || transaction.created_at
      }
    });

  } catch (error) {
    console.error('Get transaction detail error:', error);
    res.status(error.status || 500).json({
      error: 'Failed to Get Transaction',
      message: error.message || 'Unable to retrieve transaction details'
    });
  }
});

module.exports = router;
