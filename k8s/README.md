# Lunchbox Kubernetes Deployment

This directory contains Kubernetes configurations for deploying the Lunchbox application using Kustomize.

## Project Structure

```
k8s/
├── base/                          # Base configurations
│   ├── nginx/                     # Nginx web server
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── postgres/                  # PostgreSQL database
│   │   ├── statefulset.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── redis/                     # Redis cache
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── rabbitmq/                  # RabbitMQ message broker
│   │   ├── statefulset.yaml
│   │   └── service.yaml
│   ├── minio/                     # MinIO object storage
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── php-fpm/                   # PHP-FPM application server
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── pgbouncer/                 # PgBouncer connection pooler
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── kustomization.yaml         # Base kustomization
│   ├── namespace.yaml             # Namespace configuration
│   └── persistent-volume-claims.yaml # Storage configurations
├── overlays/                      # Environment-specific overlays
│   ├── development/               # Development environment
│   │   ├── kustomization.yaml
│   │   └── deployment-patches.yaml
│   ├── staging/                   # Staging environment
│   └── production/                # Production environment
│       ├── kustomization.yaml
│       └── deployment-patches.yaml
├── deploy.sh                      # Deployment script
└── README.md                      # This file
```

## Components

### Core Services

1. **Nginx** - Web server and reverse proxy
   - Ports: 80 (HTTP), 443 (HTTPS)
   - LoadBalancer service type in production

2. **PHP-FPM** - Application server
   - PHP 8.2 with FPM
   - Connects to all backend services

3. **PostgreSQL** - Primary database
   - StatefulSet with persistent storage
   - 10GB storage by default

4. **Redis** - Caching and session storage
   - Persistent storage enabled
   - Password protected

5. **RabbitMQ** - Message queue
   - Management console available
   - Persistent storage

6. **MinIO** - Object storage
   - S3-compatible API
   - Web console available

7. **PgBouncer** - Database connection pooler
   - Transaction pooling mode
   - Improves database performance

## Deployment

### Prerequisites

- Kubernetes cluster (v1.24+)
- kubectl configured
- kustomize (optional, can use kubectl kustomize)
- StorageClass configured in cluster

### Quick Start

1. **Development Environment**
   ```bash
   ./deploy.sh -e development
   ```

2. **Production Environment**
   ```bash
   ./deploy.sh -e production -c your-production-context
   ```

### Deployment Options

```bash
# Development (default)
./deploy.sh -e development

# Staging
./deploy.sh -e staging

# Production with specific context
./deploy.sh -e production -c prod-cluster

# Dry run to see what would be deployed
./deploy.sh -e production -d

# Force deployment without confirmation
./deploy.sh -e production -f
```

### Manual Deployment with Kustomize

```bash
# Development
kubectl apply -k overlays/development

# Production
kubectl apply -k overlays/production

# Or using kustomize
kustomize build overlays/development | kubectl apply -f -
```

## Environment Configuration

### Development
- Single replica for all services
- Lower resource limits
- Debug mode enabled
- Development secrets

### Production
- Multiple replicas for high availability
- Higher resource limits
- Production-grade storage
- External LoadBalancer
- SSL/TLS termination

## Resource Requirements

### Development
- CPU: ~500m total
- Memory: ~1GB total
- Storage: ~50GB total

### Production
- CPU: ~4 cores total
- Memory: ~8GB total
- Storage: ~100GB total

## Secrets Management

Secrets should be managed externally. The deployment expects:

- `postgres-secrets` - Database credentials
- `redis-secrets` - Redis password
- `rabbitmq-secrets` - RabbitMQ credentials
- `minio-secrets` - MinIO credentials
- `nginx-ssl` - SSL certificates (optional)

### Creating Secrets

```bash
# Example: Create PostgreSQL secrets
kubectl create secret generic postgres-secrets \
  --from-literal=username=postgres \
  --from-literal=password=your-secure-password \
  --namespace=lunchbox-prod
```

## Monitoring and Logs

### Check Deployment Status
```bash
kubectl get all -n lunchbox-prod
kubectl get pvc -n lunchbox-prod
```

### View Logs
```bash
# Nginx logs
kubectl logs -n lunchbox-prod deployment/nginx

# PHP-FPM logs
kubectl logs -n lunchbox-prod deployment/php-fpm

# Database logs
kubectl logs -n lunchbox-prod statefulset/postgres
```

### Port Forwarding for Local Access
```bash
# Access MinIO console
kubectl port-forward -n lunchbox-prod service/minio 9001:9001

# Access RabbitMQ management
kubectl port-forward -n lunchbox-prod service/rabbitmq 15672:15672
```

## Customization

### Resource Limits

Edit the appropriate overlay file to adjust resource requests and limits:

```yaml
# In overlays/[environment]/deployment-patches.yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "200m"
```

### Storage Configuration

Modify `base/persistent-volume-claims.yaml` to adjust storage sizes or use different StorageClasses.

### Environment Variables

Add environment-specific configuration in the overlay's `kustomization.yaml`:

```yaml
configMapGenerator:
  - name: environment-config
    behavior: merge
    literals:
      - CUSTOM_VARIABLE=value
```

## Troubleshooting

### Common Issues

1. **PVC Pending**
   - Check StorageClass availability
   - Verify cluster has sufficient storage

2. **Services Not Starting**
   - Check resource limits
   - Verify secrets are created
   - Check container image availability

3. **Database Connection Issues**
   - Verify PostgreSQL is running
   - Check connection string in secrets

### Debug Commands

```bash
# Describe pod for detailed information
kubectl describe pod -n lunchbox-prod pod-name

# Check events in namespace
kubectl get events -n lunchbox-prod

# Check service endpoints
kubectl get endpoints -n lunchbox-prod
```

## Security Considerations

- Use external secret management (Vault, AWS Secrets Manager, etc.)
- Enable network policies
- Use private container registries
- Implement proper RBAC
- Enable Pod Security Standards
- Use TLS/SSL for all external traffic

## Maintenance

### Database Backups

```bash
# Backup PostgreSQL
kubectl exec -n lunchbox-prod postgres-0 -- pg_dump -U postgres lunchbox > backup.sql

# Restore PostgreSQL
kubectl exec -i -n lunchbox-prod postgres-0 -- psql -U postgres lunchbox < backup.sql
```

### Scaling

```bash
# Scale PHP-FPM
kubectl scale deployment/php-fpm --replicas=5 -n lunchbox-prod

# Scale Nginx
kubectl scale deployment/nginx --replicas=3 -n lunchbox-prod
```

## Support

For issues with Kubernetes deployment:
1. Check the troubleshooting section
2. Verify cluster resources and permissions
3. Review application logs
4. Check Kubernetes events

For application-specific issues, refer to the main Lunchbox documentation.