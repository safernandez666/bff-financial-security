-- ================================================================
-- Database: usuario_db
-- Description: Perfiles de usuario y preferencias
-- ================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============== TABLES ==============

-- Perfiles de usuario (complementa Keycloak)
CREATE TABLE IF NOT EXISTS perfiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) UNIQUE NOT NULL,  -- Keycloak user ID
    nombre_completo VARCHAR(255) NOT NULL,
    dni VARCHAR(20) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    direccion TEXT,
    ciudad VARCHAR(100),
    provincia VARCHAR(100),
    codigo_postal VARCHAR(10),
    pais VARCHAR(3) DEFAULT 'ARG',
    fecha_nacimiento DATE,
    genero VARCHAR(20) CHECK (genero IN ('masculino', 'femenino', 'otro', 'prefiero_no_decir')),
    estado_civil VARCHAR(20) CHECK (estado_civil IN ('soltero', 'casado', 'divorciado', 'viudo')),
    ocupacion VARCHAR(100),
    ingresos_mensuales DECIMAL(15,2),
    nivel_educacion VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Preferencias de usuario
CREATE TABLE IF NOT EXISTS preferencias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) UNIQUE REFERENCES perfiles(user_id) ON DELETE CASCADE,
    notificaciones_email BOOLEAN DEFAULT TRUE,
    notificaciones_sms BOOLEAN DEFAULT FALSE,
    notificaciones_push BOOLEAN DEFAULT TRUE,
    tema VARCHAR(20) DEFAULT 'light' CHECK (tema IN ('light', 'dark', 'auto')),
    idioma VARCHAR(5) DEFAULT 'es' CHECK (idioma IN ('es', 'en', 'pt')),
    moneda_preferida VARCHAR(3) DEFAULT 'USD',
    doble_factor_auth BOOLEAN DEFAULT FALSE,
    alertas_transacciones BOOLEAN DEFAULT TRUE,
    limite_alerta_monto DECIMAL(15,2) DEFAULT 1000.00,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Contactos de emergencia
CREATE TABLE IF NOT EXISTS contactos_emergencia (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) REFERENCES perfiles(user_id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    relacion VARCHAR(50),
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    es_principal BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Historial de cambios en perfil (auditoría)
CREATE TABLE IF NOT EXISTS historial_cambios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    campo_modificado VARCHAR(100) NOT NULL,
    valor_anterior TEXT,
    valor_nuevo TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    fecha_cambio TIMESTAMP DEFAULT NOW()
);

-- ============== INDEXES ==============

CREATE INDEX idx_perfiles_user_id ON perfiles(user_id);
CREATE INDEX idx_perfiles_dni ON perfiles(dni);
CREATE INDEX idx_preferencias_user_id ON preferencias(user_id);
CREATE INDEX idx_contactos_user_id ON contactos_emergencia(user_id);
CREATE INDEX idx_historial_user_id ON historial_cambios(user_id);
CREATE INDEX idx_historial_fecha ON historial_cambios(fecha_cambio DESC);

-- ============== TRIGGERS ==============

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_perfiles_updated_at BEFORE UPDATE ON perfiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_preferencias_updated_at BEFORE UPDATE ON preferencias
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para auditoría de cambios
CREATE OR REPLACE FUNCTION audit_perfil_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.telefono IS DISTINCT FROM NEW.telefono THEN
        INSERT INTO historial_cambios (user_id, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.user_id, 'telefono', OLD.telefono, NEW.telefono);
    END IF;
    
    IF OLD.direccion IS DISTINCT FROM NEW.direccion THEN
        INSERT INTO historial_cambios (user_id, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.user_id, 'direccion', OLD.direccion, NEW.direccion);
    END IF;
    
    IF OLD.email IS DISTINCT FROM NEW.email THEN
        INSERT INTO historial_cambios (user_id, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.user_id, 'email', OLD.email, NEW.email);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Nota: Desactivado por defecto para no registrar cambios de demo data
-- CREATE TRIGGER audit_perfiles AFTER UPDATE ON perfiles
--     FOR EACH ROW EXECUTE FUNCTION audit_perfil_changes();

-- ============== DEMO DATA ==============

-- Perfil: juan.perez
INSERT INTO perfiles (
    user_id, nombre_completo, dni, telefono, direccion, ciudad, provincia,
    codigo_postal, pais, fecha_nacimiento, genero, estado_civil, ocupacion,
    ingresos_mensuales, nivel_educacion
) VALUES (
    'juan-perez-id',
    'Juan Pérez',
    '35.456.789',
    '+54 9 11 4567-8901',
    'Av. Corrientes 1234, Piso 5, Dto. B',
    'Buenos Aires',
    'CABA',
    'C1043',
    'ARG',
    '1990-05-15',
    'masculino',
    'soltero',
    'Desarrollador de Software',
    5500.00,
    'Universitario Completo'
);

-- Preferencias: juan.perez
INSERT INTO preferencias (user_id, notificaciones_email, notificaciones_sms, notificaciones_push, tema, idioma, moneda_preferida, doble_factor_auth, alertas_transacciones, limite_alerta_monto)
VALUES ('juan-perez-id', TRUE, FALSE, TRUE, 'dark', 'es', 'USD', TRUE, TRUE, 1000.00);

-- Contacto emergencia: juan.perez
INSERT INTO contactos_emergencia (user_id, nombre, relacion, telefono, email, es_principal)
VALUES ('juan-perez-id', 'María Pérez', 'Hermana', '+54 9 11 2345-6789', 'maria.perez@example.com', TRUE);

-- Perfil: maria.gonzalez
INSERT INTO perfiles (
    user_id, nombre_completo, dni, telefono, direccion, ciudad, provincia,
    codigo_postal, pais, fecha_nacimiento, genero, estado_civil, ocupacion,
    ingresos_mensuales, nivel_educacion
) VALUES (
    'maria-gonzalez-id',
    'María González',
    '32.123.456',
    '+54 9 11 9876-5432',
    'Av. Santa Fe 4567, Piso 12, Dto. A',
    'Buenos Aires',
    'CABA',
    'C1425',
    'ARG',
    '1985-08-22',
    'femenino',
    'casado',
    'Gerente de Producto',
    12000.00,
    'Posgrado'
);

-- Preferencias: maria.gonzalez
INSERT INTO preferencias (user_id, notificaciones_email, notificaciones_sms, notificaciones_push, tema, idioma, moneda_preferida, doble_factor_auth, alertas_transacciones, limite_alerta_monto)
VALUES ('maria-gonzalez-id', TRUE, TRUE, TRUE, 'light', 'es', 'USD', TRUE, TRUE, 5000.00);

-- Contactos emergencia: maria.gonzalez
INSERT INTO contactos_emergencia (user_id, nombre, relacion, telefono, email, es_principal)
VALUES 
('maria-gonzalez-id', 'Carlos González', 'Esposo', '+54 9 11 8765-4321', 'carlos.gonzalez@example.com', TRUE),
('maria-gonzalez-id', 'Ana González', 'Hermana', '+54 9 11 5555-1234', 'ana.gonzalez@example.com', FALSE);

-- Perfil: admin
INSERT INTO perfiles (
    user_id, nombre_completo, dni, telefono, direccion, ciudad, provincia,
    codigo_postal, pais, fecha_nacimiento, genero, estado_civil, ocupacion,
    ingresos_mensuales, nivel_educacion
) VALUES (
    'admin-id',
    'Administrator Bank',
    '00.000.000',
    '+54 9 11 0000-0000',
    'Av. Admin 0000',
    'Buenos Aires',
    'CABA',
    'C0000',
    'ARG',
    '1980-01-01',
    'prefiero_no_decir',
    'soltero',
    'Administrador de Sistemas',
    15000.00,
    'Posgrado'
);

-- Preferencias: admin
INSERT INTO preferencias (user_id, notificaciones_email, notificaciones_sms, notificaciones_push, tema, idioma, moneda_preferida, doble_factor_auth, alertas_transacciones, limite_alerta_monto)
VALUES ('admin-id', TRUE, FALSE, TRUE, 'dark', 'es', 'USD', TRUE, TRUE, 10000.00);

-- ============== FUNCTIONS ==============

-- Función para obtener perfil completo
CREATE OR REPLACE FUNCTION obtener_perfil_completo(p_user_id VARCHAR)
RETURNS TABLE(
    perfil_id UUID,
    nombre VARCHAR,
    dni VARCHAR,
    telefono VARCHAR,
    direccion TEXT,
    ciudad VARCHAR,
    email_notifications BOOLEAN,
    sms_notifications BOOLEAN,
    tema VARCHAR,
    idioma VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.nombre_completo,
        p.dni,
        p.telefono,
        p.direccion,
        p.ciudad,
        pref.notificaciones_email,
        pref.notificaciones_sms,
        pref.tema,
        pref.idioma
    FROM perfiles p
    LEFT JOIN preferencias pref ON p.user_id = pref.user_id
    WHERE p.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- ============== SUMMARY ==============

DO $$
DECLARE
    total_perfiles INTEGER;
    total_preferencias INTEGER;
    total_contactos INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_perfiles FROM perfiles;
    SELECT COUNT(*) INTO total_preferencias FROM preferencias;
    SELECT COUNT(*) INTO total_contactos FROM contactos_emergencia;
    
    RAISE NOTICE '✅ Usuario DB initialized successfully';
    RAISE NOTICE '   - Perfiles: %', total_perfiles;
    RAISE NOTICE '   - Preferencias: %', total_preferencias;
    RAISE NOTICE '   - Contactos: %', total_contactos;
END $$;
