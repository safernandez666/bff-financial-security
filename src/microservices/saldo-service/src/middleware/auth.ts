import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

// Extend Express Request type
declare global {
  namespace Express {
    interface Request {
      user?: any;
    }
  }
}

// JWKS client for Keycloak
const client = jwksClient({
  jwksUri: `${process.env.KEYCLOAK_URL}/realms/${process.env.KEYCLOAK_REALM}/protocol/openid-connect/certs`,
  cache: true,
  cacheMaxAge: 600000,
  rateLimit: true,
  jwksRequestsPerMinute: 10
});

const getKey = (header: any, callback: any) => {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) {
      return callback(err);
    }
    const signingKey = key?.getPublicKey();
    callback(null, signingKey);
  });
};

/**
 * Validate service token (from BFF)
 * Token comes in Authorization header
 */
export const validateServiceToken = (req: Request, res: Response, next: NextFunction): void => {
  try {
    const authHeader = req.headers['authorization'] as string;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Service token is required'
      });
      return;
    }

    const token = authHeader.replace('Bearer ', '');

    jwt.verify(token, getKey, {
      algorithms: ['RS256'],
      issuer: `${process.env.KEYCLOAK_URL}/realms/${process.env.KEYCLOAK_REALM}`
    }, (err, decoded: any) => {
      if (err) {
        console.error('Service token validation error:', err.message);
        res.status(401).json({
          error: 'Unauthorized',
          message: 'Invalid or expired service token'
        });
        return;
      }

      // Verify it's from an authorized service
      const allowedServices = ['bff-banking', 'saldo-service'];
      if (!decoded.azp || !allowedServices.includes(decoded.azp)) {
        res.status(403).json({
          error: 'Forbidden',
          message: 'Unauthorized service'
        });
        return;
      }

      console.log(`✅ Service token validated: ${decoded.azp}`);
      next();
    });
  } catch (error: any) {
    console.error('Service token validation error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Error validating service token'
    });
  }
};

/**
 * Validate user token (forwarded by BFF)
 * Token comes in X-User-Token header
 */
export const validateUserToken = (req: Request, res: Response, next: NextFunction): void => {
  try {
    const userToken = req.headers['x-user-token'] as string;
    
    if (!userToken) {
      res.status(401).json({
        error: 'Unauthorized',
        message: 'User token is required'
      });
      return;
    }

    jwt.verify(userToken, getKey, {
      algorithms: ['RS256'],
      issuer: `${process.env.KEYCLOAK_URL}/realms/${process.env.KEYCLOAK_REALM}`
    }, (err, decoded: any) => {
      if (err) {
        console.error('User token validation error:', err.message);
        res.status(401).json({
          error: 'Unauthorized',
          message: 'Invalid or expired user token'
        });
        return;
      }

      // Attach user info to request
      req.user = decoded;
      
      console.log(`✅ User token validated: ${decoded.preferred_username || decoded.sub}`);
      next();
    });
  } catch (error: any) {
    console.error('User token validation error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Error validating user token'
    });
  }
};
