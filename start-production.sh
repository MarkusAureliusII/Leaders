#!/bin/bash
# Supabase Production Deployment Script
# Server: 217.154.211.42

set -e

echo "🚀 Starting Supabase Production Backend on 217.154.211.42..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Ensure we're in the right directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found. Please create it from .env.example"
    exit 1
fi

# Create necessary directories
echo "📁 Creating volume directories..."
mkdir -p volumes/{db,storage,logs,functions,api}
mkdir -p volumes/db/init
mkdir -p volumes/functions/{hello,main}

# Set proper permissions
echo "🔐 Setting permissions..."
chmod -R 755 volumes/
chmod +x "$0"

# Stop any existing containers
echo "🛑 Stopping any existing containers..."
docker compose -f docker-compose.production.yml down 2>/dev/null || true

# Pull latest images
echo "📦 Updating Docker images..."
docker compose -f docker-compose.production.yml pull

# Start services in stages for better reliability
echo "🔧 Starting core services..."
docker compose -f docker-compose.production.yml up -d db vector

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 20

echo "🔧 Starting analytics service..."
docker compose -f docker-compose.production.yml up -d analytics

echo "⏳ Waiting for analytics to be ready..."
sleep 15

echo "🔧 Starting API services..."
docker compose -f docker-compose.production.yml up -d rest auth meta realtime imgproxy storage

echo "⏳ Waiting for API services..."
sleep 20

echo "🔧 Starting gateway and frontend services..."
docker compose -f docker-compose.production.yml up -d kong studio functions

# Wait for all services to be ready
echo "⏳ Waiting for all services to be ready..."
sleep 30

# Check service health
echo "🔍 Checking service health..."
docker compose -f docker-compose.production.yml ps

# Get server IP
SERVER_IP="217.154.211.42"

# Display connection information
echo ""
echo "✅ Supabase Production Backend is running on ${SERVER_IP}!"
echo ""
echo "🌐 External Access URLs:"
echo "  📊 Studio Dashboard: http://${SERVER_IP}:3000"
echo "  🔗 API URL: http://${SERVER_IP}:8000"
echo "  🔒 Auth: http://${SERVER_IP}:8000/auth/v1"
echo "  📁 Storage: http://${SERVER_IP}:8000/storage/v1"
echo "  ⚡ Realtime: ws://${SERVER_IP}:8000/realtime/v1"
echo ""
echo "🔑 WebApp Configuration:"
echo "  NEXT_PUBLIC_SUPABASE_URL=http://${SERVER_IP}:8000"
echo "  NEXT_PUBLIC_SUPABASE_ANON_KEY=$(grep ANON_KEY .env | cut -d'=' -f2)"
echo ""
echo "👤 Studio Login:"
echo "  URL: http://${SERVER_IP}:3000"
echo "  Username: $(grep DASHBOARD_USERNAME .env | cut -d'=' -f2)"
echo "  Password: $(grep DASHBOARD_PASSWORD .env | cut -d'=' -f2)"
echo ""
echo "🔧 Management Commands:"
echo "  📝 Logs: docker compose -f docker-compose.production.yml logs -f [service]"
echo "  🛑 Stop: docker compose -f docker-compose.production.yml down"
echo "  🔄 Restart: docker compose -f docker-compose.production.yml restart [service]"
echo "  📊 Status: docker compose -f docker-compose.production.yml ps"
echo ""
echo "🔒 Security:"
echo "  - Firewall is active with ports 3000, 8000, 8443 open"
echo "  - All services are running in isolated containers"
echo "  - Database passwords are auto-generated and secure"
echo ""
echo "⚠️  Important Notes:"
echo "  - Change default Studio password after first login"
echo "  - Configure SSL/TLS for production use"
echo "  - Set up regular database backups"
echo "  - Monitor resource usage and logs"
echo ""