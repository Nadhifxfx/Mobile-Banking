/**
 * Authentication Routes
 * Handles login, register, and token management
 */

const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const serviceLayer = require('../services/serviceLayerClient');
const authenticate = require('../authenticate');

// ===== Register =====

router.post('/register',
  [
    body('customer_name').notEmpty().withMessage('Name is required'),
    body('customer_username').notEmpty().withMessage('Username is required').isLength({ min: 4 }).withMessage('Username must be at least 4 characters'),
    body('customer_pin').notEmpty().withMessage('PIN is required').isLength({ min: 6, max: 6 }).withMessage('PIN must be exactly 6 digits'),
    body('customer_email').isEmail().withMessage('Valid email is required'),
    body('customer_phone').notEmpty().withMessage('Phone number is required'),
    body('cif_number').notEmpty().withMessage('CIF number is required')
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

      const { customer_name, customer_username, customer_pin, customer_email, customer_phone, cif_number } = req.body;

      // Hash PIN
      const hashedPin = await bcrypt.hash(customer_pin, parseInt(process.env.BCRYPT_ROUNDS) || 10);

      // Register customer via service layer
      const customer = await serviceLayer.registerCustomer({
        customer_name,
        customer_username,
        customer_pin: hashedPin,
        customer_email,
        customer_phone,
        cif_number
      });

      // Return success (without PIN)
      res.status(201).json({
        status: 'success',
        message: 'Registration successful',
        customer: {
          id: customer.id,
          name: customer.customer_name,
          username: customer.customer_username,
          email: customer.customer_email,
          phone: customer.customer_phone,
          cif_number: customer.cif_number
        }
      });

    } catch (error) {
      console.error('Register error:', error);
      res.status(error.status || 500).json({
        error: 'Registration Failed',
        message: error.message || 'Unable to register customer'
      });
    }
  }
);

// ===== Login =====

router.post('/login',
  [
    body('username').notEmpty().withMessage('Username is required'),
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

      const { username, pin } = req.body;

      // Get customer from service layer
      const customer = await serviceLayer.getCustomerByUsername(username);

      // Check if account is locked
      const lockStatus = await serviceLayer.checkLocked(customer.id);
      if (lockStatus.is_locked) {
        return res.status(403).json({
          error: 'Account Locked',
          message: 'Your account has been locked due to multiple failed login attempts. Please contact customer service.'
        });
      }

      // Verify PIN
      const isValidPin = await bcrypt.compare(pin, customer.customer_pin);

      if (!isValidPin) {
        // Record failed login
        await serviceLayer.recordFailedLogin(customer.id);

        return res.status(401).json({
          error: 'Invalid Credentials',
          message: 'Invalid username or PIN'
        });
      }

      // Generate JWT token
      const token = jwt.sign(
        {
          customer_id: customer.id,
          username: customer.customer_username,
          cif_number: customer.cif_number
        },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRY || '24h' }
      );

      // Return token and customer info
      res.json({
        status: 'success',
        message: 'Login successful',
        token: token,
        customer: {
          id: customer.id,
          name: customer.customer_name,
          username: customer.customer_username,
          email: customer.customer_email,
          phone: customer.customer_phone,
          cif_number: customer.cif_number
        }
      });

    } catch (error) {
      console.error('Login error:', error);
      res.status(error.status || 500).json({
        error: 'Login Failed',
        message: error.message || 'Unable to login'
      });
    }
  }
);

// ===== Verify Token =====

router.get('/verify', authenticate, async (req, res) => {
  try {
    // If middleware passes, token is valid
    // Get fresh customer data
    const customer = await serviceLayer.getCustomerById(req.user.customer_id);

    res.json({
      status: 'success',
      message: 'Token is valid',
      customer: {
        id: customer.id,
        name: customer.customer_name,
        username: customer.customer_username,
        email: customer.customer_email,
        phone: customer.customer_phone,
        cif_number: customer.cif_number
      }
    });
  } catch (error) {
    console.error('Verify token error:', error);
    res.status(error.status || 500).json({
      error: 'Verification Failed',
      message: error.message || 'Unable to verify token'
    });
  }
});

// ===== Logout =====

router.post('/logout', authenticate, (req, res) => {
  // With JWT, logout is handled client-side by removing token
  // This endpoint is just for confirmation
  res.json({
    status: 'success',
    message: 'Logout successful. Please remove token from your device.'
  });
});

module.exports = router;
