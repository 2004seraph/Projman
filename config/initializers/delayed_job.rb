# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

Delayed::Worker.max_attempts = 5
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.delay_jobs = !Rails.env.development? && !Rails.env.test?

module Delayed
  module WorkerClassReloadingPatch
    # Override Delayed::Worker#reserve_job to optionally reload classes before running a job
    def reserve_job(*)
      Rails.logger.level = :fatal
      job = super
      Rails.logger.level = :debug

      if job && self.class.reload_app?
        if defined?(ActiveSupport::Reloader)
          Rails.application.reloader.reload!
        else
          ActionDispatch::Reloader.cleanup!
          ActionDispatch::Reloader.prepare!
        end
      end

      job
    end

    # Override Delayed::Worker#reload! which is called from the job polling loop to not reload classes
    def reload!
      # no-op
    end
  end
end
Delayed::Worker.prepend Delayed::WorkerClassReloadingPatch
