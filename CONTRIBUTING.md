# Contributing to moreLLMMCP

Thank you for considering contributing to moreLLMMCP! Please follow these guidelines to help us maintain a high-quality, maintainable, and secure project.

## How to Contribute
- Open an issue to discuss bugs, features, or questions before submitting a PR.
- Fork the repository and create a feature branch for your changes.
- Write clear, atomic commits and descriptive PRs.
- Ensure all code follows the project's design principles and passes lint/tests.

## Code of Conduct
This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be respectful and constructive.

## Development
- See `scratchpad/design-considerations.md` for architecture and implementation plan.
- Use GitHub Actions for CI (lint, test, deploy).
- All secrets and keys must be managed via Azure App Settings or Key Vault.

## Reporting Issues
- Use the issue tracker for bugs, feature requests, or questions.
- Provide as much detail as possible (logs, steps, environment).

## Branch Protection & Pull Requests
- The `main` branch is protected: **direct commits and pushes are not allowed**.
- All changes must be submitted via a pull request (PR) from a non-main branch.
- Each PR must:
  - Receive at least one approval from a project maintainer (or as required by the branch protection rules)
  - Pass all required status checks (CI, lint, tests)
  - Resolve all review conversations before merging
- Squash or rebase merging is recommended; merge commits are discouraged.

## License
See [LICENSE](LICENSE).
