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

    return unless user.admin?
  end
end
