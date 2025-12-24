# ==============================================================================
# Haven Start9 Package Makefile
# ==============================================================================

# Package configuration
PACKAGE_ID := haven
VERSION := $(shell yq '.version' manifest.yaml 2>/dev/null || grep '^version:' manifest.yaml | head -1 | awk '{print $$2}')
ARCHITECTURES := amd64 arm64

# Docker configuration
DOCKER_IMAGE_TAG := start9/$(PACKAGE_ID)/main:$(VERSION)
DOCKER_BUILDX := DOCKER_CLI_EXPERIMENTAL=enabled docker buildx

# Build directories
BUILD_DIR := .build
ASSETS_DIR := assets

# ==============================================================================
# Default Target
# ==============================================================================

.PHONY: all
all: verify

# ==============================================================================
# Build Targets
# ==============================================================================

.PHONY: build pack package
build: $(PACKAGE_ID).s9pk
pack: build
package: build

$(PACKAGE_ID).s9pk: manifest.yaml docker-images.tar icon.png instructions.md LICENSE scripts/embassy.js
	@echo "📦 Packing Start9 package..."
	start-sdk pack

scripts/embassy.js: scripts/embassy.ts scripts/procedures/*.ts
	@echo "🔨 Bundling TypeScript to JavaScript..."
	@command -v deno >/dev/null 2>&1 || { echo >&2 "⚠️  Deno is required but not installed. Please install Deno: https://deno.land/"; exit 1; }
	deno run --allow-read --allow-write --allow-env --allow-net scripts/bundle.ts
	@echo "✅ TypeScript bundled successfully"

# ==============================================================================
# Docker Image Build
# ==============================================================================

docker-images.tar: Dockerfile docker_entrypoint.sh torrc prepare.sh haven/
	@echo "🐳 Building Docker images..."
	@./prepare.sh
	@echo "📋 Note: Building for Start9 (amd64 platform)"
	@echo "   This may take longer on Apple Silicon due to emulation"
	DOCKER_DEFAULT_PLATFORM=linux/amd64 docker build \
		--tag $(DOCKER_IMAGE_TAG) \
		.
	docker save $(DOCKER_IMAGE_TAG) -o docker-images.tar
	@echo "✅ Docker images built and saved successfully"

.PHONY: docker-images-multiarch
docker-images-multiarch: Dockerfile docker_entrypoint.sh torrc prepare.sh haven/
	@echo "🐳 Building Docker images for $(ARCHITECTURES)..."
	@./prepare.sh
	$(DOCKER_BUILDX) build \
		--platform linux/amd64,linux/arm64 \
		--tag $(DOCKER_IMAGE_TAG) \
		--output type=oci,dest=docker-images.tar \
		.
	@echo "✅ Multi-architecture Docker images built successfully"

# ==============================================================================
# Verification
# ==============================================================================

.PHONY: verify
verify: $(PACKAGE_ID).s9pk
	@echo "🔍 Verifying Start9 package..."
	start-sdk verify s9pk $(PACKAGE_ID).s9pk
	@echo "✅ Package verification successful"

# ==============================================================================
# Installation
# ==============================================================================

.PHONY: install
install: $(PACKAGE_ID).s9pk
	@echo "📥 Installing Haven on Start9..."
	start-cli package install $(PACKAGE_ID).s9pk
	@echo "✅ Installation complete"

# ==============================================================================
# Testing
# ==============================================================================

.PHONY: test
test:
	@echo "🧪 Running tests..."
	@echo "  → Testing Haven binary..."
	@cd haven && go test -v ./...
	@echo "  → Testing Docker build..."
	@docker build --target builder -t haven-test .
	@echo "  → Testing entrypoint script..."
	@bash -n docker_entrypoint.sh
	@echo "✅ All tests passed"

.PHONY: test-docker
test-docker: docker-images.tar
	@echo "🐳 Testing Docker container..."
	@docker load -i docker-images.tar
	@docker run --rm $(DOCKER_IMAGE_TAG) /app/haven --help
	@echo "✅ Docker test passed"

# ==============================================================================
# Development Helpers
# ==============================================================================

.PHONY: dev-build
dev-build:
	@echo "🔨 Building for development (native architecture)..."
	@if [ -z "$(VERSION)" ]; then \
		echo "⚠️  VERSION not detected, using 'dev'"; \
		docker build -t start9/$(PACKAGE_ID)/main:dev .; \
	else \
		docker build -t $(DOCKER_IMAGE_TAG) .; \
	fi
	@echo "✅ Development build complete"

.PHONY: dev-run
dev-run: dev-build
	@echo "🚀 Running Haven in development mode..."
	@if [ ! -f dev-config.env ]; then \
		echo "⚠️  dev-config.env not found. Creating from template..."; \
		echo "OWNER_NPUB=npub1..." > dev-config.env; \
		echo "Please edit dev-config.env with your npub"; \
		exit 1; \
	fi
	@echo "📝 Loading configuration from dev-config.env"
	@echo "💡 Press Ctrl+C to stop Haven"
	@echo ""
	docker run --rm -it \
		-p 3355:3355 \
		--env-file dev-config.env \
		-v $(PWD)/.dev-data:/data \
		$(DOCKER_IMAGE_TAG)

.PHONY: dev-run-bg
dev-run-bg: dev-build
	@echo "🚀 Running Haven in background mode..."
	@if [ ! -f dev-config.env ]; then \
		echo "⚠️  dev-config.env not found. Creating from template..."; \
		echo "OWNER_NPUB=npub1..." > dev-config.env; \
		echo "Please edit dev-config.env with your npub"; \
		exit 1; \
	fi
	@echo "📝 Loading configuration from dev-config.env"
	docker run --rm -d \
		--name haven-dev \
		-p 3355:3355 \
		--env-file dev-config.env \
		-v $(PWD)/.dev-data:/data \
		$(DOCKER_IMAGE_TAG)
	@echo "✅ Haven is running in background"
	@echo "📋 View logs: docker logs -f haven-dev"
	@echo "🛑 Stop: docker stop haven-dev"

.PHONY: dev-shell
dev-shell: dev-build
	@echo "🐚 Opening shell in container..."
	docker run --rm -it \
		-v $(PWD)/.dev-data:/data \
		--entrypoint /bin/sh \
		$(DOCKER_IMAGE_TAG)

.PHONY: dev-logs
dev-logs:
	@echo "📋 Viewing Haven logs..."
	docker logs -f haven-dev

.PHONY: dev-stop
dev-stop:
	@echo "🛑 Stopping Haven..."
	docker stop haven-dev || true
	@echo "✅ Haven stopped"

# ==============================================================================
# Asset Generation
# ==============================================================================

.PHONY: icon
icon:
	@echo "🎨 Generating icon..."
	@if [ -f "icon.png" ]; then \
		echo "  → icon.png already exists"; \
	else \
		echo "  ⚠️  icon.png not found. Please create a 256x256px PNG icon."; \
		exit 1; \
	fi

.PHONY: scripts
scripts:
	@echo "📝 Setting up compat scripts..."
	@mkdir -p $(ASSETS_DIR)/compat
	@chmod +x $(ASSETS_DIR)/compat/*.sh || true
	@echo "✅ Scripts ready"

# ==============================================================================
# Cleaning
# ==============================================================================

.PHONY: clean
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -f $(PACKAGE_ID).s9pk
	@rm -f docker-images.tar
	@rm -rf $(BUILD_DIR)
	@rm -rf .dev-data
	@echo "✅ Clean complete"

.PHONY: clean-all
clean-all: clean
	@echo "🧹 Cleaning all including Docker images..."
	@docker rmi $(DOCKER_IMAGE_TAG) 2>/dev/null || true
	@docker system prune -f
	@echo "✅ Deep clean complete"

# ==============================================================================
# Release Management
# ==============================================================================

.PHONY: release
release: clean verify
	@echo "🚀 Preparing release for version $(VERSION)..."
	@mkdir -p releases
	@cp $(PACKAGE_ID).s9pk releases/$(PACKAGE_ID)-$(VERSION).s9pk
	@cd releases && sha256sum $(PACKAGE_ID)-$(VERSION).s9pk > $(PACKAGE_ID)-$(VERSION).s9pk.sha256
	@echo "✅ Release package created: releases/$(PACKAGE_ID)-$(VERSION).s9pk"
	@echo "📋 SHA256:"
	@cat releases/$(PACKAGE_ID)-$(VERSION).s9pk.sha256

.PHONY: changelog
changelog:
	@echo "📝 Generating changelog..."
	@git log --oneline --decorate --graph --all > CHANGELOG.txt
	@echo "✅ Changelog generated: CHANGELOG.txt"

# ==============================================================================
# Documentation
# ==============================================================================

.PHONY: docs
docs:
	@echo "📚 Building documentation..."
	@echo "  → README.md"
	@echo "  → instructions.md"
	@echo "  → docs/"
	@echo "✅ Documentation ready"

# ==============================================================================
# Git Submodule Management
# ==============================================================================

.PHONY: submodule-init
submodule-init:
	@echo "📦 Initializing Haven submodule..."
	@git submodule update --init --recursive
	@echo "✅ Submodule initialized"

.PHONY: submodule-update
submodule-update:
	@echo "🔄 Updating Haven submodule..."
	@git submodule update --remote --merge
	@echo "✅ Submodule updated"

# ==============================================================================
# Help
# ==============================================================================

.PHONY: help
help:
	@echo "Haven Start9 Package - Makefile Commands"
	@echo ""
	@echo "Build Commands:"
	@echo "  make build          - Build the Start9 package"
	@echo "  make verify         - Build and verify the package"
	@echo "  make install        - Install package on Start9"
	@echo ""
	@echo "Development Commands:"
	@echo "  make dev-build      - Quick build for development (native arch)"
	@echo "  make dev-run        - Run Haven interactively (Ctrl+C to stop)"
	@echo "  make dev-run-bg     - Run Haven in background"
	@echo "  make dev-logs       - View Haven logs (background mode)"
	@echo "  make dev-stop       - Stop Haven (background mode)"
	@echo "  make dev-shell      - Open shell in container"
	@echo "  make test           - Run all tests"
	@echo "  make test-docker    - Test Docker container"
	@echo ""
	@echo "Release Commands:"
	@echo "  make release        - Create release package"
	@echo "  make changelog      - Generate changelog"
	@echo ""
	@echo "Maintenance Commands:"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make clean-all      - Remove everything including Docker images"
	@echo "  make submodule-init - Initialize Haven submodule"
	@echo "  make submodule-update - Update Haven submodule"
	@echo ""
	@echo "Info:"
	@echo "  Package ID: $(PACKAGE_ID)"
	@echo "  Version:    $(VERSION)"
	@echo "  Architectures: $(ARCHITECTURES)"

# ==============================================================================
# Phony Targets Declaration
# ==============================================================================

.PHONY: all build verify install test test-docker dev-build dev-run dev-shell \
        icon scripts clean clean-all release changelog docs submodule-init \
        submodule-update help

