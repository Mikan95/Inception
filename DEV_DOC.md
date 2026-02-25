# DEV_DOC.md - Developer Documentation

## Overview

This document provides technical details for developers who want to understand, modify, or extend the Inception project. It covers the complete development workflow, architecture decisions, and implementation details based on the actual codebase.

---

## Project Architecture

### Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Base OS | Alpine Linux | 3.22 | Lightweight container base |
| Web Server | NGINX | Latest (Alpine) | Reverse proxy, SSL termination, static files |
| Application | WordPress | Latest | Content management system |
| PHP Runtime | PHP-FPM | 8.3 | FastCGI process manager for PHP |
| Database | MariaDB | 11.4.8+ | MySQL-compatible database |
| Orchestration | Docker Compose | 2.x | Multi-container management |

### Container Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Host Machine                      │
│  ┌──────────────────────────────────────────────┐  │
│  │      Docker Network: docker-network          │  │
│  │  ┌─────────┐  ┌──────────┐  ┌───────────┐  │  │
│  │  │  NGINX  │  │WordPress │  │  MariaDB  │  │  │
│  │  │ :443    │→ │ :9000    │→ │  :3306    │  │  │
│  │  └────┬────┘  └────┬─────┘  └─────┬─────┘  │  │
│  │       │            │               │         │  │
│  │       ↓            ↓               ↓         │  │
│  │  wordpress-data ←──┴──────────────┘         │  │
│  │  mariadb-data                                │  │
│  └──────────────────────────────────────────────┘  │
│         ↓                     ↓                     │
│  /home/${LOGIN}/data/wordpress                      │
│  /home/${LOGIN}/data/mariadb                        │
└─────────────────────────────────────────────────────┘
```

### Data Flow

1. **Browser** sends HTTPS request to `https://${LOGIN}.42.fr:443`
2. **NGINX** receives request:
   - Terminates SSL/TLS
   - Serves static files (images, CSS, JS) directly
   - Forwards PHP requests to WordPress via FastCGI
3. **WordPress (PHP-FPM)** processes dynamic requests:
   - Executes PHP code
   - Queries MariaDB for data
   - Renders HTML response
4. **MariaDB** provides database services:
   - Stores posts, pages, users, settings
   - Handles queries from WordPress
   - Health check endpoint for container orchestration

---

## Environment Setup from Scratch

### Prerequisites

**System Requirements:**
- Linux distribution (Debian/Ubuntu recommended)
- Docker Engine 20.10+
- Docker Compose v2.0+
- Make utility
- 4GB+ RAM
- 20GB+ free disk space

**Installation (Debian/Ubuntu):**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg make

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
# Log out and log back in for changes to take effect
```

---

### Initial Project Setup

**1. Clone the repository:**
```bash
git clone https://github.com/yourusername/Inception.git
cd Inception
```

**2. Configure domain name:**
```bash
sudo nano /etc/hosts
```
Add line:
```
127.0.0.1    your_login.42.fr
```

**3. Run automated setup:**
```bash
make setup
```

This creates:
- `srcs/.env` from `srcs/.env.example`
- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/credentials.txt` (format: `username:password`)
- `secrets/second_user.txt`
- All secrets with chmod 600 permissions

**4. Edit environment variables:**
```bash
nano srcs/.env
```

Required variables:
```bash
LOGIN=your_42_login                    # Used for domain and data paths (must match username used in /etc/hosts)

MYSQL_DATABASE=database_name
MYSQL_USER=db_username                 # Cannot contain "admin"

WP_PAGE_TITLE=Site Title
WP_ADMIN_USER_ENV=admin_username       # Cannot contain "admin"
WP_ADMIN_EMAIL=admin@example.com
WP_USER=second_username
WP_USER_EMAIL=user@example.com

SSL_CERT=/etc/nginx/ssl/nginx.crt
SSL_KEY=/etc/nginx/ssl/nginx.key
```

---

## Project Structure

```
Inception/
├── Makefile
├── srcs/
│   ├── docker-compose.yml
│   ├── .env                     # Environment variables (gitignored)
│   ├── .env.example            # Template for .env
│   └── requirements/
│       ├── mariadb/
│       │   ├── Dockerfile       # MariaDB container image
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   └── my.cnf      # MariaDB server configuration
│       │   └── tools/
│       │       └── entrypoint.sh  # Database initialization + healthcheck
│       ├── wordpress/
│       │   ├── Dockerfile       # WordPress + PHP-FPM container
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   └── www.conf    # PHP-FPM configuration
│       │   └── tools/
│       │       └── entrypoint.sh  # WordPress installation via WP-CLI
│       └── nginx/
│           ├── Dockerfile       # NGINX container image
│           ├── .dockerignore
│           ├── conf/
│           │   └── nginx.conf.template  # NGINX config with variables
│           └── tools/
│               └── entrypoint.sh  # SSL cert generation, config processing
├── secrets/                     # Secret files (gitignored)
│   ├── .gitkeep
│   ├── README.md
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── credentials.txt          # Format: username:password
│   └── second_user.txt
└── .gitignore                   # Prevents committing secrets
```

---

## Building and Launching

### Makefile Targets

| Target | Purpose | Usage |
|--------|---------|-------|
| `setup` | Create secrets and directories | `make setup` |
| `all` | Build all Docker images (runs setup first) | `make all` |
| `up` | Start containers (use existing images) | `make up` |
| `down` | Stop and remove containers | `make down` |
| `downv` | Stop containers and remove volumes | `make downv` |
| `rebuild` | Force rebuild without cache | `make rebuild` |
| `clean` | Remove secrets and .env | `make clean` |
| `nuke` | Remove everything (images, volumes, data, secrets) | `make nuke` |
| `re` | Full clean + rebuild (clean → all) | `make re` |
| `ps` | Show running containers | `make ps` |
| `volumes` | List Docker volumes | `make volumes` |
| `logs` | Displays logs from all containers | `make logs` |

### Build Process

**Complete build sequence:**
```bash
make nuke      # Clean slate (if needed)
make setup     # Configure secrets and .env
make all       # Build images
make up        # Start containers
```

**Docker Compose commands executed internally:**
```bash
# make all:
docker compose -f srcs/docker-compose.yml build

# make up:
docker compose -f srcs/docker-compose.yml up -d --build --pull never

# make down:
docker compose -f srcs/docker-compose.yml down
```

---

## Container Management

### Manual Docker Commands

**Build specific service:**
```bash
docker compose -f srcs/docker-compose.yml build mariadb
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml build nginx
```

**Start specific service:**
```bash
docker compose -f srcs/docker-compose.yml up -d mariadb
docker compose -f srcs/docker-compose.yml up -d wordpress
docker compose -f srcs/docker-compose.yml up -d nginx
```

**View specific logs:**
```bash
docker compose -f srcs/docker-compose.yml logs -f mariadb
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f nginx
```

**Execute commands in running containers:**
```bash
# MariaDB shell
docker exec -it mariadb sh
docker exec -it mariadb mariadb -u root -p

# WordPress shell
docker exec -it wordpress sh

# WordPress WP-CLI commands
docker exec -it wordpress wp --info --allow-root
docker exec -it wordpress wp user list --allow-root
docker exec -it wordpress wp plugin list --allow-root

# NGINX shell
docker exec -it nginx sh

# Test NGINX config
docker exec -it nginx nginx -t
```

**Inspect container details:**
```bash
docker inspect mariadb
docker inspect wordpress
docker inspect nginx
```

**Container resource usage:**
```bash
docker stats
```

---

## Volume Management

### Named Volumes with Bind Mounts

The project uses Docker named volumes with bind mount configuration to satisfy two requirements:
1. Subject requirement: "use Docker named volumes"
2. Subject requirement: "store data in /home/login/data"

```yaml
volumes:
  mariadb-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${LOGIN}/data/mariadb

  wp-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${LOGIN}/data/wordpress
```

**Why this hybrid approach?**
- Named volumes provide Docker's management capabilities
- Bind mount behavior allows direct host filesystem access
- Data persists even if volumes are removed via Docker commands

### Volume Commands

**List volumes:**
```bash
docker volume ls
```

**Inspect volume:**
```bash
docker volume inspect srcs_mariadb-data
docker volume inspect srcs_wp-data
```

**Remove volumes:**
```bash
docker volume rm srcs_mariadb-data
docker volume rm srcs_wp-data
```

**Volume location on host:**
```bash
ls -la /home/${LOGIN}/data/mariadb
ls -la /home/${LOGIN}/data/wordpress
```

## Data Persistence

**What persists:**
- MariaDB database files
- WordPress core files
- Uploaded media
- Installed plugins
- Installed themes
- `wp-config.php` configuration

### Where is Data Stored?

All persistent data is stored on your host machine at:
```
/home/your_login/data/
├── mariadb/       # Database files
└── wordpress/     # WordPress files, uploads, themes, plugins
```

**This means:**
- Data survives container restarts (`make down` → `make up`)
- Data survives container rebuilds (`make rebuild`)
- Data is only deleted if you run `make nuke` or manually delete these directories

---

## Network Configuration

### Docker Network

**Network definition:**
```yaml
networks:
  docker-network:
    driver: bridge
```

**Network driver: bridge**
- Default Docker network driver
- Containers communicate by service name
- Isolated from host network
- NGINX publishes port 443 to host

**Service name resolution:**
```
wordpress → connects to → mariadb:3306
nginx     → connects to → wordpress:9000
```

Docker's built-in DNS resolves service names to container IPs.

**Network inspection:**
```bash
docker network ls
docker network inspect srcs_docker-network
```

---

## Resources

### Docker
- **Official Documentation**: https://docs.docker.com/
- **Dockerfile Best Practices**: https://docs.docker.com/develop/dev-best-practices/
- **Docker Compose**: https://docs.docker.com/compose/

### NGINX
- **Official Documentation**: https://nginx.org/en/docs/
- **Alpine Requirements**: https://wiki.alpinelinux.org/wiki/Nginx
- **envsubst usage**: https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html
- **FastCGI Parameters**: https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/

### WordPress & PHP
- **WordPress Documentation**: https://wordpress.org/documentation/
- **WP-CLI Installation**: https://wp-cli.org/#installing
- **PHP-FPM Config**: https://www.php.net/manual/en/install.fpm.configuration.php
- **PHP Memory Exhausted**: https://kinsta.com/knowledgebase/wordpress-memory-limit/

### SSL/TLS
- **OpenSSL Self-Signed Certificates**: https://www.openssl.org/docs/man1.1.1/man1/req.html

### Video Tutorials
- **TechnoTim - Build Your Own Dockerfile**: https://www.youtube.com/watch?v=SnSH8Ht3MIc

---

## Command Reference

```bash
# Setup & Build
make setup              # Initial configuration
make all                # Build images
make up                 # Start containers
make down               # Stop containers
make downv              # Stop + remove volumes
make nuke               # Complete reset

# Development
make rebuild            # Force rebuild
docker compose -f srcs/docker-compose.yml logs -f
docker compose -f srcs/docker-compose.yml ps

# Container Access
docker exec -it mariadb sh
docker exec -it wordpress sh
docker exec -it nginx sh

# Debugging
make ps
make logs
docker inspect wordpress
docker stats
```
