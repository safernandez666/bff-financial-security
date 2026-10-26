import { Pool, PoolConfig, QueryResult } from 'pg';
import logger from './logger';

// PostgreSQL connection pool
class Database {
  private pool: Pool;
  private static instance: Database;

  private constructor(config?: PoolConfig) {
    const poolConfig: PoolConfig = config || {
      connectionString: process.env.DATABASE_URL,
      max: 20, // Maximum number of clients in the pool
      idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
      connectionTimeoutMillis: 5000, // Timeout for establishing connection
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : undefined
    };

    this.pool = new Pool(poolConfig);

    // Log pool events
    this.pool.on('connect', () => {
      logger.debug('New database client connected');
    });

    this.pool.on('error', (err) => {
      logger.error('Unexpected database error', { error: err.message, stack: err.stack });
    });

    this.pool.on('remove', () => {
      logger.debug('Database client removed from pool');
    });
  }

  // Singleton pattern
  public static getInstance(config?: PoolConfig): Database {
    if (!Database.instance) {
      Database.instance = new Database(config);
    }
    return Database.instance;
  }

  // Execute query
  public async query<T = any>(text: string, params?: any[]): Promise<QueryResult<T>> {
    const start = Date.now();
    
    try {
      const result = await this.pool.query<T>(text, params);
      const duration = Date.now() - start;
      
      logger.debug('Executed query', {
        query: text,
        duration: `${duration}ms`,
        rows: result.rowCount
      });
      
      return result;
    } catch (error: any) {
      const duration = Date.now() - start;
      
      logger.error('Query error', {
        query: text,
        duration: `${duration}ms`,
        error: error.message,
        code: error.code
      });
      
      throw error;
    }
  }

  // Get a client from the pool (for transactions)
  public async getClient() {
    return await this.pool.connect();
  }

  // Close pool
  public async close(): Promise<void> {
    await this.pool.end();
    logger.info('Database pool closed');
  }

  // Health check
  public async healthCheck(): Promise<boolean> {
    try {
      await this.query('SELECT 1');
      return true;
    } catch (error) {
      logger.error('Database health check failed', { error });
      return false;
    }
  }
}

// Export singleton instance
export const db = Database.getInstance();

// Export for custom instances if needed
export default Database;
