# Contributing to DscCommunity.MaintenanceAutomation

Thank you for your interest in contributing to **DscCommunity.MaintenanceAutomation**! Your contributions help improve the project and support the DSC Community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Submitting Pull Requests](#submitting-pull-requests)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)
- [Contact](#contact)

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md) to ensure a welcoming and respectful community for everyone.

## How to Contribute

### Reporting Bugs

If you find a bug in the project, please [open an issue](https://github.com/yourusername/DscCommunity.MaintenanceAutomation/issues/new/choose) and provide the following information:

- A clear and descriptive title.
- A description of the problem.
- Steps to reproduce the issue.
- Expected and actual behavior.
- Any relevant screenshots or logs.

### Suggesting Enhancements

We welcome feature requests and enhancements! To suggest an improvement:

1. Search the [existing issues](https://github.com/yourusername/DscCommunity.MaintenanceAutomation/issues) to see if it's already been reported.
2. If not, [open a new issue](https://github.com/yourusername/DscCommunity.MaintenanceAutomation/issues/new/choose) with a clear description of the enhancement.

### Submitting Pull Requests

Contributions are welcome! To submit a pull request:

1. **Fork the Repository**

   Click the "Fork" button at the top-right of the repository page to create a personal copy.

2. **Clone Your Fork**

   ```bash
   git clone https://github.com/yourusername/DscCommunity.MaintenanceAutomation.git
   cd DscCommunity.MaintenanceAutomation
   ```

3. **Create a Branch**

   Create a new branch for your feature or bugfix:

   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make Your Changes**

   - Follow the [coding guidelines](#coding-guidelines).
   - Ensure your code is well-documented.

5. **Run Tests**

   Make sure all tests pass:

   ```bash
   # Example command, adjust based on your setup
   Invoke-Pester
   ```

6. **Commit Your Changes**

   ```bash
   git add .
   git commit -m "Add feature: Your feature description"
   ```

7. **Push to Your Fork**

   ```bash
   git push origin feature/your-feature-name
   ```

8. **Open a Pull Request**

   Navigate to the original repository and open a pull request from your fork's branch.

## Development Setup

To set up the project locally, follow the [Setup Guide](SETUP.md).

## Coding Guidelines

- **Consistency:** Follow the existing code style and conventions.
- **Clarity:** Write clear and understandable code with appropriate comments.
- **Modularity:** Ensure your code is modular and reusable.
- **Documentation:** Update or add documentation as needed.

## Testing

- **Unit Tests:** Write unit tests for new features or bug fixes.
- **Run Tests:** Use Pester to run tests locally.

  ```bash
  Invoke-Pester
  ```

- **Continuous Integration:** Ensure that all tests pass in the CI pipeline before submitting a pull request.

## Documentation

- **Update Documentation:** If your contribution affects the documentation, please update the relevant sections in the `README.md` or other markdown files.
- **New Features:** Document any new features or changes clearly.

## Contact

If you have any questions or need assistance, feel free to reach out:

- **Email:** <your-email@example.com>
- **GitHub Issues:** [Open an issue](https://github.com/yourusername/DscCommunity.MaintenanceAutomation/issues)

Thank you for contributing to **DscCommunity.MaintenanceAutomation**!
