# BFF Financial Security - Sistema Bancario con Arquitectura de Ciberseguridad

> Implementación completa de un Backend For Frontend (BFF) para aplicaciones financieras con enfoque en ciberseguridad, autenticación OAuth2/OIDC, mTLS service-to-service, y compliance PCI DSS.

## 🎯 Descripción del Proyecto

Este proyecto demuestra una arquitectura de seguridad multicapa para aplicaciones bancarias, donde el BFF actúa como gatekeeper protegiendo microservicios internos. Los usuarios **nunca** acceden directamente a los microservicios, todas las peticiones pasan por el BFF que maneja:

- ✅ Validación de tokens JWT con Keycloak
- ✅ Agregación de datos de múltiples microservicios
- ✅ Rate limiting y throttling
- ✅ Circuit breaker pattern
- ✅ Propagación segura de tokens (user token + service token)
- ✅ mTLS entre BFF y microservicios
- ✅ Logging centralizado y auditoría
- ✅ Data masking de información sensible
- ✅ Input validation con Zod

## 🏗️ Arquitectura

```
┌──────────────┐
│   Frontend   │  (React + TypeScript + Keycloak.js)
│  Port: 5173  │
└──────┬───────┘
       │ HTTPS + JWT
       ▼
┌──────────────┐      ┌─────────────┐
│     BFF      │◄────►│  Keycloak   │  (CIAM - OAuth2/OIDC)
│  Port: 4000  │      │  Port: 8080 │
└──────┬───────┘      └─────────────┘
       │ mTLS + Service Token
       ├────────────┬────────────┬────────────┬────────────┐
       ▼            ▼            ▼            ▼            ▼
   ┌────────┐  ┌────────┐  ┌─────────┐  ┌─────────┐
   │ Saldo  │  │Usuario │  │Préstamos│  │Tarjetas │
   │ :3001  │  │ :3002  │  │  :3003  │  │  :3004  │
   └───┬────┘  └───┬────┘  └────┬────┘  └────┬────┘
       │           │            │            │
       ▼           ▼            ▼            ▼
   ┌────────┐  ┌────────┐  ┌─────────┐  ┌─────────┐
   │  DB 1  │  │  DB 2  │  │   DB 3  │  │   DB 4  │
   └────────┘  └────────┘  └─────────┘  └─────────┘
```

## 🚀 Stack Tecnológico

### Backend
- **Runtime**: Node.js 20 LTS + TypeScript
- **Framework**: Express.js
- **Base de datos**: PostgreSQL 16 (4 instancias, una por microservicio)
- **Autenticación**: Keycloak 23 (OAuth2 + OIDC)
- **Security**: 
  - `express-oauth2-jwt-bearer` - JWT validation
  - `helmet` - Security headers
  - `express-rate-limit` - Rate limiting
  - `opossum` - Circuit breaker
  - `zod` - Schema validation
- **Logging**: `winston` + `express-winston`

### Frontend
- **Framework**: React 18 + TypeScript
- **Build**: Vite
- **Auth**: `@react-keycloak/web`
- **UI**: Tailwind CSS + shadcn/ui
- **HTTP**: Axios

### Infraestructura
- **Containers**: Docker + Docker Compose
- **mTLS**: OpenSSL certificates
- **Reverse Proxy**: Nginx (opcional)

## 📋 Prerequisitos

- Docker & Docker Compose
- Node.js 20+ (para desarrollo local)
- OpenSSL (para generar certificados)

## ⚡ Quick Start

### 1. Clonar el repositorio

```bash
git clone <repo-url>
cd bff-financial-security
```

### 2. Generar certificados mTLS

```bash
chmod +x scripts/generate-certs.sh
./scripts/generate-certs.sh
```

### 3. Configurar variables de entorno

```bash
cp .env.example .env
# Editar .env si es necesario (los valores por defecto funcionan para desarrollo)
```

### 4. Levantar todo el stack

```bash
chmod +x scripts/setup-all.sh
./scripts/setup-all.sh
```

Esto levantará:
- ✅ Keycloak en http://localhost:8080
- ✅ PostgreSQL (4 instancias)
- ✅ 4 Microservicios (Saldo, Usuario, Préstamos, Tarjetas)
- ✅ BFF en http://localhost:4000
- ✅ Frontend en http://localhost:5173

### 5. Acceder a la aplicación

- **Frontend**: http://localhost:5173
- **Keycloak Admin**: http://localhost:8080/admin (admin/admin)
- **BFF Health**: http://localhost:4000/health

### 6. Usuarios de prueba

| Usuario | Password | Rol |
|---------|----------|-----|
| juan.perez | Password123! | customer |
| maria.gonzalez | Password123! | premium-customer |
| admin | Admin123! | admin |

## 🔐 Flujos de Seguridad

### Flujo de Autenticación

1. Usuario hace click en "Login" en el frontend
2. Frontend redirige a Keycloak (Authorization Code + PKCE)
3. Usuario ingresa credenciales en Keycloak
4. Keycloak emite Access Token + Refresh Token
5. Frontend almacena tokens y los usa en cada request al BFF

### Flujo de Request al Dashboard

1. Frontend → BFF: `GET /api/dashboard` (con Bearer token)
2. BFF valida el token del usuario contra Keycloak
3. BFF verifica rate limits
4. BFF obtiene un Service Token (Client Credentials flow)
5. BFF hace llamadas paralelas a microservicios con:
   - `Authorization: Bearer <service-token>`
   - `X-User-Token: <user-token>` (custom header)
6. Cada microservicio valida AMBOS tokens
7. Microservicios consultan sus bases de datos
8. BFF agrega las respuestas
9. BFF enmascara datos sensibles en logs
10. BFF responde al frontend

### Propagación de Tokens

```
User Token (JWT del usuario) → BFF valida
                               ↓
                    BFF obtiene Service Token
                               ↓
              Ambos tokens → Microservicio
                               ↓
                    Microservicio valida ambos
                               ↓
                    Verifica permisos RBAC
                               ↓
                         Retorna datos
```

## 🧪 Testing

### Con Postman

```bash
# Importar collection
# Archivo: postman/BFF-Financial-Security.postman_collection.json
```

La collection incluye:
- Flujo completo de autenticación
- Requests al dashboard
- Operaciones en cada microservicio
- Casos de error (401, 403, 429)

### Tests automatizados

```bash
# BFF
cd src/bff
npm test

# Microservicios
cd src/microservices/saldo-service
npm test
```

## 📊 Diagramas Interactivos

El proyecto incluye 4 diagramas interactivos creados con Archify:

1. **Architecture Overview** - Arquitectura completa del sistema
2. **Authentication Flow** - Secuencia de autenticación con Keycloak
3. **Token Propagation** - Workflow de propagación de tokens
4. **Dashboard Request** - Secuencia de agregación de datos

Ver en: `diagrams/`

## 🔍 Monitoring y Logs

### Logs del BFF

```bash
docker-compose logs -f bff
```

### Logs de un microservicio

```bash
docker-compose logs -f saldo-service
```

### Formato de logs

```json
{
  "timestamp": "2024-10-24T10:30:45.123Z",
  "level": "info",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "abc123",
  "action": "dashboard_request",
  "resource": "/api/dashboard",
  "method": "GET",
  "status": 200,
  "latency": 245,
  "ip": "192.168.1.100"
}
```

## 🛡️ Consideraciones de Seguridad

### Rate Limiting
- **BFF**: 100 requests / 15 minutos por usuario
- **Microservicios**: 500 requests / minuto por service account

### mTLS
- Certificados únicos para cada servicio
- Validación mutua en todas las conexiones
- Renovación automática (30 días en producción)

### Data Masking
- Números de tarjeta → Solo últimos 4 dígitos
- CVV → **NUNCA** se almacena ni loguea
- Tokens → Solo primeros 8 caracteres en logs
- IPs → Hasheadas en producción

### PCI DSS Compliance
- ✅ No almacenar CVV/CVC
- ✅ Tokenización de números de tarjeta
- ✅ Encriptación en tránsito (TLS 1.3)
- ✅ Encriptación en reposo (PostgreSQL)
- ✅ Logging y auditoría completa
- ✅ Segregación de redes (Docker networks)

## 🗂️ Estructura del Proyecto

```
bff-financial-security/
├── diagrams/              # Diagramas Archify
├── keycloak/             # Configuración Keycloak
├── certs/                # Certificados mTLS
├── database/             # SQL schemas y seeds
├── src/
│   ├── bff/             # Backend For Frontend
│   ├── microservices/   # 4 microservicios
│   └── frontend/        # React app
├── postman/             # Postman collection
└── scripts/             # Scripts de utilidad
```

## 🐛 Troubleshooting

### Keycloak no inicia
```bash
docker-compose down -v
docker-compose up -d keycloak
docker-compose logs -f keycloak
```

### Certificados inválidos
```bash
./scripts/cleanup.sh
./scripts/generate-certs.sh
docker-compose restart
```

### Base de datos no tiene datos
```bash
docker-compose exec postgres-saldo psql -U saldo_user -d saldo_db -f /docker-entrypoint-initdb.d/seeds.sql
```

## 📚 Recursos Adicionales

- [Artículo completo en Hashnode](./ARTICLE.md)
- [OAuth2 + OIDC Spec](https://oauth.net/2/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [PCI DSS Requirements](https://www.pcisecuritystandards.org/)

## 👥 Autor

Santiago Agustín Fernández - [santiagoagustinfernandez@gmail.com](mailto:santiagoagustinfernandez@gmail.com)

## 📄 Licencia

MIT License - Ver [LICENSE](LICENSE) para más detalles.

---

**⚠️ Nota**: Este proyecto es para propósitos educativos. Para producción, se requieren auditorías de seguridad adicionales y compliance específico según regulaciones locales.
