# Supabase Self-Hosted Backend Deployment Guide

## 🎯 Overview

This setup provides a containerized Supabase backend optimized for webapp integration. The infrastructure includes all Supabase services in isolated Docker containers with proper networking.

## 🔧 What's Included

### Core Services
- **PostgreSQL Database** (Port 5432) - Main database with RLS
- **PostgREST API** (Port 3001) - Auto-generated REST API  
- **GoTrue Auth** (Port 9999) - Authentication service
- **Realtime** (Port 4000) - WebSocket connections
- **Storage** (Port 5000) - File storage with image processing
- **Kong Gateway** (Port 8000) - API proxy and rate limiting
- **Supabase Studio** (Port 3000) - Management dashboard
- **Edge Functions** (Port 8081) - Serverless functions

### Network Configuration
- **Docker Network**: `webapp-network` (172.20.0.0/16)
- **Isolated containers** with proper internal communication
- **External ports** exposed for webapp integration

## 🚀 Quick Start

### 1. Start Supabase Backend
```bash
cd /root/supabase-setup
./start-supabase.sh
```

### 2. Access Services
- **Studio Dashboard**: http://localhost:3000
- **API Endpoint**: http://localhost:8000
- **Database**: localhost:5432

### 3. Default Credentials
- **Studio Login**: admin / SecureAdminPassword2024!
- **Database**: postgres / [generated-password]

## 🔗 WebApp Integration

### Frontend Configuration
```javascript
// .env.local (Next.js/React)
NEXT_PUBLIC_SUPABASE_URL=http://localhost:8000
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0

# For production, replace localhost with your server IP
NEXT_PUBLIC_SUPABASE_URL=http://YOUR_SERVER_IP:8000
```

### Client Setup
```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
)
```

## 📋 Management Commands

### Service Control
```bash
# Start all services
./start-supabase.sh

# Stop all services  
./stop-supabase.sh

# View service status
docker compose -f docker-compose.yml ps

# View logs
docker compose -f docker-compose.yml logs [service-name]

# Restart a service
docker compose -f docker-compose.yml restart [service-name]
```

### Database Management
```bash
# Connect to database
docker exec -it supabase-db psql -U postgres

# Backup database
docker exec supabase-db pg_dump -U postgres postgres > backup.sql

# Restore database
docker exec -i supabase-db psql -U postgres < backup.sql
```

## 🔒 Security Considerations

### Environment Variables
- All secrets are randomly generated 64-character strings
- JWT tokens use secure signing keys
- Database passwords are auto-generated

### Network Security
- Services communicate on isolated Docker network
- Only necessary ports exposed to host
- Internal service discovery via container names

### Production Deployment
1. **Change default passwords** in Studio dashboard
2. **Update environment variables** for your domain
3. **Configure SSL/TLS** with reverse proxy (nginx/caddy)
4. **Set up firewall rules** on your server
5. **Enable database backups**

## 🌐 Production Configuration

### 1. Update Environment Variables
```bash
# Edit .env file
nano .env

# Update these values:
SITE_URL=https://yourdomain.com
API_EXTERNAL_URL=https://api.yourdomain.com
SUPABASE_PUBLIC_URL=https://api.yourdomain.com
```

### 2. Add Reverse Proxy (Nginx)
```nginx
# /etc/nginx/sites-available/supabase
server {
    listen 80;
    server_name api.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 80;
    server_name studio.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 3. SSL Certificate (Let's Encrypt)
```bash
certbot --nginx -d api.yourdomain.com -d studio.yourdomain.com
```

## 📊 Monitoring & Logs

### Health Checks
```bash
# Check all services
docker compose -f docker-compose.yml ps

# Test API endpoint
curl http://localhost:8000/health

# Test database connection
docker exec supabase-db pg_isready -U postgres
```

### Log Management
```bash
# Follow all logs
docker compose -f docker-compose.yml logs -f

# Service-specific logs
docker compose -f docker-compose.yml logs -f db
docker compose -f docker-compose.yml logs -f auth
docker compose -f docker-compose.yml logs -f rest
```

## 🔧 Troubleshooting

### Common Issues

1. **Services won't start**
   ```bash
   # Check logs
   docker compose -f docker-compose.yml logs [service]
   
   # Clean restart
   docker compose -f docker-compose.yml down -v
   rm -rf volumes/db/*
   ./start-supabase.sh
   ```

2. **Database connection issues**
   ```bash
   # Verify database is healthy
   docker exec supabase-db pg_isready -U postgres
   
   # Check environment variables
   docker exec supabase-db env | grep POSTGRES
   ```

3. **API not responding**
   ```bash
   # Check Kong gateway
   docker compose -f docker-compose.yml logs kong
   
   # Test PostgREST directly
   curl http://localhost:3001/health
   ```

### Performance Tuning

1. **Database optimization**
   - Increase `shared_buffers` for larger datasets
   - Configure connection pooling
   - Set up read replicas for high load

2. **Resource limits**
   - Add memory/CPU limits to docker-compose.yml
   - Monitor container resource usage
   - Scale horizontally for high traffic

## 📁 File Structure

```
supabase-setup/
├── .env                     # Environment configuration
├── docker-compose.yml       # Original Supabase compose
├── docker-compose.webapp.yml # Custom webapp-optimized version
├── start-supabase.sh        # Startup script
├── stop-supabase.sh         # Shutdown script
├── webapp-example.js        # Frontend integration example
├── volumes/                 # Persistent data
│   ├── db/                 # PostgreSQL data
│   ├── storage/            # File storage
│   └── logs/               # Application logs
└── DEPLOYMENT-GUIDE.md     # This guide
```

## 🔄 Backup Strategy

### Automated Database Backups
```bash
# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker exec supabase-db pg_dump -U postgres postgres > "backup_${DATE}.sql"
gzip "backup_${DATE}.sql"
# Keep only last 7 days
find . -name "backup_*.sql.gz" -mtime +7 -delete
EOF

chmod +x backup.sh

# Add to crontab for daily backups
echo "0 2 * * * /root/supabase-setup/backup.sh" | crontab -
```

## 📞 Support

For issues with this deployment:
1. Check the troubleshooting section above
2. Review Docker logs for specific services
3. Verify network connectivity between services
4. Ensure all environment variables are properly set

For Supabase-specific issues:
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase GitHub](https://github.com/supabase/supabase)
- [Self-hosting Guide](https://supabase.com/docs/guides/self-hosting)