FROM ruby:3.1-slim-bullseye as jekyll

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy the docs repo folder to the container
WORKDIR /docs

COPY docs/ /docs/

RUN gem update --system && gem install jekyll && gem install just-the-docs && gem cleanup

EXPOSE 4000

# CMD [ "bundle", "exec", "jekyll", "serve", "--force_polling", "-H", "0.0.0.0", "-P", "4000" ]
CMD ["bundle", "exec", "jekyll", "serve"]