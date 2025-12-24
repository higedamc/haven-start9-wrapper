# Contributing to Haven Start9 Wrapper

Thank you for your interest in contributing!

## How to Contribute

1. **Fork the repository**
2. **Create a branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Test thoroughly**
5. **Commit** (`git commit -m 'feat: add amazing feature'`)
6. **Push** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

## Development Setup

See [Quick Start Guide](docs/start9-quickstart.md) for detailed setup instructions.

## Code Style

- Follow Go conventions for Haven code
- Use shellcheck for shell scripts
- Format YAML with yamllint
- Use markdownlint for documentation

## Testing

Before submitting a PR:

```bash
# Run tests
make test

# Build package
make

# Verify package
make verify
```

## Commit Messages

Use conventional commits:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring

## Questions?

- Open an issue
- Join Start9 Community
- Contact @bitvora on Nostr
