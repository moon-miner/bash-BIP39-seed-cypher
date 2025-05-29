# SCypher v3.0 - Product Requirements Document (PRD)
## Documento de Requisitos del Producto para Refactoring de Seguridad

---

## 📋 INFORMACIÓN DEL DOCUMENTO

| Campo | Valor |
|-------|-------|
| **Versión del PRD** | 1.0 |
| **Fecha de Creación** | 29 de Mayo, 2025 |
| **Producto** | SCypher v3.0 - XOR-based BIP39 Seed Cipher |
| **Versión Actual** | v2.0-ErgoHack-X |
| **Versión Objetivo** | v3.0-Security-Enhanced |
| **Tipo de Release** | Security Refactoring + Enhancement |

---

## 🎯 OBJETIVOS DEL PROYECTO

### Objetivo Principal
Crear una versión completamente segura de SCypher que elimine todos los riesgos de seguridad identificados en la auditoría, manteniendo 100% de la funcionalidad existente y mejorando la robustez del sistema.

### Objetivos Específicos
1. **Seguridad**: Eliminar todos los riesgos críticos y altos identificados
2. **Compatibilidad**: Mantener 100% compatibilidad funcional con v2.0
3. **Robustez**: Mejorar manejo de errores y casos edge
4. **Mantenibilidad**: Simplificar arquitectura sin perder funcionalidad
5. **Usabilidad**: Preservar toda la experiencia de usuario existente

---

## 🔒 PROBLEMAS CRÍTICOS A RESOLVER

### 🚨 PROBLEMA 1: ELIMINACIÓN DE PRIVILEGIOS ROOT

#### **Descripción del Problema**
```bash
# CÓDIGO PROBLEMÁTICO ACTUAL
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with bash"
    echo "Please run as: sudo bash $0"
    exit 1
fi
```

#### **Requisitos de Solución**
- **REQ-SEC-001**: ELIMINAR completamente cualquier verificación de privilegios root
- **REQ-SEC-002**: IMPLEMENTAR protecciones alternativas que no requieran privilegios elevados
- **REQ-SEC-003**: MANTENER funcionalidades de seguridad mediante métodos user-space

#### **Enfoques de Implementación**

##### **Approach A: Eliminación Completa (RECOMENDADO)**
```bash
# SOLUCIÓN SIMPLE - Eliminar verificación
# NO HACER verificación de privilegios
# Documentar que no se requieren privilegios especiales
```

**Ventajas**: Máxima seguridad, simplicidad
**Desventajas**: Ninguna
**Complejidad**: Baja

##### **Approach B: Privilegios Opcionales**
```bash
# SOLUCIÓN ALTERNATIVA - Privilegios opcionales
if [ "$(id -u)" -eq 0 ]; then
    echo "Running with enhanced security features (root mode)"
    ENHANCED_SECURITY=1
else
    echo "Running in standard user mode"
    ENHANCED_SECURITY=0
fi
```

**Ventajas**: Flexibilidad
**Desventajas**: Complejidad adicional innecesaria
**Complejidad**: Media

#### **Documentación de Referencia**
- [Linux Capabilities - man 7 capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [Principle of Least Privilege - OWASP](https://owasp.org/www-community/vulnerabilities/Privilege_chaining)

---

### 🚨 PROBLEMA 2: VALIDACIÓN INSEGURA DE ENTRADA

#### **Descripción del Problema**
```bash
# CÓDIGO PROBLEMÁTICO ACTUAL
validate_input() {
    local input="$1"
    if [[ "$input" =~ [^a-zA-Z0-9\ ] ]]; then
        echo "Error: Input contains invalid characters"
        return 1
    fi
    return 0
}
```

#### **Requisitos de Solución**
- **REQ-VAL-001**: IMPLEMENTAR validación robusta contra inyección de comandos
- **REQ-VAL-002**: VALIDAR longitud máxima estricta (< 1000 caracteres)
- **REQ-VAL-003**: SANITIZAR entrada para prevenir path traversal
- **REQ-VAL-004**: MANTENER compatibilidad con caracteres BIP39 válidos

#### **Enfoques de Implementación**

##### **Approach A: Whitelist Estricta (RECOMENDADO)**
```bash
validate_input() {
    local input="$1"
    local max_length=1000
    
    # Verificar longitud
    if [[ ${#input} -gt $max_length ]]; then
        echo "Error: Input too long (max: $max_length characters)" >&2
        return 1
    fi
    
    # Solo permitir caracteres específicos (whitelist)
    if [[ ! "$input" =~ ^[a-zA-Z0-9[:space:]]+$ ]]; then
        echo "Error: Invalid characters detected" >&2
        return 1
    fi
    
    # Verificar que no esté vacío después de trim
    local trimmed="${input// /}"
    if [[ -z "$trimmed" ]]; then
        echo "Error: Empty input" >&2
        return 1
    fi
    
    return 0
}
```

##### **Approach B: Sanitización + Validación**
```bash
sanitize_input() {
    local input="$1"
    # Remover caracteres peligrosos
    local sanitized="${input//[^a-zA-Z0-9 ]/}"
    # Normalizar espacios
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

##### **Approach C: Validación por Contexto**
```bash
validate_seed_phrase() {
    local input="$1"
    local -a words
    read -ra words <<< "$input"
    
    # Validar cantidad de palabras primero
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
    
    # Validar cada palabra individualmente
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
    
    # Prevenir path traversal
    if [[ "$filepath" == *".."* ]] || [[ "$filepath" == *"/"* && ! "$filepath" =~ ^[./][^/]*$ ]]; then
        echo "Error: Invalid file path" >&2
        return 1
    fi
    
    # Validar extensión si es necesario
    if [[ "$filepath" != *.txt ]] && [[ "$filepath" != *. ]]; then
        echo "Warning: Recommended to use .txt extension" >&2
    fi
    
    return 0
}
```

#### **Documentación de Referencia**
- [Bash Parameter Expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)
- [Regular Expressions in Bash](https://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html)
- [Input Validation - OWASP Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)

---

### 🚨 PROBLEMA 3: MANEJO INSEGURO DE ARCHIVOS

#### **Descripción del Problema**
```bash
# CÓDIGO PROBLEMÁTICO ACTUAL
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

#### **Requisitos de Solución**
- **REQ-FILE-001**: PREVENIR ataques de path traversal
- **REQ-FILE-002**: VALIDAR permisos de archivo antes de acceso
- **REQ-FILE-003**: LIMITAR tamaño máximo de archivo
- **REQ-FILE-004**: SANITIZAR nombres de archivo de salida

#### **Enfoques de Implementación**

##### **Approach A: Validación Completa de Path (RECOMENDADO)**
```bash
validate_file_path() {
    local filepath="$1"
    local resolved_path
    
    # Resolver path absoluto de forma segura
    if ! resolved_path=$(realpath -s "$filepath" 2>/dev/null); then
        echo "Error: Invalid file path" >&2
        return 1
    fi
    
    # Verificar que esté en directorio permitido (CWD o subdirectorios)
    local current_dir
    current_dir=$(pwd)
    
    # Verificar que el path resuelto comience con el directorio actual
    if [[ ! "$resolved_path" == "$current_dir"* ]]; then
        echo "Error: File access outside current directory not allowed" >&2
        return 1
    fi
    
    # Verificar caracteres peligrosos
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
    
    # Validar path
    if ! validated_path=$(validate_file_path "$file"); then
        return 1
    fi
    
    # Verificar existencia
    if [[ ! -f "$validated_path" ]]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    
    # Verificar permisos de lectura
    if [[ ! -r "$validated_path" ]]; then
        echo "Error: Cannot read file: $file" >&2
        return 1
    fi
    
    # Verificar tamaño
    local file_size
    file_size=$(stat -f%z "$validated_path" 2>/dev/null || stat -c%s "$validated_path" 2>/dev/null)
    if [[ $file_size -gt $((max_size_kb * 1024)) ]]; then
        echo "Error: File too large (max: ${max_size_kb}KB)" >&2
        return 1
    fi
    
    # Leer archivo de forma segura
    local content
    if ! content=$(cat "$validated_path" 2>/dev/null); then
        echo "Error: Failed to read file" >&2
        return 1
    fi
    
    # Normalizar espacios y saltos de línea
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
    # Definir directorio base permitido
    SAFE_DIR=$(pwd)
    readonly SAFE_DIR
    export SAFE_DIR
}

validate_file_in_safe_dir() {
    local filepath="$1"
    local full_path
    
    # Construir path completo
    if [[ "$filepath" == /* ]]; then
        echo "Error: Absolute paths not allowed" >&2
        return 1
    fi
    
    full_path="${SAFE_DIR}/${filepath}"
    
    # Resolver symlinks y verificar
    if ! resolved=$(realpath -e "$full_path" 2>/dev/null); then
        echo "Error: Cannot resolve file path" >&2
        return 1
    fi
    
    # Verificar que sigue dentro del directorio seguro
    if [[ ! "$resolved" == "$SAFE_DIR"* ]]; then
        echo "Error: Access outside safe directory denied" >&2
        return 1
    fi
    
    echo "$resolved"
    return 0
}
```

##### **Approach C: Whitelist de Extensiones**
```bash
validate_file_extension() {
    local filepath="$1"
    local allowed_extensions=("txt" "seed" "bip39")
    local extension="${filepath##*.}"
    
    # Convertir a minúsculas
    extension="${extension,,}"
    
    # Verificar si está en la whitelist
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

#### **Documentación de Referencia**
- [Path Traversal Prevention - OWASP](https://owasp.org/www-community/attacks/Path_Traversal)
- [Bash realpath command](https://www.gnu.org/software/coreutils/manual/html_node/realpath-invocation.html)
- [File System Security - Linux Documentation](https://www.kernel.org/doc/html/latest/admin-guide/LSM/index.html)

---

### 🚨 PROBLEMA 4: LIMPIEZA INSEGURA DE MEMORIA

#### **Descripción del Problema**
```bash
# CÓDIGO PROBLEMÁTICO ACTUAL
cleanup() {
    # Función extremadamente compleja con 200+ líneas
    # Limpieza manual de variables individuales
    # Riesgo de no limpiar variables nuevas
    # Complejidad innecesaria
}
```

#### **Requisitos de Solución**
- **REQ-MEM-001**: SIMPLIFICAR función de limpieza manteniendo efectividad
- **REQ-MEM-002**: IMPLEMENTAR limpieza automática de variables sensibles
- **REQ-MEM-003**: ASEGURAR limpieza en todos los paths de salida
- **REQ-MEM-004**: MINIMIZAR ventana de tiempo con datos sensibles en memoria

#### **Enfoques de Implementación**

##### **Approach A: Limpieza Automática por Patrón (RECOMENDADO)**
```bash
# Variables sensibles con prefijo específico
declare SENSITIVE_password=""
declare SENSITIVE_keystream=""
declare SENSITIVE_seed_bits=""
declare SENSITIVE_result=""

cleanup_sensitive_data() {
    local var_name
    
    # Encontrar todas las variables con prefijo SENSITIVE_
    while IFS= read -r var_name; do
        if [[ "$var_name" == SENSITIVE_* ]]; then
            # Sobreescribir con datos aleatorios
            local random_data
            random_data=$(openssl rand -hex 32 2>/dev/null || echo "$(date +%s)_random_cleanup")
            printf -v "$var_name" "%s" "$random_data"
            unset "$var_name"
        fi
    done < <(compgen -v)
    
    # Limpiar arrays asociativos sensibles
    if declare -p word_lookup >/dev/null 2>&1; then
        for key in "${!word_lookup[@]}"; do
            word_lookup[$key]="$(openssl rand -hex 16)"
            unset 'word_lookup[$key]'
        done
        unset word_lookup
    fi
    
    # Limpiar historial
    history -c 2>/dev/null || true
    
    # Forzar garbage collection si está disponible
    if declare -F bash_gc >/dev/null; then
        bash_gc
    fi
}

# Función de limpieza principal simplificada
cleanup() {
    cleanup_sensitive_data
    
    # Restaurar terminal
    stty echo 2>/dev/null || true
    
    # Restaurar umask
    umask "${ORIGINAL_UMASK:-022}"
}
```

##### **Approach B: Scoped Variables**
```bash
# Usar subshells para limitar scope de variables sensibles
process_sensitive_data() {
    (
        # Variables locales se limpian automáticamente al salir del subshell
        local password="$1"
        local seed_phrase="$2"
        local iterations="$3"
        
        # Todo el procesamiento criptográfico aquí
        local result
        result=$(perform_xor_encryption "$seed_phrase" "$password" "$iterations")
        
        # Solo devolver el resultado
        echo "$result"
        
        # Variables se limpian automáticamente
    )
}

main() {
    local password seed_phrase iterations result
    
    # Obtener inputs
    password=$(read_secure_password)
    seed_phrase=$(read_seed_phrase)
    iterations=$(read_iterations)
    
    # Procesar en subshell aislado
    result=$(process_sensitive_data "$password" "$seed_phrase" "$iterations")
    
    # Limpiar inputs inmediatamente
    password="$(openssl rand -hex 32)"
    seed_phrase="$(openssl rand -hex 64)"
    iterations=0
    unset password seed_phrase iterations
    
    # Usar resultado
    handle_result "$result"
    
    # Limpiar resultado
    result="$(openssl rand -hex 64)"
    unset result
}
```

##### **Approach C: Trap-based Cleanup**
```bash
# Lista global de variables sensibles
declare -a SENSITIVE_VARS=()

register_sensitive_var() {
    local var_name="$1"
    SENSITIVE_VARS+=("$var_name")
}

cleanup_registered_vars() {
    for var_name in "${SENSITIVE_VARS[@]}"; do
        if [[ -v "$var_name" ]]; then
            # Sobreescribir con ruido
            printf -v "$var_name" "%s" "$(openssl rand -hex 32 2>/dev/null || date +%s)"
            unset "$var_name"
        fi
    done
    SENSITIVE_VARS=()
}

# Setup automático de limpieza
setup_automatic_cleanup() {
    trap 'cleanup_registered_vars' EXIT HUP INT TERM
}

# Uso
main() {
    setup_automatic_cleanup
    
    local password
    password=$(read_secure_password)
    register_sensitive_var "password"
    
    # ... resto de la lógica
}
```

#### **Documentación de Referencia**
- [Bash Subshells](https://www.gnu.org/software/bash/manual/html_node/Command-Grouping.html)
- [Memory Management Best Practices](https://owasp.org/www-community/vulnerabilities/Insecure_Storage)
- [Secure Coding in Bash](https://mywiki.wooledge.org/BashFAQ/050)

---

### 🚨 PROBLEMA 5: EJECUCIÓN INSEGURA DE COMANDOS

#### **Descripción del Problema**
```bash
# CÓDIGO PROBLEMÁTICO ACTUAL
available_memory=$(free -m | awk '/^Mem:/{print $7}')
hash_output=$(echo -e -n "$binary_data" | openssl dgst -sha256)
```

#### **Requisitos de Solución**
- **REQ-CMD-001**: VALIDAR salida de todos los comandos externos
- **REQ-CMD-002**: IMPLEMENTAR timeouts para operaciones críticas
- **REQ-CMD-003**: MANEJAR fallos de comandos gracefully
- **REQ-CMD-004**: EVITAR inyección de comandos en parámetros

#### **Enfoques de Implementación**

##### **Approach A: Wrapper Functions con Validación (RECOMENDADO)**
```bash
safe_openssl_dgst() {
    local algorithm="$1"
    local input="$2"
    local timeout_seconds=30
    local temp_file
    
    # Validar algoritmo
    case "$algorithm" in
        "sha256"|"shake256") ;;
        *) echo "Error: Unsupported hash algorithm" >&2; return 1 ;;
    esac
    
    # Crear archivo temporal seguro
    temp_file=$(mktemp) || {
        echo "Error: Cannot create temporary file" >&2
        return 1
    }
    
    # Cleanup automático del archivo temporal
    trap "rm -f '$temp_file'" RETURN
    
    # Escribir input de forma segura
    printf '%s' "$input" > "$temp_file" || {
        echo "Error: Cannot write to temporary file" >&2
        return 1
    }
    
    # Ejecutar OpenSSL con timeout
    local result
    if ! result=$(timeout "$timeout_seconds" openssl dgst -"$algorithm" < "$temp_file" 2>/dev/null); then
        echo "Error: OpenSSL operation failed or timed out" >&2
        return 1
    fi
    
    # Validar formato de salida
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
    
    # Validar parámetros
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
    
    # Extraer solo la parte hexadecimal
    local hex_part="${result##*= }"
    
    # Validar que es hexadecimal válido
    if [[ ! "$hex_part" =~ ^[0-9a-fA-F]+$ ]]; then
        echo "Error: Invalid hexadecimal output" >&2
        return 1
    fi
    
    # Validar longitud esperada
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
    
    # Encontrar path del comando
    if ! cmd_path=$(command -v "$cmd" 2>/dev/null); then
        echo "Error: Command not found: $cmd" >&2
        return 1
    fi
    
    # Verificar si está en la whitelist
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
    
    # Validar comando
    if ! cmd_path=$(validate_command "$cmd"); then
        return 1
    fi
    
    # Ejecutar con path completo
    "$cmd_path" "${args[@]}"
}
```

##### **Approach C: Sandboxing con Firejail**
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
            # Fallback a método seguro sin sandbox
            safe_openssl_dgst "$operation" "$input"
            ;;
    esac
}
```

#### **Documentación de Referencia**
- [Bash timeout command](https://www.gnu.org/software/coreutils/manual/html_node/timeout-invocation.html)
- [Command Injection Prevention](https://owasp.org/www-community/attacks/Command_Injection)
- [Firejail Sandboxing](https://firejail.wordpress.com/)

---

### 🚨 PROBLEMA 6: IMPLEMENTACIÓN CRIPTOGRÁFICA FRÁGIL

#### **Descripción del Problema**
```bash
# CÓDIGO PROBLEMÁTICO ACTUAL
derive_keystream() {
    local current_hash="$password"
    for ((i = 1; i <= iterations; i++)); do
        current_hash=$(echo -n "$current_hash" | openssl dgst -shake256 -xoflen "$byte_length" | sed 's/^.*= //')
    done
    # ... conversión manual frágil
}
```

#### **Requisitos de Solución**
- **REQ-CRYPTO-001**: ROBUSTECER derivación de claves
- **REQ-CRYPTO-002**: VALIDAR integridad de operaciones criptográficas
- **REQ-CRYPTO-003**: IMPLEMENTAR manejo de errores específico para crypto
- **REQ-CRYPTO-004**: OPTIMIZAR performance sin comprometer seguridad

#### **Enfoques de Implementación**

##### **Approach A: Crypto Library Wrapper (RECOMENDADO)**
```bash
crypto_derive_keystream() {
    local password="$1"
    local bit_length="$2"
    local iterations="$3"
    local byte_length=$(( (bit_length + 7) / 8 ))
    
    # Validar parámetros
    if [[ ! "$iterations" =~ ^[0-9]+$ ]] || [[ $iterations -lt 1 ]] || [[ $iterations -gt 1000000 ]]; then
        echo "Error: Invalid iterations parameter" >&2
        return 1
    fi
    
    if [[ $bit_length -lt 1 ]] || [[ $bit_length -gt 10000 ]]; then
        echo "Error: Invalid bit length" >&2
        return 1
    fi
    
    # Derivación inicial
    local current_hash="$password"
    local iteration=1
    
    while [[ $iteration -le $iterations ]]; do
        local new_hash
        if ! new_hash=$(safe_openssl_shake256 "$current_hash" "$byte_length"); then
            echo "Error: Key derivation failed at iteration $iteration" >&2
            return 1
        fi
        
        # Validar que el hash es válido
        if [[ ! "$new_hash" =~ ^[0-9a-fA-F]+$ ]]; then
            echo "Error: Invalid hash format at iteration $iteration" >&2
            return 1
        fi
        
        current_hash="$new_hash"
        ((iteration++))
    done
    
    # Convertir hex a binario de forma segura
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
    
    # Truncar a longitud exacta
    echo "${binary:0:$bit_length}"
    return 0
}

hex_to_binary() {
    local hex="$1"
    local binary=""
    
    # Validar input hex
    if [[ ! "$hex" =~ ^[0-9a-fA-F]{2}$ ]]; then
        echo "Error: Invalid hex byte: $hex" >&2
        return 1
    fi
    
    # Convertir usando array lookup (más rápido y seguro)
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
    
    # Convertir a minúsculas para lookup
    hex="${hex,,}"
    
    # Buscar en tabla
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
        # Verificar disponibilidad de OpenSSL
        if ! command -v openssl >/dev/null 2>&1; then
            echo "Error: OpenSSL not available" >&2
            return 1
        fi
        
        # Verificar soporte SHAKE-256
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

# Uso
derive_keystream_with_retry() {
    crypto_with_retry crypto_derive_keystream "$@"
}
```

#### **Documentación de Referencia**
- [OpenSSL Command Line Utilities](https://www.openssl.org/docs/man3.0/man1/)
- [SHAKE-256 Specification - NIST FIPS 202](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf)
- [Cryptographic Best Practices](https://owasp.org/www-project-cryptographic-storage-cheat-sheet/)

---

## 🏗️ ARQUITECTURA Y DISEÑO

### Arquitectura Propuesta v3.0

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

### Principios de Diseño

#### **PRINCIPIO 1: Defense in Depth**
- Múltiples capas de validación
- Cada componente independiente y robusto
- Fallos graceful sin comprometer seguridad

#### **PRINCIPIO 2: Fail-Safe Defaults**
- Configuración más restrictiva por defecto
- Errores resultan en operación más segura
- Sin privilegios especiales requeridos

#### **PRINCIPIO 3: Least Privilege**
- Eliminar completamente privilegios root
- Minimizar permisos de archivo
- Scope limitado para variables sensibles

#### **PRINCIPIO 4: Input Validation**
- Validar todo input en multiple puntos
- Whitelist approach vs blacklist
- Sanitización before processing

---

## 🔧 ESPECIFICACIONES TÉCNICAS DETALLADAS

### Estructura de Módulos Propuesta

```bash
#!/usr/bin/env bash
# SCypher v3.0 - Security Enhanced

# =============================================================================
# MÓDULO 1: CONFIGURACIÓN Y CONSTANTES
# =============================================================================
readonly VERSION="3.0-Security-Enhanced"
readonly MIN_BASH_VERSION=4
readonly MAX_INPUT_LENGTH=1000
readonly MAX_FILE_SIZE_KB=100
readonly CRYPTO_TIMEOUT=30
readonly MAX_ITERATIONS=1000000

# =============================================================================
# MÓDULO 2: FUNCIONES DE UTILIDAD Y VALIDACIÓN
# =============================================================================
validate_input() { ... }
validate_file_path() { ... }
validate_bip39_words() { ... }
sanitize_input() { ... }

# =============================================================================
# MÓDULO 3: MANEJO SEGURO DE ARCHIVOS
# =============================================================================
safe_file_read() { ... }
safe_file_write() { ... }
validate_output_path() { ... }

# =============================================================================
# MÓDULO 4: OPERACIONES CRIPTOGRÁFICAS SEGURAS
# =============================================================================
safe_openssl_shake256() { ... }
crypto_derive_keystream() { ... }
crypto_xor_operation() { ... }
crypto_state_manager() { ... }

# =============================================================================
# MÓDULO 5: GESTIÓN DE MEMORIA Y LIMPIEZA
# =============================================================================
register_sensitive_var() { ... }
cleanup_sensitive_data() { ... }
setup_automatic_cleanup() { ... }

# =============================================================================
# MÓDULO 6: INTERFAZ DE USUARIO
# =============================================================================
show_main_menu() { ... }
handle_user_input() { ... }
display_results() { ... }

# =============================================================================
# MÓDULO 7: FLUJO PRINCIPAL Y ORQUESTACIÓN
# =============================================================================
main() { ... }
process_arguments() { ... }
coordinate_operations() { ... }
```

---

## ✅ LISTA DE VERIFICACIÓN DE IMPLEMENTACIÓN

### Checklist de Seguridad Crítica

#### **🔴 CRÍTICO - DEBE IMPLEMENTARSE**
- [ ] **SEC-001**: Eliminar completamente verificación de privilegios root
- [ ] **SEC-002**: Implementar validación robusta de entrada (whitelist)
- [ ] **SEC-003**: Prevenir path traversal en manejo de archivos
- [ ] **SEC-004**: Validar salida de todos los comandos OpenSSL
- [ ] **SEC-005**: Implementar limpieza automática de memoria sensible
- [ ] **SEC-006**: Añadir timeouts a operaciones criptográficas
- [ ] **SEC-007**: Validar integridad de operaciones crypto end-to-end

#### **🟡 IMPORTANTE - DEBE IMPLEMENTARSE**
- [ ] **IMP-001**: Implementar logging de errores para debugging
- [ ] **IMP-002**: Añadir validación de checksums BIP39 más robusta
- [ ] **IMP-003**: Mejorar manejo de errores con mensajes específicos
- [ ] **IMP-004**: Implementar progress indicators para operaciones largas
- [ ] **IMP-005**: Añadir validación de performance (tiempo máximo)

#### **🟢 DESEABLE - PUEDE IMPLEMENTARSE**
- [ ] **DES-001**: Añadir soporte para múltiples algoritmos hash
- [ ] **DES-002**: Implementar compresión opcional de output
- [ ] **DES-003**: Añadir modo batch para múltiples archivos
- [ ] **DES-004**: Implementar configuración via archivo config

### Checklist de Compatibilidad

#### **Compatibilidad Funcional**
- [ ] **COMP-001**: Mantener todos los argumentos CLI existentes
- [ ] **COMP-002**: Preservar formato de salida exacto
- [ ] **COMP-003**: Mantener compatibilidad con archivos v2.0
- [ ] **COMP-004**: Preservar colores y formato de UI
- [ ] **COMP-005**: Mantener modo silent funcionando igual

#### **Compatibilidad de Sistema**
- [ ] **SYS-001**: Verificar funcionamiento en Linux
- [ ] **SYS-002**: Verificar funcionamiento en macOS
- [ ] **SYS-003**: Verificar funcionamiento en Windows (WSL/Cygwin)
- [ ] **SYS-004**: Testear con Bash 4.0, 4.4, 5.0+
- [ ] **SYS-005**: Verificar con OpenSSL 1.1.1 y 3.0+

---

## 🧪 PLAN DE TESTING

### Testing de Seguridad

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
# Ejecutar y verificar que no hay datos sensibles en /proc/PID/mem
```

#### **Crypto Validation Tests**
```bash
# Test 1: Reversibilidad
original="abandon ability able about above absent absorb abstract absurd abuse access accident"
encrypted=$(echo "$original" | ./scypher_v3.sh -s)
decrypted=$(echo "$encrypted" | ./scypher_v3.sh -s)
[[ "$original" == "$decrypted" ]] || echo "FAIL: Reversibility test"

# Test 2: Checksum Validation
# Verificar que tanto input como output tienen checksums BIP39 válidos

# Test 3: Determinismo
# Mismo input + password debe producir mismo output

# Test 4: Entropia
# Output debe pasar tests de randomness básicos
```

### Performance Testing

#### **Benchmarks Requeridos**
```bash
# Test de Performance - Diferentes tamaños
time echo "12_word_seed..." | ./scypher_v3.sh -s
time echo "24_word_seed..." | ./scypher_v3.sh -s

# Test de Iteraciones
time echo "seed" | timeout 30s ./scypher_v3.sh -s  # 1000 iteraciones
time echo "seed" | timeout 60s ./scypher_v3.sh -s  # 10000 iteraciones

# Memory Usage
valgrind --tool=massif ./scypher_v3.sh < test_input.txt
```

---

## 📚 REFERENCIAS Y DOCUMENTACIÓN

### Documentación Criptográfica
- **[BIP39 Specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)** - Estándar oficial BIP39
- **[NIST FIPS 202](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf)** - SHA-3 y SHAKE specification
- **[RFC 7539](https://tools.ietf.org/html/rfc7539)** - ChaCha20-Poly1305 (referencia para AEAD)

### Documentación de Seguridad
- **[OWASP Secure Coding Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)**
- **[OWASP Input Validation Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)**
- **[OWASP Command Injection Prevention](https://owasp.org/www-community/attacks/Command_Injection)**
- **[OWASP Path Traversal](https://owasp.org/www-community/attacks/Path_Traversal)**

### Documentación de Bash
- **[Bash Manual - GNU](https://www.gnu.org/software/bash/manual/bash.html)**
- **[Bash Security Best Practices](https://mywiki.wooledge.org/BashFAQ/050)**
- **[ShellCheck - Static Analysis](https://www.shellcheck.net/)**

### Documentación de OpenSSL
- **[OpenSSL Command Line Utilities](https://www.openssl.org/docs/man3.0/man1/)**
- **[OpenSSL SHAKE-256 Usage](https://www.openssl.org/docs/man3.0/man1/openssl-dgst.html)**

### Herramientas de Testing
- **[Bats - Bash Automated Testing](https://github.com/bats-core/bats-core)**
- **[ShellSpec - BDD Testing Framework](https://shellspec.info/)**
- **[Valgrind - Memory Analysis](https://valgrind.org/)**

---

## 🛠️ HERRAMIENTAS DE DESARROLLO RECOMENDADAS

### Análisis Estático
```bash
# ShellCheck - Análisis de sintaxis y mejores prácticas
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

# Bandit equivalente para Bash (custom script)
./security_audit.sh scypher_v3.sh

# SAST scanning
semgrep --config=bash-security scypher_v3.sh
```

---

## 📋 TEMPLATE DE IMPLEMENTACIÓN

### Estructura de Archivo Sugerida

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
    # Use Approach A: Whitelist Estricta
}

validate_file_path() {
    # IMPLEMENTATION REQUIRED: REQ-FILE-001 through REQ-FILE-004
    # Use Approach A: Validación Completa de Path
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
    # Use Approach A: Limpieza Automática por Patrón
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

## 🎯 CRITERIOS DE ÉXITO

### Definición de "Terminado" (Definition of Done)

Una implementación se considera **COMPLETA** cuando:

1. **✅ SEGURIDAD**:
   - Pasa todos los tests de penetración
   - No requiere privilegios root
   - Resiste ataques de inyección de comandos
   - Previene path traversal

2. **✅ FUNCIONALIDAD**:
   - 100% compatible con SCypher v2.0
   - Mismo output para mismo input
   - Todos los modos (interactivo, CLI, silent) funcionan
   - UI preservada exactamente

3. **✅ ROBUSTEZ**:
   - Maneja gracefully todos los errores
   - No crashes con inputs maliciosos
   - Performance aceptable (< 30s para 24 palabras)
   - Memory usage controlado

4. **✅ CALIDAD DE CÓDIGO**:
   - Pasa ShellCheck sin warnings
   - Código documentado y legible
   - Estructura modular y mantenible
   - Tests automatizados incluidos

### Métricas de Calidad

| Métrica | Objetivo Mínimo | Objetivo Ideal |
|---------|----------------|----------------|
| **Security Score** | 95% | 100% |
| **Test Coverage** | 80% | 95% |
| **Performance** | < 30s | < 10s |
| **Memory Usage** | < 100MB | < 50MB |
| **Code Quality** | ShellCheck ✅ | ShellCheck ✅ + Clean |

---

## 🔄 PLAN DE MIGRACIÓN

### Estrategia de Migración de v2.0 a v3.0

#### **Fase 1: Validación de Compatibilidad**
1. Crear test suite con casos de v2.0
2. Verificar outputs idénticos
3. Validar todos los modos de operación

#### **Fase 2: Implementación Gradual**
1. Implementar módulo por módulo
2. Testing continuo después de cada módulo
3. Rollback plan si hay problemas

#### **Fase 3: Validación Final**
1. Testing exhaustivo de seguridad
2. Performance benchmarking
3. User acceptance testing

### Retrocompatibilidad Garantizada

```bash
# Test de compatibilidad automático
compatibility_test() {
    local test_phrase="abandon ability able about above absent absorb abstract absurd abuse access accident"
    local test_password="TestPassword123"
    local test_iterations=1000
    
    # Test con v2.0
    local v2_output
    v2_output=$(echo "$test_phrase" | echo "$test_password" | echo "$test_iterations" | ./scypher_v2.sh -s)
    
    # Test con v3.0
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

## 🚨 ALERTAS Y CONSIDERACIONES ESPECIALES

### ⚠️ ADVERTENCIAS CRÍTICAS PARA EL IMPLEMENTADOR

#### **ALERTA 1: NO CAMBIAR ALGORITMO CRIPTOGRÁFICO**
```bash
# ❌ NO HACER ESTO - Rompe compatibilidad
new_keystream=$(some_other_hash_function "$password")

# ✅ HACER ESTO - Mantener algoritmo exacto
keystream=$(safe_openssl_shake256 "$password" "$byte_length")
```

#### **ALERTA 2: PRESERVAR ORDEN DE OPERACIONES XOR**
```bash
# ❌ NO CAMBIAR - El orden importa para reversibilidad
result_bits=$(xor_bits "$keystream" "$seed_bits")  # WRONG ORDER

# ✅ MANTENER - Orden original de v2.0
result_bits=$(xor_bits "$seed_bits" "$keystream")  # CORRECT ORDER
```

#### **ALERTA 3: CHECKSUM BIP39 CRÍTICO**
```bash
# La función recalculate_bip39_checksum es CRÍTICA
# NO simplificar sin entender completamente
# Cualquier cambio debe ser exhaustivamente testeado
```

### 🔍 PUNTOS DE ATENCIÓN ESPECIAL

#### **PUNTO 1: Conversiones Binarias**
- Las funciones `decimal_to_binary` y `binary_to_decimal` son críticas
- Cualquier error aquí corrompe completamente el resultado
- DEBE mantener compatibilidad exacta con implementación v2.0

#### **PUNTO 2: Manejo de Espacios en Input**
```bash
# v2.0 maneja espacios de forma específica
# DEBE preservar este comportamiento exacto
read -ra words <<< "$input"  # Comportamiento específico
```

#### **PUNTO 3: Colores y UI**
- Los códigos de color ANSI deben preservarse exactamente
- La experiencia de usuario debe ser idéntica
- Menu flows deben mantenerse iguales

#### **PUNTO 4: Mensajes de Error**
- Formato exacto de mensajes de error debe preservarse
- Esto incluye capitalización, puntuación, formato
- Scripts pueden depender de estos mensajes

---

## 🧩 TROUBLESHOOTING GUIDE PARA IMPLEMENTACIÓN

### Problemas Comunes y Soluciones

#### **PROBLEMA: OpenSSL Output Parsing Falla**
```bash
# SÍNTOMA
Error: Invalid hash format at iteration 1

# DIAGNÓSTICO
echo "test" | openssl dgst -shake256 -xoflen 32
# Verificar formato exacto de salida

# SOLUCIÓN
# Ajustar regex en safe_openssl_shake256
if [[ ! "$result" =~ ^[A-Za-z0-9()=\ \-]+$ ]]; then
```

#### **PROBLEMA: Path Traversal Validation Muy Restrictiva**
```bash
# SÍNTOMA
Error: File access outside current directory not allowed

# DIAGNÓSTICO
realpath -s "./test.txt"
pwd
# Verificar paths resueltos

# SOLUCIÓN
# Permitir subdirectorios legítimos
if [[ "$resolved_path" == "$current_dir"* ]] || [[ "$resolved_path" == "$current_dir/"* ]]; then
```

#### **PROBLEMA: Memory Cleanup No Funciona**
```bash
# SÍNTOMA
Variables sensibles visibles en /proc/PID/mem

# DIAGNÓSTICO
declare -p | grep SENSITIVE_
# Verificar variables registradas

# SOLUCIÓN
# Asegurar que todas las variables se registran
register_sensitive_var "password"
register_sensitive_var "keystream"
```

#### **PROBLEMA: BIP39 Checksum Falla**
```bash
# SÍNTOMA
Error: Invalid BIP39 checksum in output

# DIAGNÓSTICO
# Verificar que calculate_checksum_bits funciona correctamente
echo "10101010..." | calculate_checksum_bits

# SOLUCIÓN
# Revisar conversión hex-to-binary en calculate_checksum_bits
# Asegurar que echo -e funciona correctamente en el sistema
```

### Scripts de Debugging

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

## 📖 DOCUMENTACIÓN PARA EL USUARIO FINAL

### README.md Template para v3.0

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

## 🎓 GUÍA DE IMPLEMENTACIÓN PASO A PASO

### Paso 1: Preparación del Entorno
```bash
# 1. Clonar el código existente
cp scypher_v2.sh scypher_v3.sh

# 2. Crear directorio de testing
mkdir -p tests/{unit,integration,security}

# 3. Instalar herramientas de desarrollo
# Ubuntu/Debian:
sudo apt install shellcheck bats valgrind

# macOS:
brew install shellcheck bats-core valgrind
```

### Paso 2: Implementación por Prioridad
```bash
# ORDEN DE IMPLEMENTACIÓN RECOMENDADO:

# 1. CRÍTICO - Eliminar root check (15 min)
#    Buscar y eliminar verificación de privilegios

# 2. CRÍTICO - Input validation (2 horas)
#    Implementar validate_input() con whitelist

# 3. CRÍTICO - File handling (1 hora)
#    Implementar safe_file_read() y validaciones

# 4. IMPORTANTE - Crypto wrapper (3 horas)
#    Implementar safe_openssl_shake256() y validaciones

# 5. IMPORTANTE - Memory cleanup (1 hora)
#    Implementar cleanup automático simplificado

# 6. TESTING - Security tests (2 horas)
#    Crear test suite completo

# TIEMPO TOTAL ESTIMADO: 9-10 horas
```

### Paso 3: Validación Continua
```bash
# Después de cada módulo implementado:

# 1. Ejecutar tests automáticos
./run_tests.sh

# 2. Verificar compatibilidad
./compatibility_test.sh

# 3. Análisis de seguridad
shellcheck scypher_v3.sh
./security_audit.sh

# 4. Test manual básico
echo "abandon ability able about above absent absorb abstract absurd abuse access accident" | ./scypher_v3.sh -s
```

---

## 📋 CONCLUSIÓN Y PRÓXIMOS PASOS

### Resumen Ejecutivo del PRD

Este documento especifica completamente los requisitos para transformar SCypher v2.0 en una herramienta criptográfica de grado de producción que:

1. **Elimina todos los riesgos de seguridad críticos** identificados en la auditoría
2. **Mantiene 100% compatibilidad funcional** con la versión existente
3. **Proporciona múltiples enfoques de implementación** para cada problema
4. **Include comprehensive testing and validation** procedures

### Orden de Prioridad de Implementación

1. **🔴 CRÍTICO** (Implementar PRIMERO): Privilegios root, validación de entrada, manejo de archivos
2. **🟡 IMPORTANTE** (Implementar SEGUNDO): Operaciones crypto, limpieza de memoria
3. **🟢 DESEABLE** (Implementar ÚLTIMO): Mejoras de UX, optimizaciones adicionales

### Criterio de Éxito Final

La implementación será exitosa cuando:
- ✅ Pase todos los security tests sin excepciones
- ✅ Mantenga compatibilidad 100% con v2.0
- ✅ No requiera privilegios elevados para ninguna operación
- ✅ Resista todos los ataques de penetración definidos

### 🎯 CALL TO ACTION

**Para cualquier IA que implemente este PRD:**

1. **LEE COMPLETAMENTE** este documento antes de comenzar
2. **IMPLEMENTA EN ORDEN DE PRIORIDAD** - Crítico primero
3. **TESTA CONTINUAMENTE** después de cada módulo
4. **PRESERVA COMPATIBILIDAD** - Nunca cambies algoritmos crypto
5. **DOCUMENTA TODOS LOS CAMBIOS** realizados

**Recursos de soporte disponibles:**
- Código fuente completo de v2.0 (proporcionado)
- Test cases de ejemplo en este PRD
- Documentación técnica completa enlazada
- Scripts de debugging incluidos

---

**¡ÉXITO EN LA IMPLEMENTACIÓN!** 🚀

---

*Este PRD fue creado con el objetivo de que cualquier IA competente pueda implementar las mejoras de seguridad requeridas siguiendo las especificaciones exactas y manteniendo la máxima calidad de código.*