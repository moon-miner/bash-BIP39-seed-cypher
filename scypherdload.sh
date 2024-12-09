 
#!/bin/bash

# URLs de la API
urls=(
    "https://api.sigmaspace.io/api/v1/tokens/e19e95429dc4566292ddda535129aa5e3c0b31d9139814a52e21508510a9b389"
    "https://api.sigmaspace.io/api/v1/tokens/01efc34d6752de5554d1d756b1fba3da094e41f8cf59904902ed90ec3e18ef43"
    "https://api.sigmaspace.io/api/v1/tokens/0f19789154bf43d1cb7cb9deb8e1603adc614506ae75e95b827b7b8c65dbb753"
    "https://api.sigmaspace.io/api/v1/tokens/aca4dd9bcd304e3bd32d21e477d7b3b840f7d50ebb85b7a6ab1cc483a7ebaa9a"
)

# Archivo temporal para almacenar el contenido base64
temp_base64="scypherBASE64.txt"
# Limpiar el archivo temporal si existe
> "$temp_base64"

# Procesar cada URL
for url in "${urls[@]}"; do
    echo "Procesando $url..."

    # Realizar la petición curl y extraer el campo description usando jq
    description=$(curl -s -X GET "$url" | jq -r '.description')

    # Añadir el contenido al archivo base64
    echo "$description" >> "$temp_base64"
done

echo "Decodificando base64 a archivo comprimido..."
base64 -d "$temp_base64" > scypher.sh.xz

echo "Descomprimiendo archivo xz..."
xz -d scypher.sh.xz

echo "Limpiando archivos temporales..."
rm "$temp_base64"

echo "Proceso completado. El script resultante es scypher.sh"
