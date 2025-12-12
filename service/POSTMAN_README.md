# 📮 Quick Reference - Postman Collection

## 📦 Files

- **Mobile_Banking_Service.postman_collection.json** - Main collection
- **Mobile_Banking_Local.postman_environment.json** - Environment variables
- **POSTMAN_GUIDE.md** - Detailed documentation

---

## ⚡ Quick Import

### Import ke Postman:
1. Import → Upload Files → `Mobile_Banking_Service.postman_collection.json`
2. Import → Upload Files → `Mobile_Banking_Local.postman_environment.json`
3. Select environment: **"Mobile Banking - Local"** (dropdown kanan atas)

---

## 🎯 Quick Test

### Test Flow Cepat:
1. **Health Check** → GET `/health`
2. **Register** → POST `/service/customer`
3. **Create Account** → POST `/service/account`
4. **Check Balance** → GET `/service/account/{account_number}/balance`

### Test Scenarios (Recommended):
Gunakan folder `🧪 Test Scenarios` untuk testing terstruktur:
- **Scenario A**: Registration Flow
- **Scenario B**: Transfer Flow
- **Scenario C**: Security Test

---

## 🔧 Environment Variables

| Variable | Default | Auto-Update |
|----------|---------|-------------|
| base_url | http://localhost:8001 | - |
| customer_id | 1 | ✅ |
| account_number | 1234567890 | ✅ |
| transaction_id | 1 | ✅ |

---

## 📚 Documentation

Baca **POSTMAN_GUIDE.md** untuk:
- Struktur collection lengkap
- Cara menggunakan setiap endpoint
- Tips & tricks
- Error handling
- Testing checklist

---

## 🚀 Service Must Be Running

Sebelum testing, pastikan service running:
```powershell
cd service
uvicorn main:app --reload --port 8001
```

Check: http://localhost:8001/health
