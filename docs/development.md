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
[super-linter](https://github.com/github/super-linter).

[A GitHub Actions workflow](../.github/workflows/lint.yml) runs these code
linters and static analyzers as part of the build process.

### Run code linting and static analysis from the command-line

To run code linters and static analyzers locally, do the following:

1. Open a POSIX-compliant shell.
2. Change your working directory to the root directory of this repository.
3. Run the code linting and static analysis process:

```shell
tests/lint.sh
```

### Lint configuration

All the linters have their configuration stored in the `config/lint` directory.
Additionally, some linters shipped within super-linter also take the
[EditorConfig configuration file](../.editorconfig)
into account.

## Container image building

This project needs several container images. The build descriptors for these
container images are stored in the `docker` directory.

[A GitHub Actions workflow](../.github/workflows/build-container-images.yml)
builds these container images as part of the build process.

### Build container images from the command-line

To run build container images locally, do the following:

1. Open a POSIX-compliant shell.
2. Change your working directory to the root directory of this repository.
3. Run the code linting and static analysis process:

```shell
tests/build-container-images.sh
```

## Render the documentation as static HTML using Jekyll locally

This repository uses Jekyll and GitHub actions to render the Markdown documentation
under the `/docs` folder as static HTML.

The configuration for the Jekyll site is at [Jekyll config](../docs/_config.yml) and the [Gemfile](../docs/Gemfile).

The configuration for the associated GitHub actions is at [GitHub Actions workflow](../.github/workflows/pages.yml).

### Build the documentation locally

To test the render before pushing to GitHub, do the following:

1. Open a POSIX-copmpliant shell.
2. Change your working directory to the root directory of this repository.
3. Run Jekyll on a docker container:

```bash
    ./tests/build-documentation-site.sh
```
