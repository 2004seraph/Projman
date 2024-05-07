# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.


class Ability
  include CanCan::Ability

  # This is an amazing best practices cheatsheet that I'm using for this file:
  # https://greena13.github.io/blog/2019/07/12/cancancan-cheatsheet/

  def initialize(user)
    # you must log in to do anything on the entire site.
    return if user.blank?

    can [:read], :page
    can %i[read create issue_response update_selection update_status], :issue

    # Rails.logger.debug "################################"

    if user.is_student?
      # this if statement exists so that staff dont get these permissions,
      # it wouldnt make sense otherwise.

      # students will only be able to view their own enrollments.
      # can :read, CourseModule, id: user.student.course_modules.pluck(:id)
      can %i[read search_student_name send_chat_message], CourseProject, id: user.student.course_projects.pluck(:id)
      can :read, Group, id: user.student.groups.pluck(:id)
      can :read, Event, group: { id: user.student.groups.pluck(:id) }

      can [:create], EventResponse
      # can read their own responses
      can [:read], EventResponse, student: { id: user.student.id }

      can [:create], MilestoneResponse
      can [:read], MilestoneResponse, student: { id: user.student.id }
    end

    # Facilitator permissions
    if user.is_facilitator?
      can :read, :facilitator

      if user.is_staff?
        can :read, Group, assigned_facilitator: { staff_id: user.staff.id }
        can %i[read update], Event, group: {
          assigned_facilitator: { staff_id: user.staff.id }
        }
        can [:read], EventResponse, event: {
          group: { assigned_facilitator: { staff_id: user.staff.id } }
        }

      elsif user.is_student?
        can :read, Group, assigned_facilitator: { student_id: user.student.id }
        can %i[read update], Event, group: {
          assigned_facilitator: { student_id: user.student.id }
        }
        can [:read], EventResponse, event: {
          group: { assigned_facilitator: { student_id: user.student.id } }
        }
      end
    end

    # staff permissions
    return unless user.is_staff?

    # A staff can view students view
    can [:read], Student

    # a staff can only view the modules they lead, not change them.
    can [:read], CourseModule, staff_id: user.staff.id

    # a staff can manipulate teams under their module(groups)
    can %i[create read update delete facilitator_emails set_facilitator current_subproject set_subproject], Group, course_module: { staff_id: user.staff.id }

    # a staff can create projects
    # a staff can only view and edit projects they lead.
    can %i[
      create

      add_project_choice
      remove_project_choice
      add_project_milestone
      remove_project_milestone
      clear_facilitator_selection
      add_to_facilitator_selection
      remove_from_facilitator_selection
      add_facilitator_selection
      remove_facilitator
      search_facilitators_student
      search_facilitators_staff
      get_milestone_data
      remove_milestone_email
      set_milestone_email_data
      set_milestone_comment
    ], CourseProject
    can %i[read edit update teams], CourseProject, course_module: { staff_id: user.staff.id }

    return unless user.staff.admin

    # can [:read], :admin
    can [:read], :facilitator
    can [:read], EventResponse
    can %i[read update], Event
    can %i[create read update destroy], Group
    can %i[create read update destroy], CourseModule
    can %i[create read edit teams update destroy], CourseProject
  end
end
