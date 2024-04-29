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
#  team_allocation     :enum
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
  # !/home/seraph/Documents/University/SoftwareHut/project/bin/rails runner
  has_many :groups, dependent: :destroy
  has_many :milestones, dependent: :destroy
  has_many :assigned_facilitators, dependent: :destroy
  has_many :subprojects, dependent: :destroy
  belongs_to :course_module
  has_one :staff, through: :course_module

  has_many :students, through: :groups

  validate :creation_validation

  enum :status, {
    draft: 'draft',
    student_preference: 'student_preference',
    team_preference: 'team_preference',
    live: 'live',
    completed: 'completed',
    archived: 'archived'
  }

  enum :project_allocation, {
    # random_project_allocation: 'random',
    single_preference_project_allocation: 'single_preference_submission',
    team_preference_project_allocation: 'team_average_preference'
  }

  enum :team_allocation, {
    random_team_allocation: 'random',
    preference_form_based: 'preference_form_based'
  }

  def completion_deadline
    project_completion_deadline.deadline
  end

  def self.lifecycle_job
    # DO NOT RUN THIS IN ANY APP CODE
    # THIS IS A CRON JOB, IT IS RAN BY THE OS

    logger = Logger.new(Rails.root.join('log', 'course_project.lifecycle_job.log'))
    logger.debug("--- LIFECYCLE PASS")

    CourseProject.where.not(status: [:draft, :completed, :archived]).each do |c|
      logger.debug "### Processing #{c.name}"

      if c.team_size == 1 or c.team_allocation == nil
        #individual project -> no group assignment
        if c.project_preference_deadline
          if c.project_preference_deadline.deadline < DateTime.now && !c.project_preference_deadline.executed
            # assign projects to individuals, if not responded, use least popular project
            logger.debug "\tAssigning projects to individuals using project preference"
            DatabaseHelper.assign_projects_to_individuals c
          end
        end
      else
        #group project -> group assignment needed, potentially also project assignment
        if c.teammate_preference_deadline
          if c.teammate_preference_deadline.deadline < DateTime.now && !c.teammate_preference_deadline.executed
            # make groups

            # DatabaseHelper.preference_form_group_allocation
            logger.debug "\tAssigning groups using team mate preferences"
          end
        end
        if c.project_preference_deadline
          if c.project_preference_deadline.deadline < DateTime.now && !c.project_preference_deadline.executed
            # assign projects to groups, if not responded, use least popular project
            logger.debug "\tAssigning projects to groups using group consensus"
            DatabaseHelper.assign_projects_to_groups c
          end
        end
      end

      c.milestones.all.each do |m|
        # check its email field
        #   check if pre-reminder deadline is passed
        #     send email to relevent recipients
        #     [for_each_team] push reminder to event feed
        # check if its deadline is passed
        #   send email to relevent recipients, no actually
        #   [for_each_team] push deadline passed to event feed
        if !m.executed
          if m.json_data["Email"]
            if !m.json_data["Email"]["Sent"]
              if m.deadline - StandardHelper.str_to_int(m.json_data["Email"]["Advance"]) <= DateTime.now
                logger.debug "\tSending advance email for #{m.json_data}"
                logger.debug "\t\tType: #{m.milestone_type}"

                m.json_data["Email"]["Sent"] = true

                # send reminder email with json_data["Name"] and json_data["Comment"], as well as the number of days left
                MilestoneMailer.reminder_email(m).deliver_later
                m.push_milestone_to_teams? reminder: true
                m.save
                m.reload
              end
            end
          end
          if m.deadline < DateTime.now
            logger.debug "\tMilestone #{m.json_data} executed"
            m.push_milestone_to_teams?
            m.update executed: true
            m.save
          end
        end
      end

      if c.completion_deadline < DateTime.now
        logger.debug "\tProject complete"
        c.update status: :completed
        c.save
        c.reload
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

  # automatic method generation to get each of the system milestone types by their enum value name on a project model
  def method_missing(method_name, *args, &block)
    if method_name.to_s.end_with?("_deadline")
      system_type = method_name
      return find_milestone_by_system_type(system_type)
    else
      super
    end
  end
  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.end_with?("_deadline") || super
  end
  def find_milestone_by_system_type(system_type)
    milestones.each do |m|
      if m.system_type == system_type.to_s
        return m
      end
    end
    nil
  end
end

# CourseProject.lifecycle_job