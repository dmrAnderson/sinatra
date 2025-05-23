# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :email, null: false, unique: true
      String :password_digest, null: false
      String :stripe_customer_id, unique: true
      String :localization
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
