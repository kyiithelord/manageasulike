# Odoo 19 Docker & Kubernetes Deployment

This repository contains a complete Docker and Kubernetes setup for deploying Odoo 19 with high availability, auto-scaling, and automated backups.

## 🏗️ Architecture Overview

### Components

- **Docker**: Custom Odoo 19 image with your business modules
- **Kubernetes**: Orchestrates the entire application stack
- **PostgreSQL**: Database with persistent storage
- **Auto-scaling**: Horizontal Pod Autoscaler (HPA) based on CPU/memory
- **Load Balancing**: Kubernetes services distribute traffic
- **Ingress**: External access with SSL termination
- **Backup System**: Automated database and file-store backups
- **Monitoring**: Prometheus metrics and alerting

### High-Level Architecture

```
Internet → Ingress → Odoo Service → Odoo Pods (2-10 instances)
                                    ↓
                              PostgreSQL Service → PostgreSQL Pod
                                    ↓
                              Persistent Volume
```

## 📁 Project Structure

```
odooS/
├── Dockerfile                 # Custom Odoo 19 image
├── docker-compose.yml         # Local development setup
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

### Prerequisites

- Docker and Docker Compose
- Kubernetes cluster (minikube, GKE, EKS, AKS, etc.)
- kubectl configured
- Docker registry access (optional for production)

### 1. Local Development

```bash
# Clone the repository
git clone this repo
cd odooS

# Start local development environment
docker-compose up -d

# Access Odoo at http://localhost:8069
# Default credentials: admin/admin
```

### 2. Kubernetes Deployment

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

3. **Update odoo.yaml** with your image:
   ```yaml
   image: your-registry.com/odoo:v1.0.0
   ```

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

The Odoo configuration is managed through Kubernetes ConfigMap (`k8s/configmap.yaml`). Key settings:

- **Database**: Connected to PostgreSQL service
- **Workers**: 2 workers per pod
- **Memory limits**: 2GB per pod
- **Logging**: Configured for production

### Auto-scaling

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

## 📊 Monitoring

### Metrics

The setup includes Prometheus monitoring for:
- Pod health and availability
- CPU and memory usage
- Database connectivity
- Backup job status

### Alerts

Configured alerts for:
- Odoo instance down
- High CPU/memory usage
- PostgreSQL down
- Backup failures

## 🔒 Security

### Secrets Management

Sensitive data is stored in Kubernetes secrets:
- Database passwords
- Admin passwords
- AWS credentials (for backups)

### Network Security

- Internal service communication
- SSL termination at ingress
- Network policies (can be added)

## 🛠️ Customization

### Adding Custom Modules

1. Place your modules in the `addons/` directory
2. Rebuild the Docker image
3. Update the Kubernetes deployment

### Scaling Configuration

Modify `k8s/hpa.yaml` to adjust:
- Min/max replicas
- CPU/memory thresholds
- Scaling behavior

### Backup Configuration

Update `k8s/backup-cronjob.yaml` to:
- Change backup schedule
- Configure S3 settings
- Add notification webhooks

## 🔍 Troubleshooting

### Common Issues

1. **Pods not starting**:
   ```bash
   kubectl describe pod <pod-name> -n odoo
   kubectl logs <pod-name> -n odoo
   ```

2. **Database connection issues**:
   ```bash
   kubectl get svc -n odoo
   kubectl logs deployment/postgres -n odoo
   ```

3. **Ingress not working**:
   ```bash
   kubectl get ingress -n odoo
   kubectl describe ingress odoo-ingress -n odoo
   ```

### Useful Commands

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

## 🧹 Cleanup

To remove the entire deployment:

```bash
./scripts/cleanup.sh
```

**Warning**: This will delete all data. Make sure you have backups!

## 📚 Additional Resources

- [Odoo Documentation](https://www.odoo.com/documentation/19.0/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Prometheus Monitoring](https://prometheus.io/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review Kubernetes and Odoo logs
3. Create an issue in the repository
4. Contact the development team

---

**Note**: This setup is designed for production use but should be thoroughly tested in your environment before deploying critical workloads.
