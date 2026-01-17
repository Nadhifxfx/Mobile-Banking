# BANK SAE Service Layer

Service Layer adalah **REST API internal** untuk operasi database pada proyek BANK SAE. Komponen ini dipanggil oleh **Middleware (Node.js/Express)** dan **tidak ditujukan untuk diakses langsung oleh Mobile App**.

**Default:** berjalan di port **8001** dan menggunakan **SQLite** agar mudah dipakai untuk demo.

---

## 🏗️ Arsitektur

```
Mobile App (Flutter)
  -> Middleware (Express, port 8000)
    -> Service Layer (FastAPI, port 8001)
      -> Database (SQLite/PostgreSQL)
```

Struktur internal service layer:

```
service/
├── controllers/   # HTTP endpoints (FastAPI routers)
├── services/      # business logic
├── repository/    # akses data (SQLAlchemy)
└── db/            # konfigurasi DB + models
```

---

## 📋 Prasyarat

- Python 3.10+
- pip

> PostgreSQL **opsional** (hanya jika ingin mengganti SQLite dengan DATABASE_URL).

---

## 🗄️ Database

### Default (rekomendasi untuk demo)
- **SQLite** dengan default `DATABASE_URL=sqlite:///./ebanking.db`.
- Tabel akan dibuat otomatis saat service start.

### Opsi produksi / advanced
Kamu bisa pakai PostgreSQL dengan mengatur env var `DATABASE_URL`, contoh:

```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/ebanking
```

---

## 🚀 Menjalankan service (Windows)

### 1) Install dependencies

```powershell
cd service
pip install -r requirements.txt
```

### 2) (Opsional) konfigurasi env

Jika ada file `.env`, `python-dotenv` akan membacanya otomatis. Minimal yang biasa di-set:

```env
DATABASE_URL=sqlite:///./ebanking.db
```

### 3) Jalankan

Mode development (auto reload):

```powershell
python main.py
```

Atau jalankan langsung via uvicorn:

```powershell
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

---

## 📚 Dokumentasi API

- Swagger UI: http://localhost:8001/docs
- ReDoc: http://localhost:8001/redoc

Health check:
- http://localhost:8001/health

---

## 🔌 Endpoint (sesuai implementasi saat ini)

> Semua endpoint service layer diawali prefix `/service/*`.

### Customer

| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/service/customer` | Register customer (PIN harus sudah di-hash dari middleware) |
| GET | `/service/customer/username/{username}` | Get customer by username (untuk login; mengandung `customer_pin`) |
| GET | `/service/customer/{customer_id}` | Get customer by id |
| GET | `/service/customer?skip=0&limit=100` | List customer (pagination) |
| PUT | `/service/customer/{customer_id}` | Update customer (failed attempts, lock, profile, dll) |
| POST | `/service/customer/{customer_id}/failed-login` | Increment failed login + lock jika >= 3 |
| POST | `/service/customer/{customer_id}/successful-login` | Reset failed login + update last_login |
| GET | `/service/customer/{customer_id}/check-locked` | Cek status locked |
| POST | `/service/customer/{customer_id}/unlock` | Unlock account + reset counter |

### Account

| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/service/account` | Create portfolio account |
| GET | `/service/account/customer/{customer_id}?active_only=true` | List account per customer |
| GET | `/service/account/number/{account_number}` | Get account by number |
| GET | `/service/account/{account_id}` | Get account by id |
| GET | `/service/account/{account_number}/balance` | Get balance (clear + available) |
| PUT | `/service/account/{account_number}/balance` | Update balance |
| POST | `/service/account/{account_number}/debit?amount=...` | Debit saldo |
| POST | `/service/account/{account_number}/credit?amount=...` | Credit saldo |
| GET | `/service/account/{account_number}/check-balance?amount=...` | Cek saldo cukup/tidak |
| PUT | `/service/account/{account_id}` | Update account (mis. nama, status aktif) |
| POST | `/service/account/{account_number}/deactivate` | Deactivate (soft delete) |

### Transaction

| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/service/transaction` | Insert transaksi |
| GET | `/service/transaction/customer/{customer_id}?skip=0&limit=100` | List transaksi per customer |
| GET | `/service/transaction/account/{account_number}?skip=0&limit=100` | List transaksi per rekening |
| GET | `/service/transaction/{transaction_id}` | Detail transaksi |
| GET | `/service/transaction/customer/{customer_id}/by-date?start_date=...&end_date=...` | Filter tanggal |
| GET | `/service/transaction/customer/{customer_id}/by-type/{transaction_type}` | Filter tipe (TR/WD/DP) |
| GET | `/service/transaction/customer/{customer_id}/by-status/{status}` | Filter status |
| GET | `/service/transaction/customer/{customer_id}/recent?days=30` | Transaksi terbaru |
| PUT | `/service/transaction/{transaction_id}/status` | Update status transaksi |

---

## 🗄️ Database schema (ringkas)

Tabel utama (sesuai SQLAlchemy models):
- `m_customer`: data nasabah + failed login + lock
- `m_portfolio_account`: rekening + saldo
- `t_transaction`: histori transaksi

---

## 🔄 Contoh alur (relevan ke arsitektur)

### Cek saldo (Mobile → Middleware → Service)
1. Mobile memanggil middleware: `GET /api/v1/account/balance` (dengan JWT).
2. Middleware decode JWT → ambil `customer_id`.
3. Middleware memanggil service layer: `GET /service/account/customer/{customer_id}`.
4. Service layer query DB → balikan list akun.
5. Middleware agregasi dan balikan ke mobile.

---

## 🔐 Catatan keamanan

- Service Layer **tidak** melakukan autentikasi/otorisasi.
- Semua security (JWT, validasi akses, aturan bisnis) ada di Middleware.
- Field `customer_pin` yang masuk ke service layer **harus sudah hashed** oleh middleware.

