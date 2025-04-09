# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:posts) do
      primary_key :id
      foreign_key :user_id, :users, null: false
      String :title, null: false
      String :content, text: true, null: false
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
