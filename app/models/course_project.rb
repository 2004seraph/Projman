# == Schema Information
#
# Table name: course_projects
#
#  id                  :bigint           not null, primary key
#  avoided_teammates   :integer          default(0)
#  markscheme_json     :json
#  name                :string           default("Unnamed Project"), not null
#  preferred_teammates :integer          default(0)
#  project_allocation  :enum             not null
#  status              :enum             default("draft"), not null
#  team_allocation     :enum             not null
#  team_size           :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  course_module_id    :bigint           not null
#
# Indexes
#
#  index_course_projects_on_course_module_id  (course_module_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_module_id => course_modules.id)
#

class CourseProject < ApplicationRecord
  has_many :groups, dependent: :destroy
  has_many :milestones, dependent: :destroy
  has_many :assigned_facilitators, dependent: :destroy
  has_many :subprojects, dependent: :destroy
  belongs_to :course_module
  has_one :staff, through: :course_module

  validate :creation_validation

  enum :status, {
    draft: 'draft',
    student_preference: 'student_preference',
    student_preference_review: 'student_preference_review',
    team_preference: 'team_preference',
    team_preference_review: 'team_preference_review',
    live: 'live',
    completed: 'completed',
    archived: 'archived'
  }

  enum :project_allocation, {
    random_project_allocation: 'random',
    single_preference_project_allocation: 'single_preference_submission',
    team_preference_project_allocation: 'team_average_preference'
  }

  enum :team_allocation, {
    random_team_allocation: 'random',
    preference_form_based: 'preference_form_based'
  }


  def completion_deadline
    completion_milestone.deadline
  end
  def completion_milestone
    milestones.each do |m|
      if m.json_data["isDeadline"]
        return m
      end
    end
  end

  def team_preference_submission_milestone
    milestones.each do |m|
      if m.json_data["isDeadline"]
        return m
      end
    end
    nil
  end


  def self.lifecycle_job
    # DO NOT RUN THIS IN ANY APP CODE
    # THIS IS A CRON JOB, IT IS RAN BY THE OS

    logger = Logger.new(Rails.root.join('log', 'course_project.lifecycle_job.log'))
    logger.debug("LIFECYCLE PASS")

    def str_to_int(string)
      Integer(string || '')
    rescue ArgumentError
      1
    end

    def push_milestone_to_teams?(milestone, reminder=false)
      if milestone.milestone_type == :team
        # create events

        milestone.course_project.groups.each do |g|
          json =
            if reminder
              "{}"
            else
              "{}"
            end
          g.events << Event.create({ event_type: :milestone, json_data: json })
        end

        return true
      end
      false
    end

    CourseProject.all.each do |c|
      if ![:draft, :completed, :archived].include? c.status
        c.milestones.all.each do |m|
          # check its email field
          #   check if pre-reminder deadline is passed
          #     send email to relevent recipients
          #     [for_each_team] push reminder to event feed
          # check if its deadline is passed
          #   send email to relevent recipients
          #   [for_each_team] push deadline passed to event feed
          if m.json_data["Email"]["Content"].length > 0
            if !m.json_data["Email"]["Sent"]
              if m.deadline - str_to_int(m.json_data["Email"]["Advance"]) <= DateTime.now
                m.json_data["Email"]["Sent"] = true

                # send reminder email with json_data["Name"] and json_data["Comment"], as well as the number of days left
                MilestoneMailer.reminder_email(self).deliver_later
                push_milestone_to_teams? m, reminder: true
              end
            end
          end
          if m.deadline < DateTime.now
            push_milestone_to_teams? m
          end

          # if progress form deadline passed
          #   ???
          # if team preference < project preference OR either is nil
          #   if team preference form passed [if nil, assume the group were generated at project creation]
          #     allocate groups
          #   if project preference passed
          #     assign mode subproject to each group
          # else [GEC / EYH]
          #   if project preference passed
          #     do nothing
          #   if team preference form passed
          #     allocate groups with project preference heuristics
        end

        if c.completion_deadline < DateTime.now
          c.status = :completed
        end
      end
    end
  end

  private

  def creation_validation
    errors.add(:main, 'Project name cannot be empty') if name.blank?
    unless errors[:main].present?
      if CourseProject.where(name: name, course_module_id: course_module_id).where.not(id: self.id).exists?
        errors.add(:main, 'There exists a project on this module with the same name')
      end
    end

    if project_allocation.blank? || !project_allocation.in?(CourseProject.project_allocations)
      errors.add(:project_choices, "Invalid project allocation mode selected")
    end

    errors.add(:team_config, 'Invalid team size entry') if team_size.nil?
    if team_allocation.blank? || !team_allocation.in?(CourseProject.team_allocations)
      errors.add(:team_config, 'Invalid team allocation mode selected')
    end
    errors.add(:team_config, 'Team size must be greater than 0') if (team_size.present? && team_size <= 0)

    errors.add(:team_pref, 'Invalid preferred teammates entry') if preferred_teammates.nil?
    errors.add(:team_pref, 'Invalid avoided teammates entry') if avoided_teammates.nil?
    if !errors[:team_pref].present? && team_allocation == 'preference_form_based' && (preferred_teammates + avoided_teammates == 0)
      errors.add(:team_pref, 'Preferred and Avoided teammates cannot both be 0')
    end
  end
end
