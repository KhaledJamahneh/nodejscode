-- Add dispenser management tables
CREATE TABLE IF NOT EXISTS dispenser_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dispenser_features (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Update dispensers table to link to these
ALTER TABLE dispensers 
ADD COLUMN IF NOT EXISTS type_id INTEGER REFERENCES dispenser_types(id),
ADD COLUMN IF NOT EXISTS features TEXT[] DEFAULT '{}';

-- Seed initial data
INSERT INTO dispenser_types (name, display_order) VALUES 
('Manual', 1),
('Electric', 2),
('Touch', 3)
ON CONFLICT (name) DO NOTHING;
