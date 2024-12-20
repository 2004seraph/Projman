# frozen_string_literal: true

# == Schema Information
#
# Table name: milestones
#
#  id                :bigint           not null, primary key
#  deadline          :datetime         not null
#  executed          :boolean          default(FALSE), not null
#  json_data         :json             not null
#  milestone_type    :enum             not null
#  system_type       :enum
#  user_generated    :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  course_project_id :bigint           not null
#
# Indexes
#
#  index_milestones_on_course_project_id  (course_project_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_project_id => course_projects.id)
#

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class Milestone < ApplicationRecord
  has_many :milestone_responses, dependent: :destroy
  belongs_to :course_project
  has_one :course_module, through: :course_project

  validates :milestone_type,  presence: true
  validates :deadline,        presence: true

  enum :milestone_type, {
    student: "for_each_student",
    # staff:   "for_each_staff",
    team:    "for_each_team"
  }

  enum :system_type, {
    teammate_preference_deadline: "teammate_preference_deadline",
    project_preference_deadline:  "project_preference_deadline",
    project_completion_deadline:  "project_deadline",
    marking_deadline:             "mark_scheme"
  }

  def push_milestone_to_teams?(reminder, logger)
    if milestone_type == "team"
      # create events
      # logger.debug("teams: #{course_project.groups.count}")
      logger.debug "\tpushing this milestone 1"

      course_project.groups.each do |g|
        json = {
          "Name"     => json_data["Name"],
          "Comment"  => json_data["Comment"],
          "Reminder" => reminder,
          "Urgency"  =>
                        if ["project_deadline"].include? system_type
                          2 # Most urgent
                        elsif reminder
                          1 # Warning
                        else
                          0 # Notification
                        end
        }
        # logger.debug "\tpushing this milestone 2"
        # logger.debug("MILESTONE ACTION: #{json_data["Name"]} - #{x.valid?} - #{x.persisted?}")
        g.events << Event.create({ event_type: :milestone, json_data: json, group: g, milestone: self })
        logger.debug "\tpushing this milestone 3"
        g.save
        # logger.debug "\tpushing this milestone 4"
        g.reload

        # logger.debug "\tpushing this milestone 5"
      end

      return true
    end
    false
  end
end
