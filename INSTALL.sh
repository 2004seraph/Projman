#!/usr/bin/env bash

git config blame.ignoreRevsFile .git-blame-ignore-revs

bundle exec bin/setup
bundle install
yarn install
