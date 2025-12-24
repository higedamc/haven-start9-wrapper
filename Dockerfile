# Haven Start9 Package - Multi-stage build
# Build optimized container image for amd64 and arm64

# ==============================================================================
# Stage 1: Builder
# ==============================================================================
FROM --platform=linux/amd64 golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    git \
    build-base \
    openssl \
    ca-certificates

WORKDIR /build

# Copy Haven source from submodule
COPY haven/go.mod haven/go.sum ./
RUN go mod download

# Copy Haven source code
COPY haven/ ./

# Build for amd64 (Start9 target architecture)
RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o haven .

# ==============================================================================
# Stage 2: Runtime
# ==============================================================================
FROM --platform=linux/amd64 alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tor \
    tini \
    bash \
    curl \
    jq \
    wget \
    su-exec

# Install yq from GitHub releases (not available in Alpine repos)
RUN wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.50.1/yq_linux_amd64" && \
    chmod +x /usr/local/bin/yq

# Create non-root user
RUN adduser -D -u 1000 haven

# Create necessary directories
# Both Tor and Haven run as 'haven' user for security
RUN mkdir -p /data/db /data/blossom /data/backups /var/lib/tor/haven && \
    chown -R haven:haven /data && \
    chown -R haven:haven /var/lib/tor && \
    chmod 700 /var/lib/tor/haven

WORKDIR /app

# Copy binary from builder
COPY --from=builder /build/haven .

# Copy templates directory (for web interface)
COPY --from=builder /build/templates ./templates

# Copy relay list examples
COPY --from=builder /build/relays_blastr.example.json ./relays_blastr.example.json
COPY --from=builder /build/relays_import.example.json ./relays_import.example.json

# Copy wrapper scripts
COPY docker_entrypoint.sh /usr/local/bin/
COPY torrc /etc/tor/torrc

# Copy Start9 procedure scripts
COPY assets/compat/config_get.sh /usr/local/bin/
COPY assets/compat/config_set.sh /usr/local/bin/
COPY assets/compat/properties.sh /usr/local/bin/
COPY assets/compat/check-web.sh /usr/local/bin/

# Make scripts executable
RUN chmod +x /usr/local/bin/docker_entrypoint.sh \
    /usr/local/bin/config_get.sh \
    /usr/local/bin/config_set.sh \
    /usr/local/bin/properties.sh \
    /usr/local/bin/check-web.sh

# Change ownership of /app to haven user so it can create symlinks
RUN chown -R haven:haven /app

# Expose port 3355 (Haven's default port)
EXPOSE 3355

# NOTE: We run as root in entrypoint to start Tor, then switch to haven user for Haven itself
# Use tini for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/docker_entrypoint.sh"]

