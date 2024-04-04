class ChangeDefaultValueForEmail < ActiveRecord::Migration[7.0]
  def change
    change_column_default :students, :email, from: nil, to: ""
    change_column_default :staffs, :email, from: nil, to: ""
  end
end
