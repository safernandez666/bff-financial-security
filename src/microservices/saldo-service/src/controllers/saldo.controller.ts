import { Request, Response } from 'express';
import { Pool } from 'pg';

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

/**
 * Get all accounts for a user
 */
export const getCuentas = async (req: Request, res: Response): Promise<void> => {
  try {
    // User ID from validated JWT token
    const userId = req.user?.attributes?.user_id?.[0] || req.user?.sub;

    if (!userId) {
      res.status(400).json({
        error: 'Bad Request',
        message: 'User ID not found in token'
      });
      return;
    }

    // Query database
    const result = await pool.query(
      `SELECT 
        id,
        numero_cuenta,
        tipo_cuenta,
        saldo,
        moneda,
        estado,
        fecha_apertura,
        created_at
      FROM cuentas
      WHERE user_id = $1 AND estado = 'activa'
      ORDER BY fecha_apertura DESC`,
      [userId]
    );

    res.status(200).json({
      success: true,
      data: result.rows,
      count: result.rows.length
    });
  } catch (error: any) {
    console.error('Error getting accounts:', error);
    
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Error retrieving accounts'
    });
  }
};

/**
 * Get total balance across all accounts
 */
export const getSaldoTotal = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user?.attributes?.user_id?.[0] || req.user?.sub;

    if (!userId) {
      res.status(400).json({
        error: 'Bad Request',
        message: 'User ID not found in token'
      });
      return;
    }

    // Get total balance by currency
    const result = await pool.query(
      `SELECT 
        moneda,
        SUM(saldo) as total_saldo,
        COUNT(*) as cantidad_cuentas
      FROM cuentas
      WHERE user_id = $1 AND estado = 'activa'
      GROUP BY moneda
      ORDER BY moneda`,
      [userId]
    );

    // Calculate grand total in primary currency (USD)
    const totalGeneral = result.rows.reduce((acc, row) => {
      // Simple conversion (in production, use real exchange rates)
      const exchangeRates: Record<string, number> = {
        'USD': 1,
        'EUR': 1.10,
        'ARS': 0.0012
      };
      
      return acc + (parseFloat(row.total_saldo) * (exchangeRates[row.moneda] || 1));
    }, 0);

    res.status(200).json({
      success: true,
      data: {
        por_moneda: result.rows.map(row => ({
          moneda: row.moneda,
          total: parseFloat(row.total_saldo),
          cantidad_cuentas: parseInt(row.cantidad_cuentas)
        })),
        total_general_usd: Math.round(totalGeneral * 100) / 100
      }
    });
  } catch (error: any) {
    console.error('Error getting total balance:', error);
    
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Error retrieving total balance'
    });
  }
};

/**
 * Get account movements
 */
export const getMovimientos = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user?.attributes?.user_id?.[0] || req.user?.sub;

    if (!userId) {
      res.status(400).json({
        error: 'Bad Request',
        message: 'User ID not found in token'
      });
      return;
    }

    // Query parameters
    const cuentaId = req.query.cuenta_id as string;
    const limit = Math.min(parseInt(req.query.limit as string) || 50, 100); // Max 100
    const offset = parseInt(req.query.offset as string) || 0;

    let query = `
      SELECT 
        m.id,
        m.cuenta_id,
        c.numero_cuenta,
        m.tipo,
        m.monto,
        m.saldo_anterior,
        m.saldo_nuevo,
        m.descripcion,
        m.referencia,
        m.fecha,
        m.created_at
      FROM movimientos m
      INNER JOIN cuentas c ON m.cuenta_id = c.id
      WHERE c.user_id = $1
    `;

    const params: any[] = [userId];
    let paramIndex = 2;

    // Filter by account if provided
    if (cuentaId) {
      query += ` AND m.cuenta_id = $${paramIndex}`;
      params.push(cuentaId);
      paramIndex++;
    }

    query += ` ORDER BY m.fecha DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);

    // Get total count for pagination
    let countQuery = `
      SELECT COUNT(*) as total
      FROM movimientos m
      INNER JOIN cuentas c ON m.cuenta_id = c.id
      WHERE c.user_id = $1
    `;
    
    const countParams: any[] = [userId];
    if (cuentaId) {
      countQuery += ` AND m.cuenta_id = $2`;
      countParams.push(cuentaId);
    }

    const countResult = await pool.query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].total);

    res.status(200).json({
      success: true,
      data: result.rows,
      pagination: {
        total,
        limit,
        offset,
        has_more: offset + limit < total
      }
    });
  } catch (error: any) {
    console.error('Error getting movements:', error);
    
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Error retrieving movements'
    });
  }
};
