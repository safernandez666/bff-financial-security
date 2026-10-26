# 🎥 Instrucciones para Grabar el Video Demo

## 📋 Checklist Pre-grabación

- [ ] Leer el guion completo (`GUION_NARRATION.md`)
- [ ] Abrir la presentación HTML (`presentacion.html`) en el navegador
- [ ] Configurar herramienta de grabación (OBS Studio, QuickTime, etc.)
- [ ] Probar audio (micrófono limpio, sin ruido de fondo)
- [ ] Cerrar aplicaciones innecesarias
- [ ] Modo No Molestar activado

---

## 🛠️ Herramientas Recomendadas

### Opción 1: OBS Studio (Gratis, Profesional)
- Descargar: https://obsproject.com/
- Configuración:
  - Resolución: 1920x1080 (Full HD)
  - FPS: 30
  - Bitrate: 5000-8000 kbps
  - Audio: 192 kbps AAC

### Opción 2: QuickTime (Mac, Simple)
- Ya viene instalado en macOS
- Archivo → Nueva Grabación de Pantalla
- Seleccionar micrófono

### Opción 3: Loom (Navegador, Fácil)
- Extensión de Chrome
- Buena para videos rápidos

---

## 🎬 Proceso de Grabación

### Paso 1: Configuración Inicial

1. **Abrir la presentación:**
   ```bash
   open /Users/santiago/Proyects/Hashnode/bff-financial-security/video/presentacion.html
   ```

2. **Navegar con teclado:**
   - ← / → : Slides anterior/siguiente
   - Espacio: Siguiente slide

3. **Posicionar pantalla:**
   - Navegador en pantalla completa (Cmd+Shift+F en Chrome)
   - Zoom 100%

### Paso 2: Grabar Sección por Sección

**Opción A: Video completo (12-14 minutos)**
- Grabar todo de una vez siguiendo el guion

**Opción B: Por secciones (Recomendado)**
- Grabar cada sección por separado
- Editar y unir después

**Secciones sugeridas:**
1. Intro (Slides 1-2)
2. Problema y Solución (Slides 3-4)
3. 10 Capas Overview (Slide 5)
4. OAuth2 y PKCE (Slides 6-7)
5. Doble Validación (Slides 8-10)
6. mTLS, Rate Limiting, Circuit Breaker (Slides 11-13)
7. Headers, CORS, Masking, Validation (Slides 14-16)
8. Flujo Completo (Slides 17-18)
9. Compliance y Database (Slides 19-20)
10. Cierre (Slide 21)

### Paso 3: Tips de Narración

**Voz:**
- Tono profesional pero amigable
- Ritmo moderado (no muy rápido)
- Pausas breves entre secciones (2-3 segundos)
- Enfatizar palabras clave (tokens, validación, seguridad)

**Errores:**
- Si te equivocas, pausa 3 segundos y repite la frase
- Más fácil editar con pausas claras

**Timing:**
- No apurar las explicaciones de código
- Dar tiempo para que la audiencia lea

---

## 🎞️ Edición (Opcional)

### Herramientas de Edición

**Gratis:**
- DaVinci Resolve (profesional, curva aprendizaje)
- iMovie (Mac, simple)
- Shotcut (multiplataforma)

**De pago:**
- Adobe Premiere Pro
- Final Cut Pro
- Camtasia

### Ediciones Básicas

1. **Cortar errores y pausas largas**
2. **Añadir intro/outro:**
   - Intro: 3-5 segundos con título
   - Outro: 5 segundos con enlaces

3. **Añadir música de fondo (opcional):**
   - Fuentes: YouTube Audio Library, Epidemic Sound
   - Volumen: -20dB a -25dB (muy bajo)
   - Solo en intro, transiciones y outro

4. **Añadir efectos de zoom (opcional):**
   - Zoom suave en fragmentos de código importantes
   - No abusar

---

## 📤 Exportación

### Configuración de Export

**Resolución:** 1920x1080 (Full HD)
**FPS:** 30
**Codec de video:** H.264
**Bitrate de video:** 8000 kbps
**Codec de audio:** AAC
**Bitrate de audio:** 192 kbps

**Peso estimado:**
- 10 minutos: ~600-800 MB
- 15 minutos: ~900-1200 MB

---

## 🌐 Publicación

### YouTube

1. **Título sugerido:**
   - "Backend For Frontend (BFF): Arquitectura de Seguridad Multicapa | Tutorial Completo"
   - "BFF Security: 10 Capas de Protección para Microservicios | OAuth2, mTLS, Circuit Breaker"

2. **Descripción:**
```
En este video te muestro cómo implementar un Backend For Frontend (BFF) con 10 capas de seguridad para proteger microservicios.

🔐 Capas de Seguridad:
1. OAuth2 + OIDC con Keycloak
2. PKCE (Proof Key for Code Exchange)
3. Doble validación de tokens
4. mTLS (Mutual TLS)
5. Rate Limiting
6. Circuit Breaker
7. Security Headers (Helmet)
8. CORS Restrictivo
9. Data Masking en Logs
10. Input Validation (Zod)

📦 Código completo: [tu-repo-github]
📝 Artículo: [tu-post-hashnode]
🎨 Diagrama interactivo: [link]

🏷️ TIMESTAMPS:
0:00 - Intro
0:30 - El Problema
1:30 - La Solución: BFF
2:30 - OAuth2 + OIDC
3:30 - Doble Validación de Tokens
5:30 - mTLS
6:30 - Rate Limiting + Circuit Breaker
8:00 - Headers, CORS, Data Masking
9:30 - Input Validation
10:30 - Flujo Completo
12:00 - Compliance PCI DSS
13:15 - Conclusión

#backend #seguridad #microservicios #oauth2 #nodejs #typescript #arquitectura
```

3. **Tags:**
   - backend for frontend
   - bff
   - microservicios
   - seguridad
   - oauth2
   - keycloak
   - nodejs
   - typescript
   - arquitectura
   - fintech

4. **Thumbnail sugerido:**
   - Texto grande: "BFF Security"
   - Subtítulo: "10 Capas de Protección"
   - Icono de escudo o candado
   - Colores: azul/morado (match con presentación)

### Hashnode

Embeber el video en el artículo:

```markdown
## 🎥 Video Demo

<youtube-video-id>

En este video explico paso a paso...
```

### LinkedIn/Twitter

Post corto con link al video:

```
🔐 ¿Cómo proteger microservicios con un BFF?

Acabo de publicar un video completo sobre arquitectura de seguridad multicapa:

✅ OAuth2 + PKCE
✅ Doble validación de tokens
✅ mTLS
✅ Circuit Breaker
✅ Y 6 capas más

Video completo: [link]
Código: [github]

#backend #seguridad #microservicios
```

---

## 🎤 Alternativa: Narración con IA

Si prefieres usar voz generada con IA:

### Herramientas de TTS (Text-to-Speech)

1. **ElevenLabs** (mejor calidad, de pago)
   - https://elevenlabs.io
   - Voces en español muy naturales
   - ~$5/mes plan básico

2. **Google Cloud Text-to-Speech**
   - https://cloud.google.com/text-to-speech
   - Voz: `es-ES-Neural2-B` (masculina) o `es-ES-Neural2-A` (femenina)
   - Gratis hasta 1 millón de caracteres/mes

3. **Amazon Polly**
   - Voz: `Lucia` (español neutro)

### Proceso con TTS:

1. Copiar texto del guion por secciones
2. Generar audio con la herramienta
3. Descargar archivos .mp3
4. En el editor de video:
   - Importar audio generado
   - Sincronizar con slides
   - Ajustar timing si es necesario

---

## 📊 Checklist Post-Producción

- [ ] Video exportado en Full HD
- [ ] Audio claro (sin ruido)
- [ ] Timing adecuado (ni muy rápido ni muy lento)
- [ ] Todas las secciones incluidas
- [ ] Intro y outro agregados
- [ ] Música de fondo (opcional) en volumen bajo
- [ ] Thumbnails/miniatura diseñado
- [ ] Descripción y tags preparados
- [ ] Video subido a YouTube
- [ ] Link añadido al artículo de Hashnode
- [ ] Compartido en redes sociales

---

## 💡 Tips Adicionales

### Para Video Profesional:

1. **Iluminación:** Luz natural o ring light
2. **Audio:** Micrófono USB (no el del laptop)
3. **Fondo:** Limpio, sin distracciones
4. **Postura:** Si apareces en cámara, buena postura

### Para Máxima Engagement:

1. **Primeros 30 segundos críticos:** Hook fuerte
2. **Mostrar código real:** No solo teoría
3. **Destacar beneficios:** No solo features
4. **Call to action:** Pedir likes, suscripciones, comentarios

---

## 📞 Soporte

Si tienes dudas durante la grabación:
- Revisar el guion: `GUION_NARRATION.md`
- Navegar la presentación: flechas o espacio
- Ajustar slides: editar `presentacion.html` si es necesario

¡Éxito con la grabación! 🎬
