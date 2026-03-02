#!/bin/bash
# Update all controllers to use proper error status codes

cd /home/eito_new/Downloads/einhod-longterm/einhod-water-backend/src/controllers

# Import error handler at the top of each controller
for file in *.js; do
  # Check if file already has the import
  if ! grep -q "getStatusCode" "$file"; then
    # Add import after other requires
    sed -i '/^const.*require/a const { getStatusCode } = require('\''../middleware/error-handler.middleware'\'');' "$file"
  fi
done

echo "✅ Added error handler imports to all controllers"
