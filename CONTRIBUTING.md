# Contributing to SemiOS-contract

Thank you for your interest in contributing to the SemiOS-contract project! We welcome contributions from the community to help improve and expand this project. Please take a moment to review this document before submitting your contributions.

## Table of Contents
- [How to Contribute](#how-to-contribute)
- [Reporting Bugs](#reporting-bugs)
- [Feature Requests](#feature-requests)
- [Code Contributions](#code-contributions)
- [Pull Request Process](#pull-request-process)
- [Coding Guidelines](#coding-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)

## How to Contribute
There are several ways you can contribute to SemiOS-contract:
- Reporting bugs and issues
- Requesting new features
- Submitting code improvements
- Improving documentation

## Reporting Bugs
If you find a bug in the project, please open an issue in the [Issue Tracker](https://github.com/Semios-Protocol/SemiOS-contract/issues) and include the following information:
- A clear and descriptive title
- A detailed description of the issue
- Steps to reproduce the issue
- Any relevant screenshots or logs

## Feature Requests
We welcome suggestions for new features! To request a new feature, please open an issue in the [Issue Tracker](https://github.com/Semios-Protocol/SemiOS-contract/issues) with the following information:
- A clear and descriptive title
- A detailed description of the proposed feature
- Any relevant use cases or examples

## Code Contributions
We appreciate your help in improving SemiOS-contract. To contribute code, follow these steps:

1. Fork the repository to your own GitHub account.
2. Create a new branch from the `main` branch for your changes (e.g., `feature/my-new-feature`).
3. Make your changes in the new branch.
4. Write clear and concise commit messages.
5. Run `forge fmt` to format your code according to the project's style guidelines.
6. Push your changes to your forked repository.
7. Open a pull request (PR) to the `main` branch of the original repository.

## Pull Request Process
When you open a pull request, please ensure that:
- Your code adheres to the project's coding standards and guidelines.
- All tests pass successfully.
- Your changes are well-documented.
- Your PR includes a clear and detailed description of the changes and the problem they solve.

A project maintainer will review your pull request and may request changes before it can be merged.

## Coding Guidelines
- Follow the Solidity [Style Guide](https://docs.soliditylang.org/en/v0.8.0/style-guide.html).
- Use descriptive variable and function names.
- Write comments to explain the purpose of complex code blocks.
- Ensure your code is clean, readable, and maintainable.
- Format your code using `forge fmt` to ensure consistency

## Testing
Thorough testing is crucial for the reliability of SemiOS-contract. Please include tests for any new features or bug fixes. We use [Foundry](https://getfoundry.sh/) for testing Solidity contracts.

### Install Foundry
If you haven't already, install Foundry by following the instructions on the [Foundry website](https://getfoundry.sh/).

### Run Tests
To run the tests, use the following command:

```sh
forge test
