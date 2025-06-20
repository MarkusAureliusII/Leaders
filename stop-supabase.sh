#!/bin/bash
# Stop Supabase Services

set -e

echo "🛑 Stopping Supabase Backend..."

# Ensure we're in the right directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Stop all services
docker compose -f docker-compose.webapp.yml down

echo "✅ Supabase Backend stopped successfully!"
echo ""
echo "💡 To start again: ./start-supabase.sh"
echo "🗂️  Data preserved in volumes/ directory"