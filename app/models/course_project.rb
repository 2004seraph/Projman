# frozen_string_literal: true

# == Schema Information
#
# Table name: course_projects
#
#  id                        :bigint           not null, primary key
#  avoided_teammates         :integer          default(0)
#  markscheme_json           :json
#  name                      :string           default("Unnamed Project"), not null
#  preferred_teammates       :integer          default(0)
#  status                    :enum             default("draft"), not null
#  team_allocation           :enum
#  team_size                 :integer          not null
#  teams_from_project_choice :boolean          default(FALSE), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  course_module_id          :bigint           not null
#
# Indexes
#
#  index_course_projects_on_course_module_id  (course_module_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_module_id => course_modules.id)
#

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

require "database_helper"

class CourseProject < ApplicationRecord
  has_many :groups, dependent: :destroy
  has_many :milestones, dependent: :destroy
  has_many :assigned_facilitators, dependent: :destroy
  has_many :subprojects, dependent: :destroy
  belongs_to :course_module
  has_one :staff, through: :course_module

  has_many :students, through: :course_module

  validate :creation_validation

  enum :status, {
    draft:       "draft",
    preparation: "preparation",
    review:      "review",
    live:        "live",
    completed:   "completed",
    archived:    "archived"
  }

  enum :team_allocation, {
    random_team_allocation: "random",
    preference_form_based:  "preference_form_based"
  }

  # before_destroy :remove_all_references, prepend: true

  def completion_deadline
    project_completion_deadline.deadline
  end

  def project_notification?(current_user, group)
    if Event.chat_notification?(current_user, group)
      true
    else
      false
    end
  end

  def facilitators
    result = []
    assigned_facilitators.each do |f|
      if !f.staff_id.nil?
        result << Staff.find(f.staff_id)
      elsif !f.student_id.nil?
        result << Student.find(f.student_id)
      end
    end
    result
  end

  def show_remake_teams_button?
    proj_pref = Milestone.find_by(system_type: :project_preference_deadline, course_project_id: id)
    pref_form = Milestone.find_by(system_type: :teammate_preference_deadline, course_project_id: id)

    if (team_allocation == "random_team_allocation" && teams_from_project_choice == false) ||
       (teams_from_project_choice == true && proj_pref && proj_pref.deadline < Time.zone.now) ||
       (team_allocation == "preference_form_based" && pref_form && pref_form.deadline < Time.zone.now)

      true
    else
      false
    end
  end

  def assign_facilitators_to_groups
    return false unless assigned_facilitators.length > 0
    return false unless groups.length > 0
    groups_per_fac = (groups.length.to_f / assigned_facilitators.length).ceil

    groups.each_slice(groups_per_fac).with_index do |chunk, index|
      chunk.each do |g|
        g.assigned_facilitator = assigned_facilitators[index]
        g.save
      end
    end
    save
    reload
    true
  end

  def make_groups_with_project_preference(group_matrix_hash)
    # expects a hash of subproject.id => [[students]]
    group_matrix_hash.each do |subproject_id, group_matrix|
      group_matrix.each_with_index do |teammate_list, index|
        g = Group.make self, teammate_list
        g.subproject = Subproject.find subproject_id
        g.save
      end
    end
    assign_facilitators_to_groups
  end

  private

    def creation_validation
      errors.add(:main, "Project name cannot be empty") if name.blank?
      if errors[:main].blank? && CourseProject.where(name:, course_module_id:).where.not(id:).exists?
        errors.add(:main, "There exists a project on this module with the same name")
      end

      errors.add(:team_config, "Invalid team size entry") if team_size.nil?
      if !team_allocation.in?(CourseProject.team_allocations) && !team_allocation.nil?
        errors.add(:team_config, "Invalid team allocation mode selected")
      end
      errors.add(:team_config, "Team size must be greater than 0") if team_size.present? && team_size <= 0

      errors.add(:team_pref, "Invalid preferred teammates entry") if preferred_teammates.nil?
      errors.add(:team_pref, "Invalid avoided teammates entry") if avoided_teammates.nil?
      if errors[:team_pref].blank?
        if team_allocation == "preference_form_based" && (preferred_teammates + avoided_teammates).zero?
          errors.add(:team_pref, "Preferred and Avoided teammates cannot both be 0")
        end
        if team_allocation == "preference_form_based" && (preferred_teammates > 1)
          errors.add(:team_pref, "You cannot have more than 1 preferred teammate")
        end
      end
    end

    # automatic method generation to get each of the system milestone types by their enum value name on a project model
    def method_missing(method_name, *args, &block)
      if method_name.to_s.end_with?("_deadline")
        system_type = method_name
        find_milestone_by_system_type(system_type)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.end_with?("_deadline") || super
    end

    def find_milestone_by_system_type(system_type)
      milestones.each do |m|
        return m if m.system_type == system_type.to_s
      end
      nil
    end

    def make_groups(group_matrix)
      group_matrix.each_with_index do |teammate_list, index|
        Group.make self, teammate_list
      end
      assign_facilitators_to_groups
    end

    # def remove_all_references
    #   assigned_facilitators.delete_all
    #   # groups.delete_all

    #   save
    #   reload
    # end

    # BEGIN BACKGROUND_JOBS

    class JobLogger
      def initialize(logger)
        @logger = logger
      end
      def debug(msg)
        puts msg
        @logger.debug(msg)
      end
    end

    def self.lifecycle_job
      # !/home/seraph/Documents/University/SoftwareHut/project/bin/rails runner
      # DO NOT RUN THIS IN ANY APP CODE
      # THIS IS A CRON JOB, IT IS RAN BY THE OS

      logger = JobLogger.new(Logger.new(Rails.root.join("log/course_project.lifecycle_job.log")))
      logger.debug("--- LIFECYCLE PASS")

      unless DatabaseHelper.database_exists?
        logger.debug("Database is not present, suspending job run")
        Sentry.capture_message("Database is not present, suspending job run", level: :warn)
        return false
      end

      CourseProject.where.not(status: %i[draft completed archived]).find_each do |c|
        logger.debug "### Processing #{c.name}"

        if c.team_allocation.nil?

          if c.teams_from_project_choice
            # GEC style project
            if c.project_preference_deadline && (c.project_preference_deadline.deadline < DateTime.now && !c.project_preference_deadline.executed)
              # assign groups based off of project preference
              logger.debug "\tAssigning groups using project preferences"
              m = c.project_preference_deadline
              m.executed = true
              m.save!
              m.reload

              group_matrix = DatabaseHelper.project_choices_group_allocation c.team_size, c.students, c.project_preference_deadline
              c.make_groups_with_project_preference group_matrix
            end

          else
            # individual project: [project assignment]/[NOTHING]
            if c.project_preference_deadline && (c.project_preference_deadline.deadline < DateTime.now && !c.project_preference_deadline.executed)
              # assign projects to individuals, if not responded, use least popular project
              logger.debug "\tAssigning projects to individuals using project preference"
              DatabaseHelper.assign_projects_to_individuals c
            end
          end

        elsif c.team_allocation == "preference_form_based"
          # standard project: team mate preference -> [group project preference]/[DONE]
          if c.teammate_preference_deadline
            if c.teammate_preference_deadline.deadline < DateTime.now && !c.teammate_preference_deadline.executed
              logger.debug "\tAssigning groups using team mate preferences"

              group_matrix = DatabaseHelper.preference_form_group_allocation c.team_size, c.students,
                                                                             c.teammate_preference_deadline
              c.make_groups group_matrix
            end
          end
          if c.project_preference_deadline && (c.project_preference_deadline.deadline < DateTime.now && !c.project_preference_deadline.executed)
            # assign projects to groups, if not responded, use least popular project
            logger.debug "\tAssigning projects to groups using group consensus"
            DatabaseHelper.assign_projects_to_groups c
          end
        end

        c.reload

        c.milestones.all.each do |m|
          # check its email field
          #   check if pre-reminder deadline is passed
          #     send email to relevent recipients
          #     [for_each_team] push reminder to event feed
          # check if its deadline is passed
          #   send email to relevent recipients, no actually
          #   [for_each_team] push deadline passed to event feed
          next if m.executed

          if m.json_data["Email"] && !(m.json_data["Email"]["Sent"]) && (m.deadline - StandardHelper.str_to_int(m.json_data["Email"]["Advance"]) <= DateTime.now)
            logger.debug "\tSending advance email for #{m.json_data}"
            logger.debug "\t\tType: #{m.milestone_type}"

            m.json_data["Email"]["Sent"] = true

            # send reminder email with json_data["Name"] and json_data["Comment"], as well as the number of days left
            MilestoneMailer.reminder_email(m).deliver_later
            m.push_milestone_to_teams? true, logger
            # logger.debug "end"
            m.reload
          end
          next unless m.deadline < DateTime.now

          logger.debug "\tMilestone #{m.json_data} executed"
          m.push_milestone_to_teams? false, logger
          m.executed = true
          m.save!
          m.reload
        end

        c.reload

        next unless c.completion_deadline < DateTime.now

        logger.debug "\tProject complete"
        c.update status: :completed
        c.save
      end
      true
    end
end

# CourseProject.lifecycle_job
