#!/bin/bash
# Supabase Self-Hosted Startup Script
# Optimized for WebApp Backend

set -e

echo "🚀 Starting Supabase Self-Hosted Backend..."

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

# Pull latest images
echo "📦 Updating Docker images..."
docker compose -f docker-compose.webapp.yml pull

# Start services
echo "🔧 Starting Supabase services..."
docker compose -f docker-compose.webapp.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check service health
echo "🔍 Checking service health..."
docker compose -f docker-compose.webapp.yml ps

# Display connection information
echo ""
echo "✅ Supabase Backend is running!"
echo ""
echo "🌐 Service URLs:"
echo "  📊 Studio (Dashboard): http://localhost:3000"
echo "  🔗 API URL: http://localhost:8000"
echo "  🗄️  Database: localhost:5432"
echo "  🔒 Auth: http://localhost:9999"
echo "  📁 Storage: http://localhost:5000"
echo "  ⚡ Realtime: http://localhost:4000"
echo ""
echo "🔑 Connection Details for WebApp:"
echo "  SUPABASE_URL: http://localhost:8000"
echo "  SUPABASE_ANON_KEY: $(grep ANON_KEY .env | cut -d'=' -f2)"
echo ""
echo "👤 Studio Login:"
echo "  Username: $(grep DASHBOARD_USERNAME .env | cut -d'=' -f2)"
echo "  Password: $(grep DASHBOARD_PASSWORD .env | cut -d'=' -f2)"
echo ""
echo "🐳 Docker Network: webapp-network (172.20.0.0/16)"
echo ""
echo "📝 Logs: docker compose -f docker-compose.webapp.yml logs -f [service]"
echo "🛑 Stop: docker compose -f docker-compose.webapp.yml down"
echo "🔄 Restart: docker compose -f docker-compose.webapp.yml restart"
echo ""