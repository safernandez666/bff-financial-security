import axios from 'axios';
import { logger } from '../utils/logger';

// Service token cache
let serviceTokenCache: {
  token: string;
  expiresAt: number;
} | null = null;

/**
 * Get service token from Keycloak using Client Credentials flow
 * This token is used for service-to-service authentication (BFF → Microservices)
 */
export const getServiceToken = async (): Promise<string> => {
  try {
    // Check if cached token is still valid
    if (serviceTokenCache && serviceTokenCache.expiresAt > Date.now()) {
      logger.debug('Using cached service token');
      return serviceTokenCache.token;
    }

    // Request new token from Keycloak
    const keycloakUrl = process.env.KEYCLOAK_URL || 'http://keycloak:8080';
    const realm = process.env.KEYCLOAK_REALM || 'financial-banking';
    const clientId = process.env.KEYCLOAK_BFF_CLIENT_ID || 'bff-banking';
    const clientSecret = process.env.KEYCLOAK_BFF_CLIENT_SECRET || 'bff-secret-change-in-production';

    logger.debug('Requesting new service token from Keycloak');

    const response = await axios.post(
      `${keycloakUrl}/realms/${realm}/protocol/openid-connect/token`,
      new URLSearchParams({
        grant_type: 'client_credentials',
        client_id: clientId,
        client_secret: clientSecret,
      }).toString(),
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        timeout: 5000,
      }
    );

    const { access_token, expires_in } = response.data;

    // Cache token (refresh before expiry, leaving 30 seconds buffer)
    const expiresAt = Date.now() + (expires_in - 30) * 1000;
    serviceTokenCache = {
      token: access_token,
      expiresAt,
    };

    logger.info('Service token obtained successfully', {
      expiresIn: `${expires_in}s`,
    });

    return access_token;
  } catch (error: any) {
    logger.error('Error obtaining service token', {
      error: error.message,
      response: error.response?.data,
    });

    throw new Error('Failed to obtain service token');
  }
};

/**
 * Clear cached service token (useful for testing or when token becomes invalid)
 */
export const clearServiceTokenCache = (): void => {
  serviceTokenCache = null;
  logger.info('Service token cache cleared');
};
