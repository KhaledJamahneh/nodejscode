#!/bin/bash

# Copy backend files (overwrite old with new)
cp -rf src/* einhod-water-backend/src/ 2>/dev/null
cp -f package.json einhod-water-backend/
cp -f package-lock.json einhod-water-backend/
cp -f .env einhod-water-backend/
cp -rf database/* einhod-water-backend/database/ 2>/dev/null
cp -rf migrations/* einhod-water-backend/migrations/ 2>/dev/null

# Copy frontend files (overwrite old with new)
cp -rf lib/* einhod-water-flutter/lib/ 2>/dev/null
cp -f pubspec.yaml einhod-water-flutter/
cp -f pubspec.lock einhod-water-flutter/
cp -f .metadata einhod-water-flutter/ 2>/dev/null
cp -rf android/* einhod-water-flutter/android/ 2>/dev/null
cp -rf build einhod-water-flutter/ 2>/dev/null

# Remove root level duplicates
rm -rf src lib android ios web linux macos windows assets build .dart_tool test
rm -f package.json package-lock.json pubspec.yaml pubspec.lock .metadata
rm -f .flutter-plugins .flutter-plugins-dependencies analysis_options.yaml l10n.yaml
rm -rf database migrations logs scripts node_modules

echo "✅ Files merged and cleaned!"
