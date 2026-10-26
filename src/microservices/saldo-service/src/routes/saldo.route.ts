import { Router } from 'express';
import {
  getCuentas,
  getSaldoTotal,
  getMovimientos
} from '../controllers/saldo.controller';

// Import middleware from shared (simulated - in real scenario would import from shared package)
// For now, we'll use simplified inline versions
import { validateUserToken, validateServiceToken } from '../middleware/auth';

const router = Router();

// All routes require both user token (X-User-Token) and service token (Authorization)
// This ensures that:
// 1. We know WHO the user is (user token)
// 2. The request comes from an authorized service (service token - BFF)

/**
 * GET /api/saldo/cuentas
 * Get all accounts for the authenticated user
 * Requires: X-User-Token (user JWT) + Authorization (service JWT from BFF)
 */
router.get('/cuentas',
  validateServiceToken,  // First validate it's coming from authorized service (BFF)
  validateUserToken,     // Then validate the user token
  getCuentas
);

/**
 * GET /api/saldo/total
 * Get total balance across all accounts for the authenticated user
 * Requires: X-User-Token + Authorization
 */
router.get('/total',
  validateServiceToken,
  validateUserToken,
  getSaldoTotal
);

/**
 * GET /api/saldo/movimientos
 * Get account movements for the authenticated user
 * Query params:
 *   - cuenta_id (optional): Filter by account ID
 *   - limit (optional): Limit number of results (default: 50)
 *   - offset (optional): Pagination offset (default: 0)
 * Requires: X-User-Token + Authorization
 */
router.get('/movimientos',
  validateServiceToken,
  validateUserToken,
  getMovimientos
);

export default router;
