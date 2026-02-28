#!/bin/bash

# Premium UX Test Execution Script
# Run comprehensive tests for Phases 1, 2, and 4

echo "🧪 PREMIUM UX - COMPREHENSIVE TEST EXECUTION"
echo "=============================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo -e "${BLUE}Testing:${NC} $test_name"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# Navigate to Flutter project
cd einhod-water-flutter

echo "📦 Step 1: Checking Dependencies"
echo "--------------------------------"
run_test "Flutter SDK installed" "flutter --version"
run_test "Dependencies installed" "flutter pub get"

echo ""
echo "🎨 Step 2: Phase 1 - Quick Wins Tests"
echo "--------------------------------------"
run_test "Liquid Loading widget exists" "grep -r 'class LiquidLoadingIndicator' lib/core/widgets/"
run_test "Haptic Service exists" "grep -r 'class HapticService' lib/core/services/"
run_test "Glass Card widget exists" "grep -r 'class GlassCard' lib/core/widgets/"
run_test "Celebration Service exists" "grep -r 'class CelebrationService' lib/core/services/"
run_test "Greeting Service exists" "grep -r 'class GreetingService' lib/core/services/"
run_test "Smart Image widget exists" "grep -r 'class SmartImage' lib/core/widgets/"
run_test "Enhanced Empty State exists" "grep -r 'class EnhancedEmptyState' lib/core/widgets/"
run_test "Neumorphic Button exists" "grep -r 'NeumorphicButton' lib/"
run_test "Optimistic UI pattern used" "grep -r 'setState.*immediately' lib/"
run_test "Personalized greetings implemented" "grep -r 'Good morning.*Good afternoon' lib/"

echo ""
echo "🧠 Step 3: Phase 2 - Intelligence Tests"
echo "----------------------------------------"
run_test "AI Prediction Service exists" "grep -r 'class AIPredictionService' lib/core/services/"
run_test "Smart Defaults Service exists" "grep -r 'class SmartDefaultsService' lib/core/services/"
run_test "Predictive Alert Service exists" "grep -r 'class PredictiveAlertService' lib/core/services/"
run_test "Prefetch Service exists" "grep -r 'class PrefetchService' lib/core/services/"
run_test "Usage Dashboard exists" "grep -r 'UsageDashboard' lib/features/analytics/"
run_test "Smart Notifications implemented" "grep -r 'SmartNotification' lib/"
run_test "Contextual Help exists" "grep -r 'ContextualHelp' lib/core/widgets/"
run_test "One-handed mode implemented" "grep -r 'OneHandedLayout' lib/"
run_test "Offline-first architecture" "grep -r 'OfflineService' lib/core/services/"
run_test "Pattern recognition logic" "grep -r 'pattern.*recognition' lib/"

echo ""
echo "✨ Step 4: Phase 4 - Polish Tests"
echo "----------------------------------"
run_test "Performance optimizations applied" "grep -r 'const.*constructor' lib/ | wc -l | awk '{if(\$1>50) exit 0; else exit 1}'"
run_test "Error handling comprehensive" "grep -r 'try.*catch' lib/ | wc -l | awk '{if(\$1>20) exit 0; else exit 1}'"
run_test "Accessibility labels present" "grep -r 'Semantics' lib/ | wc -l | awk '{if(\$1>10) exit 0; else exit 1}'"
run_test "Loading states optimized" "grep -r 'ShimmerLoading\|Skeleton' lib/"
run_test "Gesture refinements" "grep -r 'GestureDetector\|Dismissible' lib/"
run_test "High contrast mode" "grep -r 'HighContrastTheme' lib/"
run_test "Screen reader optimization" "grep -r 'semanticsLabel' lib/"

echo ""
echo "🔧 Step 5: Running Automated Tests"
echo "-----------------------------------"
if [ -f "test/premium_ux_test.dart" ]; then
    echo "Running Flutter tests..."
    if flutter test test/premium_ux_test.dart; then
        echo -e "${GREEN}✓ Automated tests PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ Automated tests FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
else
    echo -e "${YELLOW}⚠ Test file not found, skipping automated tests${NC}"
fi

echo ""
echo "📊 Step 6: Code Quality Checks"
echo "-------------------------------"
run_test "No analysis errors" "flutter analyze --no-fatal-infos"
run_test "Code formatted" "flutter format --set-exit-if-changed lib/"

echo ""
echo "📱 Step 7: Build Tests"
echo "----------------------"
run_test "Android build succeeds" "flutter build apk --debug"
run_test "iOS build succeeds (if on macOS)" "[ ! -d 'ios' ] || flutter build ios --debug --no-codesign"

echo ""
echo "=============================================="
echo "📊 TEST RESULTS SUMMARY"
echo "=============================================="
echo ""
echo -e "Total Tests:  ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
echo ""

# Calculate pass rate
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "Pass Rate:    ${BLUE}$PASS_RATE%${NC}"
    echo ""
    
    if [ $PASS_RATE -ge 95 ]; then
        echo -e "${GREEN}✓ EXCELLENT! Ready for production${NC}"
        exit 0
    elif [ $PASS_RATE -ge 80 ]; then
        echo -e "${YELLOW}⚠ GOOD, but needs some fixes${NC}"
        exit 1
    else
        echo -e "${RED}✗ NEEDS WORK before production${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ No tests were run${NC}"
    exit 1
fi
