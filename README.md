*This project has been created as part of the 42 curriculum by ameechan.*

# Inception

## Description

Inception is a system administration project focused on containerization using Docker. The goal is to build a small, secure, production-like web infrastructure composed of multiple isolated services running in Docker containers.

The project includes:

- NGINX with TLS (HTTPS only)
- WordPress with PHP-FPM
- MariaDB database
- A dedicated Docker network
- Persistent volumes stored at `/home/<login>/data/`

Each service runs in its own container and communicates through a custom Docker bridge network. Data persists even if containers are stopped or rebuilt.

---

## Project Architecture

### Services

**NGINX**  
Acts as a reverse proxy and handles HTTPS connections using a self-signed SSL certificate.

**WordPress (PHP-FPM)**  
Provides the web application. Communicates with MariaDB through the internal Docker network.

**MariaDB**  
Stores WordPress data (users, posts, comments, etc.) in a persistent database.

---

## Use of Docker

Docker is used to:

- Isolate services into separate containers
- Ensure reproducibility across systems
- Control networking between services
- Manage persistent storage using volumes
- Automate initialization using Dockerfiles and entrypoints

Each service has its own Dockerfile and is orchestrated via Docker Compose.  
Note that aside for **Alpine** used in each container, NONE of the services use official images from Dockerhub.

---

## Main Design Choices

- Alpine-based images for lightweight containers
- PHP-FPM without embedded web server
- NGINX configured with FastCGI to communicate with WordPress
- MariaDB initialized automatically if the data directory is empty
- Bind-mounted named volumes mapped to `/home/<login>/data/`
- Runtime permission correction for database directory
- HTTPS only (no port 80 exposure)
- Environment validation before container startup

---

## Required Comparisons

### Virtual Machines vs Docker

**Virtual Machines**
- Include a full operating system
- Heavy resource usage
- Slower boot time
- Strong isolation

**Docker**
- Shares host kernel
- Lightweight and faster startup
- Uses container isolation
- More efficient resource usage

Docker was chosen for portability, efficiency, and service isolation.

---

### Secrets vs Environment Variables

**Environment Variables**
- Passed at container runtime
- Visible in `docker inspect`
- Convenient but less secure for sensitive data

**Secrets**
- Stored in files
- Not hardcoded in Dockerfiles
- More secure handling of credentials

This project uses environment variables for configuration and avoids hardcoding sensitive information in images.

---

### Docker Network vs Host Network

**Docker Bridge Network**
- Containers communicate via service names
- Isolated from host network
- Internal traffic not exposed externally

**Host Network**
- Container shares host network stack
- Less isolation
- Not suitable for this project

A custom bridge network is used to ensure proper isolation and service communication.

---

### Docker Volumes vs Bind Mounts

**Docker Volumes**
- Managed by Docker
- Abstract storage location
- Easy to remove via Docker commands

**Bind Mounts**
- Direct mapping to host filesystem
- Full control over storage location
- Permissions must be handled manually

This project uses bind-mounted named volumes mapped to `/home/<login>/data/` to satisfy evaluation requirements and ensure persistent storage.
Docker named volumes' storage location is handled by Docker, therefore we use this hybrid version to define a location where to store the Data on our host machine.  
This acts as a backup of sorts, as even if we run a docker command to remove the volumes, data persists in `/home/<login>/data`
---

## Instructions

### Prerequisites

- Docker
- Docker Compose
- Linux environment (VM)

---

### Initial Setup
```bash
make setup
```
_Prompts for usernames and passwords, creates all relevant secret files and a .env file based on .env.example_

### Build the Project
_Builds Container Images_
```bash
make all
```  

### Start the Containers
_Starts all containers in detached mode._  
```bash
make up
```

### Stop the Containers
_Stops containers while keeping volumes._  
```bash
make down
```

### Remove Volumes
_Stops containers and removes volumes._
```bash
make downv
```

### Full Cleanup/Reset
_Stops containers, removes images, volumes, networks, secrets, .env and `/home/<login>/data/**` directories_
```bash
make nuke
```

---

### Access the Website
Open:
```bash
https://<your-domain>
```

WordPress Admin Panel:
```bash
https://<your-domain>/wp-admin
```
---

### Data Persistence
Database and WordPress files are stored in:
```bash
/home/<login>/data/mariadb
/home/<login>/data/wordpress
```
Data remains intact when containers are stopped and restarted.
---

### Resources
Documentation and References:
- Docker official documentation
- Dockerfile best practices
- NGINX documentation
- PHP-FPM documentation
- WP-CLI documentation
- OpenSSL documentation

### AI Usage
Artificial Intelligence tools were used during the project:
- To clarify Docker networking concepts
- To understand volume behavior and permission handling
- To better understand FastCGI configuration
- To assist in understanding documentation
- To help draft and structure the project documentation
All implementation logic was written, understood, and validated manually.
---
### Additional Documentation
The repository also includes:
- USER_DOC.md — End-user documentation
- DEV_DOC.md — Developer documentation
These documents provide operational and development-level details.
