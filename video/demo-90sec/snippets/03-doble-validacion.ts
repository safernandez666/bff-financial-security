// 🛡️ Microservicio: Doble validación de tokens

import { Request, Response, NextFunction } from 'express'
import jwt from 'jsonwebtoken'
import jwksClient from 'jwks-rsa'

// Cliente JWKS para obtener la clave pública de Keycloak
const client = jwksClient({
  jwksUri: `${process.env.KEYCLOAK_URL}/realms/${process.env.KEYCLOAK_REALM}/protocol/openid-connect/certs`,
})

function getKey(header: any, callback: any) {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) return callback(err)
    const signingKey = key?.getPublicKey()
    callback(null, signingKey)
  })
}

// ============================================
// VALIDACIÓN 1: Service Token (¿Viene del BFF?)
// ============================================
export const validateServiceToken = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization']
  
  if (!authHeader) {
    return res.status(401).json({ 
      error: 'Service token required',
      message: 'Este microservicio solo acepta llamadas del BFF'
    })
  }

  const serviceToken = authHeader.replace('Bearer ', '')

  jwt.verify(serviceToken, getKey, {}, (err: any, decoded: any) => {
    if (err) {
      return res.status(401).json({ 
        error: 'Invalid service token',
        message: 'Token del BFF inválido o expirado'
      })
    }

    // ✅ Verificar que el token viene de un servicio autorizado
    const allowedServices = ['bff-banking']
    if (!allowedServices.includes(decoded.azp)) {
      return res.status(403).json({ 
        error: 'Unauthorized service',
        message: `Servicio ${decoded.azp} no autorizado`
      })
    }

    req.serviceToken = decoded
    next()
  })
}

// ============================================
// VALIDACIÓN 2: User Token (¿Quién es el usuario?)
// ============================================
export const validateUserToken = (req: Request, res: Response, next: NextFunction) => {
  const userToken = req.headers['x-user-token'] as string

  if (!userToken) {
    return res.status(401).json({ 
      error: 'User token required',
      message: 'Se requiere token del usuario'
    })
  }

  jwt.verify(userToken, getKey, {}, (err: any, decoded: any) => {
    if (err) {
      return res.status(401).json({ 
        error: 'Invalid user token',
        message: 'Token del usuario inválido o expirado'
      })
    }

    // ✅ Extraer información del usuario para RBAC
    req.user = {
      id: decoded.sub,
      email: decoded.email,
      roles: decoded.realm_access?.roles || [],
      preferredUsername: decoded.preferred_username,
    }

    next()
  })
}

// ============================================
// USO EN RUTAS
// ============================================
import { Router } from 'express'

const router = Router()

// Ruta protegida con DOBLE VALIDACIÓN
router.get('/cuentas',
  validateServiceToken,  // 1️⃣ Primero: ¿Viene del BFF autorizado?
  validateUserToken,     // 2️⃣ Segundo: ¿Quién es el usuario?
  async (req, res) => {
    // ✅ Aquí llegamos solo si AMBAS validaciones pasaron
    
    const userId = req.user.id
    const cuentas = await getCuentasDelUsuario(userId)
    
    res.json({ 
      success: true, 
      data: cuentas 
    })
  }
)

export default router

/* 
🛡️ SEGURIDAD:

Sin Service Token:
- Llamada directa del frontend → ❌ BLOQUEADA
- Atacante con user token robado → ❌ BLOQUEADA

Solo con ambos tokens:
- BFF con user token válido → ✅ PERMITIDA

Esto previene:
1. Acceso directo a microservicios
2. Uso de tokens robados
3. Bypass de rate limiting del BFF
4. Bypass de circuit breakers
5. Ataques man-in-the-middle
*/
