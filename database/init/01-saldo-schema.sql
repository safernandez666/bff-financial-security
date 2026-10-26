-- ================================================================
-- Database: saldo_db
-- Description: Cuentas bancarias y movimientos
-- ================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============== TABLES ==============

-- Cuentas bancarias
CREATE TABLE IF NOT EXISTS cuentas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,  -- Keycloak user ID
    numero_cuenta VARCHAR(20) UNIQUE NOT NULL,
    tipo_cuenta VARCHAR(20) NOT NULL CHECK (tipo_cuenta IN ('ahorro', 'corriente')),
    saldo DECIMAL(15,2) NOT NULL DEFAULT 0 CHECK (saldo >= 0),
    moneda VARCHAR(3) DEFAULT 'USD' CHECK (moneda IN ('USD', 'EUR', 'ARS')),
    estado VARCHAR(20) DEFAULT 'activa' CHECK (estado IN ('activa', 'bloqueada', 'cerrada')),
    fecha_apertura TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Movimientos de cuenta
CREATE TABLE IF NOT EXISTS movimientos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cuenta_id UUID REFERENCES cuentas(id) ON DELETE CASCADE,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('deposito', 'retiro', 'transferencia_enviada', 'transferencia_recibida')),
    monto DECIMAL(15,2) NOT NULL CHECK (monto > 0),
    saldo_anterior DECIMAL(15,2) NOT NULL,
    saldo_nuevo DECIMAL(15,2) NOT NULL,
    descripcion TEXT,
    referencia VARCHAR(100),
    fecha TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============== INDEXES ==============

CREATE INDEX idx_cuentas_user_id ON cuentas(user_id);
CREATE INDEX idx_cuentas_numero_cuenta ON cuentas(numero_cuenta);
CREATE INDEX idx_cuentas_estado ON cuentas(estado);

CREATE INDEX idx_movimientos_cuenta_id ON movimientos(cuenta_id);
CREATE INDEX idx_movimientos_fecha ON movimientos(fecha DESC);
CREATE INDEX idx_movimientos_tipo ON movimientos(tipo);

-- ============== TRIGGERS ==============

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_cuentas_updated_at BEFORE UPDATE ON cuentas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============== DEMO DATA ==============

-- Usuario: juan.perez (customer)
INSERT INTO cuentas (user_id, numero_cuenta, tipo_cuenta, saldo, moneda, estado, fecha_apertura) VALUES
('juan-perez-id', '4001-2345-6789-0001', 'ahorro', 15750.50, 'USD', 'activa', NOW() - INTERVAL '2 years'),
('juan-perez-id', '4001-2345-6789-0002', 'corriente', 3240.75, 'USD', 'activa', NOW() - INTERVAL '1 year');

-- Usuario: maria.gonzalez (premium-customer)
INSERT INTO cuentas (user_id, numero_cuenta, tipo_cuenta, saldo, moneda, estado, fecha_apertura) VALUES
('maria-gonzalez-id', '4001-8765-4321-0001', 'ahorro', 45890.25, 'USD', 'activa', NOW() - INTERVAL '3 years'),
('maria-gonzalez-id', '4001-8765-4321-0002', 'corriente', 12500.00, 'USD', 'activa', NOW() - INTERVAL '2 years'),
('maria-gonzalez-id', '4001-8765-4321-0003', 'ahorro', 8750.00, 'EUR', 'activa', NOW() - INTERVAL '1 year');

-- Usuario: admin (admin - cuenta de prueba)
INSERT INTO cuentas (user_id, numero_cuenta, tipo_cuenta, saldo, moneda, estado, fecha_apertura) VALUES
('admin-id', '4001-0000-0000-0001', 'corriente', 1000.00, 'USD', 'activa', NOW() - INTERVAL '5 years');

-- Movimientos para Juan Pérez (últimos 30 días)
DO $$
DECLARE
    cuenta_ahorro_id UUID;
    cuenta_corriente_id UUID;
BEGIN
    SELECT id INTO cuenta_ahorro_id FROM cuentas WHERE numero_cuenta = '4001-2345-6789-0001';
    SELECT id INTO cuenta_corriente_id FROM cuentas WHERE numero_cuenta = '4001-2345-6789-0002';
    
    -- Depósito hace 25 días
    INSERT INTO movimientos (cuenta_id, tipo, monto, saldo_anterior, saldo_nuevo, descripcion, referencia, fecha)
    VALUES (cuenta_ahorro_id, 'deposito', 5000.00, 10750.50, 15750.50, 'Depósito en efectivo', 'DEP-20241001-001', NOW() - INTERVAL '25 days');
    
    -- Transferencia recibida hace 20 días
    INSERT INTO movimientos (cuenta_id, tipo, monto, saldo_anterior, saldo_nuevo, descripcion, referencia, fecha)
    VALUES (cuenta_corriente_id, 'transferencia_recibida', 1500.00, 1740.75, 3240.75, 'Transferencia de María González', 'TRF-20241006-045', NOW() - INTERVAL '20 days');
    
    -- Retiro hace 15 días
    INSERT INTO movimientos (cuenta_id, tipo, monto, saldo_anterior, saldo_nuevo, descripcion, referencia, fecha)
    VALUES (cuenta_ahorro_id, 'retiro', 2000.00, 17750.50, 15750.50, 'Retiro en cajero automático', 'RET-20241011-089', NOW() - INTERVAL '15 days');
END $$;

-- Movimientos para María González (últimos 30 días)
DO $$
DECLARE
    cuenta_ahorro_id UUID;
    cuenta_corriente_id UUID;
BEGIN
    SELECT id INTO cuenta_ahorro_id FROM cuentas WHERE numero_cuenta = '4001-8765-4321-0001';
    SELECT id INTO cuenta_corriente_id FROM cuentas WHERE numero_cuenta = '4001-8765-4321-0002';
    
    -- Depósito hace 28 días
    INSERT INTO movimientos (cuenta_id, tipo, monto, saldo_anterior, saldo_nuevo, descripcion, referencia, fecha)
    VALUES (cuenta_ahorro_id, 'deposito', 10000.00, 35890.25, 45890.25, 'Depósito bancario', 'DEP-20240928-123', NOW() - INTERVAL '28 days');
    
    -- Transferencia enviada hace 20 días
    INSERT INTO movimientos (cuenta_id, tipo, monto, saldo_anterior, saldo_nuevo, descripcion, referencia, fecha)
    VALUES (cuenta_corriente_id, 'transferencia_enviada', 1500.00, 14000.00, 12500.00, 'Transferencia a Juan Pérez', 'TRF-20241006-045', NOW() - INTERVAL '20 days');
    
    -- Depósito hace 10 días
    INSERT INTO movimientos (cuenta_id, tipo, monto, saldo_anterior, saldo_nuevo, descripcion, referencia, fecha)
    VALUES (cuenta_corriente_id, 'deposito', 5000.00, 7500.00, 12500.00, 'Depósito en efectivo', 'DEP-20241016-234', NOW() - INTERVAL '10 days');
END $$;

-- ============== FUNCTIONS ==============

-- Función para obtener balance de cuenta
CREATE OR REPLACE FUNCTION obtener_balance_cuenta(p_user_id VARCHAR)
RETURNS TABLE(
    cuenta_id UUID,
    numero_cuenta VARCHAR,
    tipo VARCHAR,
    saldo DECIMAL,
    moneda VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.numero_cuenta, c.tipo_cuenta, c.saldo, c.moneda
    FROM cuentas c
    WHERE c.user_id = p_user_id AND c.estado = 'activa'
    ORDER BY c.fecha_apertura DESC;
END;
$$ LANGUAGE plpgsql;

-- ============== GRANTS ==============

-- Grant permissions (adjust user as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO saldo_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO saldo_user;

-- ============== SUMMARY ==============

-- Log summary
DO $$
DECLARE
    total_cuentas INTEGER;
    total_movimientos INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_cuentas FROM cuentas;
    SELECT COUNT(*) INTO total_movimientos FROM movimientos;
    
    RAISE NOTICE '✅ Saldo DB initialized successfully';
    RAISE NOTICE '   - Cuentas: %', total_cuentas;
    RAISE NOTICE '   - Movimientos: %', total_movimientos;
END $$;
