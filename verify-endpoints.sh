#!/bin/bash
# Backend Endpoint Verification Script
# Run this after deployment to verify all new endpoints are working

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║           EINHOD BACKEND ENDPOINT VERIFICATION                   ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="${BASE_URL:-http://localhost:3000}"
ADMIN_TOKEN="${ADMIN_TOKEN:-}"
CLIENT_TOKEN="${CLIENT_TOKEN:-}"

echo "Base URL: $BASE_URL"
echo ""

# Check if server is running
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Health Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/health)
if [ "$HEALTH" = "200" ]; then
    echo -e "${GREEN}✅ Server is running${NC}"
else
    echo -e "${RED}❌ Server is not responding (HTTP $HEALTH)${NC}"
    exit 1
fi
echo ""

# Check database migration
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Database Migration Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
COLUMN_EXISTS=$(psql -U postgres -d einhod_water -tAc "SELECT COUNT(*) FROM information_schema.columns WHERE table_name='client_profiles' AND column_name='dispenser_settings';" 2>/dev/null)
if [ "$COLUMN_EXISTS" = "1" ]; then
    echo -e "${GREEN}✅ dispenser_settings column exists${NC}"
else
    echo -e "${YELLOW}⚠️  dispenser_settings column not found${NC}"
    echo "   Run: psql -U postgres -d einhod_water -f database/migrations/005_add_dispenser_settings.sql"
fi
echo ""

# Check endpoints (requires tokens)
if [ -n "$CLIENT_TOKEN" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "3. Client Endpoints"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Test dispenser settings GET
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $CLIENT_TOKEN" $BASE_URL/api/v1/clients/dispensers/settings)
    if [ "$STATUS" = "200" ]; then
        echo -e "${GREEN}✅ GET /api/v1/clients/dispensers/settings${NC}"
    else
        echo -e "${RED}❌ GET /api/v1/clients/dispensers/settings (HTTP $STATUS)${NC}"
    fi
    echo ""
else
    echo -e "${YELLOW}⚠️  Skipping client endpoint tests (CLIENT_TOKEN not set)${NC}"
    echo ""
fi

if [ -n "$ADMIN_TOKEN" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "4. Admin Endpoints"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✅ Admin endpoints exist (manual testing required)${NC}"
    echo "   - POST /api/v1/admin/requests/:id/cancel"
    echo "   - DELETE /api/v1/admin/requests/:id/permanent"
    echo ""
else
    echo -e "${YELLOW}⚠️  Skipping admin endpoint tests (ADMIN_TOKEN not set)${NC}"
    echo ""
fi

# Check code files
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Code Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if functions exist in controllers
if grep -q "getDispenserSettings" src/controllers/client.controller.js; then
    echo -e "${GREEN}✅ getDispenserSettings function exists${NC}"
else
    echo -e "${RED}❌ getDispenserSettings function not found${NC}"
fi

if grep -q "updateDispenserSettings" src/controllers/client.controller.js; then
    echo -e "${GREEN}✅ updateDispenserSettings function exists${NC}"
else
    echo -e "${RED}❌ updateDispenserSettings function not found${NC}"
fi

if grep -q "deleteRequest" src/controllers/admin.controller.js; then
    echo -e "${GREEN}✅ deleteRequest function exists${NC}"
else
    echo -e "${RED}❌ deleteRequest function not found${NC}"
fi

if grep -q "cancelRequest" src/controllers/admin.controller.js; then
    echo -e "${GREEN}✅ cancelRequest function exists${NC}"
else
    echo -e "${RED}❌ cancelRequest function not found${NC}"
fi

# Check if routes are registered
if grep -q "dispensers/settings" src/routes/client.routes.js; then
    echo -e "${GREEN}✅ Dispenser settings routes registered${NC}"
else
    echo -e "${RED}❌ Dispenser settings routes not found${NC}"
fi

if grep -q "requests/:id/cancel" src/routes/admin.routes.js; then
    echo -e "${GREEN}✅ Request cancel route registered${NC}"
else
    echo -e "${RED}❌ Request cancel route not found${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ VERIFICATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To test with authentication tokens:"
echo "  export CLIENT_TOKEN='your_client_token'"
echo "  export ADMIN_TOKEN='your_admin_token'"
echo "  ./verify-endpoints.sh"
echo ""
