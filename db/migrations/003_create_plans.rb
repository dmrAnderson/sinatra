# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:plans) do
      primary_key :id
      String :name, null: false, unique: true
      Integer :type, null: false, unique: true
      String :description, null: false
      Integer :price, null: false
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
