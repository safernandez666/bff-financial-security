import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';
import CircuitBreaker from 'opossum';
import { logger } from '../utils/logger';
import { getServiceToken } from './serviceToken.service';

// Circuit breaker options
const circuitBreakerOptions = {
  timeout: parseInt(process.env.CIRCUIT_BREAKER_TIMEOUT || '5000'), // 5 seconds
  errorThresholdPercentage: parseFloat(process.env.CIRCUIT_BREAKER_THRESHOLD || '0.5') * 100, // 50%
  resetTimeout: 30000, // 30 seconds
};

/**
 * Create HTTP client for a microservice with circuit breaker
 */
const createServiceClient = (serviceName: string, baseURL: string): AxiosInstance => {
  const client = axios.create({
    baseURL,
    timeout: parseInt(process.env.REQUEST_TIMEOUT || '10000'), // 10 seconds
    headers: {
      'Content-Type': 'application/json',
    },
  });

  // Request interceptor to add service token
  client.interceptors.request.use(
    async (config) => {
      try {
        const serviceToken = await getServiceToken();
        config.headers.Authorization = `Bearer ${serviceToken}`;
        
        logger.debug(`Request to ${serviceName}`, {
          method: config.method?.toUpperCase(),
          url: config.url,
        });
        
        return config;
      } catch (error) {
        logger.error(`Failed to add service token for ${serviceName}`, { error });
        throw error;
      }
    },
    (error) => {
      logger.error(`Request error for ${serviceName}`, { error: error.message });
      return Promise.reject(error);
    }
  );

  // Response interceptor
  client.interceptors.response.use(
    (response) => {
      logger.debug(`Response from ${serviceName}`, {
        status: response.status,
        url: response.config.url,
      });
      return response;
    },
    (error) => {
      logger.error(`Error response from ${serviceName}`, {
        status: error.response?.status,
        message: error.message,
        url: error.config?.url,
      });
      return Promise.reject(error);
    }
  );

  return client;
};

// Create service clients
const saldoClient = createServiceClient('saldo-service', process.env.SALDO_SERVICE_URL || 'http://saldo-service:3001');
const usuarioClient = createServiceClient('usuario-service', process.env.USUARIO_SERVICE_URL || 'http://usuario-service:3002');
const prestamosClient = createServiceClient('prestamos-service', process.env.PRESTAMOS_SERVICE_URL || 'http://prestamos-service:3003');
const tarjetasClient = createServiceClient('tarjetas-service', process.env.TARJETAS_SERVICE_URL || 'http://tarjetas-service:3004');

// Circuit breaker for each service
const createBreaker = (serviceName: string, client: AxiosInstance) => {
  const breaker = new CircuitBreaker(
    async (url: string, config?: AxiosRequestConfig) => {
      return await client.get(url, config);
    },
    {
      ...circuitBreakerOptions,
      name: `${serviceName}-breaker`,
    }
  );

  // Circuit breaker events
  breaker.on('open', () => {
    logger.warn(`Circuit breaker opened for ${serviceName}`, {
      service: serviceName,
    });
  });

  breaker.on('halfOpen', () => {
    logger.info(`Circuit breaker half-open for ${serviceName}`, {
      service: serviceName,
    });
  });

  breaker.on('close', () => {
    logger.info(`Circuit breaker closed for ${serviceName}`, {
      service: serviceName,
    });
  });

  return breaker;
};

// Export clients with circuit breakers
export const saldoBreaker = createBreaker('saldo-service', saldoClient);
export const usuarioBreaker = createBreaker('usuario-service', usuarioClient);
export const prestamosBreaker = createBreaker('prestamos-service', prestamosClient);
export const tarjetasBreaker = createBreaker('tarjetas-service', tarjetasClient);

// Export raw clients (for POST, PUT, DELETE requests)
export { saldoClient, usuarioClient, prestamosClient, tarjetasClient };
