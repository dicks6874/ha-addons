FROM alpine:3.18

# Instalar davfs2, jq y dependencias
RUN apk add --no-cache davfs2 bash jq

# Crear el directorio del punto de montaje
RUN mkdir -p /data/mount

# Copiar el script de ejecución
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Establecer el punto de entrada
ENTRYPOINT ["/run.sh"]