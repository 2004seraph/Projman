require 'rails_helper'

RSpec.describe Project, type: :model do
  context "Should accept" do
    it "with a valid generated class list" do
      x = Project.create
    end
  end
end