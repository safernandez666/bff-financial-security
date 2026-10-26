# 🎬 Guía de Producción - Video 90 Segundos

## Cómo Grabar el Video Educativo del BFF

---

## 📋 Checklist Pre-Grabación

- [ ] Leer `GUION_90SEC.md` completo
- [ ] Revisar `STORYBOARD.md` para visuales
- [ ] Abrir `visual-comparison.html` en navegador
- [ ] Configurar OBS Studio (o herramienta de grabación)
- [ ] Probar audio (micrófono limpio, sin ruido)
- [ ] Cerrar aplicaciones innecesarias
- [ ] Activar Modo No Molestar
- [ ] Tener agua cerca (para hidratar entre tomas)

---

## 🛠️ Configuración de OBS Studio

### Paso 1: Descargar OBS (si no lo tienes)

```bash
# Mac con Homebrew
brew install --cask obs

# O descargar de:
# https://obsproject.com/download
```

### Paso 2: Crear Escena de Grabación

1. **Abrir OBS Studio**
2. **Crear nueva escena:**
   - Click en `+` en "Scenes"
   - Nombre: "BFF Video 90sec"

3. **Añadir fuente de pantalla:**
   - Click en `+` en "Sources"
   - Seleccionar **"Display Capture"** (captura pantalla completa)
   - O **"Window Capture"** (solo ventana del navegador)
   - Nombre: "Presentación BFF"

4. **Añadir fuente de audio:**
   - Click en `+` en "Sources"
   - Seleccionar **"Audio Input Capture"**
   - Seleccionar tu micrófono
   - Nombre: "Micrófono Narración"

### Paso 3: Configurar Settings

Click en **Settings** → **Output**:

```
Output Mode: Advanced

Recording:
- Type: Standard
- Recording Path: ~/Movies/BFF-Video/
- Recording Format: mp4
- Encoder: Apple VT H264 Hardware Encoder (Mac)
           o x264 (otras plataformas)
- Rate Control: CRF
- CRF: 18 (alta calidad)
- Keyframe Interval: 2
- Preset: Quality
- Profile: high
- Look-ahead: ✓
- Psycho Visual Tuning: ✓
```

Click en **Video**:

```
Base (Canvas) Resolution: 1920x1080
Output (Scaled) Resolution: 1920x1080
Downscale Filter: Lanczos (mejorsharp scaling)
Common FPS Values: 30
```

Click en **Audio**:

```
Sample Rate: 48 kHz
Channels: Stereo

Mic/Auxiliary Audio:
- Device: [Tu micrófono]
- Desktop Audio: Disabled (no queremos audio del sistema)
```

### Paso 4: Ajustar Audio

En el **Audio Mixer** (abajo):

1. **Configurar niveles:**
   - Narración debe estar en **-12dB a -6dB** (amarillo)
   - Evitar picos en rojo (>0dB)

2. **Añadir filtros de audio:**
   - Click derecho en "Micrófono"
   - Seleccionar **"Filters"**
   - Añadir:
     - **Noise Suppression** (RNNoise) - Nivel: -30dB
     - **Noise Gate** - Close: -35dB, Open: -30dB
     - **Compressor** - Ratio: 3:1, Threshold: -18dB
     - **Limiter** - Threshold: -6dB

---

## 🎥 Proceso de Grabación

### Opción A: Grabación Continua (Una Toma Completa)

**Ventajas:**
- Más rápido si sale bien
- Flujo natural

**Desventajas:**
- Si fallas en seg 80, pierdes toda la toma
- Más presión

**Proceso:**
1. Abrir `visual-comparison.html` en pantalla completa
2. Tener `GUION_90SEC.md` en otra pantalla o impreso
3. OBS → Start Recording
4. Narrar los 90 segundos completos navegando slides
5. OBS → Stop Recording

---

### Opción B: Por Secciones (Recomendado) ⭐

**Ventajas:**
- Puedes repetir secciones sin perder todo
- Menos presión
- Mejor calidad final

**Desventajas:**
- Requiere edición posterior

**Secciones a Grabar:**

#### **Sección 1: Intro [0:00-0:03]**
- Slide 1 visible
- Sin narración (solo déjalo 3 segundos)
- **Archivo:** `01-intro.mp4`

#### **Sección 2: Problema [0:03-0:25]**
- Slide 2 (pantalla dividida sin BFF)
- Narración según guion
- **Hacer 2-3 tomas** y elegir la mejor
- **Archivo:** `02-problema.mp4`

#### **Sección 3: Transición [0:25-0:28]**
- Slide 3 (transición animada)
- Sin narración
- **Archivo:** `03-transicion.mp4`

#### **Sección 4: Solución [0:28-1:05]**
- Slide 4 (con BFF)
- Narración más larga
- **Hacer 3-4 tomas** (es la sección más importante)
- **Archivo:** `04-solucion.mp4`

#### **Sección 5: Ataque [1:05-1:25]**
- Slide 5 (comparación ataque)
- Narración enfática
- **Hacer 2-3 tomas**
- **Archivo:** `05-ataque.mp4`

#### **Sección 6: Cierre [1:25-1:30]**
- Slide 6 (cierre con enlaces)
- Narración final
- **Archivo:** `06-cierre.mp4`

**Proceso de Grabación por Sección:**

```bash
# 1. Posicionar slide correcto
# 2. Esperar 3 segundos en silencio (para edición)
# 3. Narrar la sección
# 4. Esperar 3 segundos en silencio
# 5. Stop recording
# 6. Revisar, si no te gusta, repetir
```

---

## ✂️ Edición Básica

### Herramientas Recomendadas:

**Mac:**
- **iMovie** (gratis, simple) ⭐
- **DaVinci Resolve** (gratis, profesional)
- **Final Cut Pro** (de pago, $300)

**Windows/Linux:**
- **DaVinci Resolve** (gratis, profesional) ⭐
- **Shotcut** (gratis, simple)
- **Adobe Premiere Pro** (de pago, suscripción)

### Proceso en iMovie:

1. **Importar clips:**
   - Arrastra todos los archivos `01-intro.mp4` ... `06-cierre.mp4`

2. **Ordenar en timeline:**
   - Drag & drop en orden: 01 → 02 → 03 → 04 → 05 → 06

3. **Cortar silencios:**
   - Eliminar los 3 seg iniciales/finales de cada clip
   - Usar herramienta de tijera (Cmd+B)

4. **Transiciones:**
   - Entre secciones: "Cross Dissolve" de 0.3s
   - Entre intro y problema: "Fade"
   - Entre cierre y fin: "Fade to Black"

5. **Música de fondo (opcional):**
   - Importar música corporativa suave
   - Volumen: -25dB (muy bajo, que no tape la narración)
   - Solo en intro y outro
   - Fade in/out

6. **Ajustar audio:**
   - Normalizar volumen de narración
   - Eliminar ruidos/clicks con "Audio Enhancement"

7. **Añadir intro/outro cards:**
   - Título inicial (3s) antes del Slide 1
   - Card final (3s) después del Slide 6 con:
     - "Gracias por ver"
     - Links a GitHub/Hashnode
     - Suscríbete/Like

---

## 📤 Export Settings

### En iMovie:

1. **File → Share → File...**
2. **Settings:**
   - Resolution: **1080p**
   - Quality: **High**
   - Compress: **Better Quality**

### En DaVinci Resolve:

**Deliver Tab:**
```
Format: QuickTime
Codec: H.264
Resolution: 1920x1080
Frame Rate: 30 fps
Quality: Automatic (o CRF 18)
Audio Codec: AAC
Audio Bitrate: 192 kbps
```

### Configuración Ideal de Export:

```
Video:
- Resolución: 1920x1080 (Full HD)
- Frame rate: 30 fps
- Codec: H.264
- Bitrate: 8000-10000 kbps (VBR)
- Profile: High
- Level: 4.2

Audio:
- Codec: AAC
- Bitrate: 192 kbps
- Sample rate: 48 kHz
- Channels: Stereo

Container: MP4
```

**Peso estimado del archivo final:**
- 90 segundos a 8000 kbps ≈ **85-110 MB**

---

## 🎙️ Tips de Narración

### Antes de Grabar:

1. **Leer el guion 3-4 veces** en voz alta
2. **Practicar timing** con cronómetro
3. **Hidratar** (agua tibia, no fría)
4. **Calentar voz** (tararear, escala vocal)
5. **Postura:** Sentado derecho, no encorvado

### Durante la Grabación:

1. **Sonreír** mientras narras (suena más amigable)
2. **Pausas naturales** (respetar las del guion)
3. **Enfatizar palabras clave** (doble validación, bloqueado, etc.)
4. **Ritmo moderado** (ni muy rápido ni muy lento)
5. **Si te equivocas:**
   - Pausa 3 segundos
   - Repite la frase completa desde el inicio
   - Más fácil de editar

### Calidad de Audio:

**DO:**
- ✅ Usar micrófono USB (mínimo $30-50)
- ✅ Grabar en habitación silenciosa
- ✅ Usar filtros de ruido en OBS
- ✅ Mantener distancia constante del mic (15-20cm)

**DON'T:**
- ❌ Usar micrófono del laptop
- ❌ Grabar con ventilador encendido
- ❌ Tocar el micrófono durante grabación
- ❌ Respirar directo al micrófono (usar filtro pop)

---

## 📊 Checklist Post-Producción

Antes de publicar, verificar:

- [ ] Video dura **máximo 90 segundos**
- [ ] Audio claro y sin ruido
- [ ] No hay clicks/pops audibles
- [ ] Transiciones suaves
- [ ] Todos los slides visibles claramente
- [ ] Texto legible (probarlo en móvil también)
- [ ] Volumen consistente en toda la narración
- [ ] Música de fondo (si la usas) no tapa la voz
- [ ] Intro/outro cards incluidos
- [ ] Export en Full HD (1080p)

---

## 🌐 Publicación

### YouTube:

**Título:**
```
¿Para Qué Sirve un BFF? | Backend For Frontend en 90 Segundos
```

**Descripción:**
```
Demuestra visualmente por qué necesitas un Backend For Frontend (BFF) en tu arquitectura de microservicios.

🎯 Sin BFF:
❌ 4 llamadas separadas
❌ 8.1 segundos
❌ Tokens expuestos
❌ Vulnerable

✅ Con BFF:
✅ 1 llamada agregada
✅ 1.2 segundos (6x más rápido)
✅ Doble validación
✅ Protegido

📦 Código completo: [tu-repo]
📝 Artículo: [tu-post-hashnode]
🎨 Diagrama: [link]

#BFF #Microservicios #Seguridad #Backend #OAuth2 #Arquitectura
```

**Tags:**
- backend for frontend
- bff
- microservicios
- arquitectura
- seguridad
- oauth2
- nodejs
- typescript

**Thumbnail:**
- Texto grande: "BFF vs NO BFF"
- Comparación visual (4 calls vs 1 call)
- Colores: azul/verde

---

## ⏱️ Timeline Estimado de Producción

```
Setup OBS: 15 minutos
Grabación Sección 1: 5 minutos (1 toma)
Grabación Sección 2: 15 minutos (3 tomas)
Grabación Sección 3: 5 minutos (1 toma)
Grabación Sección 4: 20 minutos (4 tomas)
Grabación Sección 5: 15 minutos (3 tomas)
Grabación Sección 6: 10 minutos (2 tomas)
───────────────────────────────────────
Subtotal grabación: 1h 25min

Edición en iMovie: 30 minutos
Export: 5 minutos
───────────────────────────────────────
TOTAL: ~2 horas
```

---

## 💡 Tips Finales

1. **No busques perfección** en la primera toma
2. **Graba por secciones** para menos frustración
3. **Múltiples tomas** de cada sección (elige la mejor)
4. **Descansa** entre secciones si te cansas
5. **Revisa audio** después de cada sección
6. **Backup** de todos los archivos antes de editar

---

**Preparado para:** Producción de video educativo de 90 segundos  
**Optimizado para:** OBS Studio + iMovie/DaVinci Resolve  
**Resultado:** Video Full HD listo para YouTube/Hashnode
