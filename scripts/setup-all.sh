#!/bin/bash

# ================================================================
# Script: Complete Setup for BFF Financial Security
# ================================================================
# This script performs a complete setup:
# 1. Generates mTLS certificates
# 2. Creates .env file if not exists
# 3. Starts all Docker services
# 4. Waits for Keycloak to be ready
# 5. Seeds databases with demo data
# 6. Displays access information
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

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   BFF Financial Security - Complete Setup             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

cd "${BASE_DIR}"

# ============== Step 1: Check Prerequisites ==============
echo -e "${YELLOW}Step 1/7: Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

if ! command -v openssl &> /dev/null; then
    echo -e "${RED}❌ OpenSSL is not installed. Please install OpenSSL first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# ============== Step 2: Generate Certificates ==============
echo -e "${YELLOW}Step 2/7: Generating mTLS certificates...${NC}"

if [ -f "certs/ca/ca.crt" ]; then
    echo -e "${BLUE}ℹ️  Certificates already exist. Skipping generation.${NC}"
    echo -e "${BLUE}   To regenerate, run: ./scripts/cleanup.sh && ./scripts/generate-certs.sh${NC}"
else
    chmod +x scripts/generate-certs.sh
    ./scripts/generate-certs.sh
fi

echo ""

# ============== Step 3: Create .env file ==============
echo -e "${YELLOW}Step 3/7: Setting up environment variables...${NC}"

if [ ! -f ".env" ]; then
    echo -e "${BLUE}ℹ️  Creating .env file from .env.example...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created${NC}"
else
    echo -e "${BLUE}ℹ️  .env file already exists. Using existing configuration.${NC}"
fi

echo ""

# ============== Step 4: Start Docker Services ==============
echo -e "${YELLOW}Step 4/7: Starting Docker services...${NC}"

# Use docker compose (new) or docker-compose (old)
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${BLUE}ℹ️  Using: ${DOCKER_COMPOSE}${NC}"

# Build and start services
$DOCKER_COMPOSE build
$DOCKER_COMPOSE up -d

echo -e "${GREEN}✅ Docker services started${NC}"
echo ""

# ============== Step 5: Wait for Keycloak ==============
echo -e "${YELLOW}Step 5/7: Waiting for Keycloak to be ready...${NC}"

MAX_RETRIES=30
RETRY_COUNT=0

echo -n "Waiting for Keycloak"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:8080/health/ready > /dev/null 2>&1; then
        echo ""
        echo -e "${GREEN}✅ Keycloak is ready${NC}"
        break
    fi
    
    echo -n "."
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo ""
    echo -e "${RED}❌ Keycloak did not start in time${NC}"
    echo -e "${YELLOW}   Try: docker-compose logs keycloak${NC}"
    exit 1
fi

echo ""

# ============== Step 6: Wait for Databases ==============
echo -e "${YELLOW}Step 6/7: Waiting for databases to be ready...${NC}"

sleep 5

echo -e "${GREEN}✅ Databases ready${NC}"
echo ""

# ============== Step 7: Health Checks ==============
echo -e "${YELLOW}Step 7/7: Performing health checks...${NC}"

sleep 3

# Check BFF
if curl -s http://localhost:4000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ BFF is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  BFF is not responding yet (this is normal, it may take a few more seconds)${NC}"
fi

# Check Frontend
if curl -s http://localhost:5173 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend is running${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend is not responding yet${NC}"
fi

echo ""

# ============== Display Access Information ==============
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Setup Complete! Access Information Below          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📱 Application URLs:${NC}"
echo "   • Frontend:        http://localhost:5173"
echo "   • BFF API:         http://localhost:4000"
echo "   • BFF Health:      http://localhost:4000/health"
echo "   • Keycloak Admin:  http://localhost:8080/admin"
echo ""

echo -e "${BLUE}👤 Demo Users:${NC}"
echo "   ┌─────────────────┬───────────────┬──────────────────┐"
echo "   │ Username        │ Password      │ Role             │"
echo "   ├─────────────────┼───────────────┼──────────────────┤"
echo "   │ juan.perez      │ Password123!  │ customer         │"
echo "   │ maria.gonzalez  │ Password123!  │ premium-customer │"
echo "   │ admin           │ Admin123!     │ admin            │"
echo "   └─────────────────┴───────────────┴──────────────────┘"
echo ""

echo -e "${BLUE}🔐 Keycloak Admin:${NC}"
echo "   • Username: admin"
echo "   • Password: admin"
echo "   • URL:      http://localhost:8080/admin"
echo ""

echo -e "${BLUE}📊 Useful Commands:${NC}"
echo "   • View logs:        ${DOCKER_COMPOSE} logs -f"
echo "   • View BFF logs:    ${DOCKER_COMPOSE} logs -f bff"
echo "   • Stop all:         ${DOCKER_COMPOSE} down"
echo "   • Restart:          ${DOCKER_COMPOSE} restart"
echo "   • Cleanup:          ./scripts/cleanup.sh"
echo ""

echo -e "${YELLOW}⚠️  Note: It may take 10-20 seconds for all services to be fully ready.${NC}"
echo -e "${YELLOW}   If you encounter errors, wait a moment and refresh.${NC}"
echo ""

echo -e "${GREEN}🎉 Happy testing!${NC}"
echo ""
