import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';
import logger, { logSecurityEvent } from '../utils/logger';

// Extend Express Request to include user info
declare global {
  namespace Express {
    interface Request {
      user?: {
        sub: string; // user ID
        email?: string;
        preferred_username?: string;
        name?: string;
        realm_access?: {
          roles: string[];
        };
        resource_access?: any;
      };
    }
  }
}

// JWKS client for Keycloak
const getJwksClient = () => {
  const keycloakUrl = process.env.KEYCLOAK_URL || 'http://keycloak:8080';
  const realm = process.env.KEYCLOAK_REALM || 'financial-banking';
  
  return jwksClient({
    jwksUri: `${keycloakUrl}/realms/${realm}/protocol/openid-connect/certs`,
    cache: true,
    cacheMaxAge: 600000, // 10 minutes
    rateLimit: true,
    jwksRequestsPerMinute: 10
  });
};

// Get signing key from Keycloak JWKS
const getKey = (header: any, callback: any) => {
  const client = getJwksClient();
  
  client.getSigningKey(header.kid, (err, key) => {
    if (err) {
      logger.error('Error getting signing key', { error: err.message });
      return callback(err);
    }
    const signingKey = key?.getPublicKey();
    callback(null, signingKey);
  });
};

// Middleware to validate user token (from X-User-Token header or Authorization header)
export const validateUserToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Get token from custom header or Authorization header
    const userToken = req.headers['x-user-token'] as string || 
                      req.headers['authorization']?.replace('Bearer ', '');

    if (!userToken) {
      logSecurityEvent('missing_user_token', {
        path: req.path,
        ip: req.ip
      }, 'medium');
      
      res.status(401).json({
        error: 'Unauthorized',
        message: 'User token is required'
      });
      return;
    }

    // Verify token with Keycloak public key
    jwt.verify(
      userToken,
      getKey,
      {
        algorithms: ['RS256'],
        issuer: `${process.env.KEYCLOAK_URL}/realms/${process.env.KEYCLOAK_REALM}`
      },
      (err, decoded) => {
        if (err) {
          logSecurityEvent('invalid_user_token', {
            error: err.message,
            path: req.path,
            ip: req.ip
          }, 'high');
          
          res.status(401).json({
            error: 'Unauthorized',
            message: 'Invalid or expired user token'
          });
          return;
        }

        // Attach user info to request
        req.user = decoded as any;
        
        logger.debug('User token validated', {
          userId: req.user?.sub,
          username: req.user?.preferred_username
        });
        
        next();
      }
    );
  } catch (error: any) {
    logSecurityEvent('token_validation_error', {
      error: error.message,
      path: req.path
    }, 'high');
    
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Error validating token'
    });
  }
};

// Middleware to check if user has required role
export const requireRole = (...roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Authentication required'
      });
      return;
    }

    const userRoles = req.user.realm_access?.roles || [];
    const hasRole = roles.some(role => userRoles.includes(role));

    if (!hasRole) {
      logSecurityEvent('insufficient_permissions', {
        userId: req.user.sub,
        requiredRoles: roles,
        userRoles: userRoles,
        path: req.path
      }, 'medium');
      
      res.status(403).json({
        error: 'Forbidden',
        message: 'Insufficient permissions'
      });
      return;
    }

    next();
  };
};

export default validateUserToken;
