-- ================================================================
-- Database: tarjetas_db
-- Description: Tarjetas de crédito/débito y transacciones
-- ================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============== TABLES ==============

-- Tarjetas de crédito/débito
CREATE TABLE IF NOT EXISTS tarjetas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    numero_tarjeta_hash VARCHAR(255) NOT NULL UNIQUE,  -- SHA256 hash (PCI DSS compliance)
    ultimos_4_digitos VARCHAR(4) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('debito', 'credito')),
    marca VARCHAR(20) NOT NULL CHECK (marca IN ('visa', 'mastercard', 'amex', 'cabal')),
    nombre_titular VARCHAR(255) NOT NULL,
    limite_credito DECIMAL(15,2),  -- Solo para crédito
    saldo_disponible DECIMAL(15,2),
    saldo_utilizado DECIMAL(15,2) DEFAULT 0,
    fecha_emision DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'activa' CHECK (estado IN ('activa', 'bloqueada', 'vencida', 'cancelada')),
    motivo_bloqueo TEXT,
    cvv_hash VARCHAR(255),  -- NUNCA almacenar CVV en texto plano (hash temporal para validación)
    pin_hash VARCHAR(255),  -- Hash del PIN
    intentos_fallidos INTEGER DEFAULT 0,
    bloqueada_hasta TIMESTAMP,
    contactless_habilitado BOOLEAN DEFAULT TRUE,
    compras_online_habilitadas BOOLEAN DEFAULT TRUE,
    compras_exterior_habilitadas BOOLEAN DEFAULT FALSE,
    limite_diario DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Transacciones de tarjetas
CREATE TABLE IF NOT EXISTS transacciones_tarjetas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tarjeta_id UUID REFERENCES tarjetas(id) ON DELETE CASCADE,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('compra', 'retiro', 'pago', 'devolucion', 'ajuste')),
    monto DECIMAL(15,2) NOT NULL CHECK (monto > 0),
    moneda VARCHAR(3) DEFAULT 'USD',
    monto_original DECIMAL(15,2),  -- Si es conversión de moneda
    moneda_original VARCHAR(3),
    comercio VARCHAR(255) NOT NULL,
    categoria VARCHAR(50),  -- 'restaurantes', 'supermercados', 'gasolineras', etc.
    codigo_comercio VARCHAR(50),
    pais VARCHAR(3) DEFAULT 'ARG',
    ciudad VARCHAR(100),
    es_online BOOLEAN DEFAULT FALSE,
    es_contactless BOOLEAN DEFAULT FALSE,
    estado VARCHAR(20) DEFAULT 'aprobada' CHECK (estado IN ('pendiente', 'aprobada', 'rechazada', 'revertida')),
    motivo_rechazo TEXT,
    codigo_autorizacion VARCHAR(50),
    cuotas INTEGER DEFAULT 1,
    monto_cuota DECIMAL(15,2),
    interes_cuotas DECIMAL(5,2) DEFAULT 0,
    ip_address VARCHAR(45),
    latitud DECIMAL(10,8),
    longitud DECIMAL(11,8),
    fecha TIMESTAMP DEFAULT NOW(),
    fecha_liquidacion DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Alertas de seguridad
CREATE TABLE IF NOT EXISTS alertas_seguridad (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tarjeta_id UUID REFERENCES tarjetas(id) ON DELETE CASCADE,
    tipo_alerta VARCHAR(50) NOT NULL CHECK (tipo_alerta IN ('compra_sospechosa', 'monto_inusual', 'ubicacion_inusual', 'intento_fraude', 'multiples_intentos', 'uso_no_autorizado')),
    descripcion TEXT NOT NULL,
    nivel_riesgo VARCHAR(20) DEFAULT 'medio' CHECK (nivel_riesgo IN ('bajo', 'medio', 'alto', 'critico')),
    transaccion_id UUID REFERENCES transacciones_tarjetas(id),
    accion_tomada VARCHAR(100),
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'revisada', 'falsa_alarma', 'confirmada_fraude')),
    revisada_por VARCHAR(255),
    fecha_revision TIMESTAMP,
    fecha TIMESTAMP DEFAULT NOW()
);

-- Límites personalizados por categoría
CREATE TABLE IF NOT EXISTS limites_categoria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tarjeta_id UUID REFERENCES tarjetas(id) ON DELETE CASCADE,
    categoria VARCHAR(50) NOT NULL,
    limite_mensual DECIMAL(15,2) NOT NULL,
    gasto_actual DECIMAL(15,2) DEFAULT 0,
    mes_referencia DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE),
    UNIQUE(tarjeta_id, categoria, mes_referencia)
);

-- ============== INDEXES ==============

CREATE INDEX idx_tarjetas_user_id ON tarjetas(user_id);
CREATE INDEX idx_tarjetas_hash ON tarjetas(numero_tarjeta_hash);
CREATE INDEX idx_tarjetas_estado ON tarjetas(estado);
CREATE INDEX idx_tarjetas_vencimiento ON tarjetas(fecha_vencimiento);

CREATE INDEX idx_transacciones_tarjeta_id ON transacciones_tarjetas(tarjeta_id);
CREATE INDEX idx_transacciones_fecha ON transacciones_tarjetas(fecha DESC);
CREATE INDEX idx_transacciones_estado ON transacciones_tarjetas(estado);
CREATE INDEX idx_transacciones_tipo ON transacciones_tarjetas(tipo);
CREATE INDEX idx_transacciones_comercio ON transacciones_tarjetas(comercio);

CREATE INDEX idx_alertas_tarjeta_id ON alertas_seguridad(tarjeta_id);
CREATE INDEX idx_alertas_nivel_riesgo ON alertas_seguridad(nivel_riesgo);
CREATE INDEX idx_alertas_estado ON alertas_seguridad(estado);

-- ============== TRIGGERS ==============

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tarjetas_updated_at BEFORE UPDATE ON tarjetas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para actualizar saldo utilizado después de transacción
CREATE OR REPLACE FUNCTION actualizar_saldo_tarjeta()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'aprobada' AND NEW.tipo IN ('compra', 'retiro') THEN
        UPDATE tarjetas 
        SET saldo_utilizado = saldo_utilizado + NEW.monto,
            saldo_disponible = saldo_disponible - NEW.monto
        WHERE id = NEW.tarjeta_id;
    ELSIF NEW.estado = 'aprobada' AND NEW.tipo = 'pago' THEN
        UPDATE tarjetas 
        SET saldo_utilizado = GREATEST(0, saldo_utilizado - NEW.monto),
            saldo_disponible = saldo_disponible + NEW.monto
        WHERE id = NEW.tarjeta_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_saldo AFTER INSERT ON transacciones_tarjetas
    FOR EACH ROW EXECUTE FUNCTION actualizar_saldo_tarjeta();

-- ============== DEMO DATA ==============

-- Tarjeta de débito de Juan Pérez
INSERT INTO tarjetas (
    user_id, numero_tarjeta_hash, ultimos_4_digitos, tipo, marca, nombre_titular,
    limite_credito, saldo_disponible, saldo_utilizado, fecha_emision, fecha_vencimiento,
    estado, limite_diario
) VALUES (
    'juan-perez-id',
    encode(digest('4532123456789001', 'sha256'), 'hex'),
    '9001',
    'debito',
    'visa',
    'JUAN PEREZ',
    NULL,
    3240.75,  -- Mismo saldo que cuenta corriente
    0,
    NOW() - INTERVAL '2 years',
    NOW() + INTERVAL '2 years',
    'activa',
    5000.00
);

-- Tarjeta de crédito de Juan Pérez
INSERT INTO tarjetas (
    user_id, numero_tarjeta_hash, ultimos_4_digitos, tipo, marca, nombre_titular,
    limite_credito, saldo_disponible, saldo_utilizado, fecha_emision, fecha_vencimiento,
    estado, limite_diario
) VALUES (
    'juan-perez-id',
    encode(digest('4532987654321002', 'sha256'), 'hex'),
    '1002',
    'credito',
    'visa',
    'JUAN PEREZ',
    15000.00,
    11250.00,
    3750.00,
    NOW() - INTERVAL '1 year',
    NOW() + INTERVAL '3 years',
    'activa',
    10000.00
);

-- Tarjeta de crédito Platinum de María González
INSERT INTO tarjetas (
    user_id, numero_tarjeta_hash, ultimos_4_digitos, tipo, marca, nombre_titular,
    limite_credito, saldo_disponible, saldo_utilizado, fecha_emision, fecha_vencimiento,
    estado, limite_diario, compras_exterior_habilitadas
) VALUES (
    'maria-gonzalez-id',
    encode(digest('5425123456789003', 'sha256'), 'hex'),
    '9003',
    'credito',
    'mastercard',
    'MARIA GONZALEZ',
    50000.00,
    42300.00,
    7700.00,
    NOW() - INTERVAL '3 years',
    NOW() + INTERVAL '1 year',
    'activa',
    20000.00,
    TRUE
);

-- Tarjeta de débito de María González
INSERT INTO tarjetas (
    user_id, numero_tarjeta_hash, ultimos_4_digitos, tipo, marca, nombre_titular,
    limite_credito, saldo_disponible, saldo_utilizado, fecha_emision, fecha_vencimiento,
    estado, limite_diario
) VALUES (
    'maria-gonzalez-id',
    encode(digest('4532111122223004', 'sha256'), 'hex'),
    '3004',
    'debito',
    'visa',
    'MARIA GONZALEZ',
    NULL,
    12500.00,  -- Mismo saldo que cuenta corriente
    0,
    NOW() - INTERVAL '2 years',
    NOW() + INTERVAL '2 years',
    'activa',
    8000.00
);

-- Transacciones de Juan Pérez (últimos 30 días)
DO $$
DECLARE
    tarjeta_credito_id UUID;
BEGIN
    SELECT id INTO tarjeta_credito_id FROM tarjetas WHERE ultimos_4_digitos = '1002';
    
    -- Compra en supermercado
    INSERT INTO transacciones_tarjetas (tarjeta_id, tipo, monto, comercio, categoria, pais, ciudad, es_online, estado, codigo_autorizacion, fecha)
    VALUES (tarjeta_credito_id, 'compra', 1250.50, 'Carrefour San Martin', 'supermercados', 'ARG', 'Buenos Aires', FALSE, 'aprobada', 'AUTH-' || gen_random_uuid()::text, NOW() - INTERVAL '25 days');
    
    -- Compra online
    INSERT INTO transacciones_tarjetas (tarjeta_id, tipo, monto, comercio, categoria, pais, ciudad, es_online, estado, codigo_autorizacion, fecha)
    VALUES (tarjeta_credito_id, 'compra', 899.99, 'MercadoLibre', 'ecommerce', 'ARG', 'Buenos Aires', TRUE, 'aprobada', 'AUTH-' || gen_random_uuid()::text, NOW() - INTERVAL '20 days');
    
    -- Compra en gasolinera
    INSERT INTO transacciones_tarjetas (tarjeta_id, tipo, monto, comercio, categoria, pais, ciudad, es_contactless, estado, codigo_autorizacion, fecha)
    VALUES (tarjeta_credito_id, 'compra', 4500.00, 'YPF Av. Libertador', 'gasolineras', 'ARG', 'Buenos Aires', TRUE, 'aprobada', 'AUTH-' || gen_random_uuid()::text, NOW() - INTERVAL '15 days');
    
    -- Compra en restaurante
    INSERT INTO transacciones_tarjetas (tarjeta_id, tipo, monto, comercio, categoria, pais, ciudad, estado, codigo_autorizacion, fecha, cuotas)
    VALUES (tarjeta_credito_id, 'compra', 6750.00, 'Don Julio Parrilla', 'restaurantes', 'ARG', 'Buenos Aires', 'aprobada', 'AUTH-' || gen_random_uuid()::text, NOW() - INTERVAL '10 days', 3);
    
    -- Pago de tarjeta
    INSERT INTO transacciones_tarjetas (tarjeta_id, tipo, monto, comercio, categoria, estado, codigo_autorizacion, fecha)
    VALUES (tarjeta_credito_id, 'pago', 5000.00, 'Pago Online - Banco Central', 'pagos', 'aprobada', 'PAY-' || gen_random_uuid()::text, NOW() - INTERVAL '5 days');
END $$;

-- Transacciones de María González
DO $$
DECLARE
    tarjeta_platinum_id UUID;
BEGIN
    SELECT id INTO tarjeta_platinum_id FROM tarjetas WHERE ultimos_4_digitos = '9003';
    
    -- Compra internacional
    INSERT INTO transacciones_tarjetas (tarjeta_id, tipo, monto, moneda, monto_original, moneda_original, comercio, categoria, pais, ciudad, es_online, estado, codigo_autorizacion, fecha)
    VALUES (tarjeta_platinum_id, 'compra', 1850.00, 'USD', 1500.00, 'USD', 'Apple Store', 'tecnologia', 'USA', 'Cupertino', TRUE, 'aprobada', 'AUTH-' || gen_random_uuid()::text, NOW() - INTERVAL '22 days');
    
    -- Compra en shopping
    INSERT INTO transacciones_tarjetas (tarjeta_id, tipo, monto, comercio, categoria, pais, ciudad, estado, codigo_autorizacion, fecha, cuotas, interes_cuotas)
    VALUES (tarjeta_platinum_id, 'compra', 12500.00, 'Zara Unicenter', 'indumentaria', 'ARG', 'Martinez', 'aprobada', 'AUTH-' || gen_random_uuid()::text, NOW() - INTERVAL '18 days', 6, 0);  -- 6 cuotas sin interés
    
    -- Compra en farmacia
    INSERT INTO transacciones_tarjetas (tarjeta_id, tipo, monto, comercio, categoria, pais, ciudad, estado, codigo_autorizacion, fecha)
    VALUES (tarjeta_platinum_id, 'compra', 2340.00, 'Farmacity', 'salud', 'ARG', 'Buenos Aires', 'aprobada', 'AUTH-' || gen_random_uuid()::text, NOW() - INTERVAL '12 days');
    
    -- Pago de tarjeta
    INSERT INTO transacciones_tarjetas (tarjeta_id, tipo, monto, comercio, categoria, estado, codigo_autorizacion, fecha)
    VALUES (tarjeta_platinum_id, 'pago', 15000.00, 'Pago Automático Débito', 'pagos', 'aprobada', 'PAY-' || gen_random_uuid()::text, NOW() - INTERVAL '8 days');
END $$;

-- Alerta de seguridad (ejemplo)
DO $$
DECLARE
    tarjeta_id UUID;
    transaccion_id UUID;
BEGIN
    SELECT id INTO tarjeta_id FROM tarjetas WHERE ultimos_4_digitos = '9003';
    SELECT id INTO transaccion_id FROM transacciones_tarjetas WHERE comercio = 'Apple Store' LIMIT 1;
    
    INSERT INTO alertas_seguridad (tarjeta_id, tipo_alerta, descripcion, nivel_riesgo, transaccion_id, accion_tomada, estado, fecha)
    VALUES (
        tarjeta_id,
        'ubicacion_inusual',
        'Compra realizada desde ubicación inusual (USA). Usuario notificado.',
        'medio',
        transaccion_id,
        'Notificación enviada al usuario',
        'revisada',
        NOW() - INTERVAL '22 days'
    );
END $$;

-- ============== FUNCTIONS ==============

-- Función para obtener tarjetas de un usuario
CREATE OR REPLACE FUNCTION obtener_tarjetas_usuario(p_user_id VARCHAR)
RETURNS TABLE(
    tarjeta_id UUID,
    ultimos_digitos VARCHAR,
    tipo VARCHAR,
    marca VARCHAR,
    saldo_disponible DECIMAL,
    limite DECIMAL,
    estado VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.ultimos_4_digitos,
        t.tipo,
        t.marca,
        t.saldo_disponible,
        t.limite_credito,
        t.estado
    FROM tarjetas t
    WHERE t.user_id = p_user_id AND t.estado = 'activa'
    ORDER BY t.tipo DESC, t.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener resumen de gastos del mes
CREATE OR REPLACE FUNCTION resumen_gastos_mes(p_tarjeta_id UUID, p_mes DATE)
RETURNS TABLE(
    categoria VARCHAR,
    total_gastado DECIMAL,
    cantidad_transacciones BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(tt.categoria, 'otros') AS categoria,
        SUM(tt.monto) AS total_gastado,
        COUNT(*) AS cantidad_transacciones
    FROM transacciones_tarjetas tt
    WHERE tt.tarjeta_id = p_tarjeta_id
      AND tt.tipo = 'compra'
      AND tt.estado = 'aprobada'
      AND DATE_TRUNC('month', tt.fecha) = DATE_TRUNC('month', p_mes)
    GROUP BY categoria
    ORDER BY total_gastado DESC;
END;
$$ LANGUAGE plpgsql;

-- ============== SUMMARY ==============

DO $$
DECLARE
    total_tarjetas INTEGER;
    total_transacciones INTEGER;
    total_alertas INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_tarjetas FROM tarjetas;
    SELECT COUNT(*) INTO total_transacciones FROM transacciones_tarjetas;
    SELECT COUNT(*) INTO total_alertas FROM alertas_seguridad;
    
    RAISE NOTICE '✅ Tarjetas DB initialized successfully';
    RAISE NOTICE '   - Tarjetas: %', total_tarjetas;
    RAISE NOTICE '   - Transacciones: %', total_transacciones;
    RAISE NOTICE '   - Alertas: %', total_alertas;
END $$;
