import winston from 'winston';

// Data masking for sensitive information
const maskSensitiveData = (data: any): any => {
  if (typeof data !== 'object' || data === null) {
    return data;
  }

  const masked = { ...data };
  const sensitiveFields = ['password', 'token', 'secret', 'authorization', 'cvv', 'pin'];

  for (const key in masked) {
    const lowerKey = key.toLowerCase();
    
    if (sensitiveFields.some(field => lowerKey.includes(field))) {
      if (lowerKey.includes('token') || lowerKey.includes('authorization')) {
        masked[key] = typeof masked[key] === 'string' && masked[key].length > 8
          ? masked[key].substring(0, 8) + '***'
          : '***';
      } else {
        masked[key] = '***';
      }
    }
    
    if (typeof masked[key] === 'object' && masked[key] !== null) {
      masked[key] = maskSensitiveData(masked[key]);
    }
  }

  return masked;
};

// Structured logging format
const structuredFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    const logObject: any = {
      timestamp,
      level,
      service: 'bff-banking',
      message,
    };

    if (Object.keys(meta).length > 0) {
      logObject.meta = maskSensitiveData(meta);
    }

    return JSON.stringify(logObject);
  })
);

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: structuredFormat,
  defaultMeta: { service: 'bff-banking' },
  transports: [
    new winston.transports.Console({
      format: process.env.NODE_ENV === 'development'
        ? winston.format.combine(winston.format.colorize(), winston.format.simple())
        : structuredFormat
    })
  ]
});
