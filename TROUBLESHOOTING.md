# Supabase Self-Hosted Setup - Configuration & Troubleshooting Guide

## Overview
This document contains the working configuration and troubleshooting knowledge for the self-hosted Supabase instance running at `217.154.211.42`.

## Working Configuration

### JWT Authentication
**Critical:** All services must use the same JWT_SECRET and properly signed keys.

```bash
JWT_SECRET=super-secret-jwt-token-with-at-least-32-characters-long
ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU
```

### Network Configuration
All services must be on the `supabase_default` network with specific aliases for Kong routing:

| Service | Container Name | Network Alias | Kong Route Target |
|---------|----------------|---------------|-------------------|
| Database | supabase-db | db | db:5432 |
| PostgREST | supabase-rest | rest | rest:3000 |
| GoTrue Auth | supabase-auth | auth | auth:9999 |
| pg-meta | supabase-meta | meta | meta:8080 |
| Studio | supabase-studio | studio | studio:3000 |
| Kong Gateway | supabase-kong | kong | - |

### Service Endpoints
- **Supabase Studio**: http://217.154.211.42:3000
- **Kong Gateway**: http://217.154.211.42:8000
- **Direct PostgREST**: http://217.154.211.42:3001
- **Direct pg-meta**: http://217.154.211.42:8080

### API Routes (through Kong)
- **REST API**: http://217.154.211.42:8000/rest/v1/
- **Auth API**: http://217.154.211.42:8000/auth/v1/
- **pg-meta API**: http://217.154.211.42:8000/pg/
- **Dashboard**: http://217.154.211.42:3000

## Container Startup Commands

### 1. Database (PostgreSQL)
```bash
# Should already be running from docker-compose
# Contains persistent data and schema
```

### 2. PostgREST
```bash
docker run -d \
  --name supabase-rest \
  --network supabase_default \
  --network-alias rest \
  -p 3001:3000 \
  -e PGRST_DB_URI=postgres://authenticator:306acbc70d380fb3ee12a524457fab0992f26635d431f676c903926907f3705f@db:5432/postgres \
  -e PGRST_DB_SCHEMAS=public,storage,graphql_public \
  -e PGRST_DB_ANON_ROLE=anon \
  -e PGRST_JWT_SECRET=super-secret-jwt-token-with-at-least-32-characters-long \
  -e PGRST_DB_USE_LEGACY_GUCS=false \
  -e PGRST_APP_SETTINGS_JWT_SECRET=super-secret-jwt-token-with-at-least-32-characters-long \
  -e PGRST_APP_SETTINGS_JWT_EXP=3600 \
  postgrest/postgrest:v12.2.12
```

### 3. GoTrue Auth Service
```bash
docker run -d \
  --name supabase-auth \
  --network supabase_default \
  --network-alias auth \
  -e GOTRUE_API_HOST=0.0.0.0 \
  -e GOTRUE_API_PORT=9999 \
  -e API_EXTERNAL_URL=http://217.154.211.42:8000 \
  -e GOTRUE_DB_DRIVER=postgres \
  -e GOTRUE_DB_DATABASE_URL=postgres://supabase_auth_admin:306acbc70d380fb3ee12a524457fab0992f26635d431f676c903926907f3705f@db:5432/postgres \
  -e GOTRUE_SITE_URL=http://217.154.211.42 \
  -e GOTRUE_URI_ALLOW_LIST=http://217.154.211.42,http://217.154.211.42:3000,http://217.154.211.42:8000 \
  -e GOTRUE_DISABLE_SIGNUP=false \
  -e GOTRUE_JWT_ADMIN_ROLES=service_role \
  -e GOTRUE_JWT_AUD=authenticated \
  -e GOTRUE_JWT_DEFAULT_GROUP_NAME=authenticated \
  -e GOTRUE_JWT_EXP=3600 \
  -e GOTRUE_JWT_SECRET=super-secret-jwt-token-with-at-least-32-characters-long \
  -e GOTRUE_EXTERNAL_EMAIL_ENABLED=true \
  -e GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED=false \
  -e GOTRUE_MAILER_AUTOCONFIRM=true \
  -e GOTRUE_SMTP_ADMIN_EMAIL=admin@localhost \
  -e GOTRUE_SMTP_HOST=supabase-mail \
  -e GOTRUE_SMTP_PORT=2500 \
  -e GOTRUE_SMTP_USER=fake_mail_user \
  -e GOTRUE_SMTP_PASS=fake_mail_password \
  -e GOTRUE_SMTP_SENDER_NAME=Supabase \
  -e GOTRUE_MAILER_URLPATHS_INVITE=/auth/v1/verify \
  -e GOTRUE_MAILER_URLPATHS_CONFIRMATION=/auth/v1/verify \
  -e GOTRUE_MAILER_URLPATHS_RECOVERY=/auth/v1/verify \
  -e GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE=/auth/v1/verify \
  -e GOTRUE_EXTERNAL_PHONE_ENABLED=false \
  -e GOTRUE_SMS_AUTOCONFIRM=false \
  supabase/gotrue:v2.174.0
```

### 4. pg-meta Service
```bash
docker run -d \
  --name supabase-meta \
  --network supabase_default \
  --network-alias meta \
  -p 8080:8080 \
  -e PG_META_PORT=8080 \
  -e PG_META_DB_HOST=db \
  -e PG_META_DB_PORT=5432 \
  -e PG_META_DB_NAME=postgres \
  -e PG_META_DB_USER=supabase_admin \
  -e PG_META_DB_PASSWORD=306acbc70d380fb3ee12a524457fab0992f26635d431f676c903926907f3705f \
  supabase/postgres-meta:v0.89.3
```

### 5. Kong Gateway
```bash
docker run -d \
  --name supabase-kong \
  --network supabase_default \
  --network-alias kong \
  -p 8000:8000 \
  -p 8443:8443 \
  -v ./volumes/api/kong.yml:/home/kong/temp.yml:ro,z \
  -e KONG_DATABASE=off \
  -e KONG_DECLARATIVE_CONFIG=/home/kong/kong.yml \
  -e KONG_DNS_ORDER=LAST,A,CNAME \
  -e KONG_PLUGINS=request-transformer,cors,key-auth,acl,basic-auth \
  -e KONG_NGINX_PROXY_PROXY_BUFFER_SIZE=160k \
  -e KONG_NGINX_PROXY_PROXY_BUFFERS=64\ 160k \
  -e SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0 \
  -e SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU \
  -e DASHBOARD_USERNAME=admin \
  -e DASHBOARD_PASSWORD=SecureAdminPassword2024! \
  --entrypoint bash \
  kong:2.8.1 \
  -c 'eval "echo \"$(cat ~/temp.yml)\"" > ~/kong.yml && /docker-entrypoint.sh kong docker-start'
```

### 6. Supabase Studio
```bash
docker run -d \
  --name supabase-studio \
  --network supabase_default \
  --network-alias studio \
  -p 3000:3000 \
  -e STUDIO_PG_META_URL=http://meta:8080 \
  -e POSTGRES_PASSWORD=306acbc70d380fb3ee12a524457fab0992f26635d431f676c903926907f3705f \
  -e DEFAULT_ORGANIZATION_NAME="WebApp Backend" \
  -e DEFAULT_PROJECT_NAME="Production" \
  -e SUPABASE_URL=http://kong:8000 \
  -e SUPABASE_PUBLIC_URL=http://217.154.211.42:8000 \
  -e SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0 \
  -e SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU \
  -e AUTH_JWT_SECRET=super-secret-jwt-token-with-at-least-32-characters-long \
  -e NEXT_ANALYTICS_BACKEND_PROVIDER=postgres \
  supabase/studio:2025.06.02-sha-8f2993d
```

## Testing & Verification Commands

### Health Checks
```bash
# Check all containers
docker ps --filter name=supabase

# Test REST API
curl -X GET http://217.154.211.42:8000/rest/v1/leads \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

# Test Schema API
curl -X GET http://217.154.211.42:8000/pg/schemas \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

# Test Tables API
curl -X GET http://217.154.211.42:8000/pg/tables \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

# Test User Creation
curl -X POST http://217.154.211.42:8000/auth/v1/signup \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "testpass123"}'
```

### Direct Service Testing
```bash
# Direct PostgREST
curl -X GET http://217.154.211.42:3001/leads \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

# Direct pg-meta
curl -X GET http://217.154.211.42:8080/tables \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
```

## Common Issues & Solutions

### 1. JWT Authentication Errors
**Symptoms:** 
- "invalid JWT: unable to parse or verify signature"
- "Invalid authentication credentials"

**Solution:**
1. Verify JWT_SECRET matches across all services
2. Ensure ANON_KEY and SERVICE_ROLE_KEY are signed with the correct JWT_SECRET
3. Restart all services with consistent JWT configuration

**Generate correct keys:**
```python
import jwt

jwt_secret = 'super-secret-jwt-token-with-at-least-32-characters-long'

# Generate SERVICE_ROLE_KEY
service_payload = {
    'iss': 'supabase-demo',
    'role': 'service_role', 
    'exp': 1983812996
}
service_key = jwt.encode(service_payload, jwt_secret, algorithm='HS256')

# Generate ANON_KEY  
anon_payload = {
    'iss': 'supabase-demo',
    'role': 'anon',
    'exp': 1983812996
}
anon_key = jwt.encode(anon_payload, jwt_secret, algorithm='HS256')
```

### 2. Studio "Failed to retrieve tables/schemas" 
**Symptoms:**
- "Failed to retrieve tables"
- "Failed to load schemas" 
- "fetch failed" errors

**Solution:**
1. Ensure pg-meta service has `meta` network alias
2. Verify Kong can resolve `meta:8080`
3. Check Studio environment points to correct Kong URL

### 3. Kong DNS Resolution Failures
**Symptoms:**
- "name resolution failed"
- "DNS resolution failed" in Kong logs

**Solution:**
1. Ensure all services have correct network aliases:
   - `--network-alias rest` for PostgREST
   - `--network-alias auth` for GoTrue  
   - `--network-alias meta` for pg-meta
   - `--network-alias studio` for Studio
2. All containers must be on `supabase_default` network

### 4. Service Dependencies
**Critical startup order:**
1. Database (db) - must be healthy first
2. PostgREST (rest) - depends on db
3. GoTrue Auth (auth) - depends on db  
4. pg-meta (meta) - depends on db
5. Kong (kong) - depends on rest, auth, meta
6. Studio (studio) - depends on kong, meta

## Webapp Integration

### Frontend Configuration  
Update Supabase client configuration:
```typescript
// src/integrations/supabase/client.ts
const SUPABASE_URL = "http://217.154.211.42:8000";
const SUPABASE_PUBLISHABLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0";
```

### Environment Variables
```bash
# Webapp .env
NEXT_PUBLIC_SUPABASE_URL=http://217.154.211.42:8000
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
```

## Database Schema
The database contains:
- `leads` table for webapp functionality
- `webhook_settings` table for webhook management
- Standard Supabase auth and storage schemas

## Important Files
- `/root/supabase-setup/.env` - Main environment configuration
- `/root/supabase-setup/volumes/api/kong.yml` - Kong routing configuration  
- `/opt/webapp-stack/apps/frontend/src/integrations/supabase/client.ts` - Frontend Supabase client
- `/opt/webapp-stack/infrastructure/docker/.env` - Webapp environment variables

## Maintenance Commands

### Stop all services
```bash
docker stop supabase-studio supabase-kong supabase-auth supabase-rest supabase-meta
```

### Start all services (in order)
```bash
# Database should already be running
# Start in dependency order - see startup commands above
```

### View logs
```bash
docker logs supabase-[service-name] --tail 20
```

### Clean restart
```bash
# Stop and remove containers (keeps data)
docker stop supabase-studio supabase-kong supabase-auth supabase-rest supabase-meta
docker rm supabase-studio supabase-kong supabase-auth supabase-rest supabase-meta

# Restart using commands above
```

---

**Last Updated:** 2025-06-20
**Working Configuration Verified:** ✅ All services operational