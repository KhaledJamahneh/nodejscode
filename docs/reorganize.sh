#!/bin/bash

# Move backend files to einhod-water-backend
mv -f src einhod-water-backend/ 2>/dev/null
mv -f node_modules einhod-water-backend/ 2>/dev/null
mv -f package.json einhod-water-backend/
mv -f package-lock.json einhod-water-backend/
mv -f .env einhod-water-backend/
mv -f .env.example einhod-water-backend/
mv -f server.log einhod-water-backend/ 2>/dev/null
mv -f database einhod-water-backend/
mv -f migrations einhod-water-backend/
mv -f logs einhod-water-backend/
mv -f scripts einhod-water-backend/ 2>/dev/null

# Move frontend files to einhod-water-flutter
mv -f lib einhod-water-flutter/
mv -f android einhod-water-flutter/
mv -f ios einhod-water-flutter/
mv -f web einhod-water-flutter/
mv -f linux einhod-water-flutter/
mv -f macos einhod-water-flutter/
mv -f windows einhod-water-flutter/
mv -f assets einhod-water-flutter/
mv -f build einhod-water-flutter/ 2>/dev/null
mv -f .dart_tool einhod-water-flutter/
mv -f .flutter-plugins einhod-water-flutter/ 2>/dev/null
mv -f .flutter-plugins-dependencies einhod-water-flutter/ 2>/dev/null
mv -f .metadata einhod-water-flutter/ 2>/dev/null
mv -f pubspec.yaml einhod-water-flutter/
mv -f pubspec.lock einhod-water-flutter/
mv -f analysis_options.yaml einhod-water-flutter/
mv -f l10n.yaml einhod-water-flutter/
mv -f test einhod-water-flutter/ 2>/dev/null

echo "✅ Reorganization complete!"
