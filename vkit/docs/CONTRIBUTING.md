# Contributing to EVM

First off, thank you for considering contributing to EVM! It's people like you that make EVM such a great tool for the verification community.

## Code of Conduct

This project and everyone participating in it is governed by our commitment to fostering an open and welcoming environment. By participating, you are expected to uphold this commitment.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (code snippets, log files)
- **Describe the behavior you observed** and what you expected
- **Include your environment details** (simulator, OS, versions)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful**
- **List some other projects where this exists**, if applicable

### Pull Requests

1. Fork the repository and create your branch from `main`
2. Make your changes
3. Add tests if applicable
4. Update documentation as needed
5. Ensure your code follows the project's style guidelines
6. Submit a pull request

## Development Process

### Setting Up Development Environment

```bash
git clone https://github.com/username/evm.git
cd evm

# For Python tools
pip install -r requirements.txt
```

### Coding Standards

#### SystemVerilog

- Follow the style guide in [EVM_RULES.md](EVM_RULES.md)
- Use meaningful variable and class names
- Add comments for complex logic
- Include header blocks on all files
- Keep methods focused and small

#### Python

- Follow PEP 8 style guide
- Use type hints where appropriate
- Include docstrings for functions
- Write testable, modular code

### Testing

- Add tests for new features
- Ensure existing tests still pass
- Test with multiple simulators if possible

### Documentation

- Update README.md if needed
- Add/update inline documentation
- Update architecture docs for significant changes
- Include examples in commit messages

## Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally

Example:
```
Add streaming agent for SPI protocol

- Implement SPI master driver
- Add configuration class for clock polarity/phase
- Include example test
- Update documentation

Closes #123
```

## Project Structure

```
evm/
├── vkit/
│   ├── src/               # Core framework
│   └── docs/              # Documentation & examples
│       └── evm_vkit/      # Verification component library
├── python/                # Python tools
├── csr_gen/               # CSR generator tool
└── README.md
```

## Attribution

All contributors will be listed in CONTRIBUTORS.md. Your contributions are valuable and will be acknowledged.

## Questions?

Feel free to open an issue with the `question` label, or start a discussion on GitHub Discussions.

## License

By contributing to EVM, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to EVM! 🎉

**Created by Differential Audio Inc. - Community Driven**
