#!/bin/bash

# URL que contiene el scypherdload.sh
url="https://api.sigmaspace.io/api/v1/tokens/b1715708cdc9c9f42f7de433061711b2ad79814a2e837e6aa9dd9de16b82d9d4"

echo "Obteniendo scypherdload.sh desde la API..."
# Obtener y decodificar el contenido directamente a scypherdload.sh
curl -s -X GET "$url" | jq -r '.description' | base64 -d > scypherdload.sh

# Dar permisos de ejecución
chmod +x scypherdload.sh

echo "Ejecutando scypherdload.sh..."
./scypherdload.sh

echo "Limpiando archivo temporal..."
rm scypherdload.sh

echo "Proceso completado."
