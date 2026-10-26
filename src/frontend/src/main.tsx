import React from 'react'
import ReactDOM from 'react-dom/client'
import { ReactKeycloakProvider } from '@react-keycloak/web'
import keycloak from './config/keycloak.config'
import App from './App'
import './styles/globals.css'

const eventLogger = (event: unknown, error: unknown) => {
  console.log('Keycloak event:', event, error)
}

const tokenLogger = (tokens: unknown) => {
  console.log('Keycloak tokens updated:', tokens)
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ReactKeycloakProvider
      authClient={keycloak}
      initOptions={{
        onLoad: 'check-sso',
        silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html',
        pkceMethod: 'S256',
      }}
      onEvent={eventLogger}
      onTokens={tokenLogger}
    >
      <App />
    </ReactKeycloakProvider>
  </React.StrictMode>,
)
