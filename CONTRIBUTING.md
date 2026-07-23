# Contributing to OID

Thank you for your interest in contributing to OID (OpenVPN Isolated Docker)! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Commit Messages](#commit-messages)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/oid.git
   cd oid
   ```
3. Create a branch for your changes:
   ```bash
   git checkout -b feat/your-feature-name
   ```

## Development Setup

### Prerequisites

- Docker 20.10+ with Docker Compose v2
- Linux host (required for TUN device support)
- Git
- ShellCheck (for linting shell scripts)

### Local Development

1. Build the Docker image:
   ```bash
   docker build -t oid:dev .
   ```

2. Run tests (if applicable):
   ```bash
   # Test the entrypoint script
   docker run --rm --device /dev/net/tun --cap-add NET_ADMIN oid:dev
   ```

3. Lint the Dockerfile:
   ```bash
   hadolint Dockerfile
   ```

4. Lint shell scripts:
   ```bash
   shellcheck scripts/entrypoint.sh
   ```

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

When creating a bug report, include:

1. **Clear title** - Summarize the issue concisely
2. **Environment details** - Docker version, OS, kernel version
3. **Steps to reproduce** - Exact steps to trigger the bug
4. **Expected behavior** - What you expected to happen
5. **Actual behavior** - What actually happened
6. **Logs** - Relevant container logs (`docker compose logs`)

### Suggesting Features

Feature suggestions are welcome! Please provide:

1. **Problem description** - What problem does this solve?
2. **Proposed solution** - How should it work?
3. **Alternatives considered** - Other approaches you considered
4. **Use cases** - Real-world scenarios where this would be useful

### Contributing Code

1. **Small, focused changes** - One feature/fix per PR
2. **Follow existing patterns** - Match the code style of the project
3. **Add tests** - If adding new functionality
4. **Update documentation** - If changing behavior or adding features

## Pull Request Process

1. **Update documentation** - README.md, comments, or docs/ as needed
2. **Test your changes** - Verify the Docker image builds and runs correctly
3. **Follow commit conventions** - Use conventional commit messages
4. **Create a PR** - Fill out the PR template completely
5. **Respond to feedback** - Address review comments promptly

### PR Checklist

- [ ] Docker image builds successfully
- [ ] Entrypoint script runs without errors
- [ ] Documentation is updated (if applicable)
- [ ] Commit messages follow conventional format
- [ ] No secrets or sensitive data in commits

## Coding Standards

### Dockerfile

- Use multi-stage builds for smaller images
- Pin base image versions (e.g., `alpine:3.20`)
- Use `--no-cache` for package installations
- Run as non-root user when possible
- Add health checks

### Shell Scripts

- Use `#!/bin/bash` shebang
- Enable `set -euo pipefail`
- Quote all variables
- Use functions for reusable code
- Add comments for complex logic

### Docker Compose

- Use descriptive service names
- Add health checks for all services
- Set resource limits
- Use environment variables for configuration
- Document all options with comments

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(docker): add WireGuard support
fix(scripts): handle missing .ovpn file gracefully
docs(readme): add troubleshooting section
chore(ci): update Trivy action version
```

## Questions?

If you have questions about contributing, feel free to:

1. Open an issue with the "question" label
2. Start a discussion in the Discussions tab
3. Reach out to the maintainers

Thank you for contributing to OID!
