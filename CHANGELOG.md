# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-05-17

### Changed
- Upgraded Docker base image from `ruby:3.1-alpine` to `ruby:3.4-alpine`
- Bumped `actions/checkout` to v6 across all workflows
- Bumped `docker/build-push-action` to v7
- Bumped `softprops/action-gh-release` to v3

### Added
- Dedicated `lint` job in CI running a Ruby syntax check (`ruby -c`) before the action self-test
- Pre-release `verify` job (Ruby syntax + Docker build) gating the `release` job
- Automatic release notes generation (`generate_release_notes: true`)
- Major version tag move (e.g. `v1` pointing at latest `v1.x.y`) on release
- Explicit least-privilege `permissions: contents: read` on the test workflow

## [1.0.1] - 2025-04-21

### Added
- Support for updating the PR comment with the latest coverage results
- Updated README

## [1.0.0] - 2025-04-19

### Added
- Initial release
- Support for checking total code coverage
- Support for checking per-file code coverage
- GitHub Actions annotations for better visibility
- File-level error annotations
- GitHub job summary generation
- PR comment feature
- Configurable fail behavior (fail or warn)
