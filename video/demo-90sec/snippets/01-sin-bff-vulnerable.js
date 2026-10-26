// ❌ Frontend sin protección - Anti-patrón

// Llamada 1: Servicio de Saldo
fetch('http://saldo-service:3001/api/saldo/cuentas', {
  headers: { 
    'Authorization': 'Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...' 
  }
})
.then(res => res.json())
.then(data => console.log('Saldo:', data))

// Llamada 2: Servicio de Usuario
fetch('http://usuario-service:3002/api/usuario/perfil', {
  headers: { 
    'Authorization': 'Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...' 
  }
})
.then(res => res.json())
.then(data => console.log('Usuario:', data))

// Llamada 3: Servicio de Préstamos
fetch('http://prestamos-service:3003/api/prestamos/resumen', {
  headers: { 
    'Authorization': 'Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...' 
  }
})
.then(res => res.json())
.then(data => console.log('Préstamos:', data))

// Llamada 4: Servicio de Tarjetas
fetch('http://tarjetas-service:3004/api/tarjetas/resumen', {
  headers: { 
    'Authorization': 'Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...' 
  }
})
.then(res => res.json())
.then(data => console.log('Tarjetas:', data))

/* 
❌ PROBLEMAS:
1. Microservicios expuestos directamente
2. Tokens visibles en cada request
3. Sin validación centralizada  
4. 4 requests lentos (secuenciales)
5. Superficie de ataque amplia
6. Sin rate limiting
7. Sin circuit breaker
8. Complejidad en el frontend
*/
