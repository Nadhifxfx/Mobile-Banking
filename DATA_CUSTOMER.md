# Data Customer Mobile Banking

Dokumen ini menjelaskan struktur dan detail data customer yang digunakan dalam aplikasi Mobile Banking.

## Ringkasan Data Customer

Data customer mencakup informasi pribadi, kredensial keamanan, dan status akun yang digunakan untuk identifikasi dan otorisasi dalam sistem perbankan.

## Skema Database (Backend Service)

Berdasarkan model database (`service/db/models.py`), struktur tabel `m_customer` adalah sebagai berikut:

| Nama Kolom | Tipe Data | Keterangan | Aturan (Constraints) |
| :--- | :--- | :--- | :--- |
| `id` | Integer | Primary Key | Auto-increment, Index |
| `customer_name` | String(100) | Nama Lengkap | Wajib (Not Null) |
| `customer_username` | String(50) | Username Login | Unik, Wajib, Index |
| `customer_pin` | String(255) | PIN Keamanan | Wajib (Disimpan terenkripsi/hash) |
| `customer_email` | String(100) | Alamat Email | Unik, Wajib |
| `customer_phone` | String(20) | Nomor Telepon | Wajib |
| `cif_number` | String(20) | Customer Identification File | Unik, Wajib |
| `failed_login_attempts` | Integer | Percobaan Login Gagal | Default: 0 |
| `is_locked` | Boolean | Status Blokir Akun | Default: False (Tidak terkunci) |
| `last_login` | DateTime | Waktu Login Terakhir | Nullable |
| `created_at` | DateTime | Waktu Pembuatan | Default: Current Timestamp |
| `updated_at` | DateTime | Waktu Update Terakhir | Default: Current Timestamp |

### Relasi Data
*   **Accounts**: Satu customer dapat memiliki banyak akun portofolio (`PortfolioAccount`) - *One-to-Many*.
*   **Transactions**: Satu customer dapat memiliki banyak riwayat transaksi (`Transaction`) - *One-to-Many*.

## Pengumpulan Data (Mobile App)

Data customer dikumpulkan melalui aplikasi mobile, terutama pada proses Registrasi (`mobile/lib/screens/register_screen.dart`).

### Input Registrasi
Data yang diminta dari pengguna saat pendaftaran:
1.  **Nama Lengkap** (`name`): Nama sesuai identitas.
2.  **Username** (`username`): Nama pengguna untuk login.
3.  **Email** (`email`): Alamat email aktif untuk notifikasi.
4.  **Nomor Telepon** (`phone`): Nomor HP yang bisa dihubungi.
5.  **PIN** (`pin`): 6 digit angka untuk keamanan transaksi (diminta konfirmasi ulang).

### Catatan Tambahan
*   **CIF Number**: Kemungkinan digenerate secara otomatis oleh sistem backend pada saat user baru dibuat, karena tidak diminta pada form registrasi.
*   **Keamanan PIN**: PIN tidak boleh disimpan dalam bentuk plain text. Pada database kolom `customer_pin` memiliki panjang 255 karakter untuk menampung hasil hash.
*   **Validasi**:
    *   Username, Email, dan CIF Number harus unik di seluruh sistem.
    *   PIN harus dikonfirmasi dua kali saat registrasi untuk menghindari kesalahan ketik.

## Data User Dummy (Development/Testing)

Berikut adalah daftar user dummy yang hardcoded dalam aplikasi (`mobile/lib/screens/transfer_screen.dart` dan `dashboard_screen.dart`) yang digunakan untuk keperluan testing transfer dan tampilan :

| Nama Customer | Bank | Nomor Rekening | Keterangan |
| :--- | :--- | :--- | :--- |
| **Nadhif** | SAE BANK | `1234567890` | User Internal / Tujuan Transfer |
| **Baqik** | SAE BANK | `3533834869` | User Internal / Tujuan Transfer |
| **Udin** | SAE BANK | `5898452955` | User Internal / Tujuan Transfer |
| **Rafli** | SAE BANK | `9876543210` | User Internal / Tujuan Transfer |

### User Dummy Bank Lain (Eksternal)

Selain user internal SAE BANK, terdapat juga data dummy untuk bank lain:

| Nama Customer | Bank | Nomor Rekening |
| :--- | :--- | :--- |
| Ahmad BCA | BCA | `1234567890` |
| Siti BCA | BCA | `0987654321` |
| Andi BRI | BRI | `111122223333` |
| Hasan Mandiri | Mandiri | `1000200030004` |
| Rina BNI | BNI | `2222333344445` |

> **Catatan:** Data di atas hanya tersedia di sisi Mobile App sebagai *mock data* untuk mengisi list kontak transfer dan riwayat transaksi saat backend belum menyediakan data real atau saat dalam mode development.
