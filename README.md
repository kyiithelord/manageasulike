# Odoo Docker & Kubernetes Deployment (Multi‑Version)

This repository contains a complete Docker and Kubernetes setup for deploying Odoo with high availability, auto-scaling, and automated backups. It supports multiple Odoo versions for both local development and production deployment.

## 🏗️ Architecture Overview

### System Components

- **Docker**: Custom Odoo image (version set via `.env`) with your business modules
- **Kubernetes**: Orchestrates the entire application stack (production)
- **PostgreSQL 15**: Database with persistent storage
- **Auto-scaling**: Horizontal Pod Autoscaler (HPA) based on CPU/memory
- **Load Balancing**: Kubernetes services distribute traffic
- **Ingress**: External access with SSL termination
- **Backup System**: Automated database and file-store backups
- **Monitoring**: Prometheus metrics and alerting

### Architecture Diagrams

#### Local Development Architecture
```
Browser → localhost:8069 → Docker Compose → Odoo Container
                                    ↓
                              PostgreSQL Container
                                    ↓
                              Docker Volumes
```

#### Production Kubernetes Architecture
```
Internet → Ingress Controller → Odoo Service → Odoo Pods (2-10 instances)
                                    ↓
                              PostgreSQL Service → PostgreSQL Pod
                                    ↓
                              Persistent Volumes
                                    ↓
                              Backup System → S3/Storage
```

## 📁 Project Structure

```
odooS/
├── Dockerfile                 # Custom Odoo image (version via build arg)
├── docker-compose.yml         # Local development setup
├── env.example                # Example environment file (copy to .env)
├── addons/                    # Custom Odoo modules (PUT YOUR CODE HERE)
├── config/
│   └── odoo.conf             # Odoo configuration
├── k8s/                      # Kubernetes manifests
│   ├── namespace.yaml        # Namespace definition
│   ├── configmap.yaml        # Odoo configuration
│   ├── secrets.yaml          # Sensitive data
│   ├── postgres.yaml         # PostgreSQL deployment
│   ├── odoo.yaml             # Odoo deployment
│   ├── hpa.yaml              # Auto-scaling configuration
│   ├── ingress.yaml          # External access
│   ├── backup-cronjob.yaml   # Backup automation
│   └── monitoring.yaml       # Monitoring and alerts
├── backup/
│   └── backup-script.sh      # Backup script
├── scripts/
│   ├── build-and-push.sh     # Build and push Docker image
│   ├── deploy.sh             # Deploy to Kubernetes
│   └── cleanup.sh            # Cleanup deployment
└── README.md                 # This file
```

## 🚀 Quick Start

### Multi‑Version Support (Set Odoo/Postgres versions)

1. Create your `.env` from the example:
   ```bash
   cp env.example .env
   ```
2. Edit `.env` to choose versions and ports:
   ```ini
   ODOO_VERSION=18        # e.g., 16, 17, 18
   POSTGRES_VERSION=15    # e.g., 13, 14, 15
   ODOO_HOST_PORT=8069
   POSTGRES_HOST_PORT=5433
   POSTGRES_PASSWORD=odoo
   ```
3. The compose file and Dockerfile will automatically use these values.

### Prerequisites

#### For Local Development
- **Docker**: Version 20.10+ (with Docker Compose V2)
- **Git**: For cloning the repository
- **Web Browser**: For accessing Odoo interface

#### For Production Deployment
- **Docker**: Version 20.10+
- **Kubernetes**: Cluster (minikube, GKE, EKS, AKS, etc.)
- **kubectl**: Configured for your cluster
- **Docker Registry**: Access (optional for production)

### 1. Local Development Setup

#### Step 1: Clone and Setup
```bash
# Clone the repository
git clone <your-repo-url>
cd odooS

# Verify Docker is running
docker --version
docker compose version
```

#### Step 2: Start the Development Environment
```bash
# Start all services
docker compose up -d

# Check if containers are running
docker compose ps

# View logs (optional)
docker compose logs odoo
```

#### Step 3: Access Odoo
- **URL**: `http://localhost:8069/odoo`
- **Default Credentials**: 
  - Username: `admin`
  - Password: `admin`

#### Step 4: Database Initialization (if needed)
If you encounter database issues, initialize the base module:
```bash
# Stop containers
docker compose down

# Initialize database
docker compose run --rm odoo odoo -i base -d odoo --stop-after-init

# Start services again
docker compose up -d
```

### 2. Production Kubernetes Deployment

#### Step 1: Build and Push Docker Image
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Build and push to your registry
./scripts/build-and-push.sh your-registry.com v1.0.0
```

#### Step 2: Update Configuration
1. **Update secrets.yaml** with your actual values:
   ```bash
   # Encode your passwords
   echo -n "your-postgres-password" | base64
   echo -n "your-odoo-admin-password" | base64
   ```

2. **Update ingress.yaml** with your domain:
   ```yaml
   - host: odoo.yourdomain.com  # Replace with your domain
   ```

3. **Update odoo.yaml** with your image and version:
   ```yaml
   image: your-registry.com/odoo:18
   ```
   Replace `18` with the Odoo version you selected in `.env`.

#### Step 3: Deploy to Kubernetes
```bash
# Deploy everything
./scripts/deploy.sh production

# Check deployment status
kubectl get pods -n odoo
kubectl get svc -n odoo
kubectl get ingress -n odoo
```

## 🔧 Configuration

### Odoo Configuration

The Odoo configuration is managed through `config/odoo.conf`:

```ini
[options]
admin_passwd = admin
db_host = db
db_port = 5432
db_user = odoo
db_password = odoo
db_name = False
addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons
data_dir = /var/lib/odoo
workers = 2
```

### Docker Compose Configuration

**Services:**
- **odoo**: Custom Odoo container (version from `ODOO_VERSION`)
- **db**: PostgreSQL database (version from `POSTGRES_VERSION`)

**Ports (from `.env`):**
- **Odoo**: `${ODOO_HOST_PORT}` (external) → `8069` (container)
- **PostgreSQL**: `${POSTGRES_HOST_PORT}` (external) → `5432` (container)

**Volumes:**
- **odoo-web-data**: Odoo file storage
- **odoo-db-data**: PostgreSQL data
- **./addons**: Custom modules directory
- **./config**: Configuration files

### Auto-scaling (Production)

The Horizontal Pod Autoscaler (HPA) is configured to:
- **Min replicas**: 2
- **Max replicas**: 10
- **CPU threshold**: 70%
- **Memory threshold**: 80%

### Backup Strategy

Automated backups run daily at 2 AM and include:
- PostgreSQL database dump
- Odoo file-store archive
- S3 upload (configurable)
- Local cleanup (7-day retention)

## 🛠️ Development Workflow

### Adding Custom Modules

1. **Create your module** in the `addons/` directory:
   ```bash
   addons/
   └── my_custom_module/
       ├── __manifest__.py
       ├── models/
       ├── views/
       ├── static/
       └── __init__.py
   ```

2. **Rebuild the container** after adding modules:
   ```bash
   docker compose up -d --build
   ```

3. **Install the module** in Odoo:
   - Go to Apps menu
   - Update Apps List
   - Search for your module
   - Install it

### Development Commands

```bash
# Start development environment
docker compose up -d

# Stop development environment
docker compose down

# Rebuild after code changes
docker compose up -d --build

# View logs
docker compose logs odoo
docker compose logs db

# Access Odoo container shell
docker compose exec odoo bash

# Access database
docker compose exec db psql -U odoo -d odoo

# Check container status
docker compose ps
```

## 📊 Monitoring

### Local Development Monitoring

```bash
# View real-time logs
docker compose logs -f odoo

# Check resource usage
docker stats

# View container details
docker compose ps -a
```

### Production Monitoring

The setup includes Prometheus monitoring for:
- Pod health and availability
- CPU and memory usage
- Database connectivity
- Backup job status

**Useful Commands:**
```bash
# Check all resources
kubectl get all -n odoo

# View logs
kubectl logs -f deployment/odoo -n odoo

# Scale deployment
kubectl scale deployment odoo --replicas=5 -n odoo

# Port forward for testing
kubectl port-forward svc/odoo-service 8069:8069 -n odoo
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using port 8069
netstat -tlnp | grep 8069

# Change port in .env if needed
ports:
  - "8070:8069"  # Or set ODOO_HOST_PORT=8070 in .env
```

#### 2. Database Connection Issues
```bash
# Check database logs
docker compose logs db

# Test database connection
docker compose exec db psql -U odoo -d odoo -c "\l"

# Restart database
docker compose restart db
```

#### 3. Odoo Not Starting
```bash
# Check Odoo logs
docker compose logs odoo

# Initialize database if needed
docker compose run --rm odoo odoo -i base -d odoo --stop-after-init

# Restart services
docker compose down && docker compose up -d
```

#### 4. Module Not Appearing
```bash
# Rebuild container after changing versions or code
docker compose up -d --build

# Check addons path in logs
docker compose logs odoo | grep addons

# Verify module structure
ls -la addons/your_module/
```

#### 5. Permission Issues
```bash
# Fix file permissions
sudo chown -R 1000:1000 ./addons
sudo chown -R 1000:1000 ./config

# Check container user
docker compose exec odoo whoami
```

### Production Issues

#### 1. Pods Not Starting
```bash
kubectl describe pod <pod-name> -n odoo
kubectl logs <pod-name> -n odoo
```

#### 2. Ingress Not Working
```bash
kubectl get ingress -n odoo
kubectl describe ingress odoo-ingress -n odoo
```

## 🔒 Security

### Secrets Management

**Local Development:**
- Passwords stored in `docker-compose.yml` (not for production)
- Use environment variables for sensitive data

**Production:**
- Sensitive data stored in Kubernetes secrets
- Database passwords
- Admin passwords
- AWS credentials (for backups)

### Network Security

- Internal service communication
- SSL termination at ingress
- Network policies (can be added)

## 🧹 Cleanup

### Local Development
```bash
# Stop and remove containers
docker compose down

# Remove volumes (WARNING: deletes all data)
docker compose down -v

# Remove images
docker rmi odoos-odoo
```

### Production
```bash
# Remove entire deployment
./scripts/cleanup.sh
```

**Warning**: This will delete all data. Make sure you have backups!

## 📚 Additional Resources

- [Odoo 18 Documentation](https://www.odoo.com/documentation/18.0/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly (both local and production)
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review Docker and Odoo logs
3. Create an issue in the repository
4. Contact the development team

---

**Note**: This setup is designed for both development and production use. Always test thoroughly in your environment before deploying critical workloads.

## 🎯 Quick Reference

### Essential Commands
```bash
# Start development
docker compose up -d

# Access Odoo
http://localhost:8069/odoo

# Stop development
docker compose down

# Rebuild after changes
docker compose up -d --build

# View logs
docker compose logs odoo
```

### Default Credentials
- **Username**: admin
- **Password**: admin

### Key URLs
- **Odoo Interface**: http://localhost:8069/odoo
- **Database**: localhost:5433 (PostgreSQL)