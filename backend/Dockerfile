FROM ruby:3.3.10-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libsqlite3-dev \
    sqlite3 \
    libpq-dev \
    libyaml-dev \
    curl \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN mkdir -p db/sqlite tmp/pids

EXPOSE 3000

CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails db:prepare && bundle exec rails db:seed && bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
