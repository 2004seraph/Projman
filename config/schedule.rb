#####
#
# These are required to make rvm work properly within crontab
#
if ENV['MY_RUBY_HOME'] && ENV['MY_RUBY_HOME'].include?('rvm')
  env "PATH",         ENV["PATH"]
  env "GEM_HOME",     ENV["GEM_HOME"]
  env "MY_RUBY_HOME", ENV["MY_RUBY_HOME"]
  env "GEM_PATH",     ENV["_ORIGINAL_GEM_PATH"] || ENV["BUNDLE_ORIG_GEM_PATH"] || ENV["BUNDLER_ORIG_GEM_PATH"]
end
#
#####

# update project statuses and send events to groups
every 1.minute do
  # the following tasks are run in parallel (not in sequence)
  runner "CourseProject.lifecycle_job", environment: ENV['RAILS_ENV']
end

# every six, hours, sync to sheffield's database
# every 1.minute do #1.day, at: ['12:30 am', '12:30 pm']  do
#   runner "Student.ldap_sync", environment: ENV['RAILS_ENV']
# end