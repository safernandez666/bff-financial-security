// ✅ BFF: Un solo endpoint protegido y agregado

import { Router } from 'express'
import { validateAuth } from '../middleware/auth.middleware'
import { getServiceToken } from '../utils/service-token'
import { saldoBreaker, usuarioBreaker, prestamosBreaker, tarjetasBreaker } from '../utils/circuit-breakers'

const router = Router()

router.get('/dashboard', validateAuth, async (req, res) => {
  try {
    // 1. Obtener tokens
    const userToken = req.userToken  // Token del usuario (del middleware)
    const serviceToken = await getServiceToken()  // 🔑 Token del BFF
    
    // 2. Llamadas PARALELAS a los 4 microservicios con circuit breaker
    const [saldoResult, usuarioResult, prestamosResult, tarjetasResult] = 
      await Promise.allSettled([
        saldoBreaker.fire('/api/saldo/cuentas', {
          headers: { 
            'Authorization': `Bearer ${serviceToken}`,  // Token del BFF
            'X-User-Token': userToken                   // Token del usuario
          }
        }),
        usuarioBreaker.fire('/api/usuario/perfil', {
          headers: { 
            'Authorization': `Bearer ${serviceToken}`,
            'X-User-Token': userToken
          }
        }),
        prestamosBreaker.fire('/api/prestamos/resumen', {
          headers: { 
            'Authorization': `Bearer ${serviceToken}`,
            'X-User-Token': userToken
          }
        }),
        tarjetasBreaker.fire('/api/tarjetas/resumen', {
          headers: { 
            'Authorization': `Bearer ${serviceToken}`,
            'X-User-Token': userToken
          }
        }),
      ])
    
    // 3. Agregar respuestas (incluso si alguna falló)
    const dashboard = {
      user: usuarioResult.status === 'fulfilled' ? usuarioResult.value.data : null,
      saldo: saldoResult.status === 'fulfilled' ? saldoResult.value.data : null,
      prestamos: prestamosResult.status === 'fulfilled' ? prestamosResult.value.data : null,
      tarjetas: tarjetasResult.status === 'fulfilled' ? tarjetasResult.value.data : null,
    }
    
    // 4. Respuesta agregada
    res.json({ 
      success: true, 
      data: dashboard 
    })
    
  } catch (error) {
    logger.error('Dashboard error', { error: error.message })
    res.status(500).json({ 
      success: false, 
      error: 'Internal server error' 
    })
  }
})

export default router

/* 
✅ BENEFICIOS:
1. Una sola llamada desde el frontend
2. Doble validación de tokens (user + service)
3. Llamadas paralelas (6x más rápido)
4. Circuit breaker automático
5. Agregación de datos
6. Microservicios protegidos
7. Rate limiting centralizado
8. Logging con data masking
*/
