-- ================================================================
-- Database: prestamos_db
-- Description: Préstamos bancarios y pagos de cuotas
-- ================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============== TABLES ==============

-- Préstamos
CREATE TABLE IF NOT EXISTS prestamos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    tipo_prestamo VARCHAR(50) NOT NULL CHECK (tipo_prestamo IN ('personal', 'hipotecario', 'automotor', 'prendario')),
    monto_solicitado DECIMAL(15,2) NOT NULL CHECK (monto_solicitado > 0),
    monto_aprobado DECIMAL(15,2) CHECK (monto_aprobado > 0),
    tasa_interes DECIMAL(5,2) NOT NULL CHECK (tasa_interes >= 0 AND tasa_interes <= 100),
    plazo_meses INTEGER NOT NULL CHECK (plazo_meses > 0 AND plazo_meses <= 360),
    cuota_mensual DECIMAL(15,2),
    monto_total_pagar DECIMAL(15,2),
    monto_pagado DECIMAL(15,2) DEFAULT 0,
    cuotas_pagadas INTEGER DEFAULT 0,
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'en_revision', 'aprobado', 'rechazado', 'activo', 'pagado', 'cancelado', 'mora')),
    motivo_rechazo TEXT,
    fecha_solicitud TIMESTAMP DEFAULT NOW(),
    fecha_revision TIMESTAMP,
    fecha_aprobacion TIMESTAMP,
    fecha_desembolso TIMESTAMP,
    fecha_vencimiento DATE,
    revisor_id VARCHAR(255),
    notas_internas TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Pagos de préstamos (cuotas)
CREATE TABLE IF NOT EXISTS pagos_prestamos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prestamo_id UUID REFERENCES prestamos(id) ON DELETE CASCADE,
    numero_cuota INTEGER NOT NULL,
    monto_cuota DECIMAL(15,2) NOT NULL CHECK (monto_cuota > 0),
    monto_pagado DECIMAL(15,2) DEFAULT 0,
    fecha_vencimiento DATE NOT NULL,
    fecha_pago TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'pagada', 'vencida', 'mora')),
    dias_mora INTEGER DEFAULT 0,
    monto_mora DECIMAL(15,2) DEFAULT 0,
    metodo_pago VARCHAR(50),
    referencia_pago VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(prestamo_id, numero_cuota)
);

-- Documentación del préstamo
CREATE TABLE IF NOT EXISTS documentos_prestamo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prestamo_id UUID REFERENCES prestamos(id) ON DELETE CASCADE,
    tipo_documento VARCHAR(50) NOT NULL CHECK (tipo_documento IN ('dni', 'recibo_sueldo', 'cbu', 'domicilio', 'garantia', 'otro')),
    nombre_archivo VARCHAR(255) NOT NULL,
    url_documento TEXT,
    estado_verificacion VARCHAR(20) DEFAULT 'pendiente' CHECK (estado_verificacion IN ('pendiente', 'verificado', 'rechazado')),
    fecha_subida TIMESTAMP DEFAULT NOW(),
    verificado_por VARCHAR(255),
    fecha_verificacion TIMESTAMP,
    notas TEXT
);

-- ============== INDEXES ==============

CREATE INDEX idx_prestamos_user_id ON prestamos(user_id);
CREATE INDEX idx_prestamos_estado ON prestamos(estado);
CREATE INDEX idx_prestamos_fecha_solicitud ON prestamos(fecha_solicitud DESC);
CREATE INDEX idx_prestamos_tipo ON prestamos(tipo_prestamo);

CREATE INDEX idx_pagos_prestamo_id ON pagos_prestamos(prestamo_id);
CREATE INDEX idx_pagos_estado ON pagos_prestamos(estado);
CREATE INDEX idx_pagos_fecha_vencimiento ON pagos_prestamos(fecha_vencimiento);

CREATE INDEX idx_documentos_prestamo_id ON documentos_prestamo(prestamo_id);

-- ============== TRIGGERS ==============

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_prestamos_updated_at BEFORE UPDATE ON prestamos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para calcular cuota mensual (fórmula francesa)
CREATE OR REPLACE FUNCTION calcular_cuota_prestamo()
RETURNS TRIGGER AS $$
DECLARE
    tasa_mensual DECIMAL;
    cuota DECIMAL;
BEGIN
    IF NEW.monto_aprobado IS NOT NULL AND NEW.tasa_interes IS NOT NULL AND NEW.plazo_meses IS NOT NULL THEN
        -- Convertir tasa anual a mensual
        tasa_mensual := NEW.tasa_interes / 100 / 12;
        
        -- Fórmula francesa: C = P * [i * (1 + i)^n] / [(1 + i)^n - 1]
        IF tasa_mensual > 0 THEN
            cuota := NEW.monto_aprobado * (tasa_mensual * POWER(1 + tasa_mensual, NEW.plazo_meses)) / 
                     (POWER(1 + tasa_mensual, NEW.plazo_meses) - 1);
        ELSE
            -- Sin interés
            cuota := NEW.monto_aprobado / NEW.plazo_meses;
        END IF;
        
        NEW.cuota_mensual := ROUND(cuota, 2);
        NEW.monto_total_pagar := ROUND(cuota * NEW.plazo_meses, 2);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calcular_cuota BEFORE INSERT OR UPDATE ON prestamos
    FOR EACH ROW EXECUTE FUNCTION calcular_cuota_prestamo();

-- ============== DEMO DATA ==============

-- Préstamo personal activo de Juan Pérez
INSERT INTO prestamos (
    user_id, tipo_prestamo, monto_solicitado, monto_aprobado, tasa_interes,
    plazo_meses, estado, fecha_solicitud, fecha_aprobacion, fecha_desembolso
) VALUES (
    'juan-perez-id',
    'personal',
    10000.00,
    10000.00,
    24.50,  -- TNA 24.5%
    12,
    'activo',
    NOW() - INTERVAL '6 months',
    NOW() - INTERVAL '5 months 25 days',
    NOW() - INTERVAL '5 months 20 days'
);

-- Generar cuotas para el préstamo de Juan
DO $$
DECLARE
    prestamo_id UUID;
    cuota_monto DECIMAL;
    i INTEGER;
BEGIN
    SELECT id, cuota_mensual INTO prestamo_id, cuota_monto 
    FROM prestamos 
    WHERE user_id = 'juan-perez-id' AND tipo_prestamo = 'personal';
    
    FOR i IN 1..12 LOOP
        INSERT INTO pagos_prestamos (
            prestamo_id,
            numero_cuota,
            monto_cuota,
            monto_pagado,
            fecha_vencimiento,
            fecha_pago,
            estado
        ) VALUES (
            prestamo_id,
            i,
            cuota_monto,
            CASE 
                WHEN i <= 5 THEN cuota_monto  -- Ya pagó 5 cuotas
                ELSE 0
            END,
            (NOW() - INTERVAL '5 months' + (i || ' months')::INTERVAL)::DATE,
            CASE 
                WHEN i <= 5 THEN (NOW() - INTERVAL '5 months' + (i || ' months')::INTERVAL - INTERVAL '2 days')
                ELSE NULL
            END,
            CASE 
                WHEN i <= 5 THEN 'pagada'
                ELSE 'pendiente'
            END
        );
    END LOOP;
    
    -- Actualizar contador de cuotas pagadas
    UPDATE prestamos 
    SET cuotas_pagadas = 5, 
        monto_pagado = cuota_monto * 5
    WHERE id = prestamo_id;
END $$;

-- Préstamo hipotecario activo de María González
INSERT INTO prestamos (
    user_id, tipo_prestamo, monto_solicitado, monto_aprobado, tasa_interes,
    plazo_meses, estado, fecha_solicitud, fecha_aprobacion, fecha_desembolso
) VALUES (
    'maria-gonzalez-id',
    'hipotecario',
    150000.00,
    150000.00,
    18.75,  -- TNA 18.75%
    240,  -- 20 años
    'activo',
    NOW() - INTERVAL '2 years',
    NOW() - INTERVAL '1 year 11 months',
    NOW() - INTERVAL '1 year 10 months'
);

-- Generar algunas cuotas para el hipotecario de María (solo las primeras 24)
DO $$
DECLARE
    prestamo_id UUID;
    cuota_monto DECIMAL;
    i INTEGER;
BEGIN
    SELECT id, cuota_mensual INTO prestamo_id, cuota_monto 
    FROM prestamos 
    WHERE user_id = 'maria-gonzalez-id' AND tipo_prestamo = 'hipotecario';
    
    FOR i IN 1..24 LOOP
        INSERT INTO pagos_prestamos (
            prestamo_id,
            numero_cuota,
            monto_cuota,
            monto_pagado,
            fecha_vencimiento,
            fecha_pago,
            estado
        ) VALUES (
            prestamo_id,
            i,
            cuota_monto,
            CASE 
                WHEN i <= 22 THEN cuota_monto  -- Ya pagó 22 cuotas
                ELSE 0
            END,
            (NOW() - INTERVAL '22 months' + (i || ' months')::INTERVAL)::DATE,
            CASE 
                WHEN i <= 22 THEN (NOW() - INTERVAL '22 months' + (i || ' months')::INTERVAL - INTERVAL '3 days')
                ELSE NULL
            END,
            CASE 
                WHEN i <= 22 THEN 'pagada'
                ELSE 'pendiente'
            END
        );
    END LOOP;
    
    -- Actualizar contador
    UPDATE prestamos 
    SET cuotas_pagadas = 22, 
        monto_pagado = cuota_monto * 22
    WHERE id = prestamo_id;
END $$;

-- Préstamo automotor en revisión de María
INSERT INTO prestamos (
    user_id, tipo_prestamo, monto_solicitado, monto_aprobado, tasa_interes,
    plazo_meses, estado, fecha_solicitud, fecha_revision
) VALUES (
    'maria-gonzalez-id',
    'automotor',
    35000.00,
    NULL,  -- Aún no aprobado
    22.00,
    60,
    'en_revision',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '2 days'
);

-- ============== FUNCTIONS ==============

-- Función para obtener préstamos de un usuario
CREATE OR REPLACE FUNCTION obtener_prestamos_usuario(p_user_id VARCHAR)
RETURNS TABLE(
    prestamo_id UUID,
    tipo VARCHAR,
    monto_aprobado DECIMAL,
    cuota_mensual DECIMAL,
    cuotas_pagadas INTEGER,
    plazo_total INTEGER,
    estado VARCHAR,
    proxima_cuota_fecha DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.tipo_prestamo,
        p.monto_aprobado,
        p.cuota_mensual,
        p.cuotas_pagadas,
        p.plazo_meses,
        p.estado,
        (SELECT MIN(pp.fecha_vencimiento) 
         FROM pagos_prestamos pp 
         WHERE pp.prestamo_id = p.id AND pp.estado = 'pendiente')
    FROM prestamos p
    WHERE p.user_id = p_user_id
    ORDER BY p.fecha_solicitud DESC;
END;
$$ LANGUAGE plpgsql;

-- ============== SUMMARY ==============

DO $$
DECLARE
    total_prestamos INTEGER;
    total_pagos INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_prestamos FROM prestamos;
    SELECT COUNT(*) INTO total_pagos FROM pagos_prestamos;
    
    RAISE NOTICE '✅ Préstamos DB initialized successfully';
    RAISE NOTICE '   - Préstamos: %', total_prestamos;
    RAISE NOTICE '   - Pagos/Cuotas: %', total_pagos;
END $$;
