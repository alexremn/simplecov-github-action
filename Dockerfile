FROM ruby:3.1-alpine

LABEL maintainer="Aleks Remniov <alexander.remniov@gmail.com>"
LABEL org.opencontainers.image.source="https://github.com/alexremn/simplecov-github-action"
LABEL org.opencontainers.image.description="A GitHub Action to check SimpleCov code coverage"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git

# Copy the script
COPY src/check_coverage.rb /app/check_coverage.rb
RUN chmod +x /app/check_coverage.rb

# Set the entrypoint
ENTRYPOINT ["/app/check_coverage.rb"]
