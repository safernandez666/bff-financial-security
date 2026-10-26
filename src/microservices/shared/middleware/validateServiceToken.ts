import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';
import logger, { logSecurityEvent } from '../utils/logger';

// JWKS client for Keycloak (reused from validateUserToken)
const getJwksClient = () => {
  const keycloakUrl = process.env.KEYCLOAK_URL || 'http://keycloak:8080';
  const realm = process.env.KEYCLOAK_REALM || 'financial-banking';
  
  return jwksClient({
    jwksUri: `${keycloakUrl}/realms/${realm}/protocol/openid-connect/certs`,
    cache: true,
    cacheMaxAge: 600000,
    rateLimit: true,
    jwksRequestsPerMinute: 10
  });
};

const getKey = (header: any, callback: any) => {
  const client = getJwksClient();
  
  client.getSigningKey(header.kid, (err, key) => {
    if (err) {
      logger.error('Error getting signing key for service token', { error: err.message });
      return callback(err);
    }
    const signingKey = key?.getPublicKey();
    callback(null, signingKey);
  });
};

// Middleware to validate service token (from BFF or other services)
// Service token comes in the Authorization header when called from BFF
export const validateServiceToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Get service token from Authorization header
    const authHeader = req.headers['authorization'] as string;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      logSecurityEvent('missing_service_token', {
        path: req.path,
        ip: req.ip,
        userAgent: req.headers['user-agent']
      }, 'high');
      
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Service token is required'
      });
      return;
    }

    const serviceToken = authHeader.replace('Bearer ', '');

    // Verify service token
    jwt.verify(
      serviceToken,
      getKey,
      {
        algorithms: ['RS256'],
        issuer: `${process.env.KEYCLOAK_URL}/realms/${process.env.KEYCLOAK_REALM}`
      },
      (err, decoded: any) => {
        if (err) {
          logSecurityEvent('invalid_service_token', {
            error: err.message,
            path: req.path,
            ip: req.ip
          }, 'critical');
          
          res.status(401).json({
            error: 'Unauthorized',
            message: 'Invalid or expired service token'
          });
          return;
        }

        // Verify it's a service account token (has specific client_id)
        const allowedClients = [
          'bff-banking',
          'saldo-service',
          'usuario-service',
          'prestamos-service',
          'tarjetas-service'
        ];

        if (!decoded.azp || !allowedClients.includes(decoded.azp)) {
          logSecurityEvent('unauthorized_service', {
            clientId: decoded.azp,
            path: req.path,
            ip: req.ip
          }, 'critical');
          
          res.status(403).json({
            error: 'Forbidden',
            message: 'Unauthorized service'
          });
          return;
        }

        logger.debug('Service token validated', {
          clientId: decoded.azp,
          tokenType: decoded.typ
        });
        
        next();
      }
    );
  } catch (error: any) {
    logSecurityEvent('service_token_validation_error', {
      error: error.message,
      path: req.path
    }, 'critical');
    
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Error validating service token'
    });
  }
};

export default validateServiceToken;
