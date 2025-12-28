#!/bin/bash
# Test Emacs and EXWM specific functionality
# This can be run standalone or as part of the test suite

set -e

echo "=== Emacs and EXWM Specific Tests ==="

# Test 1: Check Emacs version
echo "1. Testing Emacs version..."
emacs --version | head -n 1

# Test 2: Test Emacs batch mode
echo "2. Testing Emacs batch mode..."
emacs --batch --eval '(message "Emacs batch mode works!")'

# Test 3: Check for EXWM package
echo "3. Checking for EXWM package..."
emacs --batch --eval '(progn (require '"'"'exwm) (message "EXWM is available"))'

# Test 4: Check for use-package
echo "4. Checking for use-package..."
emacs --batch --eval '(progn (require '"'"'use-package) (message "use-package is available"))'

# Test 5: Check for ivy
echo "5. Checking for ivy..."
emacs --batch --eval '(progn (require '"'"'ivy) (message "ivy is available"))'

# Test 6: Check for magit
echo "6. Checking for magit..."
emacs --batch --eval '(progn (require '"'"'magit) (message "magit is available"))'

# Test 7: Check for which-key
echo "7. Checking for which-key..."
emacs --batch --eval '(progn (require '"'"'which-key) (message "which-key is available"))'

# Test 8: Test configuration file
echo "8. Testing configuration file..."
if [ -f /root/.emacs.d/init.el ]; then
    echo "Configuration file exists"
    emacs --batch -f package-initialize --eval '(load-file "/root/.emacs.d/init.el")'
    echo "Configuration file is valid"
else
    echo "ERROR: Configuration file not found!"
    exit 1
fi

# Test 9: Check EXWM configuration
echo "9. Checking EXWM configuration..."
emacs --batch --eval '(progn (require '"'"'exwm) (message "EXWM keybindings: %s" exwm-input-global-keys))'

# Test 10: Test package downloads (if network is available)
echo "10. Testing package manager..."
emacs --batch --eval '(progn (package-refresh-contents) (message "Package refresh successful"))'

echo "=== All Emacs/EXWM tests passed! ==="
