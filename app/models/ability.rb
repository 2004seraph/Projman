# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # you must log in to do anything on the entire site
    return unless user.present?

    can :read, :page
    can :read, CourseProject

    return unless user.instance_of? Staff

    can :update, CourseProject
    can :read, :lead
    # the staff need to be allowed to view and update the projects/:id/teams route

    return unless user.admin?

    can :create, CourseProject
  end
end
