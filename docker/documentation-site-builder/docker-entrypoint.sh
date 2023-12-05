#!/bin/bash
set -e

if [ ! -f ../../docs/Gemfile ]; then
  echo "ERROR: Gemfile not found"
  exit 1
fi

bundle install --retry 5 --jobs 20

exec "$@"