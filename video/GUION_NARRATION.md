# Guion de Narración - Video Demo BFF Security
## Duración estimada: 8-10 minutos

---

## INTRO (30 segundos)

**[VISUAL: Logo + Título]**

> Hola, soy Santiago Fernández. Hoy vamos a ver cómo implementar un Backend For Frontend con arquitectura de seguridad multicapa para proteger microservicios. 
> 
> Este patrón no es solo para aplicaciones financieras, también aplica a e-commerce, salud, SaaS, logística, o cualquier sistema que maneje datos sensibles.

---

## SECCIÓN 1: EL PROBLEMA (1 minuto)

**[VISUAL: Diagrama arquitectura insegura]**

> Imagina una aplicación con varios microservicios. El error más común es exponer estos servicios directamente al frontend. Veamos por qué esto es peligroso.
> 
> **Primer problema**: Superficie de ataque amplia. Cada microservicio es un punto de entrada para un atacante.
> 
> **Segundo problema**: Sin control centralizado. No hay un punto único donde aplicar políticas de seguridad.
> 
> **Tercer problema**: El frontend debe manejar múltiples tokens y realizar muchas llamadas, aumentando la latencia y complejidad.

---

## SECCIÓN 2: LA SOLUCIÓN - BFF (1 minuto)

**[VISUAL: Diagrama arquitectura con BFF]**

> La solución es un Backend For Frontend, o BFF. Actúa como gatekeeper entre el cliente y los microservicios internos.
> 
> El BFF es el único punto de entrada. Todos los requests pasan por él. Esto nos permite centralizar validaciones, agregar datos de múltiples servicios, y aplicar rate limiting en un solo lugar.
> 
> Los microservicios quedan completamente protegidos detrás del BFF. Nadie puede acceder a ellos directamente.

**[VISUAL: Transición a lista de capas]**

> Nuestro BFF implementa 10 capas de seguridad. Vamos a revisarlas una por una.

---

## SECCIÓN 3: CAPA 1 - OAuth2 + OIDC (1 minuto)

**[VISUAL: Flujo OAuth2 con Keycloak]**

> Primera capa: OAuth2 con OpenID Connect usando Keycloak como proveedor de identidad.
> 
> Cuando un usuario hace login, el frontend lo redirige a Keycloak. El usuario ingresa sus credenciales, Keycloak las valida y devuelve un authorization code.
> 
> El frontend intercambia este código por un access token usando PKCE, que es clave para aplicaciones públicas.

**[VISUAL: Código frontend Keycloak init]**

> Aquí vemos cómo se inicializa Keycloak en el frontend. El parámetro pkceMethod en S256 garantiza que el código de autorización no pueda ser interceptado y usado por un atacante.

---

## SECCIÓN 4: CAPA 3 - DOBLE VALIDACIÓN (2 minutos)

**[VISUAL: Diagrama doble token]**

> Esta es la capa más importante. El BFF implementa doble validación de tokens.
> 
> Cada request a un microservicio incluye DOS tokens: el user token y el service token.

**[VISUAL: Header X-User-Token]**

> El user token indica QUIÉN es el usuario. Lo envía el frontend en el header Authorization.

**[VISUAL: Header Authorization con service token]**

> El service token indica que la petición viene de un servicio autorizado, en este caso el BFF. Este token lo obtiene el BFF directamente de Keycloak usando client credentials flow.

**[VISUAL: Código BFF - getServiceToken]**

> Aquí vemos cómo el BFF obtiene su propio token de servicio. Usa sus credenciales de cliente para autenticarse con Keycloak.

**[VISUAL: Código BFF - llamada a microservicio]**

> Cuando el BFF llama a un microservicio, incluye ambos tokens: el service token en Authorization y el user token en X-User-Token.

**[VISUAL: Código microservicio - validación]**

> En el microservicio, tenemos dos middlewares de validación. El primero verifica que el service token sea válido y venga de un servicio autorizado como el BFF.
> 
> El segundo middleware valida el user token y extrae la información del usuario para aplicar control de acceso basado en roles.

**[VISUAL: Destacar flujo]**

> ¿Por qué dos tokens? Porque si un atacante roba el user token, no puede usarlo directamente contra los microservicios. Necesita también el service token, que solo tiene el BFF.

---

## SECCIÓN 5: CAPA 4 - mTLS (1 minuto)

**[VISUAL: Certificados mTLS]**

> Cuarta capa: mTLS o mutual TLS. Los microservicios solo aceptan conexiones del BFF usando certificados mutuos.
> 
> Generamos una autoridad certificadora propia y certificados para cada servicio. El BFF presenta su certificado al conectarse, y el microservicio verifica que es quien dice ser.

**[VISUAL: Código axios con certificados]**

> Aquí configuramos el cliente HTTP del BFF con los certificados. Solo conexiones con certificado válido pueden comunicarse con los microservicios.

---

## SECCIÓN 6: CAPAS 5 y 6 - RATE LIMITING Y CIRCUIT BREAKER (1.5 minutos)

**[VISUAL: Código rate limiting]**

> Quinta capa: Rate limiting. Limitamos a 100 requests cada 15 minutos por cliente. Esto protege contra ataques de fuerza bruta y abuso.

**[VISUAL: Diagrama circuit breaker estados]**

> Sexta capa: Circuit breaker usando Opossum. Esto nos da resiliencia ante fallos.
> 
> El circuit breaker tiene tres estados: cerrado cuando todo funciona, abierto cuando el servicio falla mucho, y semi-abierto cuando está probando si el servicio se recuperó.

**[VISUAL: Código circuit breaker configuración]**

> Configuramos el circuit breaker con un timeout de 5 segundos y un threshold del 50%. Si más de la mitad de las peticiones fallan, se abre el circuito.

---

## SECCIÓN 7: CAPAS 7, 8 y 9 - HEADERS, CORS, DATA MASKING (1.5 minutos)

**[VISUAL: Código helmet]**

> Séptima capa: Security headers con Helmet. Aplicamos cabeceras como X-Frame-Options para prevenir clickjacking, Content-Security-Policy para prevenir XSS, y HSTS para forzar HTTPS.

**[VISUAL: Código CORS]**

> Octava capa: CORS restrictivo. Solo permitimos requests desde orígenes autorizados, en este caso nuestro frontend en localhost:5173.

**[VISUAL: Código data masking]**

> Novena capa: Data masking en logs. Nunca logueamos datos sensibles completos.
> 
> Los tokens solo muestran los primeros 8 caracteres. Los números de tarjeta solo muestran los últimos 4 dígitos. Las contraseñas se ocultan completamente.

---

## SECCIÓN 8: CAPA 10 - INPUT VALIDATION (1 minuto)

**[VISUAL: Código Zod validation]**

> Décima capa: Validación de inputs con Zod. Cada endpoint valida sus parámetros antes de procesarlos.
> 
> Aquí vemos un schema que valida que userId sea un UUID válido, periodo sea uno de los valores permitidos, y limit esté entre 1 y 100.
> 
> Si la validación falla, retornamos un error 400 con los detalles específicos.

---

## SECCIÓN 9: FLUJO COMPLETO (1.5 minutos)

**[VISUAL: Diagrama flujo completo animado]**

> Veamos cómo funciona todo junto cuando un usuario accede a su dashboard.
> 
> 1. El usuario accede al frontend y hace login con Keycloak usando OAuth2 y PKCE.
> 2. El frontend obtiene un access token y lo envía al BFF.
> 3. El BFF valida el user token con Keycloak.
> 4. El BFF verifica el rate limit.
> 5. El BFF obtiene su propio service token.
> 6. El BFF hace llamadas paralelas a los 4 microservicios, cada una con circuit breaker.
> 7. Cada microservicio valida el service token, luego el user token, verifica permisos, y consulta su base de datos.
> 8. El BFF agrega todas las respuestas en un solo JSON.
> 9. El BFF aplica data masking en los logs.
> 10. El frontend recibe la respuesta y renderiza el dashboard.

**[VISUAL: Código endpoint dashboard]**

> Este es el endpoint del dashboard en el BFF. Usa Promise.allSettled para hacer las llamadas en paralelo y agrega los resultados, incluso si algún servicio falla.

---

## SECCIÓN 10: COMPLIANCE (45 segundos)

**[VISUAL: Checklist PCI DSS]**

> Para aplicaciones financieras, PCI DSS es obligatorio. Nuestra implementación cumple con los requisitos principales:
> 
> - Nunca almacenar CVV o CVC
> - Encriptación en tránsito con TLS 1.3 y mTLS
> - Encriptación en reposo en PostgreSQL
> - Logging y auditoría completa
> - Rate limiting contra fuerza bruta
> - Strong authentication con OAuth2 y soporte para MFA

---

## SECCIÓN 11: BASE DE DATOS (30 segundos)

**[VISUAL: Diagrama database per service]**

> Cada microservicio tiene su propia base de datos PostgreSQL. Esto da independencia, escalado independiente, y fallo aislado.
> 
> Si una base de datos cae, las otras siguen funcionando.

---

## CIERRE (30 segundos)

**[VISUAL: Resumen puntos clave]**

> Recapitulando los puntos clave:
> 
> ✅ Nunca exponer microservicios directamente
> ✅ Doble validación de tokens: user token + service token  
> ✅ mTLS para comunicación service-to-service
> ✅ Rate limiting y circuit breakers para resiliencia
> ✅ Data masking para compliance
> ✅ Validación de inputs en todos los endpoints
> 
> La seguridad no es un feature, es un requisito fundamental. Cada capa suma, y la combinación de todas crea un sistema robusto y confiable.

**[VISUAL: Enlaces y recursos]**

> El código completo está en mi GitHub. También puedes ver el diagrama interactivo de arquitectura y leer el artículo completo en mi blog.
> 
> Si te gustó este video, déjame un comentario. ¡Hasta la próxima!

---

## NOTAS DE PRODUCCIÓN

### Timing sugerido por sección:
- Intro: 0:00 - 0:30
- Problema: 0:30 - 1:30
- Solución BFF: 1:30 - 2:30
- OAuth2: 2:30 - 3:30
- Doble validación: 3:30 - 5:30
- mTLS: 5:30 - 6:30
- Rate limiting + Circuit breaker: 6:30 - 8:00
- Headers + CORS + Masking: 8:00 - 9:30
- Input validation: 9:30 - 10:30
- Flujo completo: 10:30 - 12:00
- Compliance: 12:00 - 12:45
- Base de datos: 12:45 - 13:15
- Cierre: 13:15 - 14:00

### Tono de voz:
- Profesional pero accesible
- Ritmo moderado (no muy rápido)
- Pausas breves entre secciones
- Énfasis en palabras clave (tokens, validación, seguridad)

### Música de fondo sugerida:
- Música corporativa/tecnológica suave
- Volumen bajo (no debe distraer de la narración)
- Sin música durante explicaciones de código (solo durante transiciones)
