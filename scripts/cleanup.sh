#!/bin/bash

# ================================================================
# Script: Cleanup for BFF Financial Security
# ================================================================
# This script performs a complete cleanup:
# - Stops and removes all Docker containers
# - Removes Docker volumes
# - Removes generated certificates
# - Optionally removes .env file
# ================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║   BFF Financial Security - Cleanup                     ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

cd "${BASE_DIR}"

# Confirm cleanup
echo -e "${YELLOW}⚠️  This will remove:${NC}"
echo "   • All Docker containers and volumes"
echo "   • Generated mTLS certificates"
echo "   • Build artifacts"
echo ""

read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}ℹ️  Cleanup cancelled${NC}"
    exit 0
fi

echo ""

# ============== Step 1: Stop Docker Services ==============
echo -e "${YELLOW}Step 1/5: Stopping Docker services...${NC}"

# Use docker compose (new) or docker-compose (old)
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

if [ -f "docker-compose.yml" ]; then
    $DOCKER_COMPOSE down -v
    echo -e "${GREEN}✅ Docker services stopped and volumes removed${NC}"
else
    echo -e "${YELLOW}⚠️  docker-compose.yml not found. Skipping.${NC}"
fi

echo ""

# ============== Step 2: Remove Certificates ==============
echo -e "${YELLOW}Step 2/5: Removing generated certificates...${NC}"

if [ -d "certs" ]; then
    find certs -name "*.key" -type f -delete
    find certs -name "*.crt" -type f -delete
    find certs -name "*.csr" -type f -delete
    find certs -name "*.srl" -type f -delete
    echo -e "${GREEN}✅ Certificates removed${NC}"
else
    echo -e "${YELLOW}⚠️  Certs directory not found. Skipping.${NC}"
fi

echo ""

# ============== Step 3: Remove Build Artifacts ==============
echo -e "${YELLOW}Step 3/5: Removing build artifacts...${NC}"

# Remove node_modules and dist folders
find . -name "node_modules" -type d -prune -exec rm -rf {} +
find . -name "dist" -type d -prune -exec rm -rf {} +
find . -name "build" -type d -prune -exec rm -rf {} +
find . -name ".archify" -type d -prune -exec rm -rf {} +

echo -e "${GREEN}✅ Build artifacts removed${NC}"
echo ""

# ============== Step 4: Remove Log Files ==============
echo -e "${YELLOW}Step 4/5: Removing log files...${NC}"

find . -name "*.log" -type f -delete

echo -e "${GREEN}✅ Log files removed${NC}"
echo ""

# ============== Step 5: Optional - Remove .env ==============
echo -e "${YELLOW}Step 5/5: Environment file cleanup...${NC}"

if [ -f ".env" ]; then
    read -p "Do you want to remove .env file? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm .env
        echo -e "${GREEN}✅ .env file removed${NC}"
    else
        echo -e "${BLUE}ℹ️  Keeping .env file${NC}"
    fi
else
    echo -e "${BLUE}ℹ️  No .env file found${NC}"
fi

echo ""

# ============== Summary ==============
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Cleanup Complete!                                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📝 Next steps:${NC}"
echo "   • To set up again: ./scripts/setup-all.sh"
echo "   • To generate only certs: ./scripts/generate-certs.sh"
echo ""

echo -e "${GREEN}✨ System is clean!${NC}"
echo ""
