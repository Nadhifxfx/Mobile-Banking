# 🔧 BANK SAE Middleware (API Gateway)

Middleware adalah **gerbang API** untuk Mobile App (Flutter). Layer ini menangani:
- Autentikasi (JWT)
- Validasi request
- Aturan bisnis sederhana (cek saldo cukup, kepemilikan rekening)
- Orkestrasi transaksi (debit/credit + pencatatan)
- Routing request ke **Service Layer (FastAPI)**
- Realtime event transaksi via **Socket.IO** (opsional)

---

## 🏗️ Arsitektur

```
Mobile App (Flutter)
  -> Middleware (Express, port 8000)
    -> Service Layer (FastAPI, port 8001)
      -> Database (SQLite/PostgreSQL)
```

Catatan:
- Mobile App **hanya** memanggil endpoint middleware (`/api/v1/*`).
- Endpoint service layer (`/service/*`) bersifat internal.

---

## ✅ Prasyarat

- Node.js (disarankan 16+)
- Service Layer sudah berjalan (default `http://localhost:8001`)

---

## 🚀 Menjalankan middleware

```powershell
cd middleware
npm install
```

Development (auto-reload):

```powershell
npm run dev
```

Production:

```powershell
npm start
```

Server default berjalan di: **http://localhost:8000**

Health check:
- http://localhost:8000/health

---

## 🔧 Konfigurasi (.env)

Gunakan `.env.example` sebagai template.

Variabel yang dipakai:

| Variable | Keterangan | Default |
|----------|------------|---------|
| PORT | Port middleware | 8000 |
| NODE_ENV | `development`/`production` | development |
| SERVICE_LAYER_URL | Base URL service layer | http://localhost:8001 |
| JWT_SECRET | Secret JWT (wajib) | - |
| JWT_EXPIRY | Masa berlaku token | 24h |
| BCRYPT_ROUNDS | Round hashing PIN saat register | 10 |
| RATE_LIMIT_WINDOW_MS | Window rate limit | 900000 (15 menit) |
| RATE_LIMIT_MAX_REQUESTS | Max request per window | 100 |

Catatan tambahan:
- `.env.example` memiliki `MAX_LOGIN_ATTEMPTS`, tetapi pada implementasi saat ini nilai itu **belum dipakai langsung di middleware**. Mekanisme lock account dijalankan lewat service layer (counter `failed_login_attempts` dan flag `is_locked`).

---

## 📡 API untuk Mobile App (endpoint publik)

Base path: `http://localhost:8000/api/v1`

### Auth

| Method | Endpoint | Auth |
|--------|----------|------|
| POST | `/auth/register` | ❌ |
| POST | `/auth/login` | ❌ |
| GET | `/auth/verify` | ✅ |
| POST | `/auth/logout` | ✅ |

### Account

| Method | Endpoint | Auth |
|--------|----------|------|
| GET | `/account/balance` | ✅ |
| GET | `/account/list` | ✅ |
| GET | `/account/details/:accountNumber` | ✅ |
| POST | `/account/create` | ✅ |

### Transaction

| Method | Endpoint | Auth |
|--------|----------|------|
| POST | `/transaction/transfer` | ✅ |
| POST | `/transaction/withdraw` | ✅ |
| POST | `/transaction/deposit` | ✅ |
| GET | `/transaction/history?skip=0&limit=50` | ✅ |
| GET | `/transaction/detail/:transactionId` | ✅ |

### Customer/Profile

| Method | Endpoint | Auth |
|--------|----------|------|
| GET | `/customer/profile` | ✅ |
| PUT | `/customer/profile` | ✅ |
| PUT | `/customer/pin` | ✅ |

### Health

| Method | Endpoint | Auth |
|--------|----------|------|
| GET | `/health` | ❌ |

---

## 🔐 Cara kerja autentikasi

1) Login menghasilkan JWT.
2) Request berikutnya mengirim header:

```
Authorization: Bearer <token>
```

Middleware akan memverifikasi token dan mengisi `req.user` (`customer_id`, `username`, `cif_number`).

---

## 💼 Alur logika transaksi (ringkas)

### Transfer
1. Validasi input (rekening, amount > 0).
2. Verifikasi rekening sumber milik customer.
3. Verifikasi rekening tujuan ada.
4. Cek saldo cukup.
5. Debit rekening sumber (service layer).
6. Credit rekening tujuan (service layer).
7. Insert transaksi (service layer).
8. Kembalikan saldo terbaru.

Catatan demo:
- Field `pin` tetap diminta oleh API, namun beberapa transaksi dibuat **auto-approved** untuk memudahkan demo.

---

## ⚡ Realtime (Socket.IO)

Middleware menyediakan Socket.IO server pada host/port yang sama dengan HTTP.

- Client mengirim auth token saat connect.
- Middleware memasukkan user ke room: `customer:<customer_id>`
- Setelah transaksi sukses, middleware emit event:
  - `transaction:new`

Realtime ini dipakai oleh Mobile App untuk update “transaksi terbaru/history” tanpa refresh manual.

---

## 📂 Struktur folder

```
middleware/
├── server.js
├── authenticate.js
├── routes/
│   ├── auth.js
│   ├── account.js
│   ├── transaction.js
│   └── customer.js
├── services/
│   └── serviceLayerClient.js
├── package.json
├── .env.example
└── README.md
```

---

## 🧩 Related

- Service Layer: `../service/` (FastAPI, port 8001)
- Mobile App: `../mobile/` (Flutter)

