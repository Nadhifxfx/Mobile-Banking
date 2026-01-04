/**
 * Authentication Middleware
 * Verifies JWT tokens from mobile app requests
 */

const jwt = require('jsonwebtoken');

const authenticate = (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'No token provided. Please login first.'
      });
    }

    // Extract token
    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Attach user info to request
    req.user = {
      customer_id: decoded.customer_id,
      username: decoded.username,
      cif_number: decoded.cif_number
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Token Expired',
        message: 'Your session has expired. Please login again.'
      });
    } else if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Invalid Token',
        message: 'Invalid authentication token.'
      });
    } else {
      return res.status(500).json({
        error: 'Authentication Error',
        message: 'Error verifying token.'
      });
    }
  }
};

module.exports = authenticate;
