#!/usr/bin/env bash
whenever --update-crontab
bundle exec bin/shakapacker-dev-server &
bundle exec rails s