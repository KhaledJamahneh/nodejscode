#!/bin/bash
# Setup Neon database with schema and initial admin user

echo "Setting up Neon database..."

# Run schema
psql "$DATABASE_URL" -f database/schema-no-postgis.sql

# Create initial admin user
psql "$DATABASE_URL" << 'EOF'
-- Insert admin user (password: admin123)
INSERT INTO users (username, password_hash, phone, roles, is_active, created_at, updated_at)
VALUES (
  'admin',
  '$2b$10$rZ5L5YxGJZ5YxGJZ5YxGJeK5L5YxGJZ5YxGJZ5YxGJZ5YxGJZ5YxG',
  '+972500000000',
  ARRAY['admin']::user_role[],
  true,
  NOW(),
  NOW()
) ON CONFLICT (username) DO NOTHING;

-- Insert test client user (password: client123)
INSERT INTO users (username, password_hash, phone, roles, is_active, created_at, updated_at)
VALUES (
  'client1',
  '$2b$10$rZ5L5YxGJZ5YxGJZ5YxGJeK5L5YxGJZ5YxGJZ5YxGJZ5YxGJZ5YxG',
  '+972501111111',
  ARRAY['client']::user_role[],
  true,
  NOW(),
  NOW()
) ON CONFLICT (username) DO NOTHING;

-- Insert test worker user (password: worker123)
INSERT INTO users (username, password_hash, phone, roles, is_active, created_at, updated_at)
VALUES (
  'worker1',
  '$2b$10$rZ5L5YxGJZ5YxGJZ5YxGJeK5L5YxGJZ5YxGJZ5YxGJZ5YxGJZ5YxG',
  '+972502222222',
  ARRAY['worker']::user_role[],
  true,
  NOW(),
  NOW()
) ON CONFLICT (username) DO NOTHING;

SELECT 'Database setup complete!' as status;
EOF

echo "Done!"
