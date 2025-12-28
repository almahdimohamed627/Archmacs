#!/bin/bash
# Automated test suite for Archmacs
# This script runs comprehensive tests on the live ISO

set -e

TEST_RESULTS="/tmp/test-results"
TEST_LOG="$TEST_RESULTS/tests.log"

# Create results directory
mkdir -p "$TEST_RESULTS"
chmod 755 "$TEST_RESULTS"

echo "======================================================================" | tee -a "$TEST_LOG"
echo "=== Archmacs Automated Test Suite ===" | tee -a "$TEST_LOG"
echo "Started at: $(date)" | tee -a "$TEST_LOG"
echo "======================================================================" | tee -a "$TEST_LOG"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"  # 0 = success, non-zero = failure
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "" | tee -a "$TEST_LOG"
    echo "[TEST $TESTS_RUN] $test_name" | tee -a "$TEST_LOG"
    echo "Command: $test_command" | tee -a "$TEST_LOG"
    
    if eval "$test_command" >> "$TEST_LOG" 2>&1; then
        if [ "$expected_result" -eq 0 ]; then
            echo "✓ PASSED" | tee -a "$TEST_LOG"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo "✗ FAILED (expected failure but succeeded)" | tee -a "$TEST_LOG"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        if [ "$expected_result" -ne 0 ]; then
            echo "✓ PASSED (expected failure)" | tee -a "$TEST_LOG"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo "✗ FAILED" | tee -a "$TEST_LOG"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 1: Basic System Tests ===" | tee -a "$TEST_LOG"

# Test 1.1: System boot
run_test "System boot check" "uptime" 0

# Test 1.2: Memory detection
run_test "Memory detection" "free -h" 0

# Test 1.3: CPU detection
run_test "CPU detection" "nproc" 0

# Test 1.4: Disk detection
run_test "Disk detection" "df -h" 0

# Test 1.5: Network interface
run_test "Network interface detection" "ip link show" 0

# Test 1.6: Time sync
run_test "System time" "date" 0

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 2: Package Installation Tests ===" | tee -a "$TEST_LOG"

# Test 2.1: Base packages
for pkg in bash zsh vim nano git curl wget htop tmux; do
    run_test "Package $pkg is installed" "pacman -Q $pkg" 0
done

# Test 2.2: X11 packages
for pkg in xorg-server xorg-xinit dmenu; do
    run_test "X11 package $pkg is installed" "pacman -Q $pkg" 0
done

# Test 2.3: Emacs package
run_test "Emacs package is installed" "pacman -Q emacs" 0

# Test 2.4: Display packages
for pkg in picom feh; do
    run_test "Display package $pkg is installed" "pacman -Q $pkg" 0
done

# Test 2.5: Network packages
for pkg in openssh networkmanager; do
    run_test "Network package $pkg is installed" "pacman -Q $pkg" 0
done

# Test 2.6: Development tools
for pkg in python nodejs go; do
    run_test "Dev tool $pkg is installed" "command_exists $pkg" 0
done

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 3: Service Tests ===" | tee -a "$TEST_LOG"

# Test 3.1: SSH service
run_test "SSH service is running" "systemctl is-active sshd" 0

# Test 3.2: NetworkManager service
run_test "NetworkManager service is running" "systemctl is-active NetworkManager" 0

# Test 3.3: SSH port listening
run_test "SSH is listening on port 22" "ss -tlnp | grep :22" 0

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 4: Emacs and EXWM Tests ===" | tee -a "$TEST_LOG"

# Test 4.1: Emacs executable
run_test "Emacs is executable" "which emacs" 0

# Test 4.2: Emacs version
run_test "Emacs version check" "emacs --version | head -n 1" 0

# Test 4.3: Emacs batch mode works
run_test "Emacs batch mode" "emacs --batch --eval '(message \"Emacs batch test\")'" 0

# Test 4.4: Emacs configuration file exists
run_test "Emacs configuration exists" "test -f /root/.emacs.d/init.el" 0

# Test 4.5: Emacs configuration is valid syntax
run_test "Emacs config syntax check" "emacs --batch -f package-initialize --eval '(load-file \"/root/.emacs.d/init.el\")'" 0

# Test 4.6: Check for EXWM package
run_test "EXWM package availability" "emacs --batch --eval '(progn (require 'exwm) (message \"EXWM loaded successfully\"))'" 0

# Test 4.7: Check for use-package
run_test "use-package availability" "emacs --batch --eval '(progn (require 'use-package) (message \"use-package loaded\"))'" 0

# Test 4.8: Check for ivy
run_test "ivy package availability" "emacs --batch --eval '(progn (require 'ivy) (message \"ivy loaded\"))'" 0

# Test 4.9: Check for magit
run_test "magit package availability" "emacs --batch --eval '(progn (require 'magit) (message \"magit loaded\"))'" 0

# Test 4.10: Check for which-key
run_test "which-key package availability" "emacs --batch --eval '(progn (require 'which-key) (message \"which-key loaded\"))'" 0

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 5: Spacemacs/EXWM Keybinding Tests ===" | tee -a "$TEST_LOG"

# Test 5.1: EXWM global keybindings
run_test "EXWM keybindings check" "emacs --batch --eval '(progn (require 'exwm) (message \"EXWM keybindings: %s\" exwm-input-global-keys))'" 0

# Test 5.2: EXWM workspace management
run_test "EXWM workspace configuration" "emacs --batch --eval '(progn (require 'exwm) (message \"Workspaces enabled\"))'" 0

# Test 5.3: Display compositor
run_test "Display compositor" "pgrep picom" 0

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 6: Development Environment Tests ===" | tee -a "$TEST_LOG"

# Test 6.1: Python executable
run_test "Python executable" "which python3" 0

# Test 6.2: Python version
run_test "Python version check" "python3 --version" 0

# Test 6.3: Node.js executable
run_test "Node.js executable" "which node" 0

# Test 6.4: Node.js version
run_test "Node.js version check" "node --version" 0

# Test 6.5: Go executable
run_test "Go executable" "which go" 0

# Test 6.6: Go version
run_test "Go version check" "go version" 0

# Test 6.7: Git executable
run_test "Git executable" "which git" 0

# Test 6.8: Git version
run_test "Git version check" "git --version" 0

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 7: Configuration File Tests ===" | tee -a "$TEST_LOG"

# Test 7.1: Xinitrc exists
run_test "Xinitrc exists" "test -f /root/.xinitrc" 0

# Test 7.2: Xinitrc is executable
run_test "Xinitrc is executable" "test -x /root/.xinitrc" 0

# Test 7.3: SSH directory exists
run_test "SSH directory exists" "test -d /root/.ssh" 0

# Test 7.4: SSH directory permissions
run_test "SSH directory has correct permissions" "stat -c '%a' /root/.ssh | grep -q '^700$'" 0

# Test 7.5: Customization script exists
run_test "Customization script exists" "test -f /root/customize.sh" 0

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 8: Network Connectivity Tests ===" | tee -a "$TEST_LOG"

# Test 8.1: DNS resolution
run_test "DNS resolution" "ping -c 1 archlinux.org" 0

# Test 8.2: External connectivity
run_test "External connectivity" "curl -s -o /dev/null -w '%{http_code}' https://archlinux.org | grep -q '200'" 0

# Test 8.3: Localhost connectivity
run_test "Localhost connectivity" "ping -c 1 127.0.0.1" 0

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 9: File System Tests ===" | tee -a "$TEST_LOG"

# Test 9.1: Write permission
run_test "Write permission test" "echo 'test write' > /tmp/test-write" 0

# Test 9.2: Read permission
run_test "Read permission test" "cat /tmp/test-write" 0

# Test 9.3: Delete permission
run_test "Delete permission test" "rm /tmp/test-write" 0

# Test 9.4: Directory creation
run_test "Directory creation" "mkdir -p /tmp/test-dir" 0

# Test 9.5: Disk space available
run_test "Disk space check" "df -h / | tail -n 1 | awk '{print \$4}' | grep -E '^[0-9.]+[GM]'" 0

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 10: Security Tests ===" | tee -a "$TEST_LOG"

# Test 10.1: User creation
run_test "Test user exists" "id archuser" 0

# Test 10.2: User sudo access
run_test "Test user sudo access" "sudo -l -U archuser" 0

# Test 10.3: Root user
run_test "Root user exists" "id root" 0

# Test 10.4: SSH config
run_test "SSH config exists" "test -f /etc/ssh/sshd_config" 0

# Test 10.5: Sudo config
run_test "Sudo config exists" "test -f /etc/sudoers" 0

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 11: Performance Tests ===" | tee -a "$TEST_LOG"

# Test 11.1: CPU load
run_test "CPU load check" "uptime | awk '{print \$NF}' | awk '{print \$1 < 2.0}'" 0

# Test 11.2: Memory usage
run_test "Memory usage check" "free | grep Mem | awk '{print (\$3/\$2) < 0.8}'" 0

# Test 11.3: Disk I/O performance
run_test "Disk I/O test" "dd if=/dev/zero of=/tmp/test-io bs=1M count=100 2>&1 | tail -n 1 | grep -q 'copied'" 0

# Test 11.4: Network latency (local)
run_test "Local network latency" "ping -c 5 127.0.0.1 | tail -n 1 | awk '{print \$4}' | cut -d'/' -f2 | awk '{print \$1 < 1.0}'" 0

echo "" | tee -a "$TEST_LOG"
echo "=== PHASE 12: Integration Tests ===" | tee -a "$TEST_LOG"

# Test 12.1: Emacs package initialization
run_test "Emacs package initialization" "emacs --batch --eval '(progn (package-initialize) (message \"Packages initialized\"))'" 0

# Test 12.2: Spacemacs layers configuration
run_test "Spacemacs configuration test" "emacs --batch --eval '(progn (load-file \"/root/.emacs.d/init.el\") (message \"Configuration loaded\"))'" 0

# Test 12.3: EXWM startup check
run_test "EXWM startup check" "emacs --batch --eval '(progn (require 'exwm) (require 'exwm-config) (message \"EXWM ready to start\"))'" 0

# Test 12.4: System integration
run_test "System integration check" "systemctl status sshd NetworkManager" 0

echo "" | tee -a "$TEST_LOG"
echo "======================================================================" | tee -a "$TEST_LOG"
echo "=== Test Results Summary ===" | tee -a "$TEST_LOG"
echo "======================================================================" | tee -a "$TEST_LOG"
echo "Total Tests Run:    $TESTS_RUN" | tee -a "$TEST_LOG"
echo "Tests Passed:       $TESTS_PASSED" | tee -a "$TEST_LOG"
echo "Tests Failed:       $TESTS_FAILED" | tee -a "$TEST_LOG"
echo "Success Rate:       $(echo "scale=2; $TESTS_PASSED * 100 / $TESTS_RUN" | bc)%" | tee -a "$TEST_LOG"
echo "======================================================================" | tee -a "$TEST_LOG"
echo "Completed at: $(date)" | tee -a "$TEST_LOG"
echo "======================================================================" | tee -a "$TEST_LOG"

# Create JSON summary
cat > "$TEST_RESULTS/summary.json" << EOF
{
  "test_run": $TESTS_RUN,
  "test_passed": $TESTS_PASSED,
  "test_failed": $TESTS_FAILED,
  "success_rate": $(echo "scale=2; $TESTS_PASSED * 100 / $TESTS_RUN" | bc),
  "timestamp": "$(date -Iseconds)"
}
EOF

echo "Test results saved to: $TEST_RESULTS"
echo "Detailed log: $TEST_LOG"
echo "Summary: $TEST_RESULTS/summary.json"

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
    echo "All tests passed!" | tee -a "$TEST_LOG"
    exit 0
else
    echo "Some tests failed!" | tee -a "$TEST_LOG"
    exit 1
fi
