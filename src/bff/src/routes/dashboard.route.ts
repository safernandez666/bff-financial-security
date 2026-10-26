import { Router, Request, Response } from 'express';
import { validateAuth } from '../middleware/auth.middleware';
import { logger } from '../utils/logger';
import {
  saldoBreaker,
  usuarioBreaker,
  prestamosBreaker,
  tarjetasBreaker,
} from '../services/httpClient.service';

const router = Router();

/**
 * GET /api/dashboard
 * Aggregate data from all microservices for the user's dashboard
 * 
 * This endpoint demonstrates the BFF pattern:
 * 1. Validates user token (from frontend)
 * 2. Calls multiple microservices in parallel
 * 3. Aggregates responses
 * 4. Returns a single, optimized response to the frontend
 * 
 * Security layers:
 * - User authentication (validateAuth middleware)
 * - Service token (automatically added by HTTP client)
 * - Circuit breaker (automatic fallback on service failures)
 * - Rate limiting (applied globally in index.ts)
 */
router.get('/', validateAuth, async (req: Request, res: Response): Promise<void> => {
  const requestId = req.headers['x-request-id'] as string;
  const userId = req.user?.sub;
  const userToken = req.userToken;

  try {
    logger.info('Dashboard request started', {
      requestId,
      userId,
      username: req.user?.preferred_username,
    });

    const startTime = Date.now();

    // Call all microservices in parallel with circuit breakers
    // Each call includes:
    // - Service token (in Authorization header - added by HTTP client)
    // - User token (in X-User-Token header - forwarded from frontend)
    const [saldoResult, usuarioResult, prestamosResult, tarjetasResult] = await Promise.allSettled([
      // Saldo Service
      saldoBreaker.fire('/api/saldo/cuentas', {
        headers: { 'X-User-Token': userToken },
      }),

      // Usuario Service  
      usuarioBreaker.fire('/api/usuario/perfil', {
        headers: { 'X-User-Token': userToken },
      }),

      // Prestamos Service
      prestamosBreaker.fire('/api/prestamos/resumen', {
        headers: { 'X-User-Token': userToken },
      }),

      // Tarjetas Service
      tarjetasBreaker.fire('/api/tarjetas/resumen', {
        headers: { 'X-User-Token': userToken },
      }),
    ]);

    const duration = Date.now() - startTime;

    // Aggregate responses
    const dashboard: any = {
      user: null,
      saldo: null,
      prestamos: null,
      tarjetas: null,
      errors: [],
    };

    // Process Usuario response
    if (usuarioResult.status === 'fulfilled') {
      dashboard.user = usuarioResult.value.data?.data || null;
    } else {
      logger.warn('Usuario service failed', {
        requestId,
        error: usuarioResult.reason?.message,
      });
      dashboard.errors.push({
        service: 'usuario',
        message: 'Failed to fetch user profile',
      });
    }

    // Process Saldo response
    if (saldoResult.status === 'fulfilled') {
      dashboard.saldo = saldoResult.value.data?.data || null;
    } else {
      logger.warn('Saldo service failed', {
        requestId,
        error: saldoResult.reason?.message,
      });
      dashboard.errors.push({
        service: 'saldo',
        message: 'Failed to fetch account balance',
      });
    }

    // Process Prestamos response
    if (prestamosResult.status === 'fulfilled') {
      dashboard.prestamos = prestamosResult.value.data?.data || null;
    } else {
      logger.warn('Prestamos service failed', {
        requestId,
        error: prestamosResult.reason?.message,
      });
      dashboard.errors.push({
        service: 'prestamos',
        message: 'Failed to fetch loans',
      });
    }

    // Process Tarjetas response
    if (tarjetasResult.status === 'fulfilled') {
      dashboard.tarjetas = tarjetasResult.value.data?.data || null;
    } else {
      logger.warn('Tarjetas service failed', {
        requestId,
        error: tarjetasResult.reason?.message,
      });
      dashboard.errors.push({
        service: 'tarjetas',
        message: 'Failed to fetch cards',
      });
    }

    // Log successful aggregation
    logger.info('Dashboard request completed', {
      requestId,
      userId,
      duration: `${duration}ms`,
      successfulServices: 4 - dashboard.errors.length,
      failedServices: dashboard.errors.length,
    });

    // Return aggregated response
    res.status(200).json({
      success: true,
      data: dashboard,
      metadata: {
        requestId,
        timestamp: new Date().toISOString(),
        duration: `${duration}ms`,
        servicesQueried: 4,
        successfulServices: 4 - dashboard.errors.length,
      },
    });
  } catch (error: any) {
    logger.error('Dashboard request failed', {
      requestId,
      userId,
      error: error.message,
      stack: error.stack,
    });

    res.status(500).json({
      success: false,
      error: 'Internal Server Error',
      message: 'Failed to fetch dashboard data',
      requestId,
    });
  }
});

export default router;
