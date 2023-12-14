FROM ruby:3.2-slim-bullseye as jekyll

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /docs

# First copy the Gemfile
COPY docs/Gemfile /docs/
COPY docs/Gemfile.lock /docs/

# Installing the Gems for Jeckyll and just-the-docs
RUN bundle install

# Copying the docs last, to maximize docker cache
COPY docs/ /docs/

EXPOSE 4000

ENTRYPOINT [ "bundle", "exec", "jekyll"]
CMD ["serve", "-H" , "0.0.0.0", "-P", "4000" ]
