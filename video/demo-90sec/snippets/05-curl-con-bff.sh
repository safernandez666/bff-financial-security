#!/bin/bash

# ✅ ATAQUE CON BFF - BLOQUEADO (Protegido)

# El mismo atacante intenta lo mismo, pero ahora el microservicio
# exige doble validación (user token + service token)

echo "🔒 Intentando acceder directamente al microservicio..."
echo "   (con BFF implementado)"
echo ""

curl -X GET http://saldo-service:3001/api/saldo/cuentas \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ..." \
  -H "Content-Type: application/json" \
  -v

# ❌ RESPUESTA: 401 Unauthorized
# {
#   "error": "Service token required",
#   "message": "Este microservicio solo acepta llamadas del BFF"
# }

echo ""
echo "✅ ATAQUE BLOQUEADO - SISTEMA PROTEGIDO!"
echo ""
echo "¿Por qué se bloqueó?"
echo "  1. El microservicio exige DOS tokens:"
echo "     • User Token (del usuario) ✅ Lo tiene el atacante"
echo "     • Service Token (del BFF)  ❌ Solo lo tiene el BFF"
echo ""
echo "  2. El atacante solo tiene el user token"
echo "  3. Sin el service token, el acceso se NIEGA"
echo ""
echo "Beneficios:"
echo "  ✅ Microservicio protegido detrás del BFF"
echo "  ✅ Token robado es inútil sin el service token"
echo "  ✅ Todas las peticiones pasan por validación del BFF"
echo "  ✅ Rate limiting activo"
echo "  ✅ Circuit breaker activo"
echo "  ✅ Logging centralizado"
echo ""
echo "═══════════════════════════════════════════"
echo "  BFF = Tu capa de seguridad esencial"
echo "═══════════════════════════════════════════"
