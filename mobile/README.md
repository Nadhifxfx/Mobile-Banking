# 📱 BANK SAE Mobile App (Flutter)

Mobile App adalah **client** untuk proyek Mini Bank (BANK SAE). Aplikasi ini dipakai oleh **nasabah/user** untuk login, cek saldo, melakukan transaksi, dan melihat riwayat transaksi.

Penting:
- Mobile App **tidak** mengakses database secara langsung.
- Mobile App **hanya** memanggil **Middleware API** (port 8000). Middleware yang meneruskan ke Service Layer (FastAPI, port 8001).

---

## 🎯 Fitur utama

- Autentikasi: **Register** & **Login** (JWT)
- Dashboard: informasi saldo total dan daftar rekening
- Transaksi: **Transfer**, **Tarik Tunai**, **Setor Tunai** (mode demo)
- Riwayat transaksi (History)
- Profil: update PIN (melalui middleware)
- Realtime update (opsional): transaksi baru via **Socket.IO**

---

## 🧩 Arsitektur singkat (role mobile)

```
Flutter (Mobile/Web)  ->  Middleware (Express, :8000)  ->  Service Layer (FastAPI, :8001)  ->  DB
```

Alur request/response umum:

`Mobile App -> Middleware -> Service Layer -> Middleware -> Mobile App`

---

## ✅ Prasyarat

- Flutter SDK (sesuai kebutuhan project)
- Chrome (untuk menjalankan mode web)
- Backend sudah berjalan:
	- Middleware: `http://localhost:8000`
	- Service Layer: `http://localhost:8001`

---

## 🚀 Menjalankan di browser (Chrome)

Jalankan backend dulu:
1. Service Layer (FastAPI) di port 8001
2. Middleware (Express) di port 8000

Kemudian jalankan Flutter:

```powershell
cd mobile
flutter pub get
flutter run -d chrome
```

---

## ⚙️ Konfigurasi host/port backend

Default base URL middleware (untuk web lokal):
- `http://localhost:8000/api/v1`

Pada kode, base URL **tidak hardcode** permanen. Aplikasi memakai `AppSettings` (SharedPreferences) agar host/port dapat diubah saat runtime:
- File: `lib/services/app_settings.dart`
- Builder URL:
	- Middleware: `http(s)://<host>:<port>/api/v1`
	- Service: `http(s)://<host>:<port>/service` (umumnya tidak dipakai langsung oleh UI)

Jika kamu menjalankan di emulator/device (bukan web), ingat `localhost` bisa berbeda konteks.

---

## 🔐 Autentikasi & penyimpanan lokal

- Saat login sukses, Mobile menyimpan:
	- JWT token (key: `jwt_token`)
	- data customer (id, name, username, email, phone, cif)
	- flag login (`is_logged_in`)
- Penyimpanan: `SharedPreferences`

---

## 🔌 Endpoint yang dipakai Mobile (via Middleware)

Mobile memanggil middleware `/api/v1/*` (lihat `lib/services/api_service.dart`), contoh:
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/account/balance`
- `POST /api/v1/transaction/transfer`
- `POST /api/v1/transaction/withdraw`
- `POST /api/v1/transaction/deposit`
- `GET /api/v1/transaction/history`
- `PUT /api/v1/customer/pin`

---

## ⚡ Realtime transaksi (Socket.IO)

Aplikasi dapat menerima event transaksi baru untuk update UI cepat.

- Client connect ke host middleware dengan auth token:
	- File: `lib/services/realtime_service.dart`
- Event yang didengar:
	- `transaction:new`

Catatan: realtime bersifat pelengkap; sumber data utama tetap bisa di-refresh via endpoint history.

---

## 🧭 Layar utama (screens)

- `LoginScreen`
- `RegisterScreen`
- `DashboardScreen` (saldo + transaksi terbaru)
- `TransferScreen`
- `DepositScreen`
- `WithdrawScreen`
- `HistoryScreen`
- `ProfileScreen`

---

## 🧪 Data demo

Untuk simulasi rekening tujuan/contacts (dummy), lihat dokumen root project:
- `../DATA_CUSTOMER.md`

