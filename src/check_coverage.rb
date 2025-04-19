#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'pathname'
require 'net/http'
require 'uri'

# Debug helper using GitHub Actions debug logging
def debug(message, debug_mode)
  puts "::debug::#{message}" if debug_mode && ['true', 'TRUE', '1'].include?(debug_mode)
end

begin
  # Get inputs from environment variables
  min_suite_coverage = (ENV['MINIMUM_SUITE_COVERAGE'] || '0').to_f
  min_file_coverage = (ENV['MINIMUM_FILE_COVERAGE'] || '0').to_f
  coverage_path = ENV['COVERAGE_PATH'] || 'coverage/.resultset.json'
  debug_mode = ENV['DEBUG_MODE']
  on_fail_status = (ENV['ON_FAIL_STATUS'] || 'fail').downcase
  post_comment = ENV['POST_COMMENT']
  github_token = ENV['GITHUB_TOKEN']

  debug("Environment variables: #{ENV.keys.select { |k| !k.include?('TOKEN') && !k.include?('SECRET') }.join(', ')}", debug_mode)

  # Validate inputs
  unless (0..100).cover?(min_suite_coverage)
    puts "::error::`minimum_suite_coverage` must be between 0 and 100, got #{min_suite_coverage}"
    exit 1
  end

  unless (0..100).cover?(min_file_coverage)
    puts "::error::`minimum_file_coverage` must be between 0 and 100, got #{min_file_coverage}"
    exit 1
  end

  # Validate debug_mode
  unless ['true', 'false', 'TRUE', 'FALSE', '1', '0', '', nil].include?(debug_mode)
    puts "::warning::`debug_mode` should be 'true' or 'false', got '#{debug_mode}'. Using default (false)."
  end

  # Validate on_fail_status
  unless ['fail', 'warn'].include?(on_fail_status)
    puts "::warning::`on_fail_status` should be 'fail' or 'warn', got '#{on_fail_status}'. Using default (fail)."
    on_fail_status = 'fail'
  end

  # Validate post_comment
  valid_post_comment_values = ['true', 'TRUE', '1', 'false', 'FALSE', '0', '', nil]
  unless valid_post_comment_values.include?(post_comment)
    puts "::warning::`post_comment` should be 'true' or 'false', got '#{post_comment}'. Using default (false)."
  end

  # Check if post_comment is enabled but no token provided
  should_post_comment = ['true', 'TRUE', '1'].include?(post_comment)
  if should_post_comment && github_token.to_s.strip.empty?
    puts "::warning::`post_comment` is enabled but no `github_token` was provided. Comments won't be posted."
    should_post_comment = false
  end

  debug("Inputs: minimum_suite_coverage=#{min_suite_coverage}, minimum_file_coverage=#{min_file_coverage}", debug_mode)
  debug("Options: on_fail_status=#{on_fail_status}, post_comment=#{should_post_comment}", debug_mode)

  # Check if coverage file exists
  unless File.exist?(coverage_path)
    puts "::error::SimpleCov results file not found at #{coverage_path}"
    exit 1
  end

  # Parse SimpleCov results
  results = JSON.parse(File.read(coverage_path))
  debug("Found results file with #{results.keys.size} results", debug_mode)

  if results.empty?
    puts "::error::SimpleCov results file is empty or invalid"
    exit 1
  end

  # Get the most recent result - sort keys to ensure we get the latest
  # This handles both numeric keys and timestamp strings
  result_key = if results.keys.all? { |k| k.to_i.to_s == k }
    # If all keys can be converted to integers, sort numerically
    results.keys.max_by { |k| k.to_i }
  else
    # Otherwise sort as strings (likely timestamps)
    results.keys.sort.last
  end

  debug("Using result key: #{result_key}", debug_mode)
  result = results[result_key]

  # Get the coverage data
  unless result && result['coverage'].is_a?(Hash)
    puts "::error::SimpleCov results file has invalid format"
    exit 1
  end

  coverage_data = result['coverage']

  total_lines = 0
  covered_lines = 0
  failing_files = []

  # Process each file
  coverage_data.each do |file_path, coverage|
    next unless coverage.is_a?(Hash)
    next unless coverage['lines'].is_a?(Array)

    file_lines = coverage['lines'].compact.size
    file_covered_lines = coverage['lines'].compact.count { |line| line && line > 0 }

    # Calculate file coverage more accurately
    if file_lines > 0
      file_coverage = (file_covered_lines.to_f / file_lines) * 100
      file_name = Pathname.new(file_path).relative_path_from(Pathname.pwd).to_s rescue file_path

      debug("File: #{file_name} - Coverage: #{file_coverage.round(2)}% (#{file_covered_lines}/#{file_lines} lines)", debug_mode)

      # Strict comparison: file coverage must be >= min_file_coverage
      if file_coverage < min_file_coverage
        failing_files << {
          name: file_name,
          coverage: file_coverage.round(2),
          lines: file_lines,
          covered: file_covered_lines
        }
      end

      total_lines += file_lines
      covered_lines += file_covered_lines
    end
  end

  # Calculate total coverage with explicit strictness
  total_coverage = total_lines > 0 ? (covered_lines.to_f / total_lines) * 100 : 0
  debug("Total lines: #{total_lines}, Covered lines: #{covered_lines}", debug_mode)
  debug("Raw total coverage: #{total_coverage}", debug_mode)

  # Round for display
  formatted_total_coverage = total_coverage.round(2)

  # Strict comparison: total coverage must be >= min_suite_coverage
  total_coverage_passed = total_coverage >= min_suite_coverage

  # Prepare summary data
  summary = []
  summary << "## SimpleCov Coverage Results"
  summary << ""
  summary << "| Metric | Expected | Actual | Status |"
  summary << "|--------|----------|--------|--------|"
  summary << "| Total Coverage | #{min_suite_coverage}% | #{formatted_total_coverage}% | #{total_coverage_passed ? '✅' : '❌'} |"

  # Create a detailed output for the workflow log
  puts "SimpleCov Coverage Results:"
  puts "- Expected total coverage: #{min_suite_coverage}%"
  puts "- Actual total coverage:   #{formatted_total_coverage}%"

  # Add status for total coverage
  if total_coverage_passed
    puts "::notice::✅ Total coverage meets minimum requirement"
  else
    puts "::error::❌ Total coverage (#{formatted_total_coverage}%) is below the minimum required (#{min_suite_coverage}%)"
  end

  # Annotate files with file-level errors
  if failing_files.any?
    summary << ""
    summary << "## Files Below Minimum Coverage"
    summary << ""
    summary << "| File | Expected | Actual | Missing |"
    summary << "|------|----------|--------|---------|"

    puts "\nFiles below minimum coverage (#{min_file_coverage}%):"

    # Use file-level annotations for each failing file
    sorted_failing_files = failing_files.sort_by { |f| f[:coverage] }

    sorted_failing_files.each do |file|
      missing = (min_file_coverage - file[:coverage]).round(2)
      summary << "| #{file[:name]} | #{min_file_coverage}% | #{file[:coverage]}% | #{missing}% |"

      # Create GitHub annotation tied to the specific file
      puts "::error file=#{file[:name]},line=1::Coverage #{file[:coverage]}% below threshold #{min_file_coverage}% (missing #{missing}%)"
    end

    puts "::error::#{failing_files.size} files have coverage below the minimum required (#{min_file_coverage}%)"
  else
    summary << ""
    summary << "✅ All files meet the minimum coverage requirement of #{min_file_coverage}%"
    puts "::notice::✅ All files meet the minimum coverage requirement of #{min_file_coverage}%"
  end

  # Write summary to GitHub step summary if available
  if ENV['GITHUB_STEP_SUMMARY']
    File.open(ENV['GITHUB_STEP_SUMMARY'], 'w') do |f|
      f.puts summary.join("\n")
    end
  end

  # Determine overall success/failure
  success = total_coverage_passed && failing_files.empty?

  # Generate markdown for PR comment if enabled
  if should_post_comment
    comment_body = []
    comment_body << "## SimpleCov Coverage Results"

    if success
      comment_body << "✅ **Coverage check passed successfully!**"
    else
      comment_body << "❌ **Coverage check failed!**"
    end

    comment_body << ""
    comment_body << "| Metric | Expected | Actual | Status |"
    comment_body << "|--------|----------|--------|--------|"
    comment_body << "| Total Coverage | #{min_suite_coverage}% | #{formatted_total_coverage}% | #{total_coverage_passed ? '✅' : '❌'} |"

    if failing_files.any?
      comment_body << ""
      comment_body << "### Files Below Minimum Coverage"
      comment_body << ""
      comment_body << "| File | Expected | Actual | Missing |"
      comment_body << "|------|----------|--------|---------|"

      sorted_failing_files.each do |file|
        missing = (min_file_coverage - file[:coverage]).round(2)
        comment_body << "| #{file[:name]} | #{min_file_coverage}% | #{file[:coverage]}% | #{missing}% |"
      end
    else
      comment_body << ""
      comment_body << "✅ All files meet the minimum coverage requirement of #{min_file_coverage}%"
    end

    # Post the comment to the PR
    begin
      event_path = ENV['GITHUB_EVENT_PATH']
      if event_path && File.exist?(event_path)
        event_data = JSON.parse(File.read(event_path))

        # Only proceed if this is a PR
        if event_data['pull_request']
          pr_number = event_data['pull_request']['number']
          repo = ENV['GITHUB_REPOSITORY']

          if pr_number && repo
            debug("Posting comment to PR ##{pr_number} in repository #{repo}", debug_mode)

            uri = URI.parse("https://api.github.com/repos/#{repo}/issues/#{pr_number}/comments")
            request = Net::HTTP::Post.new(uri)
            request['Accept'] = 'application/vnd.github.v3+json'
            request['Authorization'] = "token #{github_token}"
            request['Content-Type'] = 'application/json'
            request.body = { body: comment_body.join("\n") }.to_json

            response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
              http.request(request)
            end

            if response.code.to_i >= 200 && response.code.to_i < 300
              puts "::notice::Successfully posted coverage results as a comment on PR ##{pr_number}"
            else
              puts "::warning::Failed to post comment to PR. Response: #{response.code} #{response.message}"
              debug("Response body: #{response.body}", debug_mode)
            end
          else
            puts "::warning::Could not determine PR number or repository from event data"
          end
        else
          puts "::notice::Not a pull request - skipping comment"
        end
      else
        puts "::warning::Could not find GITHUB_EVENT_PATH or file does not exist"
      end
    rescue => e
      puts "::warning::Error posting comment to PR: #{e.message}"
      debug(e.backtrace.join("\n"), debug_mode)
    end
  end

  if success
    puts "::notice::✅ Code coverage check passed successfully! Total coverage: #{formatted_total_coverage}%"
  else
    puts "::error::❌ Code coverage check failed! Total coverage: #{formatted_total_coverage}%"

    # Only exit with error code if on_fail_status is 'fail'
    if on_fail_status == 'fail'
      exit 1  # Explicitly fail the job if requirements aren't met
    else
      puts "::warning::Coverage requirements not met, but continuing due to on_fail_status=warn"
    end
  end

rescue => e
  puts "::error::Error processing SimpleCov results: #{e.message}"
  puts e.backtrace
  exit 1
end
