# Jawaban 7 Soal — Proyek Mini Bank (BANK SAE)

**Tanggal:** 16 Januari 2026

Dokumen ini menjawab 7 soal presentasi/penjelasan terkait proyek Mini Bank (BANK SAE) yang ada di workspace ini.

---

## 1) Menggunakan aplikasi sesuai role masing-masing

### A. Role: Nasabah/User (Client Mobile App — Flutter)
Yang dilakukan user di aplikasi:
1. **Register** (opsional) 
   - Isi nama, username, PIN 6 digit, email, dan no HP.
2. **Login**
   - Masukkan username + PIN → aplikasi menyimpan **JWT token** dan data customer ke **SharedPreferences**.
3. **Cek saldo**
   - Masuk Dashboard → aplikasi memanggil endpoint saldo dan menampilkan total saldo + daftar rekening.
4. **Transaksi**
   - **Transfer**: pilih rekening sumber, isi rekening tujuan, nominal, PIN (pada demo PIN tidak diverifikasi ulang), deskripsi.
   - **Tarik Tunai**: pilih rekening, nominal, PIN (demo).
   - **Setor Tunai**: pilih rekening, nominal, PIN (demo).
5. **Riwayat transaksi**
   - Buka menu History → daftar transaksi ditarik dari API.
6. **Realtime update (opsional)**
   - Saat transaksi sukses, dashboard/history dapat menerima event realtime melalui Socket.IO.

Catatan demo:
- Untuk simulasi transfer cepat, proyek ini menyediakan contoh rekening tujuan (dummy/internal) yang terdokumentasi di `DATA_CUSTOMER.md`.

### B. Role: Operator Sistem (Menjalankan Server)
Yang dilakukan operator/developer:
1. Jalankan **Service Layer (FastAPI)** pada port **8001**.
2. Jalankan **Middleware (Node.js/Express)** pada port **8000**.
3. Jalankan **Mobile App (Flutter)** (contoh: `flutter run -d chrome`).
4. Monitoring:
   - Cek endpoint health middleware: `/health`
   - Cek Swagger service layer: `http://localhost:8001/docs`

### C. Role: Pengelola Data/DB (Storage)
Yang dilakukan role “DB/Storage”:
- Menyimpan data customer, rekening, dan transaksi.
- Di implementasi saat ini, database default adalah **SQLite** (mudah untuk demo), dan dapat diarahkan ke **PostgreSQL** melalui env `DATABASE_URL`.

---

## 2) Arsitektur sistem terdistribusi

Proyek ini memakai arsitektur **3-lapis (distributed layers)**:

### A. Client (Role)
**Client:** Flutter App (folder `mobile/`)
- **Role:** Nasabah/User yang berinteraksi melalui UI.
- Tanggung jawab utama:
  - Menampilkan layar login, dashboard saldo, transaksi, dan history.
  - Menyimpan token login & data dasar user di local storage (SharedPreferences).
  - Menangani koneksi realtime (Socket.IO) untuk update transaksi terbaru.

### B. Server/Service (Role)
**Service Layer:** Python FastAPI (folder `service/`)
- **Role:** “Data service” / backend yang **langsung mengakses database**.
- Tanggung jawab utama:
  - CRUD customer, account, transaction.
  - Menyediakan endpoint internal `/service/*` yang dipanggil oleh middleware.
  - Menjalankan inisialisasi DB (create tables) saat startup (SQLAlchemy).

Di service layer, modul logisnya bisa dianggap sebagai service terpisah:
- **Customer service**: data nasabah + status lock.
- **Account service**: rekening dan saldo (debit/credit).
- **Transaction service**: pencatatan transaksi dan history.

### C. Middleware (Role)
**Middleware:** Node.js + Express (folder `middleware/`)
- **Role:** API Gateway + “business rules” + keamanan.
- Tanggung jawab utama:
  - **Autentikasi JWT** untuk semua endpoint bisnis.
  - Validasi request (contoh: amount > 0, format PIN, dll).
  - Orkestrasi transaksi (cek kepemilikan rekening, cek saldo, debit/credit, catat transaksi).
  - Menghubungkan ke service layer via HTTP (axios).
  - Realtime event ke client melalui Socket.IO (event `transaction:new`).

### D. Database / Storage
**Storage utama:** SQL database via SQLAlchemy
- Default konfigurasi: **SQLite** `sqlite:///./ebanking.db` (file DB berada di folder `service/`).
- Opsi produksi: bisa pakai PostgreSQL dengan mengatur `DATABASE_URL`.

**Storage sisi client:** SharedPreferences (Flutter)
- Menyimpan token JWT, data user, dan cache seperti `recent_transactions` dan `saved_contacts`.

### E. Mekanisme komunikasi antar komponen
1. **Client → Middleware:** REST HTTP JSON
   - Base: `http://localhost:8000/api/v1/*`
   - Auth: `Authorization: Bearer <JWT>`
2. **Middleware → Service Layer:** REST HTTP JSON
   - Base: `http://localhost:8001/service/*`
   - Dipanggil memakai axios (timeout dan error mapping).
3. **Service Layer → Database:** SQLAlchemy (ORM) ke SQLite/PostgreSQL.
4. **Realtime (opsional):** WebSocket (Socket.IO)
   - Middleware membuat room `customer:<customer_id>`
   - Client connect dan menerima event `transaction:new` untuk update UI.

---

## 3) Pembagian role dalam sistem

### Role bisnis (aktor)
- **Nasabah/User**
  - Register, login, cek saldo, transaksi, lihat histori, update PIN.
- **Admin/Backoffice (konseptual)**
  - Pada proyek ini **tidak dibuat UI admin khusus**, tetapi konsepnya bisa mencakup: unlock account, monitoring transaksi, manajemen data.

### Role teknis (komponen/servis)
- **Service Autentikasi** (di middleware)
  - Login/register, JWT issuance, validasi token, lock account (memanggil service layer).
- **Service Transaksi** (kombinasi middleware + service layer)
  - Middleware: validasi & orkestrasi alur transfer/deposit/withdraw.
  - Service layer: debit/credit saldo + pencatatan transaksi.
- **Service Account**
  - Mengelola rekening, cek saldo, update balance.
- **Service Customer**
  - Mengelola profil nasabah, status failed-login, lock/unlock.

---

## 4) Fitur utama aplikasi

### A. Login
- UI: `LoginScreen` (Flutter)
- API: `POST /api/v1/auth/login`
- Output: JWT token disimpan (SharedPreferences) dan dipakai di request berikutnya.

### B. Informasi saldo
- UI: Dashboard menampilkan total saldo + list rekening.
- API: `GET /api/v1/account/balance` (butuh JWT)
- Middleware mengambil akun customer dari service layer dan mengagregasi total saldo.

### C. Transaksi (setor / tarik / transfer simulasi)
- **Transfer**
  - API: `POST /api/v1/transaction/transfer`
  - Validasi penting: kepemilikan rekening sumber, rekening tujuan ada, saldo cukup.
  - Demo: field `pin` tetap diminta, tetapi transaksi dibuat **auto-approved**.
- **Tarik Tunai**
  - API: `POST /api/v1/transaction/withdraw`
  - Validasi: kepemilikan rekening, saldo cukup.
- **Setor Tunai**
  - API: `POST /api/v1/transaction/deposit`

### D. Riwayat transaksi
- UI: `HistoryScreen`
- API: `GET /api/v1/transaction/history`
- Ada dukungan realtime: jika ada transaksi baru, History dapat insert event terbaru ke atas list.

---

## 5) Progress pengembangan aplikasi (tahapan)

Ringkasan tahapan yang telah dilalui selama pembuatan:
1. **Analisis kebutuhan & scope demo**
   - Menetapkan fitur inti: login, saldo, transaksi, histori.
   - Menetapkan mode demo: beberapa transaksi auto-approved agar mudah dipresentasikan.
2. **Desain arsitektur 3-lapis**
   - Memisahkan client, middleware, dan service layer agar mudah dikembangkan dan diuji.
3. **Pembuatan Service Layer (FastAPI + SQLAlchemy)**
   - Membuat model DB (`Customer`, `PortfolioAccount`, `Transaction`).
   - Membuat controller, services, repository untuk operasi data.
4. **Pembuatan Middleware (Express API Gateway)**
   - Menambahkan JWT auth, validasi input, rate limiting, dan error handling.
   - Membuat orkestrasi bisnis: cek saldo, transfer, tarik/setor.
5. **Pembuatan Mobile App (Flutter)**
   - Screen utama: login, dashboard, transfer, deposit, withdraw, history, profile.
   - Implementasi API client (HTTP + token storage).
6. **Fitur Realtime (Socket.IO)**
   - Middleware emit event transaksi; client menerima dan update UI.
7. **Dokumentasi & troubleshooting**
   - README root menjelaskan cara run, port, dan alur data.

---

## 6) Kendala yang dihadapi

### A. Kendala teknis
- **Konfigurasi host/port saat menjalankan mobile app**
  - Misalnya berjalan di device/emulator sehingga `localhost` berbeda konteks.
- **Perbedaan tipe data saldo/amount**
  - Service layer menggunakan `Decimal`/`Numeric`, sedangkan client/middleware sering memakai `double/number`.
- **CORS & security headers**
  - Karena client web membutuhkan izin akses lintas origin.

### B. Kendala komunikasi antar service
- **Timeout / service layer tidak merespon**
  - Middleware butuh error mapping yang jelas agar client mendapat pesan yang konsisten.
- **Standarisasi format error antar layer**
  - Error dari FastAPI (`detail`) perlu dipetakan agar mudah dibaca di client.

### C. Kendala sinkronisasi data
- **Update transaksi realtime vs hasil fetch REST**
  - Bisa terjadi duplikasi item histori jika event realtime masuk dan client juga melakukan refresh.
- **Cache local (SharedPreferences) bisa menjadi stale**
  - Misalnya `recent_transactions` tersimpan lama ketika user logout/login ulang.

---

## 7) Solusi yang dilakukan

### A. Solusi kendala teknis
- **Runtime-configurable server host**
  - Mobile app menyediakan `AppSettings` agar host/port dapat diubah (tidak hardcode).
- **Validasi input & pembatasan request**
  - Middleware memakai validator + rate limiting untuk menekan request tidak valid.
- **Pengamanan dasar**
  - JWT untuk autentikasi, bcrypt untuk hashing PIN, dan header keamanan (Helmet).

### B. Solusi komunikasi antar service
- **Service client dengan error handling terpusat**
  - Middleware memakai `serviceLayerClient` (axios) yang memetakan:
    - error response dari service layer
    - error koneksi (503)
  - Tujuannya: client mendapat respons yang konsisten.
- **Health endpoint**
  - Middleware dan service layer menyediakan endpoint `/health` untuk memudahkan pengecekan status.

### C. Solusi sinkronisasi data
- **Realtime untuk pengalaman cepat, REST untuk sumber kebenaran**
  - Realtime menambah “transaksi terbaru”, sementara history tetap bisa di-refresh dari API.
- **Dedup & ordering di dashboard**
  - Di dashboard, transaksi baru di-*upsert* (berdasarkan id) dan diurutkan berdasarkan tanggal agar tidak berantakan/duplikat.

---

### Catatan singkat untuk presentasi
- Sistem ini menunjukkan konsep sistem terdistribusi: UI (client) dipisah dari gateway (middleware) dan data service (service layer), dengan komunikasi REST + realtime.
- Jika dibutuhkan role admin, pengembangan berikutnya bisa menambah modul admin dashboard untuk unlock user, audit transaksi, dan approval.
