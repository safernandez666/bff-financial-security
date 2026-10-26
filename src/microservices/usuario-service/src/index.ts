import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import dotenv from 'dotenv'
import { Pool } from 'pg'
import jwt from 'jsonwebtoken'
import jwksClient from 'jwks-rsa'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3002

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'usuario-db',
  port: Number(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'usuario_db',
  user: process.env.DB_USER || 'usuario_user',
  password: process.env.DB_PASSWORD || 'usuario_password',
})

// JWKS client for Keycloak
const client = jwksClient({
  jwksUri: `${process.env.KEYCLOAK_URL}/realms/${process.env.KEYCLOAK_REALM}/protocol/openid-connect/certs`,
})

function getKey(header: any, callback: any) {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) return callback(err)
    const signingKey = key?.getPublicKey()
    callback(null, signingKey)
  })
}

// Middleware
app.use(helmet())
app.use(cors())
app.use(express.json())

// Middleware: Validate Service Token
const validateServiceToken = (req: any, res: any, next: any) => {
  const authHeader = req.headers['authorization']
  if (!authHeader) return res.status(401).json({ error: 'Service token required' })

  const token = authHeader.replace('Bearer ', '')

  jwt.verify(token, getKey, {}, (err: any, decoded: any) => {
    if (err) return res.status(401).json({ error: 'Invalid service token' })

    const allowedServices = ['bff-banking']
    if (!allowedServices.includes(decoded.azp)) {
      return res.status(403).json({ error: 'Unauthorized service' })
    }

    req.serviceToken = decoded
    next()
  })
}

// Middleware: Validate User Token
const validateUserToken = (req: any, res: any, next: any) => {
  const userToken = req.headers['x-user-token']
  if (!userToken) return res.status(401).json({ error: 'User token required' })

  jwt.verify(userToken, getKey, {}, (err: any, decoded: any) => {
    if (err) return res.status(401).json({ error: 'Invalid user token' })

    req.user = decoded
    next()
  })
}

// Routes
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1')
    res.json({ status: 'healthy', service: 'usuario-service' })
  } catch (error) {
    res.status(503).json({ status: 'unhealthy', error: 'Database connection failed' })
  }
})

app.get('/api/usuario/perfil', validateServiceToken, validateUserToken, async (req: any, res) => {
  try {
    const userId = req.user.sub

    const result = await pool.query(
      'SELECT user_id, nombre, apellido, email, telefono, fecha_nacimiento FROM usuarios WHERE user_id = $1',
      [userId]
    )

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' })
    }

    res.json({ success: true, data: result.rows[0] })
  } catch (error) {
    console.error('Error fetching user profile:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
})

app.get('/api/usuario/preferencias', validateServiceToken, validateUserToken, async (req: any, res) => {
  try {
    const userId = req.user.sub

    const result = await pool.query(
      'SELECT * FROM preferencias WHERE user_id = $1',
      [userId]
    )

    res.json({ success: true, data: result.rows })
  } catch (error) {
    console.error('Error fetching preferences:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
})

// Start server
app.listen(PORT, () => {
  console.log(`✅ Usuario Service running on port ${PORT}`)
  console.log(`📊 Health check: http://localhost:${PORT}/health`)
})
