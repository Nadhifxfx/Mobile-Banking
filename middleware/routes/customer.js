/**
 * Customer Routes
 * Handles profile management
 */

const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcrypt');
const serviceLayer = require('../services/serviceLayerClient');
const authenticate = require('../authenticate');

// All routes require authentication
router.use(authenticate);

// ===== Get Profile =====

router.get('/profile', async (req, res) => {
  try {
    const customer_id = req.user.customer_id;

    // Get customer from service layer
    const customer = await serviceLayer.getCustomerById(customer_id);

    res.json({
      status: 'success',
      customer: {
        id: customer.id,
        name: customer.customer_name,
        username: customer.customer_username,
        email: customer.customer_email,
        phone: customer.customer_phone,
        cif_number: customer.cif_number,
        created_at: customer.created_at
      }
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(error.status || 500).json({
      error: 'Failed to Get Profile',
      message: error.message || 'Unable to retrieve profile'
    });
  }
});

// ===== Update Profile =====

router.put('/profile',
  [
    body('customer_name').optional().notEmpty().withMessage('Name cannot be empty'),
    body('customer_email').optional().isEmail().withMessage('Valid email is required'),
    body('customer_phone').optional().notEmpty().withMessage('Phone cannot be empty')
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
      const { customer_name, customer_email, customer_phone } = req.body;

      // Update customer via service layer
      const updatedCustomer = await serviceLayer.updateCustomer(customer_id, {
        customer_name,
        customer_email,
        customer_phone
      });

      res.json({
        status: 'success',
        message: 'Profile updated successfully',
        customer: {
          id: updatedCustomer.id,
          name: updatedCustomer.customer_name,
          username: updatedCustomer.customer_username,
          email: updatedCustomer.customer_email,
          phone: updatedCustomer.customer_phone,
          cif_number: updatedCustomer.cif_number
        }
      });

    } catch (error) {
      console.error('Update profile error:', error);
      res.status(error.status || 500).json({
        error: 'Failed to Update Profile',
        message: error.message || 'Unable to update profile'
      });
    }
  }
);

// ===== Update/Set PIN =====

router.put('/pin',
  [
    body('old_pin').optional().isLength({ min: 6, max: 6 }).withMessage('Old PIN must be 6 digits'),
    body('new_pin').notEmpty().withMessage('New PIN is required').isLength({ min: 6, max: 6 }).withMessage('New PIN must be 6 digits').isNumeric().withMessage('PIN must be numeric')
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
      const { old_pin, new_pin } = req.body;

      // Get customer
      const customer = await serviceLayer.getCustomerById(customer_id);

      // If customer already has a PIN, verify old PIN
      if (customer.customer_pin) {
        if (!old_pin) {
          return res.status(400).json({
            error: 'Bad Request',
            message: 'Old PIN is required to change PIN'
          });
        }

        const isValidOldPin = await bcrypt.compare(old_pin, customer.customer_pin);
        if (!isValidOldPin) {
          return res.status(401).json({
            error: 'Unauthorized',
            message: 'PIN lama salah'
          });
        }
      }

      // Hash new PIN
      const hashedPin = await bcrypt.hash(new_pin, 10);

      // Update PIN via service layer
      const updatedCustomer = await serviceLayer.updateCustomer(customer_id, {
        customer_pin: hashedPin
      });

      res.json({
        status: 'success',
        message: customer.customer_pin ? 'PIN berhasil diubah' : 'PIN berhasil diatur'
      });

    } catch (error) {
      console.error('Update PIN error:', error);
      res.status(error.status || 500).json({
        error: 'Failed to Update PIN',
        message: error.message || 'Unable to update PIN'
      });
    }
  }
);

module.exports = router;
