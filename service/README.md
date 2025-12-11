# E-Banking Service Layer

REST API Service untuk operasi database E-Banking System. Service layer ini berinteraksi langsung dengan PostgreSQL database dan menyediakan endpoint yang digunakan oleh Middleware layer.

## 🏗 Arsitektur

```
Service Layer (Port 8001)
├── Controllers/     → REST API Endpoints
├── Services/        → Business Logic
├── Repository/      → Data Access Layer
└── DB/             → Database Models & Connection
```

## 📋 Prasyarat

- Python 3.10+
- PostgreSQL 14+
- pip (Python package manager)

## 🚀 Installation

### 1. Setup Virtual Environment

```bash
cd service
python -m venv venv
```

**Windows:**
```bash
venv\Scripts\activate
```

**Linux/Mac:**
```bash
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Environment

```bash
# Copy .env.example ke .env
cp .env.example .env
```

Edit `.env` dan sesuaikan konfigurasi database:
```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/ebanking
SERVICE_PORT=8001
```

### 4. Initialize Database

Database akan otomatis dibuat saat aplikasi pertama kali dijalankan. Pastikan PostgreSQL sudah running dan database `ebanking` sudah dibuat:

```sql
CREATE DATABASE ebanking;
```

## 🏃 Running the Service

### Development Mode (dengan auto-reload)

```bash
python main.py
```

Atau menggunakan uvicorn:

```bash
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

### Production Mode

```bash
uvicorn main:app --host 0.0.0.0 --port 8001 --workers 4
```

Service akan berjalan di: **http://localhost:8001**

## 📚 API Documentation

Setelah service running, akses dokumentasi API di:

- **Swagger UI**: http://localhost:8001/docs
- **ReDoc**: http://localhost:8001/redoc

## 🔌 API Endpoints

### Customer Service

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/service/customer` | Register customer baru |
| GET | `/service/customer/username/{username}` | Get customer by username (untuk login) |
| GET | `/service/customer/{id}` | Get customer by ID |
| PUT | `/service/customer/{id}` | Update customer data |
| POST | `/service/customer/{id}/failed-login` | Handle failed login |
| POST | `/service/customer/{id}/successful-login` | Handle successful login |

### Account Service

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/service/account` | Create portfolio account |
| GET | `/service/account/customer/{id}` | Get accounts by customer ID |
| GET | `/service/account/number/{account_number}` | Get account by number |
| PUT | `/service/account/{account_number}/balance` | Update balance |
| POST | `/service/account/{account_number}/debit` | Debit account |
| POST | `/service/account/{account_number}/credit` | Credit account |

### Transaction Service

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/service/transaction` | Insert transaction |
| GET | `/service/transaction/customer/{id}` | Get transactions by customer |
| GET | `/service/transaction/account/{account_number}` | Get transactions by account |
| GET | `/service/transaction/{id}` | Get transaction by ID |
| PUT | `/service/transaction/{id}/status` | Update transaction status |

## 🗄 Database Schema

### m_customer
- id, customer_name, customer_username, customer_pin
- customer_email, customer_phone, cif_number
- failed_login_attempts, is_locked, last_login
- created_at, updated_at

### m_portfolio_account
- id, m_customer_id, account_number, account_name
- account_type, currency_code
- clear_balance, available_balance
- is_active, created_at, updated_at

### t_transaction
- id, m_customer_id, transaction_type
- transaction_amount, from_account_number, to_account_number
- status, description
- transaction_date, created_at

## 🔄 Flow Example

### Cek Saldo dari Mobile → Middleware → Service

1. **Mobile** → Kirim request ke Middleware:
   ```
   GET /api/v1/balance
   Authorization: Bearer <token>
   ```

2. **Middleware** → Decode token, dapat customer_id, panggil Service:
   ```
   GET /service/account/customer/12
   ```

3. **Service** → Query database:
   ```sql
   SELECT * FROM m_portfolio_account WHERE m_customer_id = 12;
   ```

4. **Service** → Return JSON ke Middleware

5. **Middleware** → Format dan kirim ke Mobile

## 🧪 Testing

```bash
# Install testing dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest
```

## 📦 Project Structure

```
service/
│
├── main.py                    # Entry point aplikasi
├── requirements.txt           # Python dependencies
├── .env.example              # Environment template
├── .gitignore                # Git ignore rules
├── README.md                 # This file
│
├── controllers/              # REST API Endpoints
│   ├── customer_controller.py
│   ├── account_controller.py
│   └── transaction_controller.py
│
├── services/                 # Business Logic Layer
│   ├── customer_service.py
│   ├── account_service.py
│   └── transaction_service.py
│
├── repository/               # Data Access Layer
│   ├── customer_repository.py
│   ├── account_repository.py
│   └── transaction_repository.py
│
└── db/                       # Database Configuration
    ├── database.py           # Connection & session
    └── models.py             # SQLAlchemy models
```

## 🔐 Security Notes

- Service Layer **TIDAK** melakukan autentikasi
- Service Layer **TIDAK** melakukan otorisasi
- Service Layer hanya fokus pada CRUD database
- Semua security logic ada di Middleware layer
- PIN yang diterima harus sudah dalam bentuk HASHED

## 🛠 Development Guidelines

1. **Stateless**: Service tidak menyimpan session
2. **Clean Separation**: Controller → Service → Repository
3. **Reusable**: Function dapat dipanggil berkali-kali
4. **Validation**: Minimal validation (username/email unique)
5. **Error Handling**: Gunakan HTTPException dengan status code yang tepat

## 📝 License

E-Banking Service Layer - Internal Project

---

**Port**: 8001  
**Database**: PostgreSQL  
**Framework**: FastAPI + SQLAlchemy
