require "application_job"

class CourseProjectLifecycleJob < ApplicationJob
  queue_as :default

  around_perform :around_cleanup

  def perform
    puts "Repeating job executed!"

    # self.class.set(wait: 50.minute).perform_later
  end

  private

  def around_cleanup
    # Do something before perform
    yield
    # Do something after perform
    self.class.set(wait_until: 100.second).perform_later
  end

end
