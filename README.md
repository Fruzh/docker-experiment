# Docker Laravel Setup

Setup Laravel dengan Docker menggunakan Apache dan MySQL.

## Yang Harus Diinstall Dulu

### 1. Install Docker dan Docker Compose
```bash
sudo apt update
sudo apt install -y docker.io docker-compose
```

### 2. Start Docker Service
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

## Setup Project

### 1. Clone Repository
Pergi ke directory root Laravel, kemudian clone repository ini:
```bash
git clone https://github.com/Fruzh/docker-experiment.git .
```

### 2. Konfigurasi Environment
Edit file `.env` sesuai dengan konfigurasi di `docker-compose.yml`:

#### Contoh `.env`:
```env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=nama_database
DB_USERNAME=root
DB_PASSWORD=root
```

**Pastikan konfigurasi `.env` sama persis dengan `docker-compose.yml`**:
- `DB_HOST` harus `mysql` (sesuai service name di docker-compose)
- `DB_DATABASE` sesuaikan dengan nama database yang diinginkan
- `DB_USERNAME` dan `DB_PASSWORD` harus sama dengan environment MySQL di docker-compose

## Kustomisasi Database (Opsional)

Jika ingin mengubah nama database atau password root, lakukan perubahan di **kedua file**:

### 1. Edit `docker-compose.yml`
```yaml
mysql:
  image: mysql:8.0
  container_name: laravel-mysql
  restart: unless-stopped
  environment:
    MYSQL_ROOT_PASSWORD: password_baru    # Ganti password
    MYSQL_DATABASE: database_baru         # Ganti nama database
```

### 2. Edit `.env`
```env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=database_baru      # Sama dengan docker-compose.yml
DB_USERNAME=root
DB_PASSWORD=password_baru      # Sama dengan docker-compose.yml
```

**Penting**: Kedua file harus memiliki nilai yang sama untuk database dan password!

### 3. Jalankan Container
```bash
# Untuk pertama kali atau jika ada perubahan Dockerfile
docker-compose up -d --build

# Untuk run biasa
docker-compose up -d
```

## Informasi Container

- **Laravel App**: Berjalan di port `80`
- **MySQL**: Internal port `3306` 
- **Network**: `laravel-net`
- **Volume**: `mysql-data` untuk persistent database

## Perintah Berguna

```bash
# Melihat status container
docker-compose ps
# atau bisa juga pakai
docker ps

# Melihat logs
docker-compose logs laravel-app

# Masuk ke container Laravel
docker exec -it laravel-apache bash

# Stop container
docker-compose down

# Stop dan hapus volume
docker-compose down -v
```

## Akses Aplikasi

Setelah container berjalan, aplikasi dapat diakses di:

**Lokal**: http://localhost

**Dari mesin lain**: http://[IP_MESIN] 
*Catatan: Harus dalam network yang sama*

Contoh: http://192.168.1.100