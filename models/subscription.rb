# frozen_string_literal: true

require 'sequel'
require 'bcrypt'

class Subscription < Sequel::Model
  plugin :timestamps, update_on_create: true

  many_to_one :user
  many_to_one :plan

  def validate
    super
    errors.add(:user_id, "can't be empty") if self.user_id.nil?
    errors.add(:plan_id, "can't be empty") if self.plan_id.nil?
  end

  def end_date
    return self.deactivated_at if deactivated?

    self.created_at + 30 * 24 * 60 * 60
  end

  def expired?
    return true if deactivated?

    end_date < Time.now
  end

  def deactivate
    return false if deactivated?

    self.deactivated_at = Time.now
    self.save
    true
  end

  def not_deactivated?
    self.deactivated_at.nil?
  end

  def deactivated?
    !not_deactivated?
  end
end
