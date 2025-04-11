# frozen_string_literal: true

require 'sequel'

class Plan < Sequel::Model
  plugin :timestamps, update_on_create: true

  BASIC = 10
  STANDARD = 20
  PREMIUM = 30

  PLANS = [
    { type: BASIC, name: 'Basic Plan', description: 'Basic plan with limited features.', price: 10 },
    { type: STANDARD, name: 'Standard Plan', description: 'Standard plan with additional features.', price: 20 },
    { type: PREMIUM, name: 'Premium Plan', description: 'Premium plan with all features included.', price: 30 }
  ]

  def validate
    super
    errors.add(:name, "can't be empty") if self.name.empty?
    errors.add(:name, "must be unique") if Plan.where(name: self.name).count > 0
    errors.add(:type, "must be a valid plan type") unless [BASIC, STANDARD, PREMIUM].include?(self.type)
    errors.add(:description, "can't be empty") if self.description.empty?
    errors.add(:price, "must be a positive number") if self.price.nil? || self.price <= 0
  end

  def self.all
    seed
    super
  end

  def self.seed
    return if Plan.count > 0

    PLANS.each do |data|
      plan = Plan.create(data)

      next if ENV['RACK_ENV'] == 'test'

      product = Stripe::Product.create(
        name: plan.name,
        description: plan.description,
        metadata: { plan_id: plan.id }
      )
      Stripe::Plan.create(
        currency: 'usd',
        interval: 'month',
        amount: plan.price * 100,
        product: product.id
      )
    end
  end
end
