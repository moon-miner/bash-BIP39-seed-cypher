# SCypher v3.0 - Product Requirements Document (PRD)
## Product Requirements Document for Security Refactoring

---

## 📋 DOCUMENT INFORMATION

| Field | Value |
|-------|-------|
| **PRD Version** | 1.0 |
| **Creation Date** | May 29, 2025 |
| **Product** | SCypher v3.0 - XOR-based BIP39 Seed Cipher |
| **Current Version** | v2.0-ErgoHack-X |
| **Target Version** | v3.0-Security-Enhanced |
| **Release Type** | Security Refactoring + Enhancement |

---

## 🎯 PROJECT OBJECTIVES

### Main Objective
Create a completely secure version of SCypher that eliminates all security risks identified in the audit, maintaining 100% of existing functionality and improving system robustness.

### Specific Objectives
1. **Security**: Eliminate all critical and high risks identified
2. **Compatibility**: Maintain 100% functional compatibility with v2.0
3. **Robustness**: Improve error handling and edge cases
4. **Maintainability**: Simplify architecture without losing functionality
5. **Usability**: Preserve all existing user experience

---

## 🔒 CRITICAL PROBLEMS TO SOLVE

### 🚨 PROBLEM 1: ROOT PRIVILEGE ELIMINATION

#### **Problem Description**
```bash
# CURRENT PROBLEMATIC CODE
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with bash"
    echo "Please run as: sudo bash $0"
    exit 1
fi
```

#### **Solution Requirements**
- **REQ-SEC-001**: COMPLETELY ELIMINATE any root privilege verification
- **REQ-SEC-002**: IMPLEMENT alternative protections that don't require elevated privileges
- **REQ-SEC-003**: MAINTAIN security functionalities through user-space methods

#### **Implementation Approaches**

##### **Approach A: Complete Elimination (RECOMMENDED)**
```bash
# SIMPLE SOLUTION - Remove verification
# DO NOT perform privilege verification
# Document that no special privileges are required
```

**Advantages**: Maximum security, simplicity
**Disadvantages**: None
**Complexity**: Low

##### **Approach B: Optional Privileges**
```bash
# ALTERNATIVE SOLUTION - Optional privileges
if [ "$(id -u)" -eq 0 ]; then
    echo "Running with enhanced security features (root mode)"
    ENHANCED_SECURITY=1
else
    echo "Running in standard user mode"
    ENHANCED_SECURITY=0
fi
```

**Advantages**: Flexibility
**Disadvantages**: Unnecessary additional complexity
**Complexity**: Medium

#### **Reference Documentation**
- [Linux Capabilities - man 7 capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [Principle of Least Privilege - OWASP](https://owasp.org/www-community/vulnerabilities/Privilege_chaining)

---

### 🚨 PROBLEM 2: INSECURE INPUT VALIDATION

#### **Problem Description**
```bash
# CURRENT PROBLEMATIC CODE
validate_input() {
    local input="$1"
    if [[ "$input" =~ [^a-zA-Z0-9\ ] ]]; then
        echo "Error: Input contains invalid characters"
        return 1
    fi
    return 0
}
```

#### **Solution Requirements**
- **REQ-VAL-001**: IMPLEMENT robust validation against command injection
- **REQ-VAL-002**: VALIDATE strict maximum length (< 1000 characters)
- **REQ-VAL-003**: SANITIZE input to prevent path traversal
- **REQ-VAL-004**: MAINTAIN compatibility with valid BIP39 characters

#### **Implementation Approaches**

##### **Approach A: Strict Whitelist (RECOMMENDED)**
```bash
validate_input() {
    local input="$1"
    local max_length=1000
    
    # Verify length
    if [[ ${#input} -gt $max_length ]]; then
        echo "Error: Input too long (max: $max_length characters)" >&2
        return 1
    fi
    
    # Only allow specific characters (whitelist)
    if [[ ! "$input" =~ ^[a-zA-Z0-9[:space:]]+$ ]]; then
        echo "Error: Invalid characters detected" >&2
        return 1
    fi
    
    # Verify not empty after trim
    local trimmed="${input// /}"
    if [[ -z "$trimmed" ]]; then
        echo "Error: Empty input" >&2
        return 1
    fi
    
    return 0
}
```

##### **Approach B: Sanitization + Validation**
```bash
sanitize_input() {
    local input="$1"
    # Remove dangerous characters
    local sanitized="${input//[^a-zA-Z0-9 ]/}"
    # Normalize spaces
    sanitized=$(echo "$sanitized" | tr -s ' ')
    # Trim
    sanitized="${sanitized# }"
    sanitized="${sanitized% }"
    echo "$sanitized"
}

validate_input() {
    local input="$1"
    local sanitized
    sanitized=$(sanitize_input "$input")
    
    if [[ ${#sanitized} -eq 0 ]]; then
        echo "Error: No valid input after sanitization" >&2
        return 1
    fi
    
    if [[ ${#sanitized} -gt 1000 ]]; then
        echo "Error: Input too long after sanitization" >&2
        return 1
    fi
    
    echo "$sanitized"
    return 0
}
```

##### **Approach C: Context-based Validation**
```bash
validate_seed_phrase() {
    local input="$1"
    local -a words
    read -ra words <<< "$input"
    
    # Validate word count first
    local word_count=${#words[@]}
    local valid_counts=(12 15 18 21 24)
    local is_valid_count=0
    
    for count in "${valid_counts[@]}"; do
        if [[ $word_count -eq $count ]]; then
            is_valid_count=1
            break
        fi
    done
    
    if [[ $is_valid_count -eq 0 ]]; then
        echo "Error: Invalid word count: $word_count" >&2
        return 1
    fi
    
    # Validate each word individually
    for word in "${words[@]}"; do
        if [[ ! "$word" =~ ^[a-z]+$ ]] || [[ ${#word} -lt 3 ]] || [[ ${#word} -gt 12 ]]; then
            echo "Error: Invalid word format: '$word'" >&2
            return 1
        fi
    done
    
    return 0
}

validate_file_path() {
    local filepath="$1"
    
    # Prevent path traversal
    if [[ "$filepath" == *".."* ]] || [[ "$filepath" == *"/"* && ! "$filepath" =~ ^[./][^/]*$ ]]; then
        echo "Error: Invalid file path" >&2
        return 1
    fi
    
    # Validate extension if necessary
    if [[ "$filepath" != *.txt ]] && [[ "$filepath" != *. ]]; then
        echo "Warning: Recommended to use .txt extension" >&2
    fi
    
    return 0
}
```

#### **Reference Documentation**
- [Bash Parameter Expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)
- [Regular Expressions in Bash](https://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html)
- [Input Validation - OWASP Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)

---

### 🚨 PROBLEM 3: INSECURE FILE HANDLING

#### **Problem Description**
```bash
# CURRENT PROBLEMATIC CODE
read_words_from_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found" >&2
        return 1
    fi
    local content
    content=$(tr '\n' ' ' < "$file" 2>/dev/null)
    echo "$content"
}
```

#### **Solution Requirements**
- **REQ-FILE-001**: PREVENT path traversal attacks
- **REQ-FILE-002**: VALIDATE file permissions before access
- **REQ-FILE-003**: LIMIT maximum file size
- **REQ-FILE-004**: SANITIZE output filenames

#### **Implementation Approaches**

##### **Approach A: Complete Path Validation (RECOMMENDED)**
```bash
validate_file_path() {
    local filepath="$1"
    local resolved_path
    
    # Safely resolve absolute path
    if ! resolved_path=$(realpath -s "$filepath" 2>/dev/null); then
        echo "Error: Invalid file path" >&2
        return 1
    fi
    
    # Verify it's in allowed directory (CWD or subdirectories)
    local current_dir
    current_dir=$(pwd)
    
    # Verify resolved path starts with current directory
    if [[ ! "$resolved_path" == "$current_dir"* ]]; then
        echo "Error: File access outside current directory not allowed" >&2
        return 1
    fi
    
    # Verify dangerous characters
    if [[ "$filepath" =~ (\.\./|\.\.\\|[<>|&;`$()]) ]]; then
        echo "Error: Dangerous characters in file path" >&2
        return 1
    fi
    
    echo "$resolved_path"
    return 0
}

read_words_from_file() {
    local file="$1"
    local max_size_kb=100
    local validated_path
    
    # Validate path
    if ! validated_path=$(validate_file_path "$file"); then
        return 1
    fi
    
    # Verify existence
    if [[ ! -f "$validated_path" ]]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    
    # Verify read permissions
    if [[ ! -r "$validated_path" ]]; then
        echo "Error: Cannot read file: $file" >&2
        return 1
    fi
    
    # Verify size
    local file_size
    file_size=$(stat -f%z "$validated_path" 2>/dev/null || stat -c%s "$validated_path" 2>/dev/null)
    if [[ $file_size -gt $((max_size_kb * 1024)) ]]; then
        echo "Error: File too large (max: ${max_size_kb}KB)" >&2
        return 1
    fi
    
    # Read file safely
    local content
    if ! content=$(cat "$validated_path" 2>/dev/null); then
        echo "Error: Failed to read file" >&2
        return 1
    fi
    
    # Normalize spaces and line breaks
    content=$(echo "$content" | tr '\n\r\t' ' ' | tr -s ' ')
    content="${content# }"
    content="${content% }"
    
    echo "$content"
    return 0
}
```

##### **Approach B: Chroot-like Restriction**
```bash
setup_safe_file_access() {
    # Define allowed base directory
    SAFE_DIR=$(pwd)
    readonly SAFE_DIR
    export SAFE_DIR
}

validate_file_in_safe_dir() {
    local filepath="$1"
    local full_path
    
    # Build full path
    if [[ "$filepath" == /* ]]; then
        echo "Error: Absolute paths not allowed" >&2
        return 1
    fi
    
    full_path="${SAFE_DIR}/${filepath}"
    
    # Resolve symlinks and verify
    if ! resolved=$(realpath -e "$full_path" 2>/dev/null); then
        echo "Error: Cannot resolve file path" >&2
        return 1
    fi
    
    # Verify it remains within safe directory
    if [[ ! "$resolved" == "$SAFE_DIR"* ]]; then
        echo "Error: Access outside safe directory denied" >&2
        return 1
    fi
    
    echo "$resolved"
    return 0
}
```

##### **Approach C: Extension Whitelist**
```bash
validate_file_extension() {
    local filepath="$1"
    local allowed_extensions=("txt" "seed" "bip39")
    local extension="${filepath##*.}"
    
    # Convert to lowercase
    extension="${extension,,}"
    
    # Verify if in whitelist
    for allowed in "${allowed_extensions[@]}"; do
        if [[ "$extension" == "$allowed" ]]; then
            return 0
        fi
    done
    
    echo "Error: File extension '$extension' not allowed" >&2
    echo "Allowed extensions: ${allowed_extensions[*]}" >&2
    return 1
}
```

#### **Reference Documentation**
- [Path Traversal Prevention - OWASP](https://owasp.org/www-community/attacks/Path_Traversal)
- [Bash realpath command](https://www.gnu.org/software/coreutils/manual/html_node/realpath-invocation.html)
- [File System Security - Linux Documentation](https://www.kernel.org/doc/html/latest/admin-guide/LSM/index.html)

---

### 🚨 PROBLEM 4: INSECURE MEMORY CLEANUP

#### **Problem Description**
```bash
# CURRENT PROBLEMATIC CODE
cleanup() {
    # Extremely complex function with 200+ lines
    # Manual cleanup of individual variables
    # Risk of not cleaning new variables
    # Unnecessary complexity
}
```

#### **Solution Requirements**
- **REQ-MEM-001**: SIMPLIFY cleanup function while maintaining effectiveness
- **REQ-MEM-002**: IMPLEMENT automatic cleanup of sensitive variables
- **REQ-MEM-003**: ENSURE cleanup in all exit paths
- **REQ-MEM-004**: MINIMIZE time window with sensitive data in memory

#### **Implementation Approaches**

##### **Approach A: Pattern-based Automatic Cleanup (RECOMMENDED)**
```bash
# Sensitive variables with specific prefix
declare SENSITIVE_password=""
declare SENSITIVE_keystream=""
declare SENSITIVE_seed_bits=""
declare SENSITIVE_result=""

cleanup_sensitive_data() {
    local var_name
    
    # Find all variables with SENSITIVE_ prefix
    while IFS= read -r var_name; do
        if [[ "$var_name" == SENSITIVE_* ]]; then
            # Overwrite with random data
            local random_data
            random_data=$(openssl rand -hex 32 2>/dev/null || echo "$(date +%s)_random_cleanup")
            printf -v "$var_name" "%s" "$random_data"
            unset "$var_name"
        fi
    done < <(compgen -v)
    
    # Clean sensitive associative arrays
    if declare -p word_lookup >/dev/null 2>&1; then
        for key in "${!word_lookup[@]}"; do
            word_lookup[$key]="$(openssl rand -hex 16)"
            unset 'word_lookup[$key]'
        done
        unset word_lookup
    fi
    
    # Clean history
    history -c 2>/dev/null || true
    
    # Force garbage collection if available
    if declare -F bash_gc >/dev/null; then
        bash_gc
    fi
}

# Simplified main cleanup function
cleanup() {
    cleanup_sensitive_data
    
    # Restore terminal
    stty echo 2>/dev/null || true
    
    # Restore umask
    umask "${ORIGINAL_UMASK:-022}"
}
```

##### **Approach B: Scoped Variables**
```bash
# Use subshells to limit variable scope
process_sensitive_data() {
    (
        # Local variables are automatically cleaned when exiting subshell
        local password="$1"
        local seed_phrase="$2"
        local iterations="$3"
        
        # All cryptographic processing here
        local result
        result=$(perform_xor_encryption "$seed_phrase" "$password" "$iterations")
        
        # Only return the result
        echo "$result"
        
        # Variables automatically cleaned
    )
}

main() {
    local password seed_phrase iterations result
    
    # Get inputs
    password=$(read_secure_password)
    seed_phrase=$(read_seed_phrase)
    iterations=$(read_iterations)
    
    # Process in isolated subshell
    result=$(process_sensitive_data "$password" "$seed_phrase" "$iterations")
    
    # Clean inputs immediately
    password="$(openssl rand -hex 32)"
    seed_phrase="$(openssl rand -hex 64)"
    iterations=0
    unset password seed_phrase iterations
    
    # Use result
    handle_result "$result"
    
    # Clean result
    result="$(openssl rand -hex 64)"
    unset result
}
```

##### **Approach C: Trap-based Cleanup**
```bash
# Global list of sensitive variables
declare -a SENSITIVE_VARS=()

register_sensitive_var() {
    local var_name="$1"
    SENSITIVE_VARS+=("$var_name")
}

cleanup_registered_vars() {
    for var_name in "${SENSITIVE_VARS[@]}"; do
        if [[ -v "$var_name" ]]; then
            # Overwrite with noise
            printf -v "$var_name" "%s" "$(openssl rand -hex 32 2>/dev/null || date +%s)"
            unset "$var_name"
        fi
    done
    SENSITIVE_VARS=()
}

# Automatic cleanup setup
setup_automatic_cleanup() {
    trap 'cleanup_registered_vars' EXIT HUP INT TERM
}

# Usage
main() {
    setup_automatic_cleanup
    
    local password
    password=$(read_secure_password)
    register_sensitive_var "password"
    
    # ... rest of logic
}
```

#### **Reference Documentation**
- [Bash Subshells](https://www.gnu.org/software/bash/manual/html_node/Command-Grouping.html)
- [Memory Management Best Practices](https://owasp.org/www-community/vulnerabilities/Insecure_Storage)
- [Secure Coding in Bash](https://mywiki.wooledge.org/BashFAQ/050)

---

### 🚨 PROBLEM 5: INSECURE COMMAND EXECUTION

#### **Problem Description**
```bash
# CURRENT PROBLEMATIC CODE
available_memory=$(free -m | awk '/^Mem:/{print $7}')
hash_output=$(echo -e -n "$binary_data" | openssl dgst -sha256)
```

#### **Solution Requirements**
- **REQ-CMD-001**: VALIDATE output of all external commands
- **REQ-CMD-002**: IMPLEMENT timeouts for critical operations
- **REQ-CMD-003**: HANDLE command failures gracefully
- **REQ-CMD-004**: AVOID command injection in parameters

#### **Implementation Approaches**

##### **Approach A: Wrapper Functions with Validation (RECOMMENDED)**
```bash
safe_openssl_dgst() {
    local algorithm="$1"
    local input="$2"
    local timeout_seconds=30
    local temp_file
    
    # Validate algorithm
    case "$algorithm" in
        "sha256"|"shake256") ;;
        *) echo "Error: Unsupported hash algorithm" >&2; return 1 ;;
    esac
    
    # Create secure temporary file
    temp_file=$(mktemp) || {
        echo "Error: Cannot create temporary file" >&2
        return 1
    }
    
    # Automatic cleanup of temporary file
    trap "rm -f '$temp_file'" RETURN
    
    # Write input safely
    printf '%s' "$input" > "$temp_file" || {
        echo "Error: Cannot write to temporary file" >&2
        return 1
    }
    
    # Execute OpenSSL with timeout
    local result
    if ! result=$(timeout "$timeout_seconds" openssl dgst -"$algorithm" < "$temp_file" 2>/dev/null); then
        echo "Error: OpenSSL operation failed or timed out" >&2
        return 1
    fi
    
    # Validate output format
    if [[ ! "$result" =~ ^[A-Za-z0-9()=\ ]+$ ]]; then
        echo "Error: Invalid OpenSSL output format" >&2
        return 1
    fi
    
    echo "$result"
    return 0
}

safe_openssl_shake256() {
    local input="$1"
    local xoflen="$2"
    local timeout_seconds=30
    
    # Validate parameters
    if [[ ! "$xoflen" =~ ^[0-9]+$ ]] || [[ $xoflen -lt 1 ]] || [[ $xoflen -gt 1024 ]]; then
        echo "Error: Invalid xoflen parameter" >&2
        return 1
    fi
    
    local temp_file
    temp_file=$(mktemp) || {
        echo "Error: Cannot create temporary file" >&2
        return 1
    }
    
    trap "rm -f '$temp_file'" RETURN
    
    printf '%s' "$input" > "$temp_file" || {
        echo "Error: Cannot write input to temporary file" >&2
        return 1
    }
    
    local result
    if ! result=$(timeout "$timeout_seconds" openssl dgst -shake256 -xoflen "$xoflen" < "$temp_file" 2>/dev/null); then
        echo "Error: SHAKE-256 operation failed" >&2
        return 1
    fi
    
    # Extract only hexadecimal part
    local hex_part="${result##*= }"
    
    # Validate it's valid hexadecimal
    if [[ ! "$hex_part" =~ ^[0-9a-fA-F]+$ ]]; then
        echo "Error: Invalid hexadecimal output" >&2
        return 1
    fi
    
    # Validate expected length
    local expected_length=$((xoflen * 2))
    if [[ ${#hex_part} -ne $expected_length ]]; then
        echo "Error: Unexpected output length" >&2
        return 1
    fi
    
    echo "$hex_part"
    return 0
}
```

##### **Approach B: Command Validation Framework**
```bash
declare -A ALLOWED_COMMANDS=(
    ["openssl"]="^/usr/bin/openssl$|^/usr/local/bin/openssl$"
    ["timeout"]="^/usr/bin/timeout$|^/bin/timeout$"
    ["mktemp"]="^/usr/bin/mktemp$|^/bin/mktemp$"
)

validate_command() {
    local cmd="$1"
    local cmd_path
    
    # Find command path
    if ! cmd_path=$(command -v "$cmd" 2>/dev/null); then
        echo "Error: Command not found: $cmd" >&2
        return 1
    fi
    
    # Verify if in whitelist
    if [[ -n "${ALLOWED_COMMANDS[$cmd]:-}" ]]; then
        if [[ "$cmd_path" =~ ${ALLOWED_COMMANDS[$cmd]} ]]; then
            echo "$cmd_path"
            return 0
        fi
    fi
    
    echo "Error: Command not in whitelist: $cmd ($cmd_path)" >&2
    return 1
}

safe_command_exec() {
    local cmd="$1"
    shift
    local args=("$@")
    local cmd_path
    
    # Validate command
    if ! cmd_path=$(validate_command "$cmd"); then
        return 1
    fi
    
    # Execute with full path
    "$cmd_path" "${args[@]}"
}
```

##### **Approach C: Sandboxing with Firejail**
```bash
check_sandboxing_available() {
    if command -v firejail >/dev/null 2>&1; then
        echo "firejail"
        return 0
    elif command -v bwrap >/dev/null 2>&1; then
        echo "bwrap"
        return 0
    else
        echo "none"
        return 1
    fi
}

safe_sandboxed_openssl() {
    local operation="$1"
    local input="$2"
    local sandbox_type
    
    sandbox_type=$(check_sandboxing_available)
    
    case "$sandbox_type" in
        "firejail")
            echo "$input" | firejail --quiet --private --net=none --no-sound openssl dgst "-$operation"
            ;;
        "bwrap")
            echo "$input" | bwrap --ro-bind /usr /usr --ro-bind /lib /lib --proc /proc --dev /dev --unshare-all openssl dgst "-$operation"
            ;;
        "none")
            # Fallback to safe method without sandbox
            safe_openssl_dgst "$operation" "$input"
            ;;
    esac
}
```

#### **Reference Documentation**
- [Bash timeout command](https://www.gnu.org/software/coreutils/manual/html_node/timeout-invocation.html)
- [Command Injection Prevention](https://owasp.org/www-community/attacks/Command_Injection)
- [Firejail Sandboxing](https://firejail.wordpress.com/)

---

### 🚨 PROBLEM 6: FRAGILE CRYPTOGRAPHIC IMPLEMENTATION

#### **Problem Description**
```bash
# CURRENT PROBLEMATIC CODE
derive_keystream() {
    local current_hash="$password"
    for ((i = 1; i <= iterations; i++)); do
        current_hash=$(echo -n "$current_hash" | openssl dgst -shake256 -xoflen "$byte_length" | sed 's/^.*= //')
    done
    # ... fragile manual conversion
}
```

#### **Solution Requirements**
- **REQ-CRYPTO-001**: STRENGTHEN key derivation
- **REQ-CRYPTO-002**: VALIDATE integrity of cryptographic operations
- **REQ-CRYPTO-003**: IMPLEMENT specific error handling for crypto
- **REQ-CRYPTO-004**: OPTIMIZE performance without compromising security

#### **Implementation Approaches**

##### **Approach A: Crypto Library Wrapper (RECOMMENDED)**
```bash
crypto_derive_keystream() {
    local password="$1"
    local bit_length="$2"
    local iterations="$3"
    local byte_length=$(( (bit_length + 7) / 8 ))
    
    # Validate parameters
    if [[ ! "$iterations" =~ ^[0-9]+$ ]] || [[ $iterations -lt 1 ]] || [[ $iterations -gt 1000000 ]]; then
        echo "Error: Invalid iterations parameter" >&2
        return 1
    fi
    
    if [[ $bit_length -lt 1 ]] || [[ $bit_length -gt 10000 ]]; then
        echo "Error: Invalid bit length" >&2
        return 1
    fi
    
    # Initial derivation
    local current_hash="$password"
    local iteration=1
    
    while [[ $iteration -le $iterations ]]; do
        local new_hash
        if ! new_hash=$(safe_openssl_shake256 "$current_hash" "$byte_length"); then
            echo "Error: Key derivation failed at iteration $iteration" >&2
            return 1
        fi
        
        # Validate hash is valid
        if [[ ! "$new_hash" =~ ^[0-9a-fA-F]+$ ]]; then
            echo "Error: Invalid hash format at iteration $iteration" >&2
            return 1
        fi
        
        current_hash="$new_hash"
        ((iteration++))
    done
    
    # Convert hex to binary safely
    local binary=""
    local i=0
    while [[ $i -lt ${#current_hash} ]] && [[ ${#binary} -lt $bit_length ]]; do
        local hex_byte="${current_hash:$i:2}"
        local binary_byte
        
        if ! binary_byte=$(hex_to_binary "$hex_byte"); then
            echo "Error: Hex to binary conversion failed" >&2
            return 1
        fi
        
        binary+="$binary_byte"
        ((i += 2))
    done
    
    # Truncate to exact length
    echo "${binary:0:$bit_length}"
    return 0
}

hex_to_binary() {
    local hex="$1"
    local binary=""
    
    # Validate hex input
    if [[ ! "$hex" =~ ^[0-9a-fA-F]{2}$ ]]; then
        echo "Error: Invalid hex byte: $hex" >&2
        return 1
    fi
    
    # Convert using array lookup (faster and safer)
    local -A hex_to_bin=(
        ["00"]="00000000" ["01"]="00000001" ["02"]="00000010" ["03"]="00000011"
        ["04"]="00000100" ["05"]="00000101" ["06"]="00000110" ["07"]="00000111"
        ["08"]="00001000" ["09"]="00001001" ["0a"]="00001010" ["0b"]="00001011"
        ["0c"]="00001100" ["0d"]="00001101" ["0e"]="00001110" ["0f"]="00001111"
        ["10"]="00010000" ["11"]="00010001" ["12"]="00010010" ["13"]="00010011"
        ["14"]="00010100" ["15"]="00010101" ["16"]="00010110" ["17"]="00010111"
        ["18"]="00011000" ["19"]="00011001" ["1a"]="00011010" ["1b"]="00011011"
        ["1c"]="00011100" ["1d"]="00011101" ["1e"]="00011110" ["1f"]="00011111"
        ["20"]="00100000" ["21"]="00100001" ["22"]="00100010" ["23"]="00100011"
        ["24"]="00100100" ["25"]="00100101" ["26"]="00100110" ["27"]="00100111"
        ["28"]="00101000" ["29"]="00101001" ["2a"]="00101010" ["2b"]="00101011"
        ["2c"]="00101100" ["2d"]="00101101" ["2e"]="00101110" ["2f"]="00101111"
        ["30"]="00110000" ["31"]="00110001" ["32"]="00110010" ["33"]="00110011"
        ["34"]="00110100" ["35"]="00110101" ["36"]="00110110" ["37"]="00110111"
        ["38"]="00111000" ["39"]="00111001" ["3a"]="00111010" ["3b"]="00111011"
        ["3c"]="00111100" ["3d"]="00111101" ["3e"]="00111110" ["3f"]="00111111"
        ["40"]="01000000" ["41"]="01000001" ["42"]="01000010" ["43"]="01000011"
        ["44"]="01000100" ["45"]="01000101" ["46"]="01000110" ["47"]="01000111"
        ["48"]="01001000" ["49"]="01001001" ["4a"]="01001010" ["4b"]="01001011"
        ["4c"]="01001100" ["4d"]="01001101" ["4e"]="01001110" ["4f"]="01001111"
        ["50"]="01010000" ["51"]="01010001" ["52"]="01010010" ["53"]="01010011"
        ["54"]="01010100" ["55"]="01010101" ["56"]="01010110" ["57"]="01010111"
        ["58"]="01011000" ["59"]="01011001" ["5a"]="01011010" ["5b"]="01011011"
        ["5c"]="01011100" ["5d"]="01011101" ["5e"]="01011110" ["5f"]="01011111"
        ["60"]="01100000" ["61"]="01100001" ["62"]="01100010" ["63"]="01100011"
        ["64"]="01100100" ["65"]="01100101" ["66"]="01100110" ["67"]="01100111"
        ["68"]="01101000" ["69"]="01101001" ["6a"]="01101010" ["6b"]="01101011"
        ["6c"]="01101100" ["6d"]="01101101" ["6e"]="01101110" ["6f"]="01101111"
        ["70"]="01110000" ["71"]="01110001" ["72"]="01110010" ["73"]="01110011"
        ["74"]="01110100" ["75"]="01110101" ["76"]="01110110" ["77"]="01110111"
        ["78"]="01111000" ["79"]="01111001" ["7a"]="01111010" ["7b"]="01111011"
        ["7c"]="01111100" ["7d"]="01111101" ["7e"]="01111110" ["7f"]="01111111"
        ["80"]="10000000" ["81"]="10000001" ["82"]="10000010" ["83"]="10000011"
        ["84"]="10000100" ["85"]="10000101" ["86"]="10000110" ["87"]="10000111"
        ["88"]="10001000" ["89"]="10001001" ["8a"]="10001010" ["8b"]="10001011"
        ["8c"]="10001100" ["8d"]="10001101" ["8e"]="10001110" ["8f"]="10001111"
        ["90"]="10010000" ["91"]="10010001" ["92"]="10010010" ["93"]="10010011"
        ["94"]="10010100" ["95"]="10010101" ["96"]="10010110" ["97"]="10010111"
        ["98"]="10011000" ["99"]="10011001" ["9a"]="10011010" ["9b"]="10011011"
        ["9c"]="10011100" ["9d"]="10011101" ["9e"]="10011110" ["9f"]="10011111"
        ["a0"]="10100000" ["a1"]="10100001" ["a2"]="10100010" ["a3"]="10100011"
        ["a4"]="10100100" ["a5"]="10100101" ["a6"]="10100110" ["a7"]="10100111"
        ["a8"]="10101000" ["a9"]="10101001" ["aa"]="10101010" ["ab"]="10101011"
        ["ac"]="10101100" ["ad"]="10101101" ["ae"]="10101110" ["af"]="10101111"
        ["b0"]="10110000" ["b1"]="10110001" ["b2"]="10110010" ["b3"]="10110011"
        ["b4"]="10110100" ["b5"]="10110101" ["b6"]="10110110" ["b7"]="10110111"
        ["b8"]="10111000" ["b9"]="10111001" ["ba"]="10111010" ["bb"]="10111011"
        ["bc"]="10111100" ["bd"]="10111101" ["be"]="10111110" ["bf"]="10111111"
        ["c0"]="11000000" ["c1"]="11000001" ["c2"]="11000010" ["c3"]="11000011"
        ["c4"]="11000100" ["c5"]="11000101" ["c6"]="11000110" ["c7"]="11000111"
        ["c8"]="11001000" ["c9"]="11001001" ["ca"]="11001010" ["cb"]="11001011"
        ["cc"]="11001100" ["cd"]="11001101" ["ce"]="11001110" ["cf"]="11001111"
        ["d0"]="11010000" ["d1"]="11010001" ["d2"]="11010010" ["d3"]="11010011"
        ["d4"]="11010100" ["d5"]="11010101" ["d6"]="11010110" ["d7"]="11010111"
        ["d8"]="11011000" ["d9"]="11011001" ["da"]="11011010" ["db"]="11011011"
        ["dc"]="11011100" ["dd"]="11011101" ["de"]="11011110" ["df"]="11011111"
        ["e0"]="11100000" ["e1"]="11100001" ["e2"]="11100010" ["e3"]="11100011"
        ["e4"]="11100100" ["e5"]="11100101" ["e6"]="11100110" ["e7"]="11100111"
        ["e8"]="11101000" ["e9"]="11101001" ["ea"]="11101010" ["eb"]="11101011"
        ["ec"]="11101100" ["ed"]="11101101" ["ee"]="11101110" ["ef"]="11101111"
        ["f0"]="11110000" ["f1"]="11110001" ["f2"]="11110010" ["f3"]="11110011"
        ["f4"]="11110100" ["f5"]="11110101" ["f6"]="11110110" ["f7"]="11110111"
        ["f8"]="11111000" ["f9"]="11111001" ["fa"]="11111010" ["fb"]="11111011"
        ["fc"]="11111100" ["fd"]="11111101" ["fe"]="11111110" ["ff"]="11111111"
    )
    
    # Convert to lowercase for lookup
    hex="${hex,,}"
    
    # Search in table
    if [[ -n "${hex_to_bin[$hex]:-}" ]]; then
        echo "${hex_to_bin[$hex]}"
        return 0
    else
        echo "Error: Hex byte not found in lookup table: $hex" >&2
        return 1
    fi
}
```

##### **Approach B: Crypto State Validation**
```bash
crypto_state_manager() {
    local -A crypto_state=(
        ["initialized"]=false
        ["last_operation"]=""
        ["error_count"]=0
        ["max_errors"]=3
    )
    
    crypto_init() {
        # Verify OpenSSL availability
        if ! command -v openssl >/dev/null 2>&1; then
            echo "Error: OpenSSL not available" >&2
            return 1
        fi
        
        # Verify SHAKE-256 support
        if ! echo "test" | openssl dgst -shake256 -xoflen 32 >/dev/null 2>&1; then
            echo "Error: SHAKE-256 not supported" >&2
            return 1
        fi
        
        crypto_state["initialized"]=true
        crypto_state["error_count"]=0
        return 0
    }
    
    crypto_check_state() {
        if [[ "${crypto_state[initialized]}" != "true" ]]; then
            echo "Error: Crypto subsystem not initialized" >&2
            return 1
        fi
        
        if [[ ${crypto_state[error_count]} -ge ${crypto_state[max_errors]} ]]; then
            echo "Error: Too many crypto errors, aborting" >&2
            return 1
        fi
        
        return 0
    }
    
    crypto_record_error() {
        ((crypto_state[error_count]++))
        crypto_state["last_operation"]="$1"
    }
    
    crypto_record_success() {
        crypto_state["last_operation"]="$1"
    }
}
```

##### **Approach C: Crypto Operation Retry Logic**
```bash
crypto_with_retry() {
    local operation="$1"
    local max_retries=3
    local retry_delay=1
    shift
    local args=("$@")
    
    local attempt=1
    while [[ $attempt -le $max_retries ]]; do
        if "$operation" "${args[@]}"; then
            return 0
        fi
        
        echo "Crypto operation failed (attempt $attempt/$max_retries)" >&2
        
        if [[ $attempt -lt $max_retries ]]; then
            echo "Retrying in ${retry_delay}s..." >&2
            sleep "$retry_delay"
            ((retry_delay *= 2))  # Exponential backoff
        fi
        
        ((attempt++))
    done
    
    echo "Error: Crypto operation failed after $max_retries attempts" >&2
    return 1
}

# Usage
derive_keystream_with_retry() {
    crypto_with_retry crypto_derive_keystream "$@"
}
```

#### **Reference Documentation**
- [OpenSSL Command Line Utilities](https://www.openssl.org/docs/man3.0/man1/)
- [SHAKE-256 Specification - NIST FIPS 202](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf)
- [Cryptographic Best Practices](https://owasp.org/www-project-cryptographic-storage-cheat-sheet/)

---

## 🏗️ ARCHITECTURE AND DESIGN

### Proposed Architecture v3.0

```
┌─────────────────────────────────────────────────────────────┐
│                        SCypher v3.0                        │
│              Security-Enhanced Architecture                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Input Layer   │    │ Validation Layer│    │  Crypto Layer   │
│                 │    │                 │    │                 │
│ • CLI Args      │───▶│ • Input Sanit.  │───▶│ • Safe OpenSSL  │
│ • File Input    │    │ • Path Valid.   │    │ • Keystream     │
│ • User Input    │    │ • BIP39 Valid.  │    │ • XOR Ops       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   UI Layer      │    │ Security Layer  │    │  Output Layer   │
│                 │    │                 │    │                 │
│ • Menu System   │    │ • Memory Clean  │    │ • File Output   │
│ • Progress      │    │ • Trap Handlers │    │ • Screen Output │
│ • Error Display │    │ • State Mgmt    │    │ • Validation    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Design Principles

#### **PRINCIPLE 1: Defense in Depth**
- Multiple validation layers
- Each component independent and robust
- Graceful failures without compromising security

#### **PRINCIPLE 2: Fail-Safe Defaults**
- Most restrictive configuration by default
- Errors result in safer operation
- No special privileges required

#### **PRINCIPLE 3: Least Privilege**
- Completely eliminate root privileges
- Minimize file permissions
- Limited scope for sensitive variables

#### **PRINCIPLE 4: Input Validation**
- Validate all input at multiple points
- Whitelist approach vs blacklist
- Sanitization before processing

---

## 🔧 DETAILED TECHNICAL SPECIFICATIONS

### Proposed Module Structure

```bash
#!/usr/bin/env bash
# SCypher v3.0 - Security Enhanced

# =============================================================================
# MODULE 1: CONFIGURATION AND CONSTANTS
# =============================================================================
readonly VERSION="3.0-Security-Enhanced"
readonly MIN_BASH_VERSION=4
readonly MAX_INPUT_LENGTH=1000
readonly MAX_FILE_SIZE_KB=100
readonly CRYPTO_TIMEOUT=30
readonly MAX_ITERATIONS=1000000

# =============================================================================
# MODULE 2: UTILITY AND VALIDATION FUNCTIONS
# =============================================================================
validate_input() { ... }
validate_file_path() { ... }
validate_bip39_words() { ... }
sanitize_input() { ... }

# =============================================================================
# MODULE 3: SECURE FILE HANDLING
# =============================================================================
safe_file_read() { ... }
safe_file_write() { ... }
validate_output_path() { ... }

# =============================================================================
# MODULE 4: SECURE CRYPTOGRAPHIC OPERATIONS
# =============================================================================
safe_openssl_shake256() { ... }
crypto_derive_keystream() { ... }
crypto_xor_operation() { ... }
crypto_state_manager() { ... }

# =============================================================================
# MODULE 5: MEMORY MANAGEMENT AND CLEANUP
# =============================================================================
register_sensitive_var() { ... }
cleanup_sensitive_data() { ... }
setup_automatic_cleanup() { ... }

# =============================================================================
# MODULE 6: USER INTERFACE
# =============================================================================
show_main_menu() { ... }
handle_user_input() { ... }
display_results() { ... }

# =============================================================================
# MODULE 7: MAIN FLOW AND ORCHESTRATION
# =============================================================================
main() { ... }
process_arguments() { ... }
coordinate_operations() { ... }
```

---

## ✅ IMPLEMENTATION VERIFICATION CHECKLIST

### Critical Security Checklist

#### **🔴 CRITICAL - MUST IMPLEMENT**
- [ ] **SEC-001**: Completely eliminate root privilege verification
- [ ] **SEC-002**: Implement robust input validation (whitelist)
- [ ] **SEC-003**: Prevent path traversal in file handling
- [ ] **SEC-004**: Validate output of all OpenSSL commands
- [ ] **SEC-005**: Implement automatic cleanup of sensitive memory
- [ ] **SEC-006**: Add timeouts to cryptographic operations
- [ ] **SEC-007**: Validate integrity of end-to-end crypto operations

#### **🟡 IMPORTANT - SHOULD IMPLEMENT**
- [ ] **IMP-001**: Implement error logging for debugging
- [ ] **IMP-002**: Add more robust BIP39 checksum validation
- [ ] **IMP-003**: Improve error handling with specific messages
- [ ] **IMP-004**: Implement progress indicators for long operations
- [ ] **IMP-005**: Add performance validation (maximum time)

#### **🟢 DESIRABLE - CAN IMPLEMENT**
- [ ] **DES-001**: Add support for multiple hash algorithms
- [ ] **DES-002**: Implement optional output compression
- [ ] **DES-003**: Add batch mode for multiple files
- [ ] **DES-004**: Implement configuration via config file

### Compatibility Checklist

#### **Functional Compatibility**
- [ ] **COMP-001**: Maintain all existing CLI arguments
- [ ] **COMP-002**: Preserve exact output format
- [ ] **COMP-003**: Maintain compatibility with v2.0 files
- [ ] **COMP-004**: Preserve colors and UI format
- [ ] **COMP-005**: Keep silent mode working identically

#### **System Compatibility**
- [ ] **SYS-001**: Verify functionality on Linux
- [ ] **SYS-002**: Verify functionality on macOS
- [ ] **SYS-003**: Verify functionality on Windows (WSL/Cygwin)
- [ ] **SYS-004**: Test with Bash 4.0, 4.4, 5.0+
- [ ] **SYS-005**: Verify with OpenSSL 1.1.1 and 3.0+

---

## 🧪 TESTING PLAN

### Security Testing

#### **Penetration Testing Checklist**
```bash
# Test 1: Path Traversal
echo "../../../etc/passwd" | ./scypher_v3.sh -s

# Test 2: Command Injection
echo "test; cat /etc/passwd #" | ./scypher_v3.sh -s

# Test 3: Input Length Attack
python3 -c "print('a' * 10000)" | ./scypher_v3.sh -s

# Test 4: Privilege Escalation
./scypher_v3.sh  # Should NOT request sudo

# Test 5: Memory Dump Analysis
# Execute and verify no sensitive data in /proc/PID/mem
```

#### **Crypto Validation Tests**
```bash
# Test 1: Reversibility
original="abandon ability able about above absent absorb abstract absurd abuse access accident"
encrypted=$(echo "$original" | ./scypher_v3.sh -s)
decrypted=$(echo "$encrypted" | ./scypher_v3.sh -s)
[[ "$original" == "$decrypted" ]] || echo "FAIL: Reversibility test"

# Test 2: Checksum Validation
# Verify both input and output have valid BIP39 checksums

# Test 3: Determinism
# Same input + password should produce same output

# Test 4: Entropy
# Output should pass basic randomness tests
```

### Performance Testing

#### **Required Benchmarks**
```bash
# Performance Test - Different sizes
time echo "12_word_seed..." | ./scypher_v3.sh -s
time echo "24_word_seed..." | ./scypher_v3.sh -s

# Iteration Tests
time echo "seed" | timeout 30s ./scypher_v3.sh -s  # 1000 iterations
time echo "seed" | timeout 60s ./scypher_v3.sh -s  # 10000 iterations

# Memory Usage
valgrind --tool=massif ./scypher_v3.sh < test_input.txt
```

---

## 📚 REFERENCES AND DOCUMENTATION

### Cryptographic Documentation
- **[BIP39 Specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)** - Official BIP39 standard
- **[NIST FIPS 202](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf)** - SHA-3 and SHAKE specification
- **[RFC 7539](https://tools.ietf.org/html/rfc7539)** - ChaCha20-Poly1305 (AEAD reference)

### Security Documentation
- **[OWASP Secure Coding Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)**
- **[OWASP Input Validation Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)**
- **[OWASP Command Injection Prevention](https://owasp.org/www-community/attacks/Command_Injection)**
- **[OWASP Path Traversal](https://owasp.org/www-community/attacks/Path_Traversal)**

### Bash Documentation
- **[Bash Manual - GNU](https://www.gnu.org/software/bash/manual/bash.html)**
- **[Bash Security Best Practices](https://mywiki.wooledge.org/BashFAQ/050)**
- **[ShellCheck - Static Analysis](https://www.shellcheck.net/)**

### OpenSSL Documentation
- **[OpenSSL Command Line Utilities](https://www.openssl.org/docs/man3.0/man1/)**
- **[OpenSSL SHAKE-256 Usage](https://www.openssl.org/docs/man3.0/man1/openssl-dgst.html)**

### Testing Tools
- **[Bats - Bash Automated Testing](https://github.com/bats-core/bats-core)**
- **[ShellSpec - BDD Testing Framework](https://shellspec.info/)**
- **[Valgrind - Memory Analysis](https://valgrind.org/)**

---

## 🛠️ RECOMMENDED DEVELOPMENT TOOLS

### Static Analysis
```bash
# ShellCheck - Syntax analysis and best practices
shellcheck scypher_v3.sh

# Bashate - Style checker
bashate scypher_v3.sh

# Checkbashisms - Portability checker
checkbashisms scypher_v3.sh
```

### Testing Frameworks
```bash
# Bats - Unit testing
# tests/test_scypher.bats
@test "input validation works" {
    run ./scypher_v3.sh -s < /dev/null
    [ "$status" -eq 1 ]
}

# ShellSpec - BDD testing
# spec/scypher_spec.sh
Describe 'SCypher v3.0'
  It 'should not require root privileges'
    When run ./scypher_v3.sh --help
    The status should be 0
    The output should not include "sudo"
  End
End
```

### Security Testing Tools
```bash
# Lynis - Security auditing
lynis audit system

# Bandit equivalent for Bash (custom script)
./security_audit.sh scypher_v3.sh

# SAST scanning
semgrep --config=bash-security scypher_v3.sh
```

---

## 📋 IMPLEMENTATION TEMPLATE

### Suggested File Structure

```bash
#!/usr/bin/env bash
# SCypher v3.0 - Security Enhanced XOR-based BIP39 Seed Cipher
# 
# SECURITY IMPROVEMENTS:
# - Removed root privilege requirements
# - Enhanced input validation with whitelist approach
# - Secure file handling with path traversal prevention
# - Robust cryptographic operations with validation
# - Simplified but effective memory cleanup
# - Command injection prevention
# - Comprehensive error handling

set -euo pipefail  # Bash strict mode

# =============================================================================
# CONFIGURATION AND CONSTANTS
# =============================================================================
readonly VERSION="3.0-Security-Enhanced"
readonly SCRIPT_NAME="$(basename "$0")"

# Security limits
readonly MAX_INPUT_LENGTH=1000
readonly MAX_FILE_SIZE_KB=100
readonly CRYPTO_TIMEOUT=30
readonly MAX_ITERATIONS=1000000
readonly MIN_PASSWORD_LENGTH=8

# BIP39 constants
readonly VALID_WORD_COUNTS=(12 15 18 21 24)
readonly BIP39_WORDLIST=( ... )  # Full wordlist here

# Color scheme (preserve existing)
readonly COLOR_RESET='\033[0m'
readonly COLOR_PRIMARY='\033[38;5;214m'
# ... other colors

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Logging function
log_error() {
    echo "ERROR: $*" >&2
}

log_warning() {
    echo "WARNING: $*" >&2
}

log_info() {
    echo "INFO: $*" >&2
}

# =============================================================================
# INPUT VALIDATION (SECURITY-CRITICAL)
# =============================================================================

validate_input() {
    # IMPLEMENTATION REQUIRED: REQ-VAL-001 through REQ-VAL-004
    # Use Approach A: Strict Whitelist
}

validate_file_path() {
    # IMPLEMENTATION REQUIRED: REQ-FILE-001 through REQ-FILE-004
    # Use Approach A: Complete Path Validation
}

# =============================================================================
# SECURE FILE OPERATIONS
# =============================================================================

safe_file_read() {
    # IMPLEMENTATION REQUIRED: Secure file reading with all validations
}

safe_file_write() {
    # IMPLEMENTATION REQUIRED: Secure file writing with validation
}

# =============================================================================
# CRYPTOGRAPHIC OPERATIONS (SECURITY-CRITICAL)
# =============================================================================

safe_openssl_shake256() {
    # IMPLEMENTATION REQUIRED: REQ-CRYPTO-001 through REQ-CRYPTO-004
    # Use Approach A: Crypto Library Wrapper
}

crypto_derive_keystream() {
    # IMPLEMENTATION REQUIRED: Robust keystream derivation
}

# =============================================================================
# MEMORY MANAGEMENT (SECURITY-CRITICAL)
# =============================================================================

declare -a SENSITIVE_VARS=()

register_sensitive_var() {
    # IMPLEMENTATION REQUIRED: REQ-MEM-001 through REQ-MEM-004
    # Use Approach A: Pattern-based Automatic Cleanup
}

cleanup_sensitive_data() {
    # IMPLEMENTATION REQUIRED: Simplified but effective cleanup
}

setup_automatic_cleanup() {
    trap cleanup_sensitive_data EXIT HUP INT TERM
}

# =============================================================================
# MAIN PROGRAM FLOW
# =============================================================================

main() {
    # IMPLEMENTATION REQUIRED: 
    # 1. Remove all root privilege checks
    # 2. Implement secure input handling
    # 3. Add comprehensive error handling
    # 4. Maintain full backward compatibility
    
    setup_automatic_cleanup
    
    # Process arguments securely
    process_arguments "$@"
    
    # Main crypto operation
    perform_secure_crypto_operation
    
    # Output results
    handle_output_securely
}

# Start execution
main "$@"
```

---

## 🎯 SUCCESS CRITERIA

### Definition of Done

An implementation is considered **COMPLETE** when:

1. **✅ SECURITY**:
   - Passes all penetration tests
   - Does not require root privileges
   - Resists command injection attacks
   - Prevents path traversal

2. **✅ FUNCTIONALITY**:
   - 100% compatible with SCypher v2.0
   - Same output for same input
   - All modes (interactive, CLI, silent) work
   - UI preserved exactly

3. **✅ ROBUSTNESS**:
   - Handles all errors gracefully
   - No crashes with malicious inputs
   - Acceptable performance (< 30s for 24 words)
   - Controlled memory usage

4. **✅ CODE QUALITY**:
   - Passes ShellCheck without warnings
   - Documented and readable code
   - Modular and maintainable structure
   - Automated tests included

### Quality Metrics

| Metric | Minimum Target | Ideal Target |
|--------|----------------|--------------|
| **Security Score** | 95% | 100% |
| **Test Coverage** | 80% | 95% |
| **Performance** | < 30s | < 10s |
| **Memory Usage** | < 100MB | < 50MB |
| **Code Quality** | ShellCheck ✅ | ShellCheck ✅ + Clean |

---

## 🔄 MIGRATION PLAN

### Migration Strategy from v2.0 to v3.0

#### **Phase 1: Compatibility Validation**
1. Create test suite with v2.0 cases
2. Verify identical outputs
3. Validate all operation modes

#### **Phase 2: Gradual Implementation**
1. Implement module by module
2. Continuous testing after each module
3. Rollback plan if issues arise

#### **Phase 3: Final Validation**
1. Exhaustive security testing
2. Performance benchmarking
3. User acceptance testing

### Guaranteed Backward Compatibility

```bash
# Automatic compatibility test
compatibility_test() {
    local test_phrase="abandon ability able about above absent absorb abstract absurd abuse access accident"
    local test_password="TestPassword123"
    local test_iterations=1000
    
    # Test with v2.0
    local v2_output
    v2_output=$(echo "$test_phrase" | echo "$test_password" | echo "$test_iterations" | ./scypher_v2.sh -s)
    
    # Test with v3.0
    local v3_output
    v3_output=$(echo "$test_phrase" | echo "$test_password" | echo "$test_iterations" | ./scypher_v3.sh -s)
    
    if [[ "$v2_output" == "$v3_output" ]]; then
        echo "✅ COMPATIBILITY TEST PASSED"
        return 0
    else
        echo "❌ COMPATIBILITY TEST FAILED"
        echo "v2.0 output: $v2_output"
        echo "v3.0 output: $v3_output"
        return 1
    fi
}
```

---

## 🚨 ALERTS AND SPECIAL CONSIDERATIONS

### ⚠️ CRITICAL WARNINGS FOR IMPLEMENTER

#### **ALERT 1: DO NOT CHANGE CRYPTOGRAPHIC ALGORITHM**
```bash
# ❌ DO NOT DO THIS - Breaks compatibility
new_keystream=$(some_other_hash_function "$password")

# ✅ DO THIS - Maintain exact algorithm
keystream=$(safe_openssl_shake256 "$password" "$byte_length")
```

#### **ALERT 2: PRESERVE XOR OPERATION ORDER**
```bash
# ❌ DO NOT CHANGE - Order matters for reversibility
result_bits=$(xor_bits "$keystream" "$seed_bits")  # WRONG ORDER

# ✅ MAINTAIN - Original v2.0 order
result_bits=$(xor_bits "$seed_bits" "$keystream")  # CORRECT ORDER
```

#### **ALERT 3: BIP39 CHECKSUM CRITICAL**
```bash
# The recalculate_bip39_checksum function is CRITICAL
# DO NOT simplify without complete understanding
# Any change must be exhaustively tested
```

### 🔍 SPECIAL ATTENTION POINTS

#### **POINT 1: Binary Conversions**
- The `decimal_to_binary` and `binary_to_decimal` functions are critical
- Any error here completely corrupts the result
- MUST maintain exact compatibility with v2.0 implementation

#### **POINT 2: Input Space Handling**
```bash
# v2.0 handles spaces in specific way
# MUST preserve this exact behavior
read -ra words <<< "$input"  # Specific behavior
```

#### **POINT 3: Colors and UI**
- ANSI color codes must be preserved exactly
- User experience must be identical
- Menu flows must remain the same

#### **POINT 4: Error Messages**
- Exact format of error messages must be preserved
- This includes capitalization, punctuation, format
- Scripts may depend on these messages

---

## 🧩 IMPLEMENTATION TROUBLESHOOTING GUIDE

### Common Problems and Solutions

#### **PROBLEM: OpenSSL Output Parsing Fails**
```bash
# SYMPTOM
Error: Invalid hash format at iteration 1

# DIAGNOSIS
echo "test" | openssl dgst -shake256 -xoflen 32
# Verify exact output format

# SOLUTION
# Adjust regex in safe_openssl_shake256
if [[ ! "$result" =~ ^[A-Za-z0-9()=\ \-]+$ ]]; then
```

#### **PROBLEM: Path Traversal Validation Too Restrictive**
```bash
# SYMPTOM
Error: File access outside current directory not allowed

# DIAGNOSIS
realpath -s "./test.txt"
pwd
# Verify resolved paths

# SOLUTION
# Allow legitimate subdirectories
if [[ "$resolved_path" == "$current_dir"* ]] || [[ "$resolved_path" == "$current_dir/"* ]]; then
```

#### **PROBLEM: Memory Cleanup Not Working**
```bash
# SYMPTOM
Sensitive variables visible in /proc/PID/mem

# DIAGNOSIS
declare -p | grep SENSITIVE_
# Verify registered variables

# SOLUTION
# Ensure all variables are registered
register_sensitive_var "password"
register_sensitive_var "keystream"
```

#### **PROBLEM: BIP39 Checksum Fails**
```bash
# SYMPTOM
Error: Invalid BIP39 checksum in output

# DIAGNOSIS
# Verify calculate_checksum_bits works correctly
echo "10101010..." | calculate_checksum_bits

# SOLUTION
# Review hex-to-binary conversion in calculate_checksum_bits
# Ensure echo -e works correctly on the system
```

### Debugging Scripts

#### **Debug Script 1: Crypto Validation**
```bash
#!/bin/bash
# debug_crypto.sh

debug_crypto_operations() {
    echo "=== CRYPTO DEBUG REPORT ==="
    
    # Test OpenSSL availability
    echo "OpenSSL version:"
    openssl version
    
    # Test SHAKE-256 support
    echo "Testing SHAKE-256 support:"
    echo "test" | openssl dgst -shake256 -xoflen 32
    
    # Test keystream generation
    echo "Testing keystream generation:"
    local test_keystream
    test_keystream=$(crypto_derive_keystream "test_password" 128 1)
    echo "Keystream length: ${#test_keystream}"
    echo "Keystream format: $test_keystream"
    
    # Test XOR operations
    echo "Testing XOR operations:"
    local test_a="10101010"
    local test_b="11001100"
    local xor_result
    xor_result=$(xor_bits "$test_a" "$test_b")
    echo "XOR $test_a ⊕ $test_b = $xor_result"
}
```

#### **Debug Script 2: Input Validation**
```bash
#!/bin/bash
# debug_validation.sh

test_validation_edge_cases() {
    echo "=== VALIDATION DEBUG REPORT ==="
    
    local test_cases=(
        "normal input words"
        "input with    multiple    spaces"
        "input-with-hyphens"
        "input.with.dots"
        "input/with/slashes"
        "../path/traversal/attempt"
        "very_long_input_$(printf 'a%.0s' {1..1000})"
        ""
        " "
        \n\r\t'
    )
    
    for test_case in "${test_cases[@]}"; do
        echo "Testing: '$test_case'"
        if validate_input "$test_case"; then
            echo "  ✅ PASSED"
        else
            echo "  ❌ REJECTED"
        fi
        echo
    done
}
```

#### **Debug Script 3: Memory Analysis**
```bash
#!/bin/bash
# debug_memory.sh

analyze_memory_usage() {
    echo "=== MEMORY DEBUG REPORT ==="
    
    # Memory usage before
    local mem_before
    mem_before=$(ps -o rss= -p $)
    echo "Memory before: ${mem_before}KB"
    
    # Create sensitive variables
    SENSITIVE_test_var="very_sensitive_data_$(openssl rand -hex 1024)"
    register_sensitive_var "SENSITIVE_test_var"
    
    # Memory usage after
    local mem_after
    mem_after=$(ps -o rss= -p $)
    echo "Memory after: ${mem_after}KB"
    echo "Memory increase: $((mem_after - mem_before))KB"
    
    # Test cleanup
    cleanup_sensitive_data
    
    # Verify cleanup
    if declare -p SENSITIVE_test_var >/dev/null 2>&1; then
        echo "❌ CLEANUP FAILED: Variable still exists"
    else
        echo "✅ CLEANUP SUCCESS: Variable cleared"
    fi
}
```

---

## 📖 END USER DOCUMENTATION

### README.md Template for v3.0

```markdown
# SCypher v3.0 - Security Enhanced

## 🔒 Security Improvements in v3.0

### ✅ What's Fixed
- **Removed root requirement**: No more `sudo` needed
- **Enhanced input validation**: Prevents injection attacks
- **Secure file handling**: Path traversal protection
- **Robust crypto operations**: Better error handling
- **Improved memory cleanup**: Automatic sensitive data clearing

### ⚠️ Breaking Changes
- **NONE** - 100% backward compatible with v2.0

## 🚀 Quick Start

```bash
# Download and make executable
chmod +x scypher_v3.sh

# Interactive mode (recommended for beginners)
./scypher_v3.sh

# Command line mode
echo "your seed phrase here" | ./scypher_v3.sh -s

# File mode
./scypher_v3.sh -f output.txt < input.txt
```

## 🛡️ Security Best Practices

1. **Use strong passwords**: Minimum 12 characters with mixed case, numbers, symbols
2. **Verify checksums**: Both input and output should be valid BIP39
3. **Test with small amounts first**: Never risk large funds without testing
4. **Keep backups**: Store original seed phrases securely
5. **Use offline**: Run on air-gapped systems for maximum security

## 🐛 Troubleshooting

### Common Issues

**Problem**: "Error: OpenSSL not found"
**Solution**: Install OpenSSL 3.0+ (`apt install openssl` on Ubuntu)

**Problem**: "Error: Invalid file path"
**Solution**: Use relative paths only, avoid `../` patterns

**Problem**: "Error: Input too long"
**Solution**: Input must be < 1000 characters

For more help, run `./scypher_v3.sh --help`
```

### Changelog Template

```markdown
# SCypher Changelog

## [3.0.0] - Security Enhanced - 2025-05-29

### 🔒 Security Fixes
- **CRITICAL**: Removed root privilege requirement
- **HIGH**: Fixed command injection vulnerabilities
- **HIGH**: Added path traversal protection
- **MEDIUM**: Enhanced input validation
- **MEDIUM**: Improved memory cleanup

### 🛠️ Technical Improvements
- Robust error handling for all crypto operations
- Better validation of OpenSSL outputs
- Simplified memory management
- Enhanced file handling security
- Comprehensive input sanitization

### 🔄 Compatibility
- **100% backward compatible** with v2.0
- Same crypto algorithm (XOR + SHAKE-256)
- Identical output for identical inputs
- All CLI arguments preserved
- UI/UX unchanged

### 📊 Performance
- Slightly improved performance due to optimizations
- Better memory usage patterns
- Faster startup time
- More responsive UI

### 🧪 Testing
- Added comprehensive security test suite
- Penetration testing passed all checks
- Memory analysis shows no leaks
- Cross-platform compatibility verified

## [2.0.0] - ErgoHack X Release - Previous Version
...
```

---

## 🎓 STEP-BY-STEP IMPLEMENTATION GUIDE

### Step 1: Environment Preparation
```bash
# 1. Clone existing code
cp scypher_v2.sh scypher_v3.sh

# 2. Create testing directory
mkdir -p tests/{unit,integration,security}

# 3. Install development tools
# Ubuntu/Debian:
sudo apt install shellcheck bats valgrind

# macOS:
brew install shellcheck bats-core valgrind
```

### Step 2: Implementation by Priority
```bash
# RECOMMENDED IMPLEMENTATION ORDER:

# 1. CRITICAL - Remove root check (15 min)
#    Search and remove privilege verification

# 2. CRITICAL - Input validation (2 hours)
#    Implement validate_input() with whitelist

# 3. CRITICAL - File handling (1 hour)
#    Implement safe_file_read() and validations

# 4. IMPORTANT - Crypto wrapper (3 hours)
#    Implement safe_openssl_shake256() and validations

# 5. IMPORTANT - Memory cleanup (1 hour)
#    Implement simplified automatic cleanup

# 6. TESTING - Security tests (2 hours)
#    Create complete test suite

# TOTAL ESTIMATED TIME: 9-10 hours
```

### Step 3: Continuous Validation
```bash
# After each implemented module:

# 1. Run automated tests
./run_tests.sh

# 2. Verify compatibility
./compatibility_test.sh

# 3. Security analysis
shellcheck scypher_v3.sh
./security_audit.sh

# 4. Basic manual test
echo "abandon ability able about above absent absorb abstract absurd abuse access accident" | ./scypher_v3.sh -s
```

---

## 📋 CONCLUSION AND NEXT STEPS

### PRD Executive Summary

This document completely specifies the requirements to transform SCypher v2.0 into a production-grade cryptographic tool that:

1. **Eliminates all critical security risks** identified in the audit
2. **Maintains 100% functional compatibility** with the existing version
3. **Provides multiple implementation approaches** for each problem
4. **Includes comprehensive testing and validation** procedures

### Implementation Priority Order

1. **🔴 CRITICAL** (Implement FIRST): Root privileges, input validation, file handling
2. **🟡 IMPORTANT** (Implement SECOND): Crypto operations, memory cleanup
3. **🟢 DESIRABLE** (Implement LAST): UX improvements, additional optimizations

### Final Success Criteria

The implementation will be successful when:
- ✅ Passes all security tests without exceptions
- ✅ Maintains 100% compatibility with v2.0
- ✅ Does not require elevated privileges for any operation
- ✅ Resists all defined penetration attacks

### 🎯 CALL TO ACTION

**For any AI implementing this PRD:**

1. **READ COMPLETELY** this document before starting
2. **IMPLEMENT IN PRIORITY ORDER** - Critical first
3. **TEST CONTINUOUSLY** after each module
4. **PRESERVE COMPATIBILITY** - Never change crypto algorithms
5. **DOCUMENT ALL CHANGES** made

**Available support resources:**
- Complete v2.0 source code (provided)
- Example test cases in this PRD
- Complete linked technical documentation
- Included debugging scripts

---

**SUCCESS IN IMPLEMENTATION!** 🚀

---

*This PRD was created with the goal that any competent AI can implement the required security improvements following exact specifications and maintaining maximum code quality.*