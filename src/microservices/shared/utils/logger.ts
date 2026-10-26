import winston from 'winston';

// Data masking para información sensible
const maskSensitiveData = (data: any): any => {
  if (typeof data !== 'object' || data === null) {
    return data;
  }

  const masked = { ...data };
  const sensitiveFields = [
    'password', 'token', 'secret', 'authorization',
    'cvv', 'pin', 'ssn', 'credit_card', 'card_number'
  ];

  for (const key in masked) {
    const lowerKey = key.toLowerCase();
    
    // Mask sensitive fields
    if (sensitiveFields.some(field => lowerKey.includes(field))) {
      if (lowerKey.includes('token') || lowerKey.includes('authorization')) {
        // Show only first 8 characters for tokens
        masked[key] = typeof masked[key] === 'string' && masked[key].length > 8
          ? masked[key].substring(0, 8) + '***'
          : '***';
      } else if (lowerKey.includes('card') || lowerKey.includes('numero_tarjeta')) {
        // Show only last 4 digits for card numbers
        masked[key] = typeof masked[key] === 'string' && masked[key].length > 4
          ? '****' + masked[key].slice(-4)
          : '****';
      } else {
        masked[key] = '***';
      }
    }
    
    // Recursive masking for nested objects
    if (typeof masked[key] === 'object' && masked[key] !== null) {
      masked[key] = maskSensitiveData(masked[key]);
    }
  }

  return masked;
};

// Custom format for structured logging
const structuredFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ timestamp, level, message, service, requestId, userId, ...meta }) => {
    const logObject: any = {
      timestamp,
      level,
      service: service || process.env.SERVICE_NAME || 'unknown',
      message,
    };

    if (requestId) logObject.requestId = requestId;
    if (userId) logObject.userId = userId;

    // Mask sensitive data in meta
    if (Object.keys(meta).length > 0) {
      logObject.meta = maskSensitiveData(meta);
    }

    return JSON.stringify(logObject);
  })
);

// Create logger instance
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: structuredFormat,
  defaultMeta: { service: process.env.SERVICE_NAME || 'microservice' },
  transports: [
    new winston.transports.Console({
      format: process.env.NODE_ENV === 'development'
        ? winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
          )
        : structuredFormat
    })
  ]
});

// Helper methods for common logging patterns
export const logRequest = (req: any, userId?: string) => {
  logger.info('Incoming request', {
    requestId: req.id || req.headers['x-request-id'],
    userId: userId || req.user?.sub,
    method: req.method,
    path: req.path,
    ip: req.ip || req.headers['x-forwarded-for'] || req.connection.remoteAddress,
    userAgent: req.headers['user-agent']
  });
};

export const logResponse = (req: any, statusCode: number, latency: number) => {
  logger.info('Request completed', {
    requestId: req.id || req.headers['x-request-id'],
    method: req.method,
    path: req.path,
    statusCode,
    latency: `${latency}ms`
  });
};

export const logError = (error: Error, req?: any, context?: any) => {
  logger.error('Error occurred', {
    requestId: req?.id || req?.headers?.['x-request-id'],
    message: error.message,
    stack: error.stack,
    ...context
  });
};

export const logSecurityEvent = (event: string, details: any, severity: 'low' | 'medium' | 'high' | 'critical' = 'medium') => {
  logger.warn('Security event', {
    event,
    severity,
    details: maskSensitiveData(details),
    timestamp: new Date().toISOString()
  });
};

export default logger;
