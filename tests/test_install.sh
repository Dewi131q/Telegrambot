#!/bin/bash

# ==========================================
# VPN Script Installation Test
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_function() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS: $test_name${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: $test_name${NC}"
        ((TESTS_FAILED++))
    fi
}

# Test file existence
test_file_exists() {
    local file_path="$1"
    local test_name="$2"
    
    if [[ -f "$file_path" ]]; then
        echo -e "${GREEN}✓ PASS: $test_name exists${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: $test_name does not exist${NC}"
        ((TESTS_FAILED++))
    fi
}

# Test directory existence
test_dir_exists() {
    local dir_path="$1"
    local test_name="$2"
    
    if [[ -d "$dir_path" ]]; then
        echo -e "${GREEN}✓ PASS: $test_name exists${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: $test_name does not exist${NC}"
        ((TESTS_FAILED++))
    fi
}

# Test service status
test_service_status() {
    local service_name="$1"
    local test_name="$2"
    
    if systemctl is-active --quiet "$service_name"; then
        echo -e "${GREEN}✓ PASS: $test_name is running${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: $test_name is not running${NC}"
        ((TESTS_FAILED++))
    fi
}

# Test command availability
test_command_exists() {
    local command_name="$1"
    local test_name="$2"
    
    if command -v "$command_name" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS: $test_name is available${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: $test_name is not available${NC}"
        ((TESTS_FAILED++))
    fi
}

# Test port availability
test_port_open() {
    local port="$1"
    local test_name="$2"
    
    if netstat -tuln | grep -q ":$port "; then
        echo -e "${GREEN}✓ PASS: $test_name is open${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: $test_name is closed${NC}"
        ((TESTS_FAILED++))
    fi
}

# Main test function
run_tests() {
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}                    VPN SCRIPT TEST SUITE                      ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Test 1: Check if running as root
    echo -e "${BLUE}Test 1: Root Access${NC}"
    if [[ $EUID -eq 0 ]]; then
        echo -e "${GREEN}✓ PASS: Running as root${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: Not running as root${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
    
    # Test 2: Check OS compatibility
    echo -e "${BLUE}Test 2: OS Compatibility${NC}"
    if [[ -e /etc/debian_version ]]; then
        echo -e "${GREEN}✓ PASS: Debian/Ubuntu system detected${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: Not a Debian/Ubuntu system${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
    
    # Test 3: Check required directories
    echo -e "${BLUE}Test 3: Directory Structure${NC}"
    test_dir_exists "/usr/local/bin/vpn" "VPN scripts directory"
    test_dir_exists "/etc/xray" "XRAY config directory"
    test_dir_exists "/var/log/xray" "XRAY log directory"
    test_dir_exists "/home/vps/public_html" "Web interface directory"
    test_dir_exists "/home/vps/public_html/akun" "Account files directory"
    echo ""
    
    # Test 4: Check required files
    echo -e "${BLUE}Test 4: Script Files${NC}"
    test_file_exists "/usr/local/bin/vpn/menu.sh" "Main menu script"
    test_file_exists "/usr/local/bin/vpn/utils.sh" "Utility functions"
    test_file_exists "/usr/local/bin/vpn/ssh.sh" "SSH account script"
    test_file_exists "/usr/local/bin/vpn/vless.sh" "VLESS account script"
    test_file_exists "/usr/local/bin/vpn/vmess.sh" "VMess account script"
    test_file_exists "/usr/local/bin/vpn/trojan.sh" "Trojan account script"
    test_file_exists "/usr/local/bin/vpn/domain.sh" "Domain change script"
    test_file_exists "/usr/local/bin/vpn/banner.sh" "Banner change script"
    test_file_exists "/usr/local/bin/vpn/cekport.sh" "Port check script"
    echo ""
    
    # Test 5: Check file permissions
    echo -e "${BLUE}Test 5: File Permissions${NC}"
    if [[ -x "/usr/local/bin/vpn/menu.sh" ]]; then
        echo -e "${GREEN}✓ PASS: Menu script is executable${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: Menu script is not executable${NC}"
        ((TESTS_FAILED++))
    fi
    
    for script in ssh.sh vless.sh vmess.sh trojan.sh domain.sh banner.sh cekport.sh; do
        if [[ -x "/usr/local/bin/vpn/$script" ]]; then
            echo -e "${GREEN}✓ PASS: $script is executable${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗ FAIL: $script is not executable${NC}"
            ((TESTS_FAILED++))
        fi
    done
    echo ""
    
    # Test 6: Check required commands
    echo -e "${BLUE}Test 6: Required Commands${NC}"
    test_command_exists "curl" "curl command"
    test_command_exists "wget" "wget command"
    test_command_exists "netstat" "netstat command"
    test_command_exists "systemctl" "systemctl command"
    echo ""
    
    # Test 7: Check services
    echo -e "${BLUE}Test 7: Service Status${NC}"
    test_service_status "nginx" "Nginx web server"
    test_service_status "dropbear" "Dropbear SSH server"
    echo ""
    
    # Test 8: Check ports
    echo -e "${BLUE}Test 8: Port Status${NC}"
    test_port_open "22" "SSH port (22)"
    test_port_open "80" "HTTP port (80)"
    echo ""
    
    # Test 9: Check configuration files
    echo -e "${BLUE}Test 9: Configuration Files${NC}"
    test_file_exists "/etc/xray/domain" "Domain configuration"
    test_file_exists "/etc/issue.net" "Banner configuration"
    echo ""
    
    # Test 10: Check alias
    echo -e "${BLUE}Test 10: Alias Configuration${NC}"
    if alias | grep -q "vpn="; then
        echo -e "${GREEN}✓ PASS: VPN alias is configured${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: VPN alias is not configured${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
    
    # Test 11: Check web interface
    echo -e "${BLUE}Test 11: Web Interface${NC}"
    test_file_exists "/home/vps/public_html/index.html" "Web interface index"
    echo ""
    
    # Test 12: Check nginx configuration
    echo -e "${BLUE}Test 12: Nginx Configuration${NC}"
    if nginx -t > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS: Nginx configuration is valid${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: Nginx configuration is invalid${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
    
    # Test 13: Check system resources
    echo -e "${BLUE}Test 13: System Resources${NC}"
    local ram=$(free -m | awk '/^Mem:/ {print $2}')
    if [[ $ram -ge 512 ]]; then
        echo -e "${GREEN}✓ PASS: Sufficient RAM (${ram}MB)${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: Insufficient RAM (${ram}MB)${NC}"
        ((TESTS_FAILED++))
    fi
    
    local disk=$(df / | awk 'NR==2 {print $4}')
    if [[ $disk -ge 10485760 ]]; then  # 10GB in KB
        echo -e "${GREEN}✓ PASS: Sufficient disk space${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: Insufficient disk space${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
    
    # Test 14: Check network connectivity
    echo -e "${BLUE}Test 14: Network Connectivity${NC}"
    if curl -s --connect-timeout 5 https://www.google.com > /dev/null; then
        echo -e "${GREEN}✓ PASS: Internet connectivity${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: No internet connectivity${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
    
    # Test 15: Check script functionality
    echo -e "${BLUE}Test 15: Script Functionality${NC}"
    if source /usr/local/bin/vpn/utils.sh > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS: Utils script loads successfully${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL: Utils script fails to load${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
    
    # Summary
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}                        TEST SUMMARY                           ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo -e "${BLUE}Total Tests: $((TESTS_PASSED + TESTS_FAILED))${NC}"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! Installation is successful.${NC}"
        exit 0
    else
        echo -e "${RED}⚠️  Some tests failed. Please check the installation.${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi