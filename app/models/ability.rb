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

    can %i[read request_title_change], :page
    can %i[read create issue_response update_selection update_status], :issue

    # Rails.logger.debug "################################"

    if user.is_student?
      # this if statement exists so that staff dont get these permissions,
      # it wouldnt make sense otherwise.

      # students will only be able to view their own enrollments.
      # can :read, CourseModule, id: user.student.course_modules.pluck(:id)
      can %i[read search_student_name send_chat_message], CourseProject, id: user.student.course_projects.pluck(:id)
      # can :read, Group, id: user.student.groups.pluck(:id)
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
        # can :read, Group, assigned_facilitator: { staff_id: user.staff.id }
        can %i[read update], Event, group: {
          assigned_facilitator: { staff_id: user.staff.id }
        }
        can [:read], EventResponse, event: {
          group: { assigned_facilitator: { staff_id: user.staff.id } }
        }
        can [:facilitator_team], Group do |group|
          group&.course_project&.assigned_facilitators&.pluck(:staff_id)&.include?(user.staff.id)
        end

      elsif user.is_student?
        # can :read, Group, assigned_facilitator: { student_id: user.student.id }
        can %i[read update], Event, group: {
          assigned_facilitator: { student_id: user.student.id }
        }
        can [:read], EventResponse, event: {
          group: { assigned_facilitator: { student_id: user.student.id } }
        }
        can [:facilitator_team], Group do |group|
          group&.course_project&.assigned_facilitators&.pluck(:student_id)&.include?(user.student.id)
        end
      end
    end

    # can [:read], MilestoneResponse do |milestone_response|
    #   module_lead = milestone_response.milestone.course_module&.staff_id
    #   Rails.logger.debug("AAAAAAAAAAAA #{module_lead}")
    #   module_lead == user.staff&.id
    # end

    # staff permissions
    return unless user.is_staff?

    can %i[mail], :page

    # A staff can view students view
    can %i[read index update_selection search_students confirm_selection clear_selection clear_student remove_students_from_module],
        Student

    # a staff can only view the modules they lead, not change them.
    can [:read], CourseModule, staff_id: user.staff.id

    # a staff can manipulate teams under their module(groups)
    can %i[
      create
      read
      update
      delete
      facilitator_emails
      set_facilitator
      current_subproject
      set_subproject
      search_module_students
      add_student_to_team
      remove_students_from_team
    ], Group, course_module: { staff_id: user.staff.id }

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
      remake_teams
    ], CourseProject
    can %i[read edit update], CourseProject, course_module: { staff_id: user.staff.id }


    return unless user.staff.admin

    can [:manage], :all
    # can %i[read index update_selection search_students confirm_selection clear_selection clear_student remove_students_from_module],
    # Student

    # # can [:read], :admin
    # can [:read], :facilitator 
    # can [:read], EventResponse
    # can %i[read update], Event

    # can %i[
    #   create
    #   read
    #   update
    #   delete
    #   facilitator_emails
    #   set_facilitator
    #   current_subproject
    #   set_subproject
    #   search_module_students
    #   add_student_to_team
    #   remove_students_from_team
    # ], Group
    # can %i[create read update destroy], CourseModule

    # can %i[
    #   create

    #   add_project_choice
    #   remove_project_choice
    #   add_project_milestone
    #   remove_project_milestone
    #   clear_facilitator_selection
    #   add_to_facilitator_selection
    #   remove_from_facilitator_selection
    #   add_facilitator_selection
    #   remove_facilitator
    #   search_facilitators_student
    #   search_facilitators_staff
    #   get_milestone_data
    #   remove_milestone_email
    #   set_milestone_email_data
    #   set_milestone_comment
    #   remake_teams
    # ], CourseProject
    # can %i[read edit update], CourseProject
  end
end
