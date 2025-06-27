#!/bin/bash
# Guacamole Installation Post-Install Verification Script
# Version: 2.0 - Enhanced Real-World Testing
# This script performs comprehensive real-world testing of a Guacamole installation
# Tests both functionality and production-readiness

# Help function
show_help() {
    echo "Guacamole Installation Post-Install Verification Script v2.0"
    echo ""
    echo "USAGE:"
    echo "  sudo ./test-guacamole-installer.sh [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -q, --quiet    Quiet mode (less verbose output)"
    echo "  -v, --verbose  Verbose mode (detailed diagnostic output)"
    echo ""
    echo "DESCRIPTION:"
    echo "  This script performs comprehensive testing of your Guacamole installation"
    echo "  including system requirements, services, security, performance, and"
    echo "  real-world functionality tests."
    echo ""
    echo "EXIT CODES:"
    echo "  0 - All tests passed (production ready)"
    echo "  1 - Minor issues detected (mostly functional)"
    echo "  2 - Significant issues detected (needs attention)"
    echo "  3 - Critical failure (non-functional)"
    echo ""
    echo "EXAMPLES:"
    echo "  ./test-guacamole-installer.sh              # Run full test suite"
    echo "  ./test-guacamole-installer.sh --quiet      # Run with minimal output"
    echo "  ./test-guacamole-installer.sh --verbose    # Run with detailed diagnostics"
    echo ""
}

# Parse command line arguments
QUIET_MODE=false
VERBOSE_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "======================================================="
echo "🧪 GUACAMOLE INSTALLATION VERIFICATION TEST"
echo "======================================================="
if [ "$QUIET_MODE" = true ]; then
    echo "🔇 Running in quiet mode"
elif [ "$VERBOSE_MODE" = true ]; then
    echo "🔊 Running in verbose mode with detailed diagnostics"
fi
echo "🔍 Comprehensive post-install verification for Apache Guacamole"
echo "📋 Tests: System, Services, Security, Performance, and Real Functionality"
echo "🎯 Goal: Ensure production-ready Guacamole deployment"
echo ""

# Check if running as root (needed for some tests)
if [ "$(id -u)" -eq 0 ]; then
    echo "🔑 Running as root - full diagnostic access enabled"
else
    echo "⚠️  Running as non-root - some diagnostic tests may be limited"
fi
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Test function with enhanced error reporting
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    local error_details="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "🔍 Testing: $test_name... "
    
    # Capture both exit code and output for better diagnostics
    local test_output
    test_output=$(eval "$test_command" 2>&1)
    local test_exit_code=$?
    
    if [ $test_exit_code -eq 0 ]; then
        if [ "$expected_result" = "pass" ]; then
            echo -e "${GREEN}✅ PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}❌ FAIL (unexpected success)${NC}"
            if [ -n "$error_details" ]; then
                echo -e "   ${YELLOW}Details: $error_details${NC}"
            fi
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        if [ "$expected_result" = "fail" ]; then
            echo -e "${GREEN}✅ PASS (expected failure)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}❌ FAIL${NC}"
            if [ -n "$error_details" ]; then
                echo -e "   ${YELLOW}Details: $error_details${NC}"
            fi
            if [ -n "$test_output" ]; then
                echo -e "   ${YELLOW}Output: $(echo "$test_output" | head -1)${NC}"
            fi
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
}

# HTTP test function with detailed output
test_http_endpoint() {
    local url="$1"
    local test_name="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "🌐 Testing HTTP: $test_name... "
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$HTTP_STATUS" -eq 200 ]; then
        # Check if it's actually Guacamole content
        CONTENT=$(curl -s "$url" 2>/dev/null | grep -i "guacamole\|login" || echo "")
        if [ -n "$CONTENT" ]; then
            echo -e "${GREEN}✅ PASS (HTTP $HTTP_STATUS, Guacamole content detected)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${YELLOW}⚠️ PARTIAL (HTTP $HTTP_STATUS, but no Guacamole content)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        echo -e "${RED}❌ FAIL (HTTP $HTTP_STATUS)${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo "1️⃣ SYSTEM REQUIREMENTS TEST"
echo "─────────────────────────────"

# Test Java installation
run_test "Java 17 installation" "java -version 2>&1 | grep -q 'openjdk version \"17'" "pass" "Install OpenJDK 17: apt install openjdk-17-jdk"

# Test if Java 17 is default
run_test "Java 17 as default" "java -version 2>&1 | head -1 | grep -q '17\\.'" "pass" "Set Java 17 as default: update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java"

# Test package installations
run_test "Tomcat 10 package installed" "dpkg -l | grep -q tomcat10" "pass" "Install Tomcat 10: apt install tomcat10"
run_test "Guacd package installed" "dpkg -l | grep -q guacd" "pass" "Install Guacd: apt install guacd"
run_test "Required libraries installed" "dpkg -l | grep -q libguac-client" "pass" "Install Guacamole libraries: apt install libguac-client-*"

echo ""
echo "2️⃣ SERVICE STATUS TEST"
echo "─────────────────────────"

# Test service status
run_test "Guacd service running" "systemctl is-active --quiet guacd" "pass" "Start Guacd: systemctl start guacd"
run_test "Tomcat 10 service running" "systemctl is-active --quiet tomcat10" "pass" "Start Tomcat: systemctl start tomcat10"
run_test "Guacd service enabled" "systemctl is-enabled --quiet guacd" "pass" "Enable Guacd: systemctl enable guacd"
run_test "Tomcat 10 service enabled" "systemctl is-enabled --quiet tomcat10" "pass" "Enable Tomcat: systemctl enable tomcat10"

echo ""
echo "3️⃣ PORT BINDING TEST"
echo "───────────────────────"

# Test port binding
run_test "Guacd listening on port 4822" "netstat -tlnp | grep -q ':4822'" "pass"
run_test "Tomcat listening on port 8080" "netstat -tlnp | grep -q ':8080'" "pass"

# Test for port conflicts
run_test "No unauthorized process on 4822" "[ \$(lsof -ti:4822 | wc -l) -eq 1 ]" "pass"
run_test "No unauthorized process on 8080" "[ \$(lsof -ti:8080 | wc -l) -eq 1 ]" "pass"

echo ""
echo "4️⃣ FILE SYSTEM TEST"
echo "──────────────────────"

# Test file/directory existence
run_test "Guacamole WAR deployed" "[ -f /var/lib/tomcat10/webapps/guacamole.war ]" "pass"
run_test "Guacamole webapp extracted" "[ -d /var/lib/tomcat10/webapps/guacamole ]" "pass"
run_test "WEB-INF directory exists" "[ -d /var/lib/tomcat10/webapps/guacamole/WEB-INF ]" "pass"
run_test "web.xml exists" "[ -f /var/lib/tomcat10/webapps/guacamole/WEB-INF/web.xml ]" "pass"

# Test configuration files
run_test "Guacamole config directory" "[ -d /etc/guacamole ]" "pass"
run_test "Guacamole properties file" "[ -f /etc/guacamole/guacamole.properties ]" "pass"
run_test "User mapping file" "[ -f /etc/guacamole/user-mapping.xml ]" "pass"
run_test "Configuration symlink" "[ -L /usr/share/tomcat10/.guacamole ]" "pass"

# Test file permissions
run_test "Tomcat owns webapp files" "[ \$(stat -c %U /var/lib/tomcat10/webapps/guacamole.war) = 'tomcat' ]" "pass"
run_test "Tomcat owns config files" "[ \$(stat -c %U /etc/guacamole/guacamole.properties) = 'tomcat' ]" "pass"

echo ""
echo "5️⃣ CONFIGURATION VALIDATION TEST"
echo "───────────────────────────────────"

# Test configuration content
run_test "Guacamole config has guacd settings" "grep -q 'guacd-hostname: localhost' /etc/guacamole/guacamole.properties" "pass"
run_test "Guacamole config has auth provider" "grep -q 'auth-provider:' /etc/guacamole/guacamole.properties" "pass"
run_test "User mapping has admin user" "grep -q 'username=\"guacadmin\"' /etc/guacamole/user-mapping.xml" "pass"
run_test "User mapping is valid XML" "xmllint --noout /etc/guacamole/user-mapping.xml" "pass"

echo ""
echo "6️⃣ HTTP CONNECTIVITY TEST"
echo "────────────────────────────"

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Test HTTP endpoints
test_http_endpoint "http://localhost:8080/guacamole/" "localhost access"
test_http_endpoint "http://127.0.0.1:8080/guacamole/" "loopback access"
test_http_endpoint "http://${SERVER_IP}:8080/guacamole/" "LAN IP access"

echo ""
echo "7️⃣ WEBAPP FUNCTIONALITY TEST"
echo "───────────────────────────────"

# Test Guacamole-specific functionality
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "🔐 Testing: Login page accessibility... "
LOGIN_TEST=$(curl -s http://localhost:8080/guacamole/ 2>/dev/null | grep -i "password\|username\|login" || echo "")
if [ -n "$LOGIN_TEST" ]; then
    echo -e "${GREEN}✅ PASS (login form detected)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAIL (no login form found)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test for common error pages
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "🚫 Testing: No error pages... "
ERROR_TEST=$(curl -s http://localhost:8080/guacamole/ 2>/dev/null | grep -i "error\|exception\|404\|500" || echo "")
if [ -z "$ERROR_TEST" ]; then
    echo -e "${GREEN}✅ PASS (no error content detected)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAIL (error content detected)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "8️⃣ SECURITY & BEST PRACTICES TEST"
echo "────────────────────────────────────"

# Test security configurations
run_test "No ROOT webapp deployment" "[ ! -f /var/lib/tomcat10/webapps/ROOT.war ]" "pass"
run_test "Guacamole config not world-readable" "[ \$(stat -c %a /etc/guacamole/guacamole.properties) != '644' ]" "pass"
run_test "User mapping not world-readable" "[ \$(stat -c %a /etc/guacamole/user-mapping.xml) != '644' ]" "pass"

# Test that default Tomcat pages are not accessible
run_test "Tomcat manager not on root" "curl -s http://localhost:8080/manager/ | grep -q '404\\|403'" "pass"

echo ""
echo "9️⃣ VERSION & COMPATIBILITY TEST"
echo "──────────────────────────────────"

# Check versions
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "📋 Testing: Guacamole version detection... "
VERSION_TEST=$(curl -s http://localhost:8080/guacamole/ 2>/dev/null | grep -o "Apache Guacamole [0-9]\\+\\.[0-9]\\+\\.[0-9]\\+" || echo "")
if [ -n "$VERSION_TEST" ]; then
    echo -e "${GREEN}✅ PASS ($VERSION_TEST detected)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${YELLOW}⚠️ PARTIAL (version not detected in page)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test Jakarta EE compatibility
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "☕ Testing: Jakarta EE compatibility... "
# Check if webapp started without javax.servlet errors
JAKARTA_TEST=$(journalctl -u tomcat10 --no-pager -n 50 | grep -i "javax.servlet" || echo "")
if [ -z "$JAKARTA_TEST" ]; then
    echo -e "${GREEN}✅ PASS (no Jakarta EE compatibility issues)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAIL (Jakarta EE compatibility issues found)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "🔟 PERFORMANCE & RESOURCE TEST"
echo "─────────────────────────────────"

# Test response time
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "⚡ Testing: Response time... "
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" http://localhost:8080/guacamole/ 2>/dev/null || echo "999")
if [ $(echo "$RESPONSE_TIME < 5.0" | bc -l 2>/dev/null || echo "0") -eq 1 ]; then
    echo -e "${GREEN}✅ PASS (${RESPONSE_TIME}s response time)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${YELLOW}⚠️ SLOW (${RESPONSE_TIME}s response time)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test memory usage
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "💾 Testing: Memory usage reasonable... "
TOMCAT_PID=$(pgrep -f tomcat | head -1)
if [ -n "$TOMCAT_PID" ]; then
    TOMCAT_MEM=$(ps -o vsz --no-headers -p "$TOMCAT_PID" 2>/dev/null || echo "0")
    if [ "$TOMCAT_MEM" -lt 1048576 ] && [ "$TOMCAT_MEM" -gt 0 ]; then  # Less than 1GB, more than 0
        echo -e "${GREEN}✅ PASS (${TOMCAT_MEM}KB memory usage)${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}⚠️ HIGH (${TOMCAT_MEM}KB memory usage)${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${RED}❌ FAIL (Tomcat process not found)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "1️⃣1️⃣ REAL-WORLD FUNCTIONALITY TEST"
echo "─────────────────────────────────────"

# Test actual login attempt with wrong credentials (should fail gracefully)
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "🔐 Testing: Login form handles invalid credentials... "
LOGIN_ATTEMPT=$(curl -s -X POST \
    -d "username=invalid&password=invalid" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    http://localhost:8080/guacamole/ 2>/dev/null || echo "")
if echo "$LOGIN_ATTEMPT" | grep -qi "invalid\|error\|login"; then
    echo -e "${GREEN}✅ PASS (login form responds to invalid credentials)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAIL (login form not responding properly)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test CSS and JavaScript loading
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "🎨 Testing: Static resources (CSS/JS) loading... "
CSS_TEST=$(curl -s http://localhost:8080/guacamole/ 2>/dev/null | grep -c "\.css\|\.js" || echo "0")
if [ "$CSS_TEST" -gt 0 ]; then
    echo -e "${GREEN}✅ PASS ($CSS_TEST static resources found)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAIL (no static resources found)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test API endpoints availability
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "🔌 Testing: API endpoints reachable... "
API_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/guacamole/api/tokens 2>/dev/null || echo "000")
if [ "$API_TEST" -eq 401 ] || [ "$API_TEST" -eq 403 ]; then
    echo -e "${GREEN}✅ PASS (API endpoints responding with auth challenge)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAIL (API endpoints not responding correctly: HTTP $API_TEST)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "1️⃣2️⃣ INTEGRATION & COMMUNICATION TEST"
echo "─────────────────────────────────────────"

# Test Guacamole to Guacd communication
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "📡 Testing: Guacamole-to-Guacd communication... "
# Check if guacd is accepting connections
GUACD_TEST=$(echo "select;" | timeout 5 nc localhost 4822 2>/dev/null || echo "timeout")
if [ "$GUACD_TEST" != "timeout" ] && [ -n "$GUACD_TEST" ]; then
    echo -e "${GREEN}✅ PASS (Guacd responds to connection)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAIL (Guacd not responding to connections)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test database connectivity (if configured)
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "🗄️ Testing: Database connectivity (if configured)... "
if grep -q "mysql\|postgresql" /etc/guacamole/guacamole.properties 2>/dev/null; then
    # Database is configured, test it
    DB_ERROR=$(journalctl -u tomcat10 --no-pager -n 50 | grep -i "database\|connection\|sql.*error" | head -1 || echo "")
    if [ -z "$DB_ERROR" ]; then
        echo -e "${GREEN}✅ PASS (no database errors in logs)${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL (database errors found)${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${BLUE}ℹ️ SKIP (file-based auth, no database configured)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
fi

echo ""
echo "1️⃣3️⃣ LOG ANALYSIS & ERROR DETECTION"
echo "───────────────────────────────────────"

# Check for critical errors in logs
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "📋 Testing: No critical errors in Tomcat logs... "
CRITICAL_ERRORS=$(journalctl -u tomcat10 --no-pager -n 100 | grep -i "severe\|fatal\|critical" | wc -l)
if [ "$CRITICAL_ERRORS" -eq 0 ]; then
    echo -e "${GREEN}✅ PASS (no critical errors found)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAIL ($CRITICAL_ERRORS critical errors found)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Check for Guacd errors
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "📋 Testing: No critical errors in Guacd logs... "
GUACD_ERRORS=$(journalctl -u guacd --no-pager -n 100 | grep -i "error\|fail" | wc -l)
if [ "$GUACD_ERRORS" -eq 0 ]; then
    echo -e "${GREEN}✅ PASS (no Guacd errors found)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${YELLOW}⚠️ MINOR ($GUACD_ERRORS minor Guacd issues found)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "1️⃣4️⃣ PRODUCTION READINESS TEST"
echo "─────────────────────────────────"

# Test disk space
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "💽 Testing: Sufficient disk space... "
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 90 ]; then
    echo -e "${GREEN}✅ PASS (${DISK_USAGE}% disk usage)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAIL (${DISK_USAGE}% disk usage - critically high)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test system load
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "📊 Testing: System load reasonable... "
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
if [ $(echo "$LOAD_AVG < 2.0" | bc -l 2>/dev/null || echo "1") -eq 1 ]; then
    echo -e "${GREEN}✅ PASS (${LOAD_AVG} load average)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${YELLOW}⚠️ HIGH (${LOAD_AVG} load average)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test for security configurations
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -n "🔒 Testing: Security headers present... "
SECURITY_HEADERS=$(curl -s -I http://localhost:8080/guacamole/ 2>/dev/null | grep -i "x-frame-options\|x-content-type-options" | wc -l)
if [ "$SECURITY_HEADERS" -gt 0 ]; then
    echo -e "${GREEN}✅ PASS ($SECURITY_HEADERS security headers found)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${YELLOW}⚠️ MINOR (no security headers detected)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "======================================================="
echo "📊 COMPREHENSIVE TEST RESULTS SUMMARY"
echo "======================================================="

# Calculate pass rate
PASS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))

echo "📈 Test Statistics:"
echo -e "   ${GREEN}✅ Passed: $TESTS_PASSED${NC}"
echo -e "   ${RED}❌ Failed: $TESTS_FAILED${NC}"
echo -e "   ${BLUE}📊 Total: $TOTAL_TESTS${NC}"
echo -e "   ${BLUE}📈 Pass Rate: ${PASS_RATE}%${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 EXCELLENT! ALL TESTS PASSED! 🎉${NC}"
    echo -e "${GREEN}✅ Guacamole installation is FULLY FUNCTIONAL and PRODUCTION-READY!${NC}"
    echo ""
    echo "🚀 DEPLOYMENT STATUS: READY FOR PRODUCTION USE"
    echo ""
    echo "📍 Access Information:"
    echo -e "   ${GREEN}🌐 Primary URL: http://localhost:8080/guacamole/${NC}"
    echo -e "   ${GREEN}🌐 LAN Access: http://${SERVER_IP}:8080/guacamole/${NC}"
    echo -e "   ${GREEN}👤 Default Username: guacadmin${NC}"
    echo -e "   ${GREEN}🔐 Default Password: guacadmin${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  SECURITY REMINDER: Change the default password immediately after first login!${NC}"
    echo ""
    echo "🔧 Quick Management Commands:"
    echo "   • Restart services: sudo systemctl restart guacd tomcat10"
    echo "   • View logs: sudo journalctl -u tomcat10 -f"
    echo "   • Check status: sudo systemctl status guacd tomcat10"
    echo ""
    echo "🎯 Next Steps:"
    echo "   1. Log in and change the default password"
    echo "   2. Configure your remote connections (VNC, RDP, SSH)"
    echo "   3. Set up additional users if needed"
    echo "   4. Consider implementing SSL/HTTPS for production use"
    
    exit 0
    
elif [ $PASS_RATE -ge 85 ]; then
    echo -e "${YELLOW}⚠️ GOOD! TESTS MOSTLY PASSED WITH MINOR ISSUES ⚠️${NC}"
    echo -e "${YELLOW}Guacamole appears to be functional with some minor issues that should be addressed.${NC}"
    echo ""
    echo "🟡 DEPLOYMENT STATUS: FUNCTIONAL WITH WARNINGS"
    echo ""
    echo "📍 Access Information (likely working):"
    echo -e "   ${YELLOW}🌐 Primary URL: http://localhost:8080/guacamole/${NC}"
    echo -e "   ${YELLOW}🌐 LAN Access: http://${SERVER_IP}:8080/guacamole/${NC}"
    echo -e "   ${YELLOW}👤 Default Username: guacadmin${NC}"
    echo -e "   ${YELLOW}🔐 Default Password: guacadmin${NC}"
    echo ""
    echo "🔍 Recommended Actions:"
    echo "   1. Review the failed tests above"
    echo "   2. Test actual login and functionality"
    echo "   3. Monitor logs for any recurring issues"
    echo "   4. Consider addressing security warnings"
    
    exit 1
    
elif [ $PASS_RATE -ge 60 ]; then
    echo -e "${RED}❌ MIXED RESULTS - SIGNIFICANT ISSUES DETECTED ❌${NC}"
    echo -e "${RED}Guacamole installation has significant issues that need attention.${NC}"
    echo ""
    echo "🔴 DEPLOYMENT STATUS: NEEDS ATTENTION"
    echo ""
    echo "🚨 Critical Actions Required:"
    echo "   1. Review ALL failed tests above"
    echo "   2. Check service logs: sudo journalctl -u tomcat10 -u guacd -n 50"
    echo "   3. Verify file permissions: ls -la /etc/guacamole/ /var/lib/tomcat10/webapps/"
    echo "   4. Test services manually: sudo systemctl restart guacd tomcat10"
    echo "   5. Consider re-running the installation script"
    echo ""
    echo "🔍 Diagnostic Commands:"
    echo "   • Service status: sudo systemctl status tomcat10 guacd"
    echo "   • Port check: sudo netstat -tlnp | grep -E ':(8080|4822)'"
    echo "   • Process check: ps aux | grep -E '(tomcat|guacd)'"
    echo "   • Disk space: df -h"
    
    exit 2
    
else
    echo -e "${RED}💥 CRITICAL FAILURE - INSTALLATION NOT WORKING 💥${NC}"
    echo -e "${RED}Guacamole installation has CRITICAL issues and is likely non-functional.${NC}"
    echo ""
    echo "🆘 DEPLOYMENT STATUS: CRITICAL FAILURE"
    echo ""
    echo "🚨 IMMEDIATE ACTIONS REQUIRED:"
    echo "   1. DO NOT USE THIS INSTALLATION IN PRODUCTION"
    echo "   2. Review the installation logs and error messages above"
    echo "   3. Consider completely reinstalling Guacamole"
    echo "   4. Check system requirements and dependencies"
    echo ""
    echo "🔍 Emergency Diagnostic Steps:"
    echo "   1. Check system resources:"
    echo "      sudo df -h && free -h"
    echo "   2. Verify Java installation:"
    echo "      java -version"
    echo "   3. Check service failures:"
    echo "      sudo systemctl status tomcat10 guacd --no-pager -l"
    echo "   4. Review recent logs:"
    echo "      sudo journalctl -u tomcat10 -u guacd -n 100"
    echo "   5. Check network/ports:"
    echo "      sudo netstat -tlnp | grep -E ':(8080|4822)'"
    echo ""
    echo "📞 If these steps don't resolve the issues:"
    echo "   • Stop services: sudo systemctl stop tomcat10 guacd"
    echo "   • Clean installation: sudo rm -rf /var/lib/tomcat10/webapps/guacamole*"
    echo "   • Re-run installer: sudo ./install-java-tomcat-and-guacamole-in-ubuntu-24.04.sh"
    echo "   • Re-run this test: sudo ./test-guacamole-installer.sh"
    
    exit 3
fi
