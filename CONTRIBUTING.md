# Contributing

Thanks for your interest in improving SimpleCov GitHub Action! Contributions of
all kinds are welcome — bug reports, feature requests, documentation, and code.

## Reporting issues

- Search [existing issues](https://github.com/alexremn/simplecov-github-action/issues)
  before opening a new one.
- Use the issue templates and include a minimal reproduction: your workflow YAML,
  the action inputs you used, and the relevant log output.

## Development setup

The action is a single Ruby script (`src/check_coverage.rb`) packaged as a Docker
action.

```bash
# Syntax check (same as CI lint job)
ruby -c src/check_coverage.rb

# Build the container locally
docker build -t simplecov-github-action .
```

The script reads its configuration from environment variables (see `action.yml`
for the full input-to-env mapping). To run it against a SimpleCov result file:

```bash
docker run --rm \
  -e MINIMUM_SUITE_COVERAGE=95 \
  -e COVERAGE_PATH=coverage/.resultset.json \
  -e GITHUB_STEP_SUMMARY=/dev/stdout \
  -v "$PWD:/github/workspace" -w /github/workspace \
  simplecov-github-action
```

## Pull request workflow

1. Fork the repository and create a feature branch off `main`.
2. Make your change. Keep it focused — one logical change per PR.
3. Run `ruby -c src/check_coverage.rb` and build the Docker image to confirm the
   action still works.
4. Update `README.md` and `CHANGELOG.md` (under an `## [Unreleased]` heading) when
   your change affects behavior or inputs.
5. Open a PR using the template and describe what changed and why.

CI runs a lint job, an action self-test, and a Docker build on every PR — make
sure all checks are green before requesting review.

## Conventions

- Follow [Conventional Commits](https://www.conventionalcommits.org/) for commit
  messages (`feat:`, `fix:`, `chore:`, `docs:`, …).
- This project follows [Semantic Versioning](https://semver.org/).
- The CHANGELOG format is based on [Keep a Changelog](https://keepachangelog.com/).

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).
