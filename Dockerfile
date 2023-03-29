ARG RUBY_VERSION=3.2.1
FROM ruby:$RUBY_VERSION-slim as base

# Rack app lives here
WORKDIR /app

ENV BUNDLE_WITHOUT="development:test"
ENV BUNDLE_DEPLOYMENT="1"
ENV BUNDLE_PATH="/usr/local/bundle"

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler


# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential

# Install application gems
COPY Gemfile* .
RUN bundle install


# Final stage for app image
FROM base

# Run and own the application files as a non-root user for security
RUN useradd ruby --home /app --shell /bin/bash
USER ruby:ruby

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=ruby:ruby /app /app

# Copy application code
COPY . .

# Start the server
EXPOSE 8080
ENTRYPOINT ["bundle", "exec", "ruby", "bot/bot.rb"]
