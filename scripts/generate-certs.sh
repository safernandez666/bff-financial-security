#!/bin/bash

# ================================================================
# Script: Generate mTLS Certificates for BFF Financial Security
# ================================================================
# This script generates a complete PKI infrastructure:
# - Certificate Authority (CA)
# - BFF certificate
# - Microservices certificates (Saldo, Usuario, Préstamos, Tarjetas)
# ================================================================

set -e

echo "🔐 Generating mTLS certificates for BFF Financial Security..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERTS_DIR="${BASE_DIR}/certs"

# Certificate validity (days)
CA_VALIDITY=3650    # 10 years
CERT_VALIDITY=365   # 1 year

echo -e "${BLUE}📁 Certificates directory: ${CERTS_DIR}${NC}"
echo ""

# ============== Step 1: Generate Certificate Authority ==============
echo -e "${YELLOW}Step 1/6: Generating Certificate Authority (CA)...${NC}"

cd "${CERTS_DIR}/ca"

# Generate CA private key
openssl genrsa -out ca.key 4096

# Generate CA certificate
openssl req -new -x509 -days ${CA_VALIDITY} -key ca.key -out ca.crt \
  -subj "/C=AR/ST=Buenos Aires/L=CABA/O=BFF Financial Security/OU=Security/CN=BFF-CA"

echo -e "${GREEN}✅ CA certificate generated${NC}"
echo ""

# ============== Step 2: Generate BFF Certificate ==============
echo -e "${YELLOW}Step 2/6: Generating BFF certificate...${NC}"

cd "${CERTS_DIR}/bff"

# Generate BFF private key
openssl genrsa -out bff.key 2048

# Generate Certificate Signing Request (CSR)
openssl req -new -key bff.key -out bff.csr \
  -subj "/C=AR/ST=Buenos Aires/L=CABA/O=BFF Financial Security/OU=BFF/CN=bff"

# Sign certificate with CA
openssl x509 -req -in bff.csr -CA ../ca/ca.crt -CAkey ../ca/ca.key \
  -CAcreateserial -out bff.crt -days ${CERT_VALIDITY} \
  -extfile <(printf "subjectAltName=DNS:bff,DNS:localhost,IP:127.0.0.1")

# Copy CA certificate for validation
cp ../ca/ca.crt .

echo -e "${GREEN}✅ BFF certificate generated${NC}"
echo ""

# ============== Step 3: Generate Saldo Service Certificate ==============
echo -e "${YELLOW}Step 3/6: Generating Saldo Service certificate...${NC}"

cd "${CERTS_DIR}/services/saldo"

openssl genrsa -out saldo.key 2048

openssl req -new -key saldo.key -out saldo.csr \
  -subj "/C=AR/ST=Buenos Aires/L=CABA/O=BFF Financial Security/OU=Microservices/CN=saldo-service"

openssl x509 -req -in saldo.csr -CA ../../ca/ca.crt -CAkey ../../ca/ca.key \
  -CAcreateserial -out saldo.crt -days ${CERT_VALIDITY} \
  -extfile <(printf "subjectAltName=DNS:saldo-service,DNS:localhost,IP:127.0.0.1")

cp ../../ca/ca.crt .

echo -e "${GREEN}✅ Saldo Service certificate generated${NC}"
echo ""

# ============== Step 4: Generate Usuario Service Certificate ==============
echo -e "${YELLOW}Step 4/6: Generating Usuario Service certificate...${NC}"

cd "${CERTS_DIR}/services/usuario"

openssl genrsa -out usuario.key 2048

openssl req -new -key usuario.key -out usuario.csr \
  -subj "/C=AR/ST=Buenos Aires/L=CABA/O=BFF Financial Security/OU=Microservices/CN=usuario-service"

openssl x509 -req -in usuario.csr -CA ../../ca/ca.crt -CAkey ../../ca/ca.key \
  -CAcreateserial -out usuario.crt -days ${CERT_VALIDITY} \
  -extfile <(printf "subjectAltName=DNS:usuario-service,DNS:localhost,IP:127.0.0.1")

cp ../../ca/ca.crt .

echo -e "${GREEN}✅ Usuario Service certificate generated${NC}"
echo ""

# ============== Step 5: Generate Préstamos Service Certificate ==============
echo -e "${YELLOW}Step 5/6: Generating Préstamos Service certificate...${NC}"

cd "${CERTS_DIR}/services/prestamos"

openssl genrsa -out prestamos.key 2048

openssl req -new -key prestamos.key -out prestamos.csr \
  -subj "/C=AR/ST=Buenos Aires/L=CABA/O=BFF Financial Security/OU=Microservices/CN=prestamos-service"

openssl x509 -req -in prestamos.csr -CA ../../ca/ca.crt -CAkey ../../ca/ca.key \
  -CAcreateserial -out prestamos.crt -days ${CERT_VALIDITY} \
  -extfile <(printf "subjectAltName=DNS:prestamos-service,DNS:localhost,IP:127.0.0.1")

cp ../../ca/ca.crt .

echo -e "${GREEN}✅ Préstamos Service certificate generated${NC}"
echo ""

# ============== Step 6: Generate Tarjetas Service Certificate ==============
echo -e "${YELLOW}Step 6/6: Generating Tarjetas Service certificate...${NC}"

cd "${CERTS_DIR}/services/tarjetas"

openssl genrsa -out tarjetas.key 2048

openssl req -new -key tarjetas.key -out tarjetas.csr \
  -subj "/C=AR/ST=Buenos Aires/L=CABA/O=BFF Financial Security/OU=Microservices/CN=tarjetas-service"

openssl x509 -req -in tarjetas.csr -CA ../../ca/ca.crt -CAkey ../../ca/ca.key \
  -CAcreateserial -out tarjetas.crt -days ${CERT_VALIDITY} \
  -extfile <(printf "subjectAltName=DNS:tarjetas-service,DNS:localhost,IP:127.0.0.1")

cp ../../ca/ca.crt .

echo -e "${GREEN}✅ Tarjetas Service certificate generated${NC}"
echo ""

# ============== Set proper permissions ==============
echo -e "${BLUE}🔒 Setting proper permissions...${NC}"

cd "${CERTS_DIR}"

# Private keys should be read-only for owner
find . -name "*.key" -exec chmod 400 {} \;

# Certificates can be read by everyone
find . -name "*.crt" -exec chmod 644 {} \;

echo -e "${GREEN}✅ Permissions set${NC}"
echo ""

# ============== Summary ==============
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ All certificates generated successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📊 Certificate inventory:${NC}"
echo "   • CA certificate: certs/ca/ca.crt"
echo "   • BFF: certs/bff/{bff.key, bff.crt, ca.crt}"
echo "   • Saldo: certs/services/saldo/{saldo.key, saldo.crt, ca.crt}"
echo "   • Usuario: certs/services/usuario/{usuario.key, usuario.crt, ca.crt}"
echo "   • Préstamos: certs/services/prestamos/{prestamos.key, prestamos.crt, ca.crt}"
echo "   • Tarjetas: certs/services/tarjetas/{tarjetas.key, tarjetas.crt, ca.crt}"
echo ""
echo -e "${YELLOW}⚠️  Note: These certificates are for DEVELOPMENT only.${NC}"
echo -e "${YELLOW}   For production, use certificates from a trusted CA.${NC}"
echo ""
