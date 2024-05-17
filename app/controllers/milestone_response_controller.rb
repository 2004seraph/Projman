# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class MilestoneResponseController < ApplicationController
  load_and_authorize_resource

  def create
    milestone = Milestone.find(params[:milestone_id])

    # Teammate Preference Form Milestone Response
    if milestone.system_type == "teammate_preference_deadline"

      preferred_teammates = extract_teammates(params, :preferred_teammate)
      avoided_teammates = extract_teammates(params, :avoided_teammate)

      preferred_teammates.each do |student_id|
        if avoided_teammates.include?(student_id)
          render json: { error: "Invalid Form Entry" }, status: :unprocessable_entity
          return
        end
      end

      json_data = {}
      json_data["preferred"] = preferred_teammates
      json_data["avoided"] = avoided_teammates

      MilestoneResponse.create(json_data:, milestone_id: milestone.id, student_id: current_user.student.id)

    # Project Choices Form Milestone Response
    elsif milestone.system_type == "project_preference_deadline"

      project = CourseProject.find(milestone.course_project_id)
      choices = extract_choices(params, project)

      json_data = {}
      choices.size.times do |i|
        json_data[i + 1] = choices[i]
      end

      MilestoneResponse.create(json_data:, milestone_id: milestone.id, student_id: current_user.student.id)

    end
  end

  private
    def extract_teammates(params, key)
      teammates = []
      params.each do |param_key, value|
        next unless param_key.to_s.start_with?(key.to_s)
        next if value.nil?

        f_name = value.strip.split(" ")[0]
        l_name = value.strip.split(" ")[1]
        unless Student.where(preferred_name: f_name, surname: l_name).first.nil?
          teammates << Student.where(preferred_name: f_name, surname: l_name).first.id
        end
      end
      teammates
    end

    def extract_choices(params, project)
      choices = []
      params.each do |param_key, value|
        choices << project.subprojects.find_by(name: value).id if param_key.to_s.start_with?("choice_")
      end
      choices
    end
end
