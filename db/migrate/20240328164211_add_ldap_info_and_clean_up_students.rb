class AddLdapInfoAndCleanUpStudents < ActiveRecord::Migration[7.0]
  def change
    Student.reset_column_information
    existing_columns = Student.column_names

    unless existing_columns.include?('username')
      add_column :students, :username, :string
      add_index :students, :username
    end

    if existing_columns.include?('email')
      # We don't want the unique index on email which is added by devise by default
      remove_index :students, :email
    else
      add_column :students, :email, :string
    end
    add_index :students, :email

    # Cache the ldap attributes
    missing_columns = %w(uid mail ou dn sn givenname account_type) - existing_columns
    missing_columns.each do |column_name|
      add_column :students, column_name, :string
    end

    reversible do |dir|
      dir.up do
        # Remove devise fields we don't need
        unnecessary_columns = %w(reset_password_token reset_password_sent_at remember_created_at encrypted_password) & existing_columns
        unnecessary_columns.each do |column_name|
          remove_column :students, column_name
        end
      end
      dir.down do
        add_column :users, :reset_password_token, :string
        add_index :users, :reset_password_token, unique: true
      end
    end
  end
end