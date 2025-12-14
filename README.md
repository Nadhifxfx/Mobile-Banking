# Mobile Banking System

Sistem Mobile Banking lengkap dengan 3 layer: Service Layer, Middleware, dan Mobile App.

## 🏗️ Arsitektur

```
┌─────────────────┐
│   Mobile App    │  (Cordova - Hybrid App)
│  Port: Browser  │
└────────┬────────┘
         │ HTTP
         ↓
┌─────────────────┐
│   Middleware    │  (Node.js + Express)
│   Port: 8000    │  - JWT Authentication
└────────┬────────┘  - Business Logic
         │ HTTP      - Rate Limiting
         ↓
┌─────────────────┐
│ Service Layer   │  (Python + FastAPI)
│   Port: 8001    │  - Database Operations
└────────┬────────┘  - CRUD APIs
         │
         ↓
    ┌──────────┐
    │ SQLite DB│
    └──────────┘
```

## 📁 Struktur Folder

```
Mobile Banking/
├── service/              # Service Layer (FastAPI)
│   ├── main.py
│   ├── controllers/
│   ├── services/
│   ├── repository/
│   └── db/
├── middleware/           # Middleware (Express)
│   ├── server.js
│   ├── routes/
│   ├── middleware/
│   └── services/
└── mobile/              # Mobile App (Cordova)
    ├── www/
    │   ├── index.html
    │   ├── css/
    │   └── js/
    └── config.xml
```

## 🚀 Quick Start - Jalankan Semua Sekaligus

### Windows PowerShell:
```powershell
.\start-all.ps1
```

### Windows Command Prompt:
```batch
start-all.bat
```

Script akan membuka 3 terminal terpisah:
1. **Service Layer** - Port 8001
2. **Middleware** - Port 8000  
3. **Mobile App** - Browser

## 🔧 Manual Setup (per Layer)

### 1. Service Layer

```bash
cd service
pip install -r requirements.txt
python main.py
```

**Docs:** http://localhost:8001/docs

### 2. Middleware

```bash
cd middleware
npm install
npm start
```

**API:** http://localhost:8000/api

### 3. Mobile App

```bash
cd mobile
npm install
cordova platform add browser
cordova run browser
```

**App:** Otomatis buka di browser

## 📱 Fitur Aplikasi

### ✅ Authentication
- Register nasabah baru
- Login dengan username & PIN
- JWT token management
- Logout

### ✅ Account Management
- View semua rekening
- Check balance per rekening
- Total balance dashboard

### ✅ Transactions
- **Transfer** - Antar rekening
- **Withdraw** - Tarik tunai
- **Deposit** - Setor tunai
- **History** - Riwayat transaksi

### ✅ Profile
- View data nasabah
- CIF Number
- Contact information

## 🧪 Testing

### Postman
Import collection dari `service/Mobile_Banking_Service.postman_collection.json`

### Browser
1. Jalankan semua layer
2. Buka browser ke mobile app
3. Register user baru
4. Login dan test fitur

### Testing Flow:
```
1. Register → john_doe, PIN: 123456
2. Login → Dapat token
3. Dashboard → Lihat balance
4. Transfer → Rp 100,000
5. History → Lihat transaksi
6. Logout
```

## 🔐 Security

- **PIN Hashing**: bcrypt (10 rounds)
- **JWT Token**: 24 jam expiry
- **CORS**: Enabled untuk cross-origin
- **Rate Limiting**: 100 req/15 min
- **Input Validation**: Express-validator

## 🌐 Ports

| Layer         | Port | URL                      |
|---------------|------|--------------------------|
| Service       | 8001 | http://localhost:8001    |
| Middleware    | 8000 | http://localhost:8000    |
| Mobile (Dev)  | Auto | Browser auto-open        |

## 📚 Documentation

- **Service Layer**: [service/README.md](service/README.md)
- **Middleware**: [middleware/README.md](middleware/README.md)
- **Mobile App**: [mobile/README.md](mobile/README.md)
- **Postman Guide**: [service/POSTMAN_GUIDE.md](service/POSTMAN_GUIDE.md)
- **Testing Guide**: [service/TESTING_GUIDE.md](service/TESTING_GUIDE.md)

## 🛑 Stop Services

**PowerShell/CMD**: Tekan `Ctrl+C` di setiap terminal window

atau tutup semua terminal yang dibuka oleh script

## 🐛 Troubleshooting

### Port sudah digunakan
```powershell
# Check port 8001
netstat -ano | findstr :8001

# Check port 8000  
netstat -ano | findstr :8000

# Kill process
taskkill /PID <PID> /F
```

### CORS Error
- Pastikan middleware running
- Check CORS config di middleware/server.js

### Database Error
- Delete `service/ebanking.db`
- Restart service layer (auto-create new DB)

### Token Expired
- Clear browser localStorage
- Login ulang

## 📦 Build Mobile App

### Android APK
```bash
cd mobile
cordova platform add android
cordova build android --release
```

APK location: `mobile/platforms/android/app/build/outputs/apk/`

### iOS (Mac only)
```bash
cd mobile
cordova platform add ios
cordova build ios
```

## 🔄 Development Workflow

1. **Backend Development**: Edit service layer → Test via Postman
2. **Middleware Development**: Edit routes → Test via Postman/cURL
3. **Frontend Development**: Edit mobile/www → Test di browser
4. **Integration Testing**: Jalankan semua layer → Test full flow

## 📊 Database

**File**: `service/ebanking.db` (SQLite)

**Tables**:
- `customer` - Data nasabah
- `account` - Data rekening
- `transaction` - Riwayat transaksi

**Auto-initialize** saat service layer start pertama kali.

## 🎯 Next Features

- [ ] Push notifications
- [ ] Biometric authentication
- [ ] QR code payment
- [ ] Bill payment
- [ ] Virtual card

## 📝 License

MIT License

## 👨‍💻 Support

Untuk pertanyaan atau issue, check documentation di masing-masing folder.

---

**Happy Banking! 🏦💰**
