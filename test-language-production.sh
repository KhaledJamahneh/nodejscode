#!/bin/bash
# Test language endpoint on production

echo "🧪 Testing Language Endpoint on Production"
echo "==========================================="
echo ""

# Test credentials
USERNAME="owner"
PASSWORD="Admin123!"

echo "1️⃣ Logging in as '$USERNAME'..."
LOGIN_RESPONSE=$(curl -s -X POST https://nodejscode-33ip.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}")

# Extract token using grep
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed"
  echo "$LOGIN_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Login successful"
echo "   Token: ${TOKEN:0:30}..."
echo ""

# Get current language
CURRENT_LANG=$(echo "$LOGIN_RESPONSE" | grep -o '"preferred_language":"[^"]*"' | cut -d'"' -f4)
echo "   Current language: ${CURRENT_LANG:-en}"
echo ""

# Change to Arabic
echo "2️⃣ Changing language to Arabic..."
UPDATE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X PUT https://nodejscode-33ip.onrender.com/api/v1/users/language \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"language": "ar"}')

HTTP_CODE=$(echo "$UPDATE_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
RESPONSE_BODY=$(echo "$UPDATE_RESPONSE" | sed '/HTTP_CODE/d')

echo "   HTTP Status: $HTTP_CODE"
echo "   Response:"
echo "$RESPONSE_BODY" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE_BODY"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Language update successful!"
else
  echo "❌ Language update failed (HTTP $HTTP_CODE)"
fi
