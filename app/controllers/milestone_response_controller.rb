class MilestoneResponseController < ApplicationController
    load_and_authorize_resource

    def create

        preferred_teammates = extract_teammates(params, :preferred_teammate)
        avoided_teammates = extract_teammates(params, :avoided_teammate)

        json_data = {
            preferred: preferred_teammates,
            avoided: avoided_teammates
        }.to_json

        MilestoneResponse.create(json_data: json_data, milestone_id: params[:milestone_id], student_id: current_user.student.id)
    end

    private

    def extract_teammates(params, key)
        teammates = []
        params.each do |param_key, value|
          if param_key.to_s.start_with?(key.to_s)
            teammates << value.strip
          end
        end
        teammates
    end

end
