# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # you must log in to do anything on the entire site.
    return unless user.present?

    # Rails.logger.debug "################################"

    if user.is_student?
      # this if statement exists so that staff dont get these permissions,
      # it wouldnt make sense otherwise.

      # students will only be able to view their own enrollments.
      can :read, CourseModule, id: user.student.course_modules.pluck(:id)
      can :read, CourseProject, id: user.student.course_projects.pluck(:id)
      can :read, Group, id: user.student.groups.pluck(:id)
      can :read, Event, group: { id: user.student.groups.pluck(:id) }

      can [:create], EventResponse
      can [:read], EventResponse, student: { id: user.student.id }
      return
    end

    # Facilitator permissions
    if user.is_staff?
      can :read, Group, id: user.staff.assigned_facilitators.pluck(:course_project_id)
      can [:read, :update], Event, group: { assigned_facilitator: { staff_id: user.staff.id } }
      can [:read], EventResponse, event: { group: { assigned_facilitator: { staff_id: user.staff.id } } }
    elsif user.is_student?
      can :read, Group, id: user.student.assigned_facilitators.pluck(:course_project_id)
      can [:read, :update], Event, group: { assigned_facilitator: { student_id: user.student.id } }
      can [:read], EventResponse, event: { group: { assigned_facilitator: { student_id: user.student.id } } }
    end

    return unless user.is_staff?

    # a staff can only view the modules they lead, not change them.
    can [:read], CourseModule, staff_id: user.staff.id

    # a staff can only view and edit projects they lead.
    # I imagine that when an admin creates a module, they specify the projects,
    # staff can then edit them and only them as they please.
    can [:read, :update], CourseProject, course_module: { staff_id: user.staff.id }

    return unless user.admin?

    can [:read], :admin

    can [:create, :read, :update, :destroy], CourseModule
    can [:create, :read, :update, :destroy], CourseProject
  end
end
