#!/bin/bash
# Test language update endpoint

echo "🧪 Testing Language Update Endpoint"
echo "===================================="
echo ""

# Login as 'home' user
echo "1️⃣ Logging in as 'home' user..."
LOGIN_RESPONSE=$(curl -s -X POST https://nodejscode-33ip.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "home", "password": "Client123!"}')

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed"
  echo "$LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Login successful"
CURRENT_LANG=$(echo $LOGIN_RESPONSE | grep -o '"preferred_language":"[^"]*"' | cut -d'"' -f4)
echo "   Current language: $CURRENT_LANG"
echo ""

# Change to English
echo "2️⃣ Changing language to English..."
UPDATE_RESPONSE=$(curl -s -X PUT https://nodejscode-33ip.onrender.com/api/v1/users/language \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"language": "en"}')

echo "$UPDATE_RESPONSE"
echo ""

# Verify by logging in again
echo "3️⃣ Verifying change (login again)..."
VERIFY_RESPONSE=$(curl -s -X POST https://nodejscode-33ip.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "home", "password": "Client123!"}')

NEW_LANG=$(echo $VERIFY_RESPONSE | grep -o '"preferred_language":"[^"]*"' | cut -d'"' -f4)
echo "   New language: $NEW_LANG"
echo ""

if [ "$NEW_LANG" = "en" ]; then
  echo "✅ Language update works!"
else
  echo "❌ Language update failed"
fi
