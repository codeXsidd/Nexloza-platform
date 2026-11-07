#!/usr/bin/env bash
#
# Nexloza Platform -- Development Setup Script
#
# This script checks prerequisites, configures the environment,
# and installs dependencies for local development.
#
# Usage:
#   chmod +x scripts/setup.sh
#   ./scripts/setup.sh

set -euo pipefail

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================"
echo "  Nexloza Platform -- Development Setup"
echo "============================================"
echo ""

ERRORS=0

# --- Check Flutter ---
echo -n "Checking Flutter... "
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version 2>&1 | head -n 1)
    echo -e "${GREEN}OK${NC} ($FLUTTER_VERSION)"
else
    echo -e "${RED}NOT FOUND${NC}"
    echo "  Install Flutter: https://docs.flutter.dev/get-started/install"
    ERRORS=$((ERRORS + 1))
fi

# --- Check Docker ---
echo -n "Checking Docker... "
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}OK${NC} ($DOCKER_VERSION)"
else
    echo -e "${RED}NOT FOUND${NC}"
    echo "  Install Docker: https://docs.docker.com/get-docker/"
    ERRORS=$((ERRORS + 1))
fi

# --- Check Docker Compose ---
echo -n "Checking Docker Compose... "
if docker compose version &> /dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version 2>&1)
    echo -e "${GREEN}OK${NC} ($COMPOSE_VERSION)"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    echo -e "${GREEN}OK${NC} ($COMPOSE_VERSION)"
else
    echo -e "${YELLOW}NOT FOUND${NC} (optional, needed for backend services)"
fi

# --- Check Git ---
echo -n "Checking Git... "
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    echo -e "${GREEN}OK${NC} ($GIT_VERSION)"
else
    echo -e "${RED}NOT FOUND${NC}"
    echo "  Install Git: https://git-scm.com/downloads"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# --- Abort if required tools are missing ---
if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}$ERRORS required tool(s) missing. Please install them and re-run this script.${NC}"
    exit 1
fi

# --- Configure environment ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Project root: $PROJECT_ROOT"
echo ""

if [ -f "$PROJECT_ROOT/.env" ]; then
    echo -e "Environment file: ${GREEN}.env already exists${NC} (skipping copy)"
else
    if [ -f "$PROJECT_ROOT/.env.example" ]; then
        cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
        echo -e "Environment file: ${GREEN}Copied .env.example to .env${NC}"
        echo -e "  ${YELLOW}Edit .env with your Supabase URL and keys before running the app.${NC}"
    else
        echo -e "Environment file: ${YELLOW}.env.example not found${NC} (skipping)"
    fi
fi

echo ""

# --- Install Flutter dependencies ---
echo "Installing Flutter dependencies..."
cd "$PROJECT_ROOT/app"
flutter pub get
echo -e "${GREEN}Flutter dependencies installed.${NC}"

echo ""

# --- Next steps ---
echo "============================================"
echo -e "  ${GREEN}Setup complete!${NC}"
echo "============================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Edit .env with your Supabase project URL and anon key"
echo "  2. Start backend services:"
echo "       docker compose up -d"
echo "  3. Run database migrations:"
echo "       cd backend/supabase && supabase db push"
echo "  4. Run the Flutter app:"
echo "       cd app && flutter run"
echo ""
echo "Documentation:"
echo "  - Local development:  docs/setup/local-development.md"
echo "  - Architecture:       ARCHITECTURE.md"
echo "  - MQTT protocol:      docs/api/mqtt-protocol.md"
echo ""
