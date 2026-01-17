# Contributing to Qdrant AWS HA Setup

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. Check if the issue already exists
2. Create a new issue with:
   - Clear description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Terraform/AWS versions

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
   - Follow Terraform best practices
   - Update documentation as needed
   - Test your changes
4. **Commit your changes**
   ```bash
   git commit -m "Add: description of changes"
   ```
5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
6. **Create a Pull Request**

## Code Style

### Terraform

- Use `terraform fmt` before committing
- Follow HashiCorp's style guide
- Use meaningful variable and resource names
- Add comments for complex logic

### Shell Scripts

- Use `#!/bin/bash` with `set -e`
- Add comments explaining non-obvious operations
- Make scripts executable

## Testing

Before submitting:

1. Run `terraform fmt -recursive`
2. Run `terraform validate`
3. Test deployment in a non-production environment
4. Verify all resources are created correctly

## Documentation

- Update README.md for user-facing changes
- Update QUICKSTART.md for workflow changes
- Add comments in code for complex logic

## Questions?

Open an issue with the `question` label!
