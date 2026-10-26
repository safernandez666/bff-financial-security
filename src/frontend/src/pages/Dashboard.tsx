import { useEffect, useState } from 'react'
import { useKeycloak } from '@react-keycloak/web'
import axios from 'axios'

interface DashboardData {
  user: any
  saldo: any
  prestamos: any
  tarjetas: any
  errors: any[]
}

function Dashboard() {
  const { keycloak } = useKeycloak()
  const [data, setData] = useState<DashboardData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchDashboard()
  }, [])

  const fetchDashboard = async () => {
    try {
      setLoading(true)
      setError(null)

      const response = await axios.get(
        `${import.meta.env.VITE_BFF_URL || 'http://localhost:4000'}/api/dashboard`,
        {
          headers: {
            Authorization: `Bearer ${keycloak.token}`,
          },
        }
      )

      setData(response.data.data)
    } catch (err: any) {
      console.error('Error fetching dashboard:', err)
      setError(err.response?.data?.message || 'Error cargando dashboard')
    } finally {
      setLoading(false)
    }
  }

  const handleLogout = () => {
    keycloak.logout()
  }

  if (loading) {
    return (
      <div style={styles.container}>
        <div style={styles.loading}>
          <h2>Cargando dashboard...</h2>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div style={styles.container}>
        <div style={{ ...styles.card, background: '#fee', border: '2px solid #fcc' }}>
          <h2>❌ Error</h2>
          <p>{error}</p>
          <button onClick={fetchDashboard} style={styles.button}>
            Reintentar
          </button>
        </div>
      </div>
    )
  }

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <div>
          <h1 style={styles.title}>🏦 Banking Dashboard</h1>
          <p style={styles.subtitle}>
            Usuario: <strong>{keycloak.tokenParsed?.preferred_username}</strong>
          </p>
        </div>
        <button onClick={handleLogout} style={styles.logoutButton}>
          Cerrar Sesión
        </button>
      </div>

      <div style={styles.grid}>
        {/* Saldo Card */}
        <div style={styles.card}>
          <h2 style={styles.cardTitle}>💰 Saldo</h2>
          {data?.saldo ? (
            <div>
              <p><strong>Cuentas:</strong> {data.saldo.length || 0}</p>
              {data.saldo.map((cuenta: any, idx: number) => (
                <div key={idx} style={styles.item}>
                  <p><strong>{cuenta.tipo_cuenta}:</strong> {cuenta.moneda} {cuenta.saldo}</p>
                  <p style={styles.itemDetail}>Cuenta: ***{cuenta.numero_cuenta?.slice(-4)}</p>
                </div>
              ))}
            </div>
          ) : (
            <p style={styles.emptyState}>Sin datos de saldo</p>
          )}
        </div>

        {/* Usuario Card */}
        <div style={styles.card}>
          <h2 style={styles.cardTitle}>👤 Perfil</h2>
          {data?.user ? (
            <div>
              <p><strong>Nombre:</strong> {data.user.nombre_completo || 'N/A'}</p>
              <p><strong>DNI:</strong> {data.user.dni || 'N/A'}</p>
              <p><strong>Email:</strong> {keycloak.tokenParsed?.email || 'N/A'}</p>
            </div>
          ) : (
            <p style={styles.emptyState}>Sin datos de perfil</p>
          )}
        </div>

        {/* Préstamos Card */}
        <div style={styles.card}>
          <h2 style={styles.cardTitle}>🏠 Préstamos</h2>
          {data?.prestamos && data.prestamos.length > 0 ? (
            <div>
              <p><strong>Préstamos activos:</strong> {data.prestamos.length}</p>
              {data.prestamos.slice(0, 2).map((prestamo: any, idx: number) => (
                <div key={idx} style={styles.item}>
                  <p><strong>{prestamo.tipo_prestamo}:</strong> USD {prestamo.monto_aprobado}</p>
                  <p style={styles.itemDetail}>Cuotas: {prestamo.cuotas_pagadas}/{prestamo.plazo_total}</p>
                </div>
              ))}
            </div>
          ) : (
            <p style={styles.emptyState}>Sin préstamos activos</p>
          )}
        </div>

        {/* Tarjetas Card */}
        <div style={styles.card}>
          <h2 style={styles.cardTitle}>💳 Tarjetas</h2>
          {data?.tarjetas && data.tarjetas.length > 0 ? (
            <div>
              <p><strong>Tarjetas:</strong> {data.tarjetas.length}</p>
              {data.tarjetas.slice(0, 2).map((tarjeta: any, idx: number) => (
                <div key={idx} style={styles.item}>
                  <p><strong>{tarjeta.tipo} {tarjeta.marca}:</strong> ***{tarjeta.ultimos_digitos}</p>
                  <p style={styles.itemDetail}>
                    {tarjeta.tipo === 'credito' ? `Disponible: USD ${tarjeta.saldo_disponible}` : 'Débito'}
                  </p>
                </div>
              ))}
            </div>
          ) : (
            <p style={styles.emptyState}>Sin tarjetas</p>
          )}
        </div>
      </div>

      {/* Errors */}
      {data?.errors && data.errors.length > 0 && (
        <div style={{ ...styles.card, background: '#fff3cd', marginTop: '1rem' }}>
          <h3>⚠️ Advertencias</h3>
          {data.errors.map((err: any, idx: number) => (
            <p key={idx}>• {err.service}: {err.message}</p>
          ))}
        </div>
      )}

      {/* Footer Info */}
      <div style={styles.footer}>
        <p>
          🔐 <strong>Seguridad:</strong> Autenticado vía Keycloak OAuth2/OIDC | 
          Tokens validados | Rate limiting activo
        </p>
      </div>
    </div>
  )
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    minHeight: '100vh',
    background: '#f5f5f5',
    padding: '2rem',
    fontFamily: 'system-ui, -apple-system, sans-serif',
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '2rem',
    padding: '1.5rem',
    background: 'white',
    borderRadius: '12px',
    boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
  },
  title: {
    margin: 0,
    fontSize: '2rem',
    color: '#333',
  },
  subtitle: {
    margin: '0.5rem 0 0 0',
    color: '#666',
  },
  logoutButton: {
    padding: '0.75rem 1.5rem',
    background: '#dc3545',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    cursor: 'pointer',
    fontSize: '1rem',
    fontWeight: 'bold',
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
    gap: '1.5rem',
  },
  card: {
    background: 'white',
    padding: '1.5rem',
    borderRadius: '12px',
    boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
  },
  cardTitle: {
    margin: '0 0 1rem 0',
    fontSize: '1.5rem',
    color: '#333',
  },
  item: {
    padding: '0.75rem',
    background: '#f9f9f9',
    borderRadius: '6px',
    marginBottom: '0.5rem',
  },
  itemDetail: {
    fontSize: '0.9rem',
    color: '#666',
    margin: '0.25rem 0 0 0',
  },
  emptyState: {
    color: '#999',
    fontStyle: 'italic',
  },
  loading: {
    textAlign: 'center',
    padding: '4rem',
  },
  button: {
    padding: '0.75rem 1.5rem',
    background: '#667eea',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    cursor: 'pointer',
    fontSize: '1rem',
    marginTop: '1rem',
  },
  footer: {
    marginTop: '2rem',
    padding: '1rem',
    background: 'white',
    borderRadius: '12px',
    textAlign: 'center',
    fontSize: '0.9rem',
    color: '#666',
  },
}

export default Dashboard
