# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:subscriptions) do
      primary_key :id
      foreign_key :user_id, :users, null: false
      foreign_key :plan_id, :plans, null: false
      String :hosted_invoice_url, null: false
      String :stripe_subscription_id, null: false
      DateTime :deactivated_at
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
