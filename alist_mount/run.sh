#!/bin/bash

# Leer la configuración desde las opciones del complemento de HAOS
WEBDAV_URL=$(jq -r '.webdav_url' /data/options.json)
USERNAME=$(jq -r '.username' /data/options.json)
PASSWORD=$(jq -r '.password' /data/options.json)
MOUNT_POINT=$(jq -r '.mount_point' /data/options.json)

# Validar la configuración
if [ -z "$WEBDAV_URL" ] || [ "$WEBDAV_URL" = "null" ]; then
  echo "Error: webdav_url no está configurado o es inválido en /data/options.json"
  exit 1
fi
if [ -z "$USERNAME" ] || [ "$USERNAME" = "null" ]; then
  echo "Error: username no está configurado o es inválido en /data/options.json"
  exit 1
fi
if [ -z "$PASSWORD" ] || [ "$PASSWORD" = "null" ]; then
  echo "Error: password no está configurado o es inválido en /data/options.json"
  exit 1
fi
if [ -z "$MOUNT_POINT" ] || [ "$MOUNT_POINT" = "null" ]; then
  echo "Error: mount_point no está configurado o es inválido en /data/options.json. Usando /data/mount por defecto"
  MOUNT_POINT="/data/mount"
fi

# Asegurar que el punto de montaje exista
mkdir -p "$MOUNT_POINT"
if [ $? -ne 0 ]; then
  echo "Error: No se pudo crear el directorio del punto de montaje $MOUNT_POINT"
  exit 1
fi

# Crear el directorio de configuración de davfs2
mkdir -p /etc/davfs2
if [ $? -ne 0 ]; then
  echo "Error: No se pudo crear el directorio /etc/davfs2"
  exit 1
fi

# Crear el archivo de secretos con las credenciales
echo "$WEBDAV_URL $USERNAME $PASSWORD" > /etc/davfs2/secrets
chmod 600 /etc/davfs2/secrets
if [ $? -ne 0 ]; then
  echo "Error: No se pudo crear o establecer permisos para /etc/davfs2/secrets"
  exit 1
fi

# Configurar davfs2 para evitar problemas de bloqueo
echo use_locks 0 >> /etc/davfs2/davfs2.conf

# Montar el recurso WebDAV
mount -t davfs -o rw,uid=0,gid=0 "$WEBDAV_URL" "$MOUNT_POINT"
if [ $? -ne 0 ]; then
  echo "Error: No se pudo montar $WEBDAV_URL en $MOUNT_POINT"
  exit 1
fi

echo "Montado exitosamente $WEBDAV_URL en $MOUNT_POINT"

# Mantener el contenedor en ejecución
tail -f /dev/null