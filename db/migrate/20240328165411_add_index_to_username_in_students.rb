class AddIndexToUsernameInStudents < ActiveRecord::Migration[7.0]
  def change
    add_index :students, :username, unique: true
  end
end
