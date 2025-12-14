# 🔧 Mobile Banking Middleware Layer

Middleware layer untuk Mobile Banking System - Handles authentication, business logic, dan routing ke Service Layer.

## 🏗️ Architecture

```
Mobile App → Middleware (Port 8000) → Service Layer (Port 8001) → Database
```

## 📋 Features

- ✅ **Authentication & Authorization** (JWT)
- ✅ **Business Logic** (Transfer validation, balance checks)
- ✅ **API Gateway** (Single endpoint untuk mobile)
- ✅ **Security** (Helmet, CORS, Rate Limiting)
- ✅ **Error Handling** (Consistent error responses)
- ✅ **Request Validation** (Express Validator)

## 🚀 Installation

### 1. Install Dependencies

```bash
cd middleware
npm install
```

### 2. Environment Setup

Copy `.env.example` ke `.env` dan sesuaikan:

```bash
cp .env.example .env
```

Edit `.env`:
```
PORT=8000
SERVICE_LAYER_URL=http://localhost:8001
JWT_SECRET=your-secret-key-here
JWT_EXPIRY=24h
```

### 3. Start Middleware

**Development mode (with auto-reload):**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

Server akan berjalan di: **http://localhost:8000**

## 📡 API Endpoints

### Authentication

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/v1/auth/register` | Register new customer | ❌ |
| POST | `/api/v1/auth/login` | Login and get JWT token | ❌ |
| GET | `/api/v1/auth/verify` | Verify token validity | ✅ |
| POST | `/api/v1/auth/logout` | Logout (client-side) | ✅ |

### Account Management

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/account/balance` | Get all accounts & total balance | ✅ |
| GET | `/api/v1/account/list` | Get list of accounts | ✅ |
| GET | `/api/v1/account/details/:accountNumber` | Get account details | ✅ |
| POST | `/api/v1/account/create` | Create new account | ✅ |

### Transactions

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/v1/transaction/transfer` | Transfer between accounts | ✅ |
| POST | `/api/v1/transaction/withdraw` | Withdraw cash | ✅ |
| POST | `/api/v1/transaction/deposit` | Deposit cash | ✅ |
| GET | `/api/v1/transaction/history` | Get transaction history | ✅ |
| GET | `/api/v1/transaction/detail/:id` | Get transaction detail | ✅ |

### Customer/Profile

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/customer/profile` | Get customer profile | ✅ |
| PUT | `/api/v1/customer/profile` | Update profile | ✅ |

### Health Check

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/health` | Check middleware status | ❌ |

## 🔐 Authentication Flow

### 1. Register
```bash
POST /api/v1/auth/register
Content-Type: application/json

{
  "customer_name": "John Doe",
  "customer_username": "john123",
  "customer_pin": "123456",
  "customer_email": "john@example.com",
  "customer_phone": "081234567890",
  "cif_number": "CIF001"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Registration successful",
  "customer": {
    "id": 1,
    "name": "John Doe",
    "username": "john123",
    "email": "john@example.com"
  }
}
```

### 2. Login
```bash
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "john123",
  "pin": "123456"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "customer": {
    "id": 1,
    "name": "John Doe",
    "username": "john123"
  }
}
```

### 3. Use Token in Subsequent Requests
```bash
GET /api/v1/account/balance
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 💼 Business Logic Examples

### Transfer Flow

```javascript
// 1. Verify source account ownership
// 2. Verify destination account exists
// 3. Check sufficient balance
// 4. Debit source account
// 5. Credit destination account
// 6. Record transaction
// 7. Return new balance
```

### Withdrawal Flow

```javascript
// 1. Verify account ownership
// 2. Check sufficient balance
// 3. Debit account
// 4. Record transaction
// 5. Return new balance
```

## 🛡️ Security Features

- **JWT Authentication**: Secure token-based auth
- **PIN Hashing**: bcrypt with 10 rounds
- **Rate Limiting**: Max 100 requests per 15 minutes
- **CORS Protection**: Configurable origins
- **Helmet**: Security headers
- **Input Validation**: Express Validator
- **Account Locking**: After 3 failed login attempts

## 📝 Error Handling

Consistent error responses:

```json
{
  "error": "Error Type",
  "message": "Detailed error message",
  "details": [] // Optional validation errors
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (invalid token)
- `403` - Forbidden (account locked, ownership error)
- `404` - Not Found
- `500` - Internal Server Error
- `503` - Service Unavailable (service layer down)

## 🧪 Testing

### Using cURL

**Register:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "customer_name": "Test User",
    "customer_username": "testuser",
    "customer_pin": "123456",
    "customer_email": "test@example.com",
    "customer_phone": "081234567890",
    "cif_number": "CIF999"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "pin": "123456"}'
```

**Get Balance (with token):**
```bash
curl -X GET http://localhost:8000/api/v1/account/balance \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Middleware server port | 8000 |
| NODE_ENV | Environment (development/production) | development |
| SERVICE_LAYER_URL | Service layer URL | http://localhost:8001 |
| JWT_SECRET | Secret key for JWT | (required) |
| JWT_EXPIRY | Token expiration time | 24h |
| BCRYPT_ROUNDS | bcrypt hashing rounds | 10 |
| MAX_LOGIN_ATTEMPTS | Max failed logins before lock | 3 |
| RATE_LIMIT_WINDOW_MS | Rate limit window | 900000 (15 min) |
| RATE_LIMIT_MAX_REQUESTS | Max requests per window | 100 |

## 📂 Project Structure

```
middleware/
├── server.js                  # Main server file
├── package.json              # Dependencies
├── .env                      # Environment config
├── middleware/
│   └── authenticate.js       # JWT authentication middleware
├── routes/
│   ├── auth.js              # Authentication routes
│   ├── account.js           # Account management routes
│   ├── transaction.js       # Transaction routes
│   └── customer.js          # Customer/profile routes
└── services/
    └── serviceLayerClient.js # Service layer HTTP client
```

## 🚨 Prerequisites

- **Node.js** 14+ installed
- **Service Layer** running on port 8001
- **npm** or **yarn** package manager

## 🔗 Related Projects

- **Service Layer**: `../service/` (Port 8001)
- **Mobile App**: `../mobile/` (Cordova)

## 📞 Troubleshooting

### Port already in use
```bash
# Kill process on port 8000 (Windows)
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

### Service Layer connection error
- Pastikan Service Layer running di port 8001
- Check `SERVICE_LAYER_URL` di `.env`
- Test: `curl http://localhost:8001/health`

### JWT token errors
- Check `JWT_SECRET` is set in `.env`
- Verify token format: `Bearer <token>`
- Check token expiration

---

**Status:** ✅ Middleware Ready!  
**Port:** 8000  
**Version:** 1.0.0
