[![GitHub release](https://img.shields.io/github/v/release/alexremn/simplecov-github-action.svg)](https://github.com/alexremn/simplecov-github-action/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A GitHub Action to check SimpleCov code coverage results and report them directly within GitHub workflow runs. This action provides better visibility for code coverage metrics with GitHub annotations, job summaries, and optional PR comments.

## Features

- ✅ Checks total code coverage against a minimum threshold
- ✅ Checks per-file code coverage against a minimum threshold
- ✅ Uses GitHub Actions annotations for better visibility
- ✅ Creates file-level error annotations for files below threshold
- ✅ Generates a summary report in GitHub's workflow summary
- ✅ Option to post results as a comment on Pull Requests
- ✅ Configurable behavior (fail or warn) when coverage requirements aren't met
- ✅ Support for both total coverage and per-file coverage requirements

## Usage

Add this to your GitHub Actions workflow:

```yaml
- name: Check SimpleCov coverage
  uses: alexremn/simplecov-github-action@v1
  with:
    minimum_suite_coverage: 95
    minimum_file_coverage: 90
    coverage_path: 'coverage/.resultset.json'
    debug_mode: false
    on_fail_status: fail
    post_comment: false
    github_token: ${{ secrets.GITHUB_TOKEN }} # Required if post_comment is true
```

## Inputs

| Input | Description | Required | Default                    | Validation |
|-------|-------------|----------|----------------------------|------------|
| `minimum_suite_coverage` | Minimum required total coverage percentage | No | `95`                       | 0-100 |
| `minimum_file_coverage` | Minimum required coverage percentage per file | No | `0`                        | 0-100 |
| `coverage_path` | Path to the SimpleCov .resultset.json file | No | `coverage/.resultset.json` | Must exist |
| `debug_mode` | Enable debug mode for additional output | No | `false`                    | Boolean |
| `on_fail_status` | Behavior when coverage check fails | No | `fail`                     | `fail` or `warn` |
| `post_comment` | Post results as a comment on the PR | No | `false`                    | Boolean |
| `update_comment` | Update existing comment instead of creating a new one | No | `false`                    | Boolean |
| `github_token` | GitHub token for PR comment creation | No | `''`                       | Required if post_comment is true |

## Behavior Options

### On Fail Status (`on_fail_status`)

- **`fail`** (default): Exits with a non-zero status code when coverage requirements aren't met, causing the workflow run to fail
- **`warn`**: Only outputs warnings when coverage requirements aren't met, allowing the workflow run to continue

### PR Comments (`post_comment` and `update_comment`)

- **`post_comment: true`**: Posts the coverage results as a comment on the Pull Request
- **`post_comment: false`** (default): Does not post comments
- **`update_comment: true`**: Updates existing coverage comment instead of creating a new one
- **`update_comment: false`** (default): Creates a new comment on each run

Note: When `post_comment` is set to `true`, the `github_token` input is required. You can provide it with `${{ secrets.GITHUB_TOKEN }}`.

## GitHub Token Permissions

If you're using the `post_comment` feature to comment on pull requests, you need to ensure that your `GITHUB_TOKEN` has the necessary permissions:

```yaml
permissions:
  contents: read
  pull-requests: write  # Required for posting/updating PR comments
```

Add this to your workflow file to grant the required permissions:

```yaml
name: Ruby Tests with Coverage

on:
  pull_request:
    branches: [ main ]

permissions:
  contents: read
  pull-requests: write  # Required for PR comments

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      # ... your test steps here ...
      
      - name: Check SimpleCov coverage
        uses: alexremn/simplecov-github-action@v1
        with:
          minimum_suite_coverage: 95
          post_comment: true
          update_comment: true  # Update existing comment instead of creating a new one
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

Without the `pull-requests: write` permission, the action will not be able to post or update comments on pull requests.# SimpleCov GitHub Action

## Examples

### Basic Example

```yaml
name: Ruby Tests with Coverage

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code  
        uses: actions/checkout@v4
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.1'
          bundler-cache: true
      
      - name: Install dependencies
        run: bundle install
      
      - name: Run tests with coverage
        run: bundle exec rspec
      
      - name: Check SimpleCov coverage
        uses: alexremn/simplecov-github-action@v1
        with:
          minimum_suite_coverage: 95
          minimum_file_coverage: 90
```

### Advanced Example with PR Comments

```yaml
name: Ruby Tests with Coverage

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.1'
          bundler-cache: true
      
      - name: Install dependencies
        run: bundle install
      
      - name: Run tests with coverage
        run: bundle exec rspec
      
      - name: Check SimpleCov coverage
        uses: alexremn/simplecov-github-action@v1
        with:
          minimum_suite_coverage: 95
          minimum_file_coverage: 90
          on_fail_status: warn  # Won't fail the workflow
          post_comment: true    # Post results as a PR comment
          github_token: ${{ secrets.GITHUB_TOKEN }}
      
      # Optional: Upload coverage report as an artifact
      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage
          retention-days: 7
```

### Different Requirements for Different Branches

```yaml
name: Ruby Tests with Coverage

on:
  pull_request:
  push:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.1'
          bundler-cache: true
      
      - name: Install dependencies
        run: bundle install
      
      - name: Run tests with coverage
        run: bundle exec rspec
      
      # Stricter requirements for main branch
      - name: Check SimpleCov coverage (main branch)
        if: github.ref == 'refs/heads/main'
        uses: alexremn/simplecov-github-action@v1
        with:
          minimum_suite_coverage: 95
          minimum_file_coverage: 90
          on_fail_status: fail
          post_comment: true
          github_token: ${{ secrets.GITHUB_TOKEN }}
      
      # More relaxed for other branches
      - name: Check SimpleCov coverage (other branches)
        if: github.ref != 'refs/heads/main'
        uses: alexremn/simplecov-github-action@v1
        with:
          minimum_suite_coverage: 85
          minimum_file_coverage: 70
          on_fail_status: warn
          post_comment: true
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

## Output Format

This action provides rich feedback on your test coverage:

### GitHub Workflow Annotations

- **Error Annotations**: Files below the required coverage will appear as error annotations in the GitHub UI, showing exactly which files need attention
- **File-level Errors**: Each file below threshold gets its own annotation tied to that file
- **Notice Annotations**: Success messages appear as notice annotations

### GitHub Job Summary

The action creates a detailed job summary with:

- Total coverage compared to the expected threshold
- Status indicators for passed/failed checks
- Table of files that don't meet coverage requirements
- Missing coverage percentages to show how far off each file is

### Pull Request Comments

When `post_comment` is enabled, the action will post a formatted comment on the Pull Request with:

- Overall pass/fail status
- Total coverage metrics
- List of files that don't meet coverage requirements (if any)

This provides visibility of coverage results directly in the PR, making it easier for reviewers to see coverage issues.

## Comparison with Other Solutions

### Advantages over simplecov-check-action

This action was originally created as a replacement for `joshmfrankel/simplecov-check-action` with several advantages:

- Doesn't rely on the GitHub Checks API, which can be unreliable in some environments
- Uses GitHub workflow annotations for better visibility
- Supports file-level annotations, linking coverage issues directly to files
- Allows configurable fail behavior (fail or warn)
- Generates detailed job summaries
- Can post comments directly on PRs
- More robust handling of different SimpleCov result formats

## How It Works

The action:

1. Reads the SimpleCov `.resultset.json` file generated by your tests
2. Analyzes both total coverage and per-file coverage
3. Compares them against the specified thresholds
4. Reports results using GitHub workflow annotations and job summaries
5. Optionally posts results as a PR comment
6. Either fails the workflow or just warns, depending on your configuration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
