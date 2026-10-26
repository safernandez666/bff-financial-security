#!/bin/bash

# ❌ ATAQUE SIN BFF - EXITOSO (Vulnerable)

# Un atacante roba el token del usuario y lo usa directamente
# contra el microservicio

echo "🔓 Intentando acceder directamente al microservicio..."
echo "   (sin pasar por el BFF)"
echo ""

curl -X GET http://saldo-service:3001/api/saldo/cuentas \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ..." \
  -H "Content-Type: application/json"

# ✅ RESPUESTA: 200 OK
# {
#   "success": true,
#   "data": {
#     "cuentas": [
#       {
#         "id": "uuid-1",
#         "numero_cuenta": "****9001",
#         "saldo": 45000.00,
#         "moneda": "USD"
#       }
#     ]
#   }
# }

echo ""
echo "❌ ACCESO PERMITIDO - SISTEMA VULNERABLE!"
echo ""
echo "Problemas:"
echo "  1. El microservicio está expuesto directamente"
echo "  2. Solo valida el user token (fácil de robar)"
echo "  3. Sin validación de que viene del BFF"
echo "  4. Bypass del rate limiting"
echo "  5. Bypass del circuit breaker"
echo "  6. Datos sensibles comprometidos"
