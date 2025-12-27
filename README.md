# Haven Start9 Wrapper

Start9 Server package for [Haven](https://github.com/bitvora/haven) - 
a self-sovereign Nostr relay suite with Blossom media server.

## About

This is a **wrapper repository** for packaging Haven for Start9 Server.
The Haven application itself is included as a git submodule.

## Repository Structure

```
haven-start9-wrapper/
├── haven/                    # Haven source (submodule)
├── Dockerfile                # Container definition
├── docker_entrypoint.sh      # Startup script
├── manifest.yaml             # Start9 package manifest
├── instructions.md           # User instructions
├── icon.png                  # Package icon
├── assets/
│   └── compat/               # Config/Properties scripts
├── docs/                     # Implementation documentation
└── Makefile                  # Build automation
```

## Features

### 📊 Database Dashboard (New!)
- **Web Interface**: View all stored Nostr events via the LAUNCH UI
- **Statistics**: See event counts by kind and database
- **Event Inspection**: Click any kind to view raw JSON data
- **Databases**: Separate views for private, chat, outbox, and inbox relays

Access at: `http://<your-onion-address>.local/dashboard`

See: [Database Dashboard Documentation](docs/database-dashboard.md)

### 🔒 Haven Relay Suite
- **Outbox Relay**: Your public notes and content
- **Inbox Relay**: Receive messages from your web of trust
- **Private Relay**: Personal encrypted storage
- **Chat Relay**: Community conversations with WoT protection

### 🌸 Blossom Media Server
- Store images, videos, and files
- SHA-256 based content addressing
- Integrated with your Nostr identity

## Documentation

- [📚 Documentation Index](docs/START9-INDEX.md)
- [📊 Database Dashboard](docs/database-dashboard.md) ⭐ **NEW**
- [🧪 Dashboard Testing Guide](docs/dashboard-testing-guide.md)
- [📋 Implementation Plan](docs/start9-packaging-plan.md)
- [📐 Technical Specification](docs/start9-technical-spec.md)
- [✅ Implementation Checklist](docs/start9-implementation-checklist.md)
- [🚀 Quick Start Guide](docs/start9-quickstart.md)
- [❓ FAQ](docs/start9-faq.md)

## Quick Start

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/YOUR_USERNAME/haven-start9-wrapper.git
cd haven-start9-wrapper

# Install dependencies
./prepare.sh

# Build package
make

# Verify
make verify
```

## 🔢 Version Management

自動バージョンアップスクリプトを使用できます：

```bash
# パッチバージョンアップ (1.1.6 → 1.1.7)
make bump-patch

# マイナーバージョンアップ (1.1.6 → 1.2.0)
make bump-minor

# メジャーバージョンアップ (1.1.6 → 2.0.0)
make bump-major

# インタラクティブモード（推奨）
make bump-version

# 現在のバージョン確認
make version-check
```

📖 詳細: [BUMP-VERSION-QUICKSTART.md](BUMP-VERSION-QUICKSTART.md)
```

## Installation on Start9

```bash
# Option 1: Sideload
# Start9 UI → System → Sideload Service → Upload haven.s9pk

# Option 2: CLI
start-cli package install haven.s9pk
```

## Development

See [Quick Start Guide](docs/start9-quickstart.md) for detailed development setup.

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md).

## License

MIT License - See [LICENSE](LICENSE)

## Links

- [Haven GitHub](https://github.com/bitvora/haven)
- [Start9 Documentation](https://docs.start9.com)
- [Nostr Protocol](https://github.com/nostr-protocol/nips)
- [Blossom Specification](https://github.com/hzrd149/blossom)

## Support

- GitHub Issues: https://github.com/YOUR_USERNAME/haven-start9-wrapper/issues
- Start9 Community: https://community.start9.com
- Nostr: @bitvora
