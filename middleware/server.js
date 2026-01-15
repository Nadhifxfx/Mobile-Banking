/**
 * BANK SAE Middleware Server
 * Port: 3000
 * 
 * Handles authentication, business logic, and routes requests to Service Layer
 */

require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

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

// Body parsers with error handling
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Error handler for body parser
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    console.error('Bad JSON:', err);
    return res.status(400).json({ error: 'Invalid JSON' });
  }
  next(err);
});

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
    service: 'BANK SAE Middleware',
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
    message: 'BANK SAE Middleware API',
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

const server = http.createServer(app);

// ===== Realtime (Socket.IO) =====

const io = new Server(server, {
  cors: {
    origin: '*',
    credentials: true
  }
});

// Make io available in request handlers (routes)
app.set('io', io);

// Authenticate socket connections using the same JWT_SECRET
io.use((socket, next) => {
  try {
    const token =
      socket.handshake.auth?.token ||
      socket.handshake.query?.token ||
      socket.handshake.headers?.authorization?.toString()?.replace(/^Bearer\s+/i, '');

    if (!token) {
      return next(new Error('Unauthorized'));
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.data.user = {
      customer_id: decoded.customer_id,
      username: decoded.username,
      cif_number: decoded.cif_number
    };

    next();
  } catch (err) {
    next(new Error('Unauthorized'));
  }
});

io.on('connection', (socket) => {
  const user = socket.data.user;
  if (user?.customer_id != null) {
    socket.join(`customer:${user.customer_id}`);
  }

  socket.on('disconnect', () => {
    // no-op
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 BANK SAE Middleware Server');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`📡 Server running on: http://localhost:${PORT}`);
  console.log(`🔗 Service Layer: ${process.env.SERVICE_LAYER_URL}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ Middleware ready to accept requests');
  console.log('📱 Mobile apps can now connect!');
});

server.on('error', (err) => {
  console.error('❌ Server Error:', err.message);
  if (err.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use`);
  }
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

process.on('SIGINT', () => {
  console.log('\nSIGINT signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

// Don't crash on unhandled errors - just log them
process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  console.error('Stack:', err.stack);
  // Don't exit - keep server running
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  // Don't exit - keep server running
});

module.exports = app;
