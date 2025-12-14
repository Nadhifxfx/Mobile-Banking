/**
 * Mobile Banking Middleware Server
 * Port: 8000
 * 
 * Handles authentication, business logic, and routes requests to Service Layer
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

// Import routes
const authRoutes = require('./routes/auth');
const accountRoutes = require('./routes/account');
const transactionRoutes = require('./routes/transaction');
const customerRoutes = require('./routes/customer');

const app = express();
const PORT = process.env.PORT || 8000;

// ===== Middleware Configuration =====

// Security headers
app.use(helmet());

// CORS - Allow mobile app to access
app.use(cors({
  origin: '*', // In production, specify mobile app URL
  credentials: true
}));

// Body parsers
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// ===== Routes =====

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'Mobile Banking Middleware',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    service_layer: process.env.SERVICE_LAYER_URL
  });
});

// API routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/account', accountRoutes);
app.use('/api/v1/transaction', transactionRoutes);
app.use('/api/v1/customer', customerRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Mobile Banking Middleware API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      auth: '/api/v1/auth/*',
      account: '/api/v1/account/*',
      transaction: '/api/v1/transaction/*',
      customer: '/api/v1/customer/*'
    },
    documentation: 'See README.md for API documentation'
  });
});

// ===== Error Handling =====

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.url} not found`,
    timestamp: new Date().toISOString()
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  res.status(err.status || 500).json({
    error: err.name || 'Internal Server Error',
    message: err.message || 'Something went wrong',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// ===== Start Server =====

app.listen(PORT, () => {
  console.log('🚀 Mobile Banking Middleware Server');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`📡 Server running on: http://localhost:${PORT}`);
  console.log(`🔗 Service Layer: ${process.env.SERVICE_LAYER_URL}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ Middleware ready to accept requests');
  console.log('📱 Mobile apps can now connect!');
});

module.exports = app;
