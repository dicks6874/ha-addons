FROM alpine:3.18

# Install wdfs, fuse, jq, and dependencies
RUN apk add --no-cache fuse bash jq \
 && apk add --no-cache --virtual .build-deps build-base neon-dev fuse-dev \
 && wget https://github.com/janvda/wdfs/archive/refs/tags/1.3.3.tar.gz \
 && tar -xzf 1.3.3.tar.gz \
 && cd wdfs-1.3.3 \
 && ./configure && make && make install \
 && cd .. && rm -rf wdfs-1.3.3 1.3.3.tar.gz \
 && apk del .build-deps

# Create mount point directory
RUN mkdir -p /data/mount

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Set entrypoint
ENTRYPOINT ["/run.sh"]