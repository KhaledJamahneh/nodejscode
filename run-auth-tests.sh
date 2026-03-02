#!/bin/bash
# Quick test runner for authentication tests

echo "🧪 Running Authentication & Authorization Tests..."
echo "=================================================="
echo ""

# Load test environment
export NODE_ENV=test

# Run tests
npm test -- auth.test.js --verbose

echo ""
echo "=================================================="
echo "✅ Tests completed!"
echo ""
echo "📊 View full coverage report:"
echo "   open coverage/lcov-report/index.html"
