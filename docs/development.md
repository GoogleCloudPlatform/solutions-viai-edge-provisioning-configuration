# Develop VIAI Edge

This document explains how to develop VIAI Edge.

## Creating pull requests

When creating pull requests, maintainers are required to work in a branch of
this repository. If a maintainer creates a pull request against any branch of
this repository from a fork, a
[required workflow will return an error](../.github/workflows/check-pr-origin.yaml).

Contributors that are not maintainers can work in their own forks.

## Requirements

To setup a development environment you need:

- A POSIX-compliant shell
- An OCI-compatible container runtime. Tested with Docker for Linux 20.10.21

## Code linting and static analysis

This project runs a set of code linters and static analyzers that are part of
[super-linter](https://github.com/github/super-linter) as part of the build
process.

### Run code linting and static analysis from the command-line

1. Open a POSIX-compliant shell.
1. Change your working directory to the root directory of this repository.
1. Run the code linting and static analysis process:

```shell
tests/lint.sh
```

### Lint configuration

All the linters have their configuration stored in the `config/lint` directory.
Additionally, some linters shipped within super-linter also take the
[EditorConfig configuration file](../.editorconfig)
into account.
