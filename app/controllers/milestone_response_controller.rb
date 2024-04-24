class MilestoneResponseController < ApplicationController
    load_and_authorize_resource

    def create

      milestone = Milestone.find(params[:milestone_id])

      #Teammate Preference Form Milestone Response
      if milestone.json_data['Name'] == "Teammate Preference Form Deadline"
        
        preferred_teammates = extract_teammates(params, :preferred_teammate)
        avoided_teammates = extract_teammates(params, :avoided_teammate)

        json_data = {}
        json_data["preferred"] = preferred_teammates
        json_data["avoided"] = avoided_teammates

        MilestoneResponse.create(json_data: json_data, milestone_id: milestone.id, student_id: current_user.student.id)
      
      #Project Choices Form Milestone Response
      elsif milestone.json_data['Name'] == "Project Preference Form Deadline" 

        project = CourseProject.find(milestone.course_project_id)
        choices = extract_choices(params, project)

        json_data = {}
        choices.size.times do |i|
          json_data[i+1] = choices[i]
        end

        MilestoneResponse.create(json_data: json_data, milestone_id: milestone.id, student_id: current_user.student.id)

      end

    end

    private

    def extract_teammates(params, key)
      teammates = []
      params.each do |param_key, value|
        if param_key.to_s.start_with?(key.to_s)
          f_name = value.strip.split(" ")[0]
          l_name = value.strip.split(" ")[1]
          teammates << Student.where(preferred_name: f_name, surname: l_name).first.id
        end
      end
      teammates
    end

    def extract_choices(params, project)
      choices = []
      params.each do |param_key, value|
        if param_key.to_s.start_with?('choice_')
          choices << project.subprojects.find_by(name: value).id
        end
      end
      choices
    end

end
