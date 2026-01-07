# 🏦 Sistem Mobile Banking (SAE BANK)
=======

**Last Updated:** 7 Januari 2026

Repositori ini berisi contoh **sistem Mobile Banking end-to-end** dengan arsitektur 3 lapis:

1. **Mobile App** (Flutter) — aplikasi yang dipakai user.
2. **Middleware** (Node.js + Express) — “gerbang” API: autentikasi, validasi, aturan bisnis.
3. **Service Layer** (Python FastAPI) — layanan yang langsung akses database (CRUD).

Tujuan proyek ini: memudahkan belajar alur aplikasi perbankan sederhana (login, saldo, transfer, tarik/setor, profil, histori) dengan pemisahan tugas yang jelas antar layer.

---

## 📌 Isi Dokumen

- [Gambaran Singkat (untuk orang awam)](#-gambaran-singkat-untuk-orang-awam)
- [Fitur Utama](#-fitur-utama)
- [Arsitektur & Alur Data](#-arsitektur--alur-data)
- [Struktur Proyek](#-struktur-proyek)
- [Cara Menjalankan (Windows)](#-cara-menjalankan-windows)
- [Cara Testing Cepat](#-cara-testing-cepat)
- [Daftar Endpoint API](#-daftar-endpoint-api)
- [Keamanan (Ringkas)](#-keamanan-ringkas)
- [Troubleshooting](#-troubleshooting)
- [Lisensi](#-lisensi)

---

## 🧾 Gambaran Singkat (untuk orang awam)

Bayangkan ada aplikasi “Mobile Banking” yang bisa:

- Login/daftar
- Cek saldo
- Transfer uang
- Tarik tunai / setor tunai
- Lihat histori transaksi

Supaya rapi dan aman, aplikasi ini **tidak langsung** ke database. Aplikasi akan bicara ke **Middleware**, lalu Middleware akan meneruskan ke **Service Layer**, baru Service Layer yang menyentuh database.

Kenapa dibuat begitu?

- **Mobile App** fokus ke tampilan dan pengalaman pengguna.
- **Middleware** fokus ke aturan dan keamanan (mis. token login).
- **Service Layer** fokus ke data (CRUD database).

Catatan penting: proyek ini memakai **mode demo** untuk transaksi.
- PIN disimpan dan dibandingkan dengan bcrypt.
- Beberapa transaksi dibuat **auto-approved** (untuk demo), jadi tidak ada konfirmasi PIN kedua saat transfer/tarik/setor.

---

## 🎯 Fitur Utama

### ✅ Fitur Aplikasi

- **Autentikasi**: Register & login memakai JWT.
- **Dashboard**: tampil saldo dan ringkasan transaksi.
- **Transfer**: alur 3 langkah.
- **Tarik/Setor Tunai**: alur 3 langkah.
- **Profil**: update PIN & data nasabah.
- **Histori**: tersimpan di database, dan ringkasan juga disimpan di local storage aplikasi (SharedPreferences) untuk pengalaman yang lebih cepat.

### 🔐 Fitur Keamanan (tingkat demo)

- JWT Token (expired)
- Hash PIN dengan bcrypt
- Rate limiting di middleware
- CORS + Helmet (security headers)

---

## 🏗️ Arsitektur & Alur Data

### Diagram 3 Lapis

```
┌──────────────────────────────────────────────┐
│                 MOBILE APP                  │
│              Flutter (Web/Desktop)          │
└──────────────────────┬──────────────────────┘
                              │ HTTP
                              │ http://localhost:8000/api/v1/*
                              ▼
┌──────────────────────────────────────────────┐
│                 MIDDLEWARE                  │
│            Node.js + Express (default 8000) │
│ - Auth JWT, validasi, aturan bisnis         │
│ - Panggil service layer via HTTP            │
└──────────────────────┬──────────────────────┘
                              │ HTTP
                              │ http://localhost:8001/service/*
                              ▼
┌──────────────────────────────────────────────┐
│                SERVICE LAYER                │
│              FastAPI (port 8001)            │
│ - CRUD database via SQLAlchemy              │
└──────────────────────┬──────────────────────┘
                              │ SQLite
                              ▼
                      service/db/ebanking.db
```

### Contoh Alur Transfer (bahasa sederhana)

1. User login di Mobile App → dapat **token**.
2. User isi data transfer di Mobile App.
3. Mobile App kirim request ke Middleware:
    - Middleware cek token → valid/invalid.
    - Middleware cek aturan dasar (misalnya kepemilikan rekening, saldo).
4. Middleware panggil Service Layer:
    - debit rekening sumber
    - credit rekening tujuan
    - simpan record transaksi
5. Hasilnya dikembalikan ke Mobile App → UI menampilkan sukses/gagal.

---

## 📁 Struktur Proyek

```
Mobile Banking/
├── mobile/       # Flutter App
├── middleware/   # Node.js API Gateway
└── service/      # Python FastAPI Service Layer
```

Dokumentasi per layer:

- Mobile: [mobile/README.md](mobile/README.md)
- Middleware: [middleware/README.md](middleware/README.md)
- Service: [service/README.md](service/README.md)

---

## 🚀 Cara Menjalankan (Windows)

### Prasyarat

- Flutter SDK (untuk mobile)
- Node.js + npm (untuk middleware)
- Python 3.9+ (untuk service layer)

### 1) Jalankan Service Layer (FastAPI) — Port 8001

PowerShell:

```powershell
cd service
pip install -r requirements.txt
python main.py
```

Swagger (API Docs): http://localhost:8001/docs

### 2) Jalankan Middleware (Express) — Default Port 8000

PowerShell:

```powershell
cd middleware
npm install
npm start
```

Catatan konfigurasi middleware (opsional):

- `PORT` → mengubah port middleware (default `8000`).
- `SERVICE_LAYER_URL` → alamat service layer (default `http://localhost:8001`).

Contoh (PowerShell) jika ingin set env var sementara:

```powershell
$env:PORT = "8000"
$env:SERVICE_LAYER_URL = "http://localhost:8001"
npm start
```

### 3) Jalankan Mobile App (Flutter)

PowerShell:

```powershell
cd mobile
flutter pub get
flutter run -d chrome
```

Jika URL API berubah, sesuaikan di `mobile/lib/utils/constants.dart`:

- `middlewareBaseUrl` → default `http://localhost:8000/api/v1`
- `serviceLayerBaseUrl` → default `http://localhost:8001/service`

---

## 🧪 Cara Testing Cepat

### Demo kredensial (jika database sudah terisi demo)

- Username: `johndoe`
- PIN: `123456`
- Account: `9876543210`

Jika user demo belum ada, silakan register dari aplikasi.

### Alur uji manual

1. Jalankan Service Layer → pastikan `/health` dan `/docs` bisa dibuka.
2. Jalankan Middleware → buka `http://localhost:8000/health`.
3. Jalankan Flutter → coba register/login.
4. Cek saldo di dashboard.
5. Coba transfer / tarik / setor.
6. Cek histori transaksi.

---

## 📚 Daftar Endpoint API

### Middleware API (dipakai oleh Mobile App)

Base URL: `http://localhost:8000/api/v1`

**Auth**

```
POST /auth/login
POST /auth/register
```

**Account**

```
GET  /account/balance
```

**Transaction**

```
POST /transaction/transfer
POST /transaction/withdraw
POST /transaction/deposit
GET  /transaction/history
```

**Customer**

```
GET /customer/profile
PUT /customer/profile
PUT /customer/pin
```

### Service Layer API (dipakai oleh Middleware)

Base URL: `http://localhost:8001/service`

Swagger: http://localhost:8001/docs

**Customer**

```
POST /customer
GET  /customer/{customer_id}
GET  /customer/username/{username}
PUT  /customer/{customer_id}
```

**Account**

```
POST /account
GET  /account/customer/{customer_id}
GET  /account/number/{account_number}
GET  /account/{account_number}/balance
POST /account/{account_number}/debit
POST /account/{account_number}/credit
```

**Transaction**

```
POST /transaction
GET  /transaction/customer/{customer_id}
GET  /transaction/account/{account_number}
```

---

## 🔐 Keamanan (Ringkas)

- **JWT**: Mobile App menyimpan token dan mengirim di header `Authorization: Bearer <token>`.
- **Bcrypt**: PIN disimpan dalam bentuk hash dan dibandingkan saat login.
- **Rate limiting**: membatasi request berlebihan di middleware.

---

## 🐛 Troubleshooting

### 1) Port sudah dipakai

```powershell
netstat -ano | findstr :8000
netstat -ano | findstr :8001
taskkill /PID <PID> /F
```

### 2) Middleware tidak bisa mengakses Service Layer

- Pastikan Service Layer hidup di `http://localhost:8001/health`.
- Jika Service Layer ada di host/port lain, set env: `SERVICE_LAYER_URL` sebelum `npm start`.

### 3) Database error / ingin reset data

Catatan: file database berada di `service/db/ebanking.db`.

```powershell
cd service
Remove-Item -Force .\db\ebanking.db
python main.py
```

### 4) CORS error di browser

- Pastikan middleware yang diakses Flutter sesuai (default `http://localhost:8000`).
- Cek konfigurasi CORS di `middleware/server.js`.

---

## 🛑 Menghentikan Service

- Tekan `Ctrl+C` pada terminal masing-masing.
- Alternatif (PowerShell):

```powershell
taskkill /F /IM python.exe
taskkill /F /IM node.exe
```

---

## 📄 Lisensi

MIT License

---

**SAE BANK! 🏦💰**
