import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';
import { logger } from '../utils/logger';

// Extend Express Request type
declare global {
  namespace Express {
    interface Request {
      user?: any;
      userToken?: string;
    }
  }
}

// JWKS client for Keycloak
const client = jwksClient({
  jwksUri: `${process.env.KEYCLOAK_URL}/realms/${process.env.KEYCLOAK_REALM}/protocol/openid-connect/certs`,
  cache: true,
  cacheMaxAge: 600000, // 10 minutes
  rateLimit: true,
  jwksRequestsPerMinute: 10,
});

const getKey = (header: any, callback: any) => {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) {
      logger.error('Error getting signing key', { error: err.message });
      return callback(err);
    }
    const signingKey = key?.getPublicKey();
    callback(null, signingKey);
  });
};

/**
 * Validate user token from Authorization header
 * This is the token from the frontend user
 */
export const validateAuth = (req: Request, res: Response, next: NextFunction): void => {
  try {
    const authHeader = req.headers['authorization'] as string;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      logger.warn('Missing authorization header', {
        requestId: req.headers['x-request-id'],
        path: req.path,
        ip: req.ip,
      });

      res.status(401).json({
        error: 'Unauthorized',
        message: 'Authorization token is required',
      });
      return;
    }

    const token = authHeader.replace('Bearer ', '');

    // Store original user token to forward to microservices
    req.userToken = token;

    // Verify token
    jwt.verify(
      token,
      getKey,
      {
        algorithms: ['RS256'],
        issuer: `${process.env.KEYCLOAK_URL}/realms/${process.env.KEYCLOAK_REALM}`,
      },
      (err, decoded: any) => {
        if (err) {
          logger.warn('Invalid user token', {
            requestId: req.headers['x-request-id'],
            error: err.message,
            path: req.path,
            ip: req.ip,
          });

          res.status(401).json({
            error: 'Unauthorized',
            message: 'Invalid or expired token',
          });
          return;
        }

        // Attach user info to request
        req.user = decoded;

        logger.info('User authenticated', {
          requestId: req.headers['x-request-id'],
          userId: decoded.sub,
          username: decoded.preferred_username,
          path: req.path,
        });

        next();
      }
    );
  } catch (error: any) {
    logger.error('Authentication error', {
      requestId: req.headers['x-request-id'],
      error: error.message,
      path: req.path,
    });

    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Error validating authentication',
    });
  }
};

/**
 * Check if user has required role
 */
export const requireRole = (...roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Authentication required',
      });
      return;
    }

    const userRoles = req.user.realm_access?.roles || [];
    const hasRole = roles.some((role) => userRoles.includes(role));

    if (!hasRole) {
      logger.warn('Insufficient permissions', {
        requestId: req.headers['x-request-id'],
        userId: req.user.sub,
        requiredRoles: roles,
        userRoles: userRoles,
        path: req.path,
      });

      res.status(403).json({
        error: 'Forbidden',
        message: 'Insufficient permissions',
      });
      return;
    }

    next();
  };
};
