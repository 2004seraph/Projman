# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

require "capistrano/rails/collection"

# Load additional modules
require "capistrano/rvm"
require "capistrano/bundler"
require "capistrano/rails/assets"
require "capistrano/rails/migrations"
require "capistrano/passenger"
require "whenever/capistrano"

# Configure the SCM
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Load custom tasks from `lib/capistrano/tasks' if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }

# namespace crontab entries with staging environment
# set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
