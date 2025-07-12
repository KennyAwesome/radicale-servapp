# Use the official Alpine-based image for a small footprint
FROM alpine:3.12

# Arguments for building the image (can be overridden during build)
ARG COMMIT_ID
ENV COMMIT_ID=${COMMIT_ID}
ARG VERSION
ENV VERSION=${VERSION:-3.0.6} # You can specify a different Radicale version
ARG BUILD_UID
ENV BUILD_UID=${BUILD_UID:-2999}
ARG BUILD_GID
ENV BUILD_GID=${BUILD_GID:-2999}

# Metadata labels for the Docker image
LABEL maintainer="Thomas Queste <tom@tomsquest.com>" \
      org.label-schema.description="Enhanced Docker image for Radicale, the CalDAV/CardDAV server" \
      org.label-schema.url="https://github.com/Kozea/Radicale" \
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-ref=$COMMIT_ID \
      org.label-schema.vcs-url="https://github.com/tomsquest/docker-radicale"

# Install dependencies, create user/group, and set up directories
RUN set -xe \
    && apk add --no-cache python3 py3-pip curl \
    && pip install --no-cache-dir radicale==$VERSION passlib[bcrypt] pytz ldap3 \
    && addgroup -g $BUILD_GID radicale \
    && adduser -D -s /bin/false -H -u $BUILD_UID -G radicale radicale \
    && mkdir -p /config /data \
    && chmod -R 770 /data \
    && chown -R radicale:radicale /data \
    && rm -fr /root/.cache

# Copy the configuration files from the 'config' directory in your Git repo
# These will be copied into the /config directory inside the Docker image.
COPY config/ /config/

# Healthcheck to ensure the service is running
HEALTHCHECK --interval=30s --retries=3 CMD curl --fail http://localhost:5232 || exit 1

# Define volume for persistent data. Configuration is now part of the image.
VOLUME /data

# Expose the default Radicale port
EXPOSE 5232

# Create a simple entrypoint script if not using a more complex one from a base image.
# For Radicale, often just starting the service is enough if permissions are handled by the Dockerfile.
RUN echo '#!/bin/sh' > /usr/local/bin/docker-entrypoint.sh \
    && echo 'exec radicale' >> /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

# Default command to run Radicale
CMD ["radicale"]
