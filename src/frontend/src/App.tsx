import { useKeycloak } from '@react-keycloak/web'
import Dashboard from './pages/Dashboard'

function App() {
  const { keycloak, initialized } = useKeycloak()

  if (!initialized) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        fontFamily: 'system-ui, -apple-system, sans-serif'
      }}>
        <div>
          <h2>Cargando...</h2>
          <p>Inicializando autenticación...</p>
        </div>
      </div>
    )
  }

  if (!keycloak.authenticated) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        fontFamily: 'system-ui, -apple-system, sans-serif',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        color: 'white'
      }}>
        <div style={{ textAlign: 'center', padding: '2rem', maxWidth: '500px' }}>
          <h1 style={{ fontSize: '2.5rem', marginBottom: '1rem' }}>🏦 Banking Security</h1>
          <h2 style={{ fontSize: '1.5rem', marginBottom: '2rem', fontWeight: 'normal' }}>
            Sistema Bancario con BFF
          </h2>
          <p style={{ marginBottom: '2rem', opacity: 0.9 }}>
            Demostración de arquitectura segura con Backend For Frontend,
            autenticación OAuth2/OIDC, y validación de tokens multi-capa.
          </p>
          <button
            onClick={() => keycloak.login()}
            style={{
              padding: '1rem 2rem',
              fontSize: '1.1rem',
              background: 'white',
              color: '#667eea',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
              fontWeight: 'bold',
              boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
            }}
          >
            Iniciar Sesión
          </button>
          <div style={{ marginTop: '2rem', fontSize: '0.9rem', opacity: 0.8 }}>
            <p><strong>Usuarios de prueba:</strong></p>
            <p>juan.perez / Password123!</p>
            <p>maria.gonzalez / Password123!</p>
          </div>
        </div>
      </div>
    )
  }

  return <Dashboard />
}

export default App
