#!/bin/bash
# Quick script to apply gallons_on_hand fix

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Applying Reserved Gallons Fix                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if migration file exists
if [ ! -f "migrations/add_gallons_on_hand.sql" ]; then
    echo "❌ Migration file not found!"
    exit 1
fi

echo "📝 Applying migration..."
psql -U postgres -d einhod_water -f migrations/add_gallons_on_hand.sql

if [ $? -eq 0 ]; then
    echo "✅ Migration applied successfully!"
    echo ""
    echo "🔍 Verifying..."
    node scripts/verify_gallons_on_hand.js
else
    echo "❌ Migration failed!"
    exit 1
fi
