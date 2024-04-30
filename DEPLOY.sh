#!/usr/bin/env bash

# You must be connected to the UoS VPN, and have your repository SSH key configured correctly
# to run this script

bundle exec epi_deploy release -d demo
bundle exec cap demo deploy:seed
bundle exec cap demo whenever:update_crontab