# 🎬 Video Demo: ¿Para Qué Sirve un BFF?

## 📺 Video Educativo de 90 Segundos

Este kit contiene todo lo necesario para producir un video educativo que demuestre **visualmente** el valor de un Backend For Frontend.

**📚 Dos Estilos Disponibles:**

### 1. **Storytelling** (Recomendado) 🎭
Una historia que compara el BFF con un portero de seguridad. Perfecto para audiencia general.
- **Presentación:** `visual-comparison-storytelling.html`
- **Guion:** `GUION_90SEC_STORYTELLING.md`
- **Metáfora:** Casa con puertas → Portero protegiendo
- **Audiencia:** Todos (técnicos y no técnicos)

### 2. **Técnico** 💻
Demostración con código, DevTools y comparación técnica directa.
- **Presentación:** `visual-comparison.html`
- **Guion:** `GUION_90SEC.md`
- **Enfoque:** Código real y herramientas dev
- **Audiencia:** Desarrolladores

---

## 🎯 Mensaje del Video

**Sin BFF:**
- ❌ 4 llamadas separadas
- ❌ 8.1 segundos total
- ❌ Tokens expuestos
- ❌ Microservicios vulnerables

**Con BFF:**
- ✅ 1 sola llamada agregada
- ✅ 1.2 segundos (6x más rápido)
- ✅ Doble validación de tokens
- ✅ Microservicios protegidos

---

## 🚀 Inicio Rápido (3 Pasos)

### Paso 1: Abrir Presentación
```bash
open visual-comparison.html
```

### Paso 2: Leer Guion
```bash
open GUION_90SEC.md
```

### Paso 3: Grabar
Seguir instrucciones en `PRODUCCION.md` para configurar OBS y grabar.

---

## 📦 Contenido del Kit

### Archivos Principales:
- **`visual-comparison.html`** - Presentación interactiva (5 slides)
- **`GUION_90SEC.md`** - Script de narración con timing exacto
- **`STORYBOARD.md`** - Descripción visual frame-by-frame
- **`PRODUCCION.md`** - Guía de grabación OBS paso a paso

### Snippets de Código:
- `snippets/01-sin-bff-vulnerable.js` - Frontend sin protección
- `snippets/02-con-bff-protegido.ts` - Endpoint del BFF
- `snippets/03-doble-validacion.ts` - Middleware microservicio
- `snippets/04-curl-sin-bff.sh` - Ataque sin BFF (exitoso)
- `snippets/05-curl-con-bff.sh` - Ataque con BFF (bloqueado)

---

## ⏱️ Estructura del Video (90 seg)

```
[0:00-0:03]  Intro - "¿Para Qué Sirve un BFF?"
[0:03-0:25]  Problema - Sin BFF (4 calls, vulnerable, lento)
[0:25-0:28]  Transición
[0:28-1:05]  Solución - Con BFF (1 call, protegido, 6x rápido)
[1:05-1:25]  Demo - Ataque bloqueado (doble validación)
[1:25-1:30]  Cierre - Enlaces y recursos
```

---

## 🎨 Navegación de la Presentación

- `→` o `Espacio`: Siguiente slide
- `←`: Slide anterior
- **5 slides totales**

---

## 📊 Tiempo Estimado de Producción

- **Setup:** 15 minutos
- **Grabación:** 1-1.5 horas (por secciones)
- **Edición:** 30-45 minutos
- **Export:** 10 minutos

**Total:** 2-3 horas

---

## ✅ No Requiere

- ❌ Docker corriendo
- ❌ Sistema real funcionando
- ❌ Configuración compleja

**Solo necesitas:**
- ✅ Navegador web
- ✅ OBS Studio (o QuickTime)
- ✅ Editor de video básico (opcional)

---

## 🎯 Resultado Final

Video de **máximo 90 segundos** que demuestra claramente:
1. El problema de exponer microservicios directamente
2. Cómo el BFF soluciona todos esos problemas
3. La doble validación en acción
4. Por qué el BFF es esencial, no opcional

---

**Creado por:** Santiago Fernández  
**Proyecto:** BFF Financial Security  
**Licencia:** MIT
