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

## Documentation

- [📚 Documentation Index](docs/START9-INDEX.md)
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
