# USER_DOC.md - User Documentation

## Overview

This project provides a complete WordPress website infrastructure running in isolated Docker containers. The stack consists of three main services working together to deliver a secure, production-ready WordPress site.

---

## Services Provided

### 1. **NGINX** (Web Server & Reverse Proxy)
- **Purpose**: Entry point for all web traffic
- **Features**:
  - Handles HTTPS connections on port 443
  - SSL/TLS encryption (TLSv1.2 and TLSv1.3 only)
  - Serves static files (images, CSS, JavaScript) directly
  - Forwards dynamic PHP requests to WordPress via FastCGI
- **Security**: Self-signed SSL certificate for encrypted communication

### 2. **WordPress** (Content Management System)
- **Purpose**: Website content and administration interface
- **Features**:
  - Complete WordPress installation with PHP-FPM 8.3
  - Two user accounts (administrator and author roles)
  - Plugin and theme support
  - Media library for uploads
  - Automatic installation via WP-CLI
- **Access**: Admin panel at `https://your_login.42.fr/wp-admin`

### 3. **MariaDB** (Database)
- **Purpose**: Stores all website data
- **Features**:
  - Persistent WordPress database
  - User accounts and permissions
  - Posts, pages, and media metadata
  - Plugin and theme configurations
  - Health check monitoring
- **Security**: Root access restricted to localhost only

### Architecture

```
Internet → NGINX (port 443, HTTPS) → WordPress (PHP-FPM) → MariaDB (Database)
           ↓
      SSL/TLS Encryption
           ↓
      Static Files Served Directly
           ↓
      PHP Files → FastCGI → WordPress Container
```

---

## Getting Started

### Prerequisites

- A Linux system (or VM) with Docker installed
- At least 4GB RAM and 20GB disk space
- Basic terminal knowledge

### First-Time Setup

1. **Navigate to project directory:**
   ```bash
   cd path/to/Inception
   ```

2. **Run the automated setup:**
   ```bash
   make setup
   ```
   
   This interactive process will:
   - Create a `.env` file from `.env.example`
   - Prompt for MariaDB root password (4-20 characters)
   - Prompt for WordPress database user password (4-20 characters)
   - Prompt for WordPress admin credentials
   - Validate that admin username doesn't contain "admin" or "administrator"
   - Create all necessary secret files with proper permissions (600)

3. **Edit environment variables:**
   ```bash
   nano srcs/.env
   ```
   
   **Required variables to customize:**
   ```bash
   LOGIN=your_42_login               # Your 42 username
   
   MYSQL_DATABASE=my_database        # Database name for WordPress
   MYSQL_USER=db_user                # Database username (not admin!)
   
   WP_PAGE_TITLE=My Site Title       # Website title
   WP_ADMIN_USER_ENV=site_manager    # Admin username (cannot contain "admin")
   WP_ADMIN_EMAIL=admin@example.com  # Admin email
   
   WP_USER=regular_user              # Second user username
   WP_USER_EMAIL=user@example.com    # Second user email
   ```
4. **Edit `LOGIN` variable in Makefile to match the login in .env:**
   _set to_ `ameechan` _by default_
   ```bash
   nano Makefile
   ```

5. **Configure domain resolution:**
   ```bash
   sudo nano /etc/hosts
   ```
   
   Add this line (replace `your_login` with your actual 42 login or the login you chose in .env):
   ```
   127.0.0.1    your_login.42.fr
   ```

   **Example:**
   ```
   127.0.0.1    ameechan.42.fr
   ```

---

## Starting the Project

### Build and Start

```bash
make all      # Build Docker images (runs setup automatically)
make up       # Start containers in background
```

**What happens:**
1. Docker images are built for NGINX, WordPress, and MariaDB
2. Containers start in sequence (MariaDB → WordPress → NGINX)
3. MariaDB initializes database (first run only)
4. WordPress installs automatically (first run only)
5. NGINX generates SSL certificate (first run only)

### Verify Services are Running

```bash
make ps
```

Expected output shows all three containers with "Up" status:
```
NAME        IMAGE       STATUS        PORTS
nginx       nginx       Up X seconds  0.0.0.0:443->443/tcp
wordpress   wordpress   Up X seconds  9000/tcp
mariadb     mariadb     Up X seconds  3306/tcp
```

---

## Stopping the Project

### Stop Containers (Preserve Data)

```bash
make down
```

This stops all containers but keeps:
- Database data
- WordPress files
- Uploaded media
- All settings

### Start Again Later

```bash
make up
```

Everything resumes exactly as you left it - no reconfiguration needed.

---

## Accessing the Website

### Main Website

Open your browser and navigate to:
```
https://your_login.42.fr
```

**Note**: You'll see a security warning because the SSL certificate is self-signed. This is expected and safe for local development.

**How to proceed:**
1. Click "Advanced" or "Show Details"
2. Click "Proceed to site" or "Accept Risk and Continue"
3. Your browser will remember this choice for future visits

### WordPress Admin Panel

Access the administration interface at:
```
https://your_login.42.fr/wp-admin
```

**Login credentials:**
- **Username**: The username you entered in `secrets/credentials.txt` (before the colon)
- **Password**: The password you entered in `secrets/credentials.txt` (after the colon)

**Format of credentials file:**
```
admin_username:admin_password
```

---

## Managing Credentials

### Credential Locations

All sensitive credentials are stored in the `secrets/` directory:

| File | Format | Purpose |
|------|--------|---------|
| `db_root_password.txt` | `password` | MariaDB root user (full admin) |
| `db_password.txt` | `password` | WordPress database connection |
| `credentials.txt` | `username:password` | WordPress admin login |
| `second_user.txt` | `password` | WordPress second user (author role) |

**Security**: All secret files have 600 permissions (readable only by you).

### Viewing Credentials

```bash
cat secrets/credentials.txt       # WordPress admin username:password
cat secrets/db_password.txt       # Database password
cat secrets/second_user.txt       # Second user password
```

### Changing Credentials

**⚠️ Warning**: Changing credentials requires rebuilding the entire stack and **deletes all data**.

**Process:**

1. **Backup your data first!**
   ```bash
   make down
   sudo cp -r /home/your_login/data /path/to/backup/
   ```

2. **Complete reset:**
   ```bash
   make nuke    # Removes everything (requires sudo password)
   ```

3. **Reconfigure:**
   ```bash
   make setup   # Enter new credentials
   nano srcs/.env   # Update environment variables
   ```

4. **Rebuild:**
   ```bash
   make all
   make up
   ```

---

## Checking Service Health

### Quick Status Check

```bash
make ps
```

All three services should show "Up" status.

### View Real-Time Logs

**All services:**
```bash
make logs
```

**Specific service:**
```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

Press `Ctrl+C` to exit log viewing.

### Test Database Connection

```bash
docker exec -it mariadb mariadb -u root -p
```

Enter the root password from `secrets/db_root_password.txt`, then:
```sql
SHOW DATABASES;
SELECT User, Host FROM mysql.user;
exit;
```

### Test WordPress Files

```bash
docker exec -it wordpress ls -la /var/www/html
```

Should show WordPress core files including `wp-config.php` and `wp-content/`.

---

## Common Issues

### Domain Configuration

If you see "Connection refused" or "Site not found":

1. **Verify domain is in `/etc/hosts`:**
   ```bash
   cat /etc/hosts | grep your_login.42.fr
   ```
   
   Should show:
   ```
   127.0.0.1    your_login.42.fr
   ```

2. **If missing, add it:**
   ```bash
   sudo nano /etc/hosts
   ```
   Add the line, save, and try accessing the site again.

### Containers Not Starting

Check logs for errors:
```bash
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx
```

Look for error messages that indicate what went wrong.

### SSL Certificate Warning

This is **expected behavior** for self-signed certificates. You must manually accept the certificate in your browser:
- Click "Advanced" or similar
- Click "Proceed" or "Accept Risk"

For production use, you would use a real SSL certificate from Let's Encrypt or a Certificate Authority.

---

## Complete Reset

If you need to start completely fresh:

```bash
make nuke
```

**⚠️ Warning**: This command:
- Stops all containers
- Removes all images
- Removes all volumes
- Removes all networks
- Deletes `/home/your_login/data/` directories
- Deletes all secret files
- Deletes `.env` file

**You will lose all WordPress posts, media, and database content!**

After `make nuke`, run `make setup` to reconfigure from scratch.

---

## Quick Reference

| Task | Command |
|------|---------|
| **Initial setup** | `make setup` |
| **Build images** | `make all` |
| **Start containers** | `make up` |
| **Stop containers** | `make down` |
| **View status** | `make ps` |
| **View logs** | `make logs` |
| **Access admin panel** | `https://your_login.42.fr/wp-admin` |
| **Complete reset** | `make nuke` |
| **Database shell** | `docker exec -it mariadb <name_of_database> -u root -p` |
| **View credentials** | `cat secrets/credentials.txt` |

---

## Support Resources

For more information, consult:

- **WordPress Documentation**: https://wordpress.org/documentation/
- **Docker Documentation**: https://docs.docker.com/
- **MariaDB Documentation**: https://mariadb.org/documentation/
- **NGINX Documentation**: https://nginx.org/en/docs/

For project-specific technical details, see `DEV_DOC.md`.
